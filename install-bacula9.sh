#!/bin/bash

# Preencha o valor do 'IP' de: "seu_ip" pelo ip válido definido em seu servidor:
IP="seu_ip"

# Preencha o valor da 'SENHA_BACULA' de: "senha_bacula" pela senha que será definida para o usuário 'bacula' da base PostgreSQL:
SENHA_BACULA="senha_bacula"

# Preencha o valor da 'SENHA_POSTGRES' de: "senha_postgres" pela senha que será definida para o usuário 'postgres' da base PostgreSQL:
SENHA_POSTGRES="senha_postgres"

# Preencha o valor da 'EMAIL' de: "seumail@localhost.com" por uma caixa de email válida:
EMAIL="seumail@localhost.com"

# Limpando a tela do console:
/usr/bin/clear

echo -e "###############################################################"
echo -e "# Passos para Instalação do Bacula 9 via Compilação no Debian #"
echo -e "# PostgreSQL                                                  #"
echo -e "# Autor: Daniel Cavalcante                                    #"
echo -e "# Data atualização:  05/01/2018                               #"
echo -e "###############################################################"
echo -e "# Notas:"
echo -e "# Se possuir algum erro, revise o código-fonte novamente."
echo -e "# Este script foi testado no Sistema Operacional Debian 8."
echo -e
echo -e
echo -e "* Caso não desejar prosseguir com a instalação, pressione as teclas Ctrl+c para Cancelar."
echo -e
echo -e "* O instalador estará sendo executado em alguns instantes..."

/bin/sleep 4

echo -e

# Limpando a tela do console:
/usr/bin/clear
					
#-----------------------------------------------------------------------------------#
# >>> Atualizar a lista dos pacotes e distribuiçao <<<                              #
#-----------------------------------------------------------------------------------#
echo -e "Atualizando a lista dos pacotes e distribuição..."
echo -e

/bin/sleep 4

apt-get update
apt-get upgrade -y
apt dist-upgrade -y
apt-get -y autoclean
apt-get -y autoremove

# Limpando a tela do console:
/usr/bin/clear
					
					
#-----------------------------------------------------------------------------------#
# >>> Pacotes necessários para compilação padrão + alguns utilitários <<<           #
#-----------------------------------------------------------------------------------#
echo -e
echo -e "# Instalando os pacotes / dependências necessárias para compilação padrão e mais alguns utilitários..."
echo -e
echo -e "# Obs.: Quando solicitar a configuração do postfix, deixar como \"Site da Internet\", e o domínio do email, definir para: localhost..."
echo -e
echo -e "* Caso não desejar prosseguir com a instalação, pressione as teclas Ctrl+c para Cancelar."
echo -e
echo -e "* O instalador do Bacula Backup System e de suas dependências estarão sendo executados em alguns instantes..."

/bin/sleep 4

echo -e

apt-get install -y build-essential libreadline6-dev zlib1g-dev liblzo2-dev mt-st mtx postfix libacl1-dev libssl-dev

# Limpando a tela do console:
/usr/bin/clear


#-----------------------------------------------------------------------------------#
# >>> Pacotes para utilizar o banco de dados PostgreSQL <<<                         #
#-----------------------------------------------------------------------------------#
echo -e "Pacotes para utilizar o Banco de Dados PostgreSQL..."
echo -e

/bin/sleep 4

apt-get install -y postgresql-server-dev-9.4 postgresql-9.4

# Limpando a tela do console:
/usr/bin/clear


#-----------------------------------------------------------------------------------#
# >>> Baixando e compilando e instalando o fonte Bacula Server 9 <<<                #
#-----------------------------------------------------------------------------------#
echo -e "Baixando, compilando, e instalando o fonte Bacula Server 9..."
echo -e

/bin/sleep 4

cd /usr/src
# Utilizando wget:
wget --no-check-certificate https://sourceforge.net/projects/bacula/files/bacula/9.0.6/bacula-9.0.6.tar.gz
tar xvzf bacula*
cd /usr/src/bacula*

#****************************************************************************************************#
# Nessa parte abaixo é preciso definir o banco de dados que será utilizado, neste caso, o PostgreSQL #
# Utilize os comandos de acordo com o banco escolhido.                                               #
#****************************************************************************************************#
# Comando de pré-compilação para o SGBD PostgreSQL:
./configure --with-readline=/usr/include/readline --with-systemd --disable-conio --bindir=/usr/bin --sbindir=/usr/sbin --sysconfdir=/etc/bacula --with-scriptdir=/etc/bacula/scripts --with-working-dir=/var/lib/bacula --with-logdir=/var/log/bacula --enable-smartalloc --with-postgresql --with-db-user=bacula --with-db-password=$SENHA_POSTGRES --with-db-port=5432 --with-archivedir=/bacula-backup/backup --with-pid-dir=/var/run --with-job-email=$EMAIL --with-hostname=$IP

# Comando para efetuar a compilação e instalação:
make -j 8
make install
make install-autostart

echo -e

# Comando para criar o diretório onde será restaurado os arquivos:
mkdir -p /bacula-backup/restore

#***************************************************************************************************#
# Passos para criação do banco de dados, usuários e  permisssões PostgreSQL                         #
#***************************************************************************************************#

#-----------------------------------------------------------------------------------#
# >>> Criar as tabelas do Bacula no PostgreSQL <<<                                  #
#-----------------------------------------------------------------------------------#
chmod 775 /etc/bacula

cd /etc/bacula/scripts

chown postgres create_postgresql_database
chown postgres make_postgresql_tables
chown postgres grant_postgresql_privileges 

echo -e "Criando banco de dados Bacula..."
su postgres -c './create_postgresql_database'

echo -e "Criando todas as tabelas do Bacula..."
su postgres -c './make_postgresql_tables'

echo -e "Setando permissionamento das tabelas na base de dados Bacula..."
su postgres -c './grant_postgresql_privileges'

echo -e

#-----------------------------------------------------------------------------------#
# >>> Configurar o acesso ao PostgreSQL pelo Bacula <<<                             #
#-----------------------------------------------------------------------------------#
# Antes de copiar o arquivo, é verificado se o arquivo /etc/postgresql/9.4/main/pg_hba.conf.orig já existe:
if [ -f /etc/postgresql/9.4/main/pg_hba.conf.orig ]; then
	echo "O arquivo /etc/postgresql/9.4/main/pg_hba.conf.orig já existe!"
	/bin/sleep 2
else
	# Cópia de segurança do arquivo de configuração do PostgreSQL /etc/postgresql/9.4/main/pg_hba.conf:
	cp -a /etc/postgresql/9.4/main/pg_hba.conf /etc/postgresql/9.4/main/pg_hba.conf.orig
fi

# Antes de renomear o arquivo, é verificado se o arquivo /etc/postgresql/9.4/main/postgresql.conf.orig já existe:
if [ -f /etc/postgresql/9.4/main/postgresql.conf.orig ]; then
	echo "O arquivo /etc/postgresql/9.4/main/postgresql.conf.orig já existe!"
	/bin/sleep 2
else
	# Cópia de segurança do arquivo de configuração do PostgreSQL /etc/postgresql/9.4/main/postgresql.conf.orig:
	cp -a /etc/postgresql/9.4/main/postgresql.conf /etc/postgresql/9.4/main/postgresql.conf.orig
fi

echo -e

# Script de todas as bases de dados (all), e todos os usuários (all)  de 'peer' para 'md5' no arquivo /etc/postgresql/9.4/main/pg_hba.conf:
sed -i -e 's/local   all             all                                     peer/local   all             all                                     md5/g' /etc/postgresql/9.4/main/pg_hba.conf

# Script de substituição do usuário postgres de 'peer' para 'md5' no arquivo /etc/postgresql/9.4/main/pg_hba.conf:
sed -i -e 's/local   all             postgres                                peer/local   all             postgres                                md5/g' /etc/postgresql/9.4/main/pg_hba.conf

# Incluindo no final do arquivo o usuário e base de dados Bacula em /etc/postgresql/9.4/main/pg_hba.conf:
echo -e "host    bacula          bacula          127.0.0.1/32            md5" >> /etc/postgresql/9.4/main/pg_hba.conf

# Substituindo o parâmetro listen_addresses de 'localhost' para '*' em /etc/postgresql/9.4/main/postgresql.conf:
sed -i -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/9.4/main/postgresql.conf

#-----------------------------------------------------------------------------------#
# >>> Definindo a senha do usuário Bacula no PostgreSQL <<<                         #
#-----------------------------------------------------------------------------------#
su - postgres -c "psql -U postgres -d postgres -c \"alter user bacula with password '$SENHA_BACULA';\""

#-----------------------------------------------------------------------------------#
# >>> Definindo a senha do usuário postgres no PostgreSQL <<<                         #
#-----------------------------------------------------------------------------------#
# Configurar o usuário padrão para administrar o Postgre
# Por padrão o Postgre cria um novo usuário chamado “postgres” e é com este usuário que você vai administrar o seu SGDB.
# No terminal, mude para o usuário mencionado digitando o seguinte comando:
su - postgres -c "psql -U postgres -d postgres -c \"alter user postgres with password '$SENHA_POSTGRES';\""

#------------------------------------------------------------------------------------------------------------------------------------#
# >>> Definindo autenticação automática na execução dos scripts dos usuários bacula e postgres sobre a base bacula no PostgreSQL <<< #
#------------------------------------------------------------------------------------------------------------------------------------#
touch /root/.pgpass

echo -e "localhost:*:*:postgres:$SENHA_POSTGRES" > /root/.pgpass
echo -e "localhost:*:bacula:bacula:$SENHA_BACULA" >> /root/.pgpass
echo -e >> /root/.pgpass

chmod 600 /root/.pgpass

# Reiniciar serviço PostgreSQL:
/etc/init.d/postgresql restart

#-----------------------------------------------------------------------------------#
# >>> Ajustes no Bacula <<<                                                         #
#-----------------------------------------------------------------------------------#
# Efetuando ajustes no caminho onde será restaurado os arquivos Backupeados pelo bacula:
sed -i -e 's/Where = \/bacula-backup\/backup\/bacula-restores/Where = \/bacula-backup\/restore/g' /etc/bacula/bacula-dir.conf

# Efetuando os devidos ajustes na string de conexão com Banco de Dados PostgreSQL para que o mesmo seja bem sucedido:
sed -i -e '/Name = MyCatalog/a\  dbdriver = "dbi:postgresql"; dbaddress = 127.0.0.1; dbport = 5432' /etc/bacula/bacula-dir.conf
echo -e

# Renomeando os principais arquivos de configuração originais do Bacula:
# Antes de renomear o arquivo, é verificado se o arquivo /etc/bacula/bacula-dir.conf.orig já existe:
if [ -f /etc/bacula/bacula-dir.conf.orig ]; then
	echo "O arquivo /etc/bacula/bacula-dir.conf.orig já existe!"
	/bin/sleep 2
else
	# Não existindo, o arquivo /etc/bacula/bacula-dir.conf.orig original é renomeado de bacula-dir.conf para bacula-dir.conf.orig
	mv /etc/bacula/bacula-dir.conf /etc/bacula/bacula-dir.conf.orig
fi

# Antes de renomear o arquivo, é verificado se o arquivo /etc/bacula/bacula-fd.conf.orig já existe:
if [ -f /etc/bacula/bacula-fd.conf.orig ]; then
	echo "O arquivo /etc/bacula/bacula-fd.conf.orig já existe!"
	/bin/sleep 2
else
	# Não existindo, o arquivo /etc/bacula/bacula-fd.conf.orig original é renomeado de bacula-fd.conf para bacula-fd.conf.orig
	mv /etc/bacula/bacula-fd.conf /etc/bacula/bacula-fd.conf.orig
fi

# Antes de renomear o arquivo, é verificado se o arquivo /etc/bacula/bacula-sd.conf.orig já existe:
if [ -f /etc/bacula/bacula-sd.conf.orig ]; then
	echo "O arquivo /etc/bacula/bacula-sd.conf.orig já existe!"
	/bin/sleep 2
else
	# Não existindo, o arquivo /etc/bacula/bacula-sd.conf.orig original é renomeado de bacula-sd.conf para bacula-sd.conf.orig
	mv /etc/bacula/bacula-sd.conf /etc/bacula/bacula-sd.conf.orig
fi

# Antes de renomear o arquivo, é verificado se o arquivo /etc/bacula/bconsole.conf.orig já existe:
if [ -f /etc/bacula/bconsole.conf.orig ]; then
	echo "O arquivo /etc/bacula/bconsole.conf.orig já existe!"
	/bin/sleep 2
else
	# Não existindo, o arquivo /etc/bacula/bconsole.conf.orig original é renomeado de bconsole.conf para bconsole.conf.orig
	mv /etc/bacula/bconsole.conf /etc/bacula/bconsole.conf.orig
fi

# Criando o arquivo bacula-dir.conf em /etc/bacula/bacula-dir.conf:
touch /etc/bacula/bacula-dir.conf

# Customizando o arquivo /etc/bacula/bacula-dir.conf com seus devidos ajustes:
echo -e "#
#  Bacula Director Arquivo de Configuração Padrão
#
#  Editado e customizado por Daniel Cavalcante
#
#

Director {                            # define myself
  Name = $HOSTNAME-dir
  DIRport = 9101                # where we listen for UA connections
  QueryFile = \"/etc/bacula/scripts/query.sql\"
  WorkingDirectory = \"/var/lib/bacula\"
  PidDirectory = \"/var/run\"
  Maximum Concurrent Jobs = 99
  Password = \"senha_console\"         # Console password
  Messages = Daemon
}

JobDefs {
  Name = \"DefaultJob\"
  Type = Backup
  Level = Incremental
  Client = $HOSTNAME-fd
  FileSet = \"Bacula Arquivos Set\"
  Schedule = \"Agenda_GFS_Bacula\"
  Storage = File1
  Messages = Standard
  Pool = Diario-Bacula
  SpoolAttributes = yes
  Priority = 10
  Write Bootstrap = \"/var/lib/bacula/%c.bsr\"
}


#
# Define the main nightly save backup job
#   By default, this job will back up to disk in /bacula-backup/backup
Job {
  Name = \"BackupArquivosBacula\"
  JobDefs = \"DefaultJob\"
}


# Backup the catalog database (after the nightly save)
Job {
  Name = \"BackupCatalogoBacula\"
  JobDefs = \"DefaultJob\"
  Level = Full
  FileSet=\"Catalog\"
  Schedule = \"Agenda_GFS_Bacula\"
  RunBeforeJob = \"/etc/bacula/scripts/make_catalog_backup.pl MyCatalog\"
  # This deletes the copy of the catalog
  #RunAfterJob  = \"/etc/bacula/scripts/delete_catalog_backup\"
  Write Bootstrap = \"/var/lib/bacula/%n.bsr\"
  Priority = 11                   # run after main backup
}

#
# Standard Restore template, to be changed by Console program
#  Only one such job is needed for all Jobs/Clients/Storage ...
#
Job {
  Name = \"RestoreFiles\"
  Type = Restore
  Client=$HOSTNAME-fd
  Storage = File1
# The FileSet and Pool directives are not used by Restore Jobs
# but must not be removed
  FileSet=\"Bacula Arquivos Set\"
  Pool = Diario-Bacula
  Messages = Standard
  Where = /bacula-backup/restore
}


# List of files to be backed up
FileSet {
  Name = \"Bacula Arquivos Set\"
  Include {
    Options {
      signature = MD5
      Compression = GZIP
    }
    File = /home
    File = /root
    File = /etc
    File = /var
    File = /opt
    File = /usr
  }

#
# If you backup the root directory, the following two excluded
#   files can be useful
#
  Exclude {
    File = /var/log
    File = /var/tmp
    File = /var/cache
    File = /var/lock
    File = /var/run
    File = /usr/bin
    File = /usr/sbin
    File = /usr/games
    File = /usr/local/bin
    File = /usr/local/sbin
    File = /usr/local/games
    File = /usr/local/man
  }
}

#
# When to do the backups, full backup on first sunday of the month,
#  differential (i.e. incremental since full) every other sunday,
#  and incremental backups other days
Schedule {
  Name = \"Agenda_GFS_Bacula\"
  Run=Level=Incremental     Pool=Diario-Bacula     monday-thursday    at 07:00
  Run=Level=Differential    Pool=Semanal-Bacula    2nd-5th friday     at 07:00
  Run=Level=Full            Pool=Mensal-Bacula     1st friday         at 07:00
  Run=Level=Full            Pool=Anual-Bacula      dec 5th            at 08:00
}

# This is the backup of the catalog
FileSet {
  Name = \"Catalog\"
  Include {
    Options {
      signature = MD5
      Compression = GZIP
    }
    File = \"/var/lib/bacula/bacula.sql\"
  }
}

# Client (File Services) to backup
Client {
  Name = $HOSTNAME-fd
  Address = $IP
  FDPort = 9102
  Catalog = MyCatalog
  Password = \"senha_cliente\"          # password for FileDaemon
  File Retention = 99 years            # 60 days
  Job Retention = 99 years            # six months
  AutoPrune = yes                     # Prune expired Jobs/Files
}


# Definition of file Virtual Autochanger device
Autochanger {
  Name = File1
# Do not use \"localhost\" here
  Address = $IP                # N.B. Use a fully qualified name here
  SDPort = 9103
  Password = \"senha_storage\"
  Device = FileChgr1
  Media Type = File1
  Maximum Concurrent Jobs = 10        # run up to 10 jobs a the same time
  Autochanger = File1                 # point to ourself
}

# Definition of a second file Virtual Autochanger device
#   Possibly pointing to a different disk drive
Autochanger {
  Name = File2
# Do not use \"localhost\" here
  Address = $IP                # N.B. Use a fully qualified name here
  SDPort = 9103
  Password = \"senha_storage\"
  Device = FileChgr2
  Media Type = File2
  Autochanger = File2                 # point to ourself
  Maximum Concurrent Jobs = 10        # run up to 10 jobs a the same time
}

# Generic catalog service
Catalog {
  Name = MyCatalog
  dbdriver = \"dbi:postgresql\"; dbaddress = 127.0.0.1; dbport = 5432
  dbname = \"bacula\"; dbuser = \"bacula\"; dbpassword = \"$SENHA_BACULA\"
}

# Reasonable message delivery -- send most everything to email address
#  and to the console
Messages {
  Name = Standard
  mailcommand = \"/usr/sbin/bsmtp -h localhost -f \\\"\\(Bacula\\) \\<%r\\>\\\" -s \\\"Bacula: %t %e of %c %l\\\" %r\"
  operatorcommand = \"/usr/sbin/bsmtp -h localhost -f \\\"\\(Bacula\\) \\<%r\\>\\\" -s \\\"Bacula: Intervention needed for %j\\\" %r\"
  mail = $EMAIL = all, !skipped
  operator = $EMAIL = mount
  console = all, !skipped, !saved
  append = \"/var/log/bacula/bacula.log\" = all, !skipped
  catalog = all
}


#
# Message delivery for daemon messages (no job).
Messages {
  Name = Daemon
  mailcommand = \"/usr/sbin/bsmtp -h localhost -f \\\"\\(Bacula\\) \\<%r\\>\\\" -s \\\"Bacula daemon message\\\" %r\"
  mail = $EMAIL = all, !skipped
  console = all, !skipped, !saved
  append = \"/var/log/bacula/bacula.log\" = all, !skipped
}

# Default pool definition
Pool {
  Name = Diario-Bacula
  Pool Type = Backup
  Recycle = yes                       # Bacula can automatically recycle Volumes
  AutoPrune = yes                     # Prune expired volumes
  Volume Use Duration = 24 hours
  Volume Retention = 6 days         # one year
  Label Format = \"diario-bacula_\${NumVols}\"
  Maximum Volume Bytes = 50G          # Limit Volume size to something reasonable
}

Pool {
  Name = Semanal-Bacula
  Pool Type = Backup
  Recycle = yes                       # Bacula can automatically recycle Volumes
  AutoPrune = yes                     # Prune expired volumes
  Volume Use Duration = 3 days
  Volume Retention = 27 days         # one year
  Label Format = \"semanal-bacula_\${NumVols}\"
  Maximum Volume Bytes = 50G          # Limit Volume size to something reasonable
}

Pool {
  Name = Mensal-Bacula
  Pool Type = Backup
  Recycle = yes                       # Bacula can automatically recycle Volumes
  AutoPrune = yes                     # Prune expired volumes
  Volume Use Duration = 3 days
  Volume Retention = 362 days         # one year
  Label Format = \"mensal-bacula_\${NumVols}\"
  Maximum Volume Bytes = 50G          # Limit Volume size to something reasonable
}

Pool {
  Name = Anual-Bacula
  Pool Type = Backup
  Recycle = yes                       # Bacula can automatically recycle Volumes
  AutoPrune = yes                     # Prune expired volumes
  Volume Use Duration = 3 days
  Volume Retention = 2 years         # one year
  Label Format = \"anual-bacula_\${NumVols}\"
  Maximum Volume Bytes = 50G          # Limit Volume size to something reasonable
}


# Scratch pool definition
Pool {
  Name = Scratch
  Pool Type = Backup
}

# Inserir abaixo a lista de Servidores Clientes a serem Backupeados conforme template abaixo
#
# Exemplo Client Cliente1
#
#Client {
#  Name = servidor-cliente1-fd
#  Address = ip_do_servidor_cliente1
#  FDPort = 9102
#  Catalog = MyCatalog
#  Password = \"senha_servidor_cliente1\"
#  AutoPrune = yes
#  File Retention = 99 years
#  Job Retention = 99 years
#  AutoPrune = yes
#}

# Exemplo Job Cliente1
#
#Job {
#  Name = \"BackupServidorCliente1\"
#  Type = Backup
#  Client = servidor-cliente1-fd
#  Storage = File1
#  FileSet = \"Servidor Cliente1 Set\"
#  Pool = Diario-Servidor-Cliente1
#  Level = Full
#  Messages = Standard
#  Schedule = Agenda_GFS_Servidor_Cliente1
#}

# Exemplo Fileset Cliente1
#
#FileSet {
#  Name = \"Servidor Cliente1 Set\"
#  Include {
#    Options {
#      signature = MD5
#      Compression = GZIP
#    }
#    File = /root
#    File = /home
#    File = /etc
#    File = /var/spool/cron
#  }

#
# If you backup the root directory, the following two excluded
#   files can be useful
#
#  Exclude {
#  }
#}

# Exemplo Pool Diário Cliente1
#
#Pool {
#  Name = Diario-Servidor-Cliente1
#  Pool Type = Backup
#  Recycle = yes                       # Bacula can automatically recycle Volumes
#  AutoPrune = yes                     # Prune expired volumes
#  Volume Use Duration = 24 hours
#  Volume Retention = 6 days         # one year
#  Maximum Volume Bytes = 50G          # Limit Volume size to something reasonable
#  Label Format = \"diario-servidor-cliente1_\${NumVols}\"
#}

# Exemplo Pool Semanal Cliente1
#
#Pool {
#  Name = Semanal-Servidor-Cliente1
#  Pool Type = Backup
#  Recycle = yes                       # Bacula can automatically recycle Volumes
#  AutoPrune = yes                     # Prune expired volumes
#  Volume Use Duration = 3 days
#  Volume Retention = 27 days         # one year
#  Maximum Volume Bytes = 50G          # Limit Volume size to something reasonable
#  Label Format = \"semanal-servidor-cliente1_\${NumVols}\"
#}

# Exemplo Pool Mensal Cliente1
#
#Pool {
#  Name = Mensal-Servidor-Cliente1
#  Pool Type = Backup
#  Recycle = yes                       # Bacula can automatically recycle Volumes
#  AutoPrune = yes                     # Prune expired volumes
#  Volume Use Duration = 3 days
#  Volume Retention = 362 days         # one year
#  Maximum Volume Bytes = 50G          # Limit Volume size to something reasonable
#  Label Format = \"mensal-servidor-cliente1_\${NumVols}\"
#}

# Exemplo Pool Anual Cliente1
#
#Pool {
#  Name = Anual-Servidor-Cliente1
#  Pool Type = Backup
#  Recycle = yes                       # Bacula can automatically recycle Volumes
#  AutoPrune = yes                     # Prune expired volumes
#  Volume Use Duration = 3 days
#  Volume Retention = 2 years         # one year
#  Maximum Volume Bytes = 50G          # Limit Volume size to something reasonable
#  Label Format = \"anual-servidor-cliente1_\${NumVols}\"
#}

# Exemplo Schedule (Agendamento) Cliente1
#
#Schedule {
#  Name = \"Agenda_GFS_Servidor_Cliente1\"
#  Run=Level=Incremental     Pool=Diario-Servidor-Cliente1     monday-thursday    at 00:00
#  Run=Level=Differential    Pool=Semanal-Servidor-Cliente1    2nd-5th friday     at 00:00
#  Run=Level=Full            Pool=Mensal-Servidor-Cliente1     1st friday         at 00:00
#  Run=Level=Full            Pool=Anual-Servidor-Cliente1      dec 5th            at 01:00
#}


#
# Restricted console used by tray-monitor to get the status of the director
#
Console {
  Name = $HOSTNAME-mon
  Password = \"senha_monitor\"
  CommandACL = status, .status
}" > /etc/bacula/bacula-dir.conf

# Criando o arquivo bacula-sd.conf em /etc/bacula/bacula-sd.conf:
touch /etc/bacula/bacula-sd.conf

# Customizando o arquivo /etc/bacula/bacula-sd.conf com seus devidos ajustes:
echo -e "
#
#  Arquivo Bacula Storage Daemon de Configuração Padrão
#
#  Editado e customizado por Daniel Cavalcante
#
#

Storage {                             # definition of myself
  Name = $HOSTNAME-sd
  SDPort = 9103                  # Director port
  WorkingDirectory = \"/var/lib/bacula\"
  Pid Directory = \"/var/run\"
  Plugin Directory = \"/usr/lib\"
  Maximum Concurrent Jobs = 20
}

#
# List Directors who are permitted to contact Storage daemon
#
Director {
  Name = $HOSTNAME-dir
  Password = \"senha_storage\"
}

#
# Restricted Director, used by tray-monitor to get the
#   status of the storage daemon
#
Director {
  Name = $HOSTNAME-mon
  Password = \"senha_monitor\"
  Monitor = yes
}


#
# Define a Virtual autochanger
#
Autochanger {
  Name = FileChgr1
  Device = FileChgr1-Dev1, FileChgr1-Dev2
  Changer Command = \"\"
  Changer Device = /dev/null
}

Device {
  Name = FileChgr1-Dev1
  Media Type = File1
  Archive Device = /bacula-backup/backup
  LabelMedia = yes;                   # lets Bacula label unlabeled media
  Random Access = Yes;
  AutomaticMount = yes;               # when device opened, read it
  RemovableMedia = no;
  AlwaysOpen = no;
  Maximum Concurrent Jobs = 5
}

Device {
  Name = FileChgr1-Dev2
  Media Type = File1
  Archive Device = /bacula-backup/backup
  LabelMedia = yes;                   # lets Bacula label unlabeled media
  Random Access = Yes;
  AutomaticMount = yes;               # when device opened, read it
  RemovableMedia = no;
  AlwaysOpen = no;
  Maximum Concurrent Jobs = 5
}

#
# Define a second Virtual autochanger
#
Autochanger {
  Name = FileChgr2
  Device = FileChgr2-Dev1, FileChgr2-Dev2
  Changer Command = \"\"
  Changer Device = /dev/null
}

Device {
  Name = FileChgr2-Dev1
  Media Type = File2
  Archive Device = /bacula-backup/backup
  LabelMedia = yes;                   # lets Bacula label unlabeled media
  Random Access = Yes;
  AutomaticMount = yes;               # when device opened, read it
  RemovableMedia = no;
  AlwaysOpen = no;
  Maximum Concurrent Jobs = 5
}

Device {
  Name = FileChgr2-Dev2
  Media Type = File2
  Archive Device = /bacula-backup/backup
  LabelMedia = yes;                   # lets Bacula label unlabeled media
  Random Access = Yes;
  AutomaticMount = yes;               # when device opened, read it
  RemovableMedia = no;
  AlwaysOpen = no;
  Maximum Concurrent Jobs = 5
}

#
# Send all messages to the Director,
# mount messages also are sent to the email address
#
Messages {
  Name = Standard
  director = $HOSTNAME-dir = all
}

" > /etc/bacula/bacula-sd.conf

# Criando o arquivo bacula-fd.conf em /etc/bacula/bacula-fd.conf:
touch /etc/bacula/bacula-fd.conf

# Customizando o arquivo /etc/bacula/bacula-fd.conf com seus devidos ajustes:
echo -e "#
#  Arquivo Bacula File Daemon de Configuração Padrão
#
#  Editado e customizado por Daniel Cavalcante
#
#

#
# List Directors who are permitted to contact this File daemon
#
Director {
  Name = $HOSTNAME-dir
  Password = \"senha_cliente\"
}

#
# Restricted Director, used by tray-monitor to get the
#   status of the file daemon
#
Director {
  Name = $HOSTNAME-mon
  Password = \"senha_monitor\"
  Monitor = yes
}

#
# \"Global\" File daemon configuration specifications
#
FileDaemon {                          # this is me
  Name = $HOSTNAME-fd
  FDport = 9102                  # where we listen for the director
  WorkingDirectory = /var/lib/bacula
  Pid Directory = /var/run
  Maximum Concurrent Jobs = 20
  Plugin Directory = /usr/lib
}

# Send all messages except skipped files back to Director
Messages {
  Name = Standard
  director = $HOSTNAME-dir = all, !skipped, !restored
}

" > /etc/bacula/bacula-fd.conf

# Criando o arquivo bconsole.conf em /etc/bacula/bconsole.conf:
touch /etc/bacula/bconsole.conf

# Customizando o arquivo /etc/bacula/bconsole.conf com seus devidos ajustes:
echo -e "#
#  Arquivo Bacula User Agent (ou Console) de Configuração Padrão
#
#  Editado e customizado por Daniel Cavalcante
#
#

Director {
  Name = $HOSTNAME-dir
  DIRport = 9101
  address = $IP
  Password = \"senha_console\"
}
" > /etc/bacula/bconsole.conf

# Gerando senha randômica para o Console do Bacula
/usr/bin/openssl rand -base64 33 -out /tmp/senha_console.txt
SENHA_CONSOLE=`/bin/cat /tmp/senha_console.txt`

# Gerando senha randômica para o FileDaemon do Bacula
/usr/bin/openssl rand -base64 33 -out /tmp/senha_cliente.txt
SENHA_CLIENTE=`/bin/cat /tmp/senha_cliente.txt`

# Gerando senha randômica para o(s) Storage(s) do Bacula
/usr/bin/openssl rand -base64 33 -out /tmp/senha_storage.txt
SENHA_STORAGE=`/bin/cat /tmp/senha_storage.txt`

# Gerando senha randômica para Monitor do Bacula
/usr/bin/openssl rand -base64 33 -out /tmp/senha_monitor.txt
SENHA_MONITOR=`/bin/cat /tmp/senha_monitor.txt`

# Substituindo a linha que contém "senha_console" pela linha da senha randômica gerada em /etc/bacula/bacula-dir.conf:
sed -i -e "s@senha_console@$SENHA_CONSOLE@g" /etc/bacula/bacula-dir.conf

# Substituindo a linha que contém "senha_cliente" pela linha da senha randômica gerada em /etc/bacula/bacula-dir.conf:
sed -i -e "s@senha_cliente@$SENHA_CLIENTE@g" /etc/bacula/bacula-dir.conf

# Substituindo a linha que contém "senha_storage" pela linha da senha randômica gerada em /etc/bacula/bacula-dir.conf:
sed -i -e "s@senha_storage@$SENHA_STORAGE@g" /etc/bacula/bacula-dir.conf

# Substituindo a linha que contém "senha_monitor" pela linha da senha randômica gerada em /etc/bacula/bacula-dir.conf:
sed -i -e "s@senha_monitor@$SENHA_MONITOR@g" /etc/bacula/bacula-dir.conf

# Substituindo a linha que contém "senha_storage" pela linha da senha randômica gerada em /etc/bacula/bacula-sd.conf:
sed -i -e "s@senha_storage@$SENHA_STORAGE@g" /etc/bacula/bacula-sd.conf

# Substituindo a linha que contém "senha_monitor" pela linha da senha randômica gerada em /etc/bacula/bacula-sd.conf:
sed -i -e "s@senha_monitor@$SENHA_MONITOR@g" /etc/bacula/bacula-sd.conf

# Substituindo a linha que contém "senha_cliente" pela linha da senha randômica gerada em /etc/bacula/bacula-fd.conf:
sed -i -e "s@senha_cliente@$SENHA_CLIENTE@g" /etc/bacula/bacula-fd.conf

# Substituindo a linha que contém "senha_monitor" pela linha da senha randômica gerada em /etc/bacula/bacula-fd.conf:
sed -i -e "s@senha_monitor@$SENHA_MONITOR@g" /etc/bacula/bacula-fd.conf

# Substituindo a linha que contém "senha_console" pela linha da senha randômica gerada em /etc/bacula/bconsole.conf:
sed -i -e "s@senha_console@$SENHA_CONSOLE@g" /etc/bacula/bconsole.conf

# Limpando os vestígios dos arquivos temporários com as senhas geradas:
rm /tmp/senha_*

# Limpando a variável armazenando hostname do servidor no qual será utilizado no arquivo de configuração /etc/bacula/bacula-dir.conf:
unset HOSTNAME

# Limpando a variável armazenando senha randômica para o Console do Bacula:
unset SENHA_CONSOLE

# Limpando a variável armazenando senha randômica para o FileDaemon do Bacula:
unset SENHA_CLIENTE

# Limpando a variável armazenando senha randômica para o Storage do Bacula:
unset SENHA_STORAGE

# Limpando a variável armazenando senha randômica para o Monitor do Bacula:
unset SENHA_MONITOR

echo -e

#-----------------------------------------------------------------------------------#
# >>> Reiniciar o Bacula <<<                                                        #
#-----------------------------------------------------------------------------------#
/etc/init.d/bacula-dir restart
/etc/init.d/bacula-fd restart
/etc/init.d/bacula-sd restart

echo -e
echo -e "**** O Servidor Bacula Backup System foi instalado com sucesso! ****"
echo -e
echo -e "Se tudo ocorrer bem, o Bacula iniciará sem problemas e você pode acessar com o bconsole, e verá uma tela conforme abaixo coforme exemplo:"
echo -e
echo -e "root@backup:/# bconsole"
echo -e "Connecting to Director backup:9101"
echo -e "1000 OK: 103 backup Version: 9.0.6 (20 November 2017)"
echo -e "Enter a period to cancel a command."
echo -e "*"
echo -e
echo -e "**** Nota: ****"
echo -e "Os 'backups' rotineiros serão armazenados em: /bacula-backup/backup"
echo -e "Os 'restores' caso restaurar os backups, estarão armazenados em: /bacula-backup/restore"
echo -e
echo -e "* Caso não desejar prosseguir com a instalação, pressione as teclas Ctrl+c para Cancelar."
echo -e
echo -e "* O instalador do Webmin (Interface web amigável para o Bacula Server) estará sendo executados em alguns instantes..."
echo -e

/bin/sleep 4

# Limpando a tela do console:
/usr/bin/clear


#-----------------------------------------------------------------------------------#
# >>> Instalando Webmin <<<                                                         #
#-----------------------------------------------------------------------------------#
echo -e "Instalando Webmin (Interface web amigável para o Bacula Server)..."
echo -e

/bin/sleep 4

# Pacotes necessários para instalação:
apt-get install -y perl libnet-ssleay-perl openssl libauthen-pam-perl libpam-runtime libio-pty-perl apt-show-versions python libdbd-pg-perl
apt-get -y autoclean
apt-get -y autoremove

# Baixando e Compilando o Fonte
#
cd /usr/src

# Utilizando wget:
wget --no-check-certificate http://prdownloads.sourceforge.net/webadmin/webmin_1.870_all.deb

# Comando para efetuar a instalação:
dpkg --install webmin_1.870_all.deb

#-----------------------------------------------------------------------------------#
# >>> Reiniciar o bacula <<<                                                        #
#-----------------------------------------------------------------------------------#
/etc/init.d/bacula-dir restart
/etc/init.d/bacula-fd restart
/etc/init.d/bacula-sd restart

echo -e
echo -e "**** A ferramenta web Webmin foi instalado com sucesso! ****"
echo -e 
echo -e "Se tudo ocorrer bem, conseguirá acessar com sucesso o Webmin através da URL:"
echo -e "https://$IP:10000"
echo -e
echo -e "Username: root"
echo -e "Password: Senha do superusuario root do Sistema Operacional"
echo -e
echo -e
echo -e "* Caso não desejar prosseguir com a instalação, pressione as teclas Ctrl+c para Cancelar."
echo -e
echo -e "* O instalador do Webacula (Interface Gráfica para o Bacula Server) estará sendo executados em alguns instantes..."
echo -e

/bin/sleep 4

# Limpando a tela do console:
/usr/bin/clear


#-----------------------------------------------------------------------------------#
# >>> Webacula (Interface Gráfica) <<<                                              #
#-----------------------------------------------------------------------------------#
echo -e "Instalando Webacula (Interface Gráfica para o Bacula Server)..."
echo -e

/bin/sleep 4

# Download e Cópia dos Pacotes (Debian):
apt-get install -y apache2 php5 libapache2-mod-php5 php5-gd php5-pgsql

# Baixando o Fonte:
cd /usr/src

# Utilizando wget para baixar Webacula 7.0:
wget --no-check-certificate https://downloads.sourceforge.net/project/webacula/webacula/7.0.0/webacula-7.0.0.tar.gz

# Descompactando Webacula 7.0:
tar zxvf webacula-*.tar.gz

# Renomeando a pasta webacula-7.0.0 para webacula:
mv webacula-7.0.0 webacula

# Movendo a pasta webacula para o caminho /var/www
mv webacula /var/www

# Utilizando wget para baixar Zend Framework:
wget --no-check-certificate https://packages.zendframework.com/releases/ZendFramework-1.12.20/ZendFramework-1.12.20-minimal.tar.gz

# Descompactando Zend Framework:
tar zxvf ZendFramework-1.12.20-minimal.tar.gz

# Copiando a pasta Zend para o caminho /var/www/webacula/library do Webacula:
cp -r ZendFramework-1.12.20-minimal/library/Zend /var/www/webacula/library

# Instalando Webacula:
# Modificando o arquivo original db.conf em /var/www/webacula/install/:
cp -a /var/www/webacula/install/db.conf /var/www/webacula/install/db.conf.orig

# Modificando os respectivas linhas para configuração de usuário e senha no Banco de Dados:
sed -i -e 's/db_user=\"root\"/db_user=\"postgres\"/g' /var/www/webacula/install/db.conf
sed -i -e 's/db_pwd=\"\"/db_pwd="$SENHA_POSTGRES"/g' /var/www/webacula/install/db.conf

# Efetuando as respectivas cópias de segurança dos arquivos 10_make_tables.sh.orig e 20_acl_make_tables.sh.orig em /var/www/webacula/install/PostgreSql:
cd /var/www/webacula/install/PostgreSql

cp -a /var/www/webacula/install/PostgreSql/10_make_tables.sh /var/www/webacula/install/PostgreSql/10_make_tables.sh.orig
cp -a /var/www/webacula/install/PostgreSql/20_acl_make_tables.sh /var/www/webacula/install/PostgreSql/20_acl_make_tables.sh.orig

# Modificando os parâmetros necessários para a instalação da base Webacula:
sed -i -e 's/psql -q -f - -d \$db_name \$\* <<END-OF-DATA/psql -U \$db_user -q -f - -d \$db_name \$\* <<END-OF-DATA/g' /var/www/webacula/install/PostgreSql/10_make_tables.sh

sed -i -e 's/psql -q -f - -d \$db_name \$\*  <<END-OF-DATA/psql -U \$db_user -q -f - -d \$db_name \$\*  <<END-OF-DATA/g' /var/www/webacula/install/PostgreSql/20_acl_make_tables.sh

# Criando o arquivo 30_grant_tables.sh em /var/www/webacula/install/PostgreSql:
touch /var/www/webacula/install/PostgreSql/30_grant_tables.sh

# Adicionando as configurações / ajustes necessários para o webacula em /var/www/webacula/install/PostgreSql/30_grant_tables.sh:
echo -e '#!/bin/bash' > /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "#" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "# Script to grant webacula tables" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "#" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "db_superuser=\"postgres\"" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "db_user=\"bacula\"" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "db_name=\"bacula\"" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "psql -U \$db_superuser -q -f - -d \$db_name \$* <<END-OF-DATA" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "-- grants" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_client_acl TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_client_acl_id_seq TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_command_acl TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_command_acl_id_seq TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_dt_commands TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_dt_commands_id_seq TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_dt_resources TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_dt_resources_id_seq TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_fileset_acl TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_fileset_acl_id_seq TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_job_acl TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_job_acl_id_seq TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_jobdesc TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_jobdesc_desc_id_seq TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_logbook TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT SELECT, UPDATE ON webacula_logbook_logid_seq TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT SELECT, UPDATE ON webacula_logtype TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT SELECT, UPDATE ON webacula_logtype_typeid_seq TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_php_session TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_pool_acl TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_pool_acl_id_seq TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_resources TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_resources_id_seq TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_roles TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_roles_id_seq TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_storage_acl TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_storage_acl_id_seq TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_users TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_users_id_seq TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT SELECT, REFERENCES ON webacula_version TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_where_acl TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT all ON webacula_where_acl_id_seq TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "-- execute access" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "GRANT EXECUTE ON FUNCTION webacula_clone_file(vTbl TEXT, vFileId INT, vPathId INT, vFilenameId INT, vLStat TEXT, vMD5 TEXT, visMarked INT, vFileSize INT) TO \${db_user};" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e "END-OF-DATA" >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e 'res=$?' >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e 'if test $res = 0;' >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e 'then' >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e '   echo "PostgreSql : grant of Webacula tables succeeded."' >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e 'else' >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e '   echo "PostgreSql : grant of Webacula tables failed!"' >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e 'fi' >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh
echo -e >> /var/www/webacula/install/PostgreSql/30_grant_tables.sh

# Permissão de execução do script 30_grant_tables.sh de /var/www/webacula/install/PostgreSql:
chmod +x /var/www/webacula/install/PostgreSql/30_grant_tables.sh

# Executando os scripts de criação do banco, tabelas e direitos do Webacula:
./10_make_tables.sh
./20_acl_make_tables.sh
./30_grant_tables.sh

# Alterando senha de root do Webacula no Banco de Dados...
# Gerando senha MD5:
cd /var/www/webacula/install

# Armazenando o resultado do hash para o arquivo hash.txt
./password-to-hash.php $SENHA_POSTGRES > hash.txt

# Armazenando o resultado do hash a variável HASH:
HASH=`/bin/cat /var/www/webacula/install/hash.txt`

# Efetuando os devidos ajustes e adicionando o respectivo resultado da senha hash do webacula em /var/www/webacula/install/db.conf:
sed -i -e "s/webacula_root_pwd=\"\"/#webacula_root_pwd=\"\"/g" /var/www/webacula/install/db.conf

echo -e "webacula_root_pwd="$HASH"" >> /var/www/webacula/install/db.conf

# Alterando a senha do usuário root de acesso ao webacula
psql -U postgres -d bacula -c "UPDATE \"webacula_users\" SET \"pwd\" = '"$HASH"' where id = '1000';"

# Adicionando o conteúdo catalog = all, !skipped, !saved, em /etc/bacula/bacula-dir.conf:
sed -i -e "s/catalog = all/catalog = all, \!skipped, \!saved/g" /etc/bacula/bacula-dir.conf

# reiniciando o Bacula Director:
/etc/init.d/bacula-dir restart

# Configuração PHP:
# Efetuando cópia de segurança do arquivo de configuração original /etc/php5/apache2/php.ini.orig:
cp -a /etc/php5/apache2/php.ini /etc/php5/apache2/php.ini.orig

# Aumentando os valores do memory_limit e max_execution_time do arquivo /etc/php5/apache2/php.ini:
sed -i -e "s/memory_limit = 128M/memory_limit = 32M/g" /etc/php5/apache2/php.ini
sed -i -e "s/max_execution_time = 30/max_execution_time = 3600/g" /etc/php5/apache2/php.ini

# Definindo o Timezone para America/Sao_Paulo:
sed -i -e "s/;date.timezone =/date.timezone = America\/Sao_Paulo/g" /etc/php5/apache2/php.ini

# Configuração Apache:
# Copiando o arquivo de configuração modelo do Webacula para o Apache*.:
cp /var/www/webacula/install/apache/webacula.conf /etc/apache2/sites-enabled/

# Ajustando o ambiente Webacula em /etc/apache2/sites-enabled/webacula.conf:
sed -i -e "s/\/usr\/share\/webacula\//\/var\/www\/webacula\//g" /etc/apache2/sites-enabled/webacula.conf
sed -i -e "s/Deny from all/Require all granted/g" /etc/apache2/sites-enabled/webacula.conf

# Configurando o mod_rewrite (necessário para o Debian):
echo rewrite | a2enmod

service apache2 restart

# Configurando Permissões:
chown -R www-data. /var/www/webacula

# Efetuando cópia de segurança do arquivo de configuração original /var/www/webacula/application/config.ini:
cp -a /var/www/webacula/application/config.ini /var/www/webacula/application/config.ini.orig

# Alterando o arquivo /var/www/webacula/application/config.ini definindo parâmetros para conexão com a base de dados postgresql:
sed -i -e "s/db.adapter\         = PDO_MYSQL/db.adapter\         = PDO_PGSQL/g" /var/www/webacula/application/config.ini
sed -i -e "s/db.config.username = root/db.config.username = postgres/g" /var/www/webacula/application/config.ini
sed -i -e "s/db.config.password =/db.config.password = $SENHA_POSTGRES/g" /var/www/webacula/application/config.ini
sed -i -e "s/def.timezone = \"Europe\/Minsk\"/def.timezone = \"America\/Sao_Paulo\"/g" /var/www/webacula/application/config.ini
sed -i -e "s/; locale = \"en\"/locale = \"pt_BR\"/g" /var/www/webacula/application/config.ini
sed -i -e "s/bacula.sudo        = \"\/usr\/bin\/sudo\"/bacula.sudo        = \"\"/g" /var/www/webacula/application/config.ini
sed -i -e "s/bacula.bconsole    = \"\/opt\/bacula\/sbin\/bconsole\"/bacula.bconsole    = \"\/usr\/sbin\/bconsole\"/g" /var/www/webacula/application/config.ini
sed -i -e "s/bacula.bconsolecmd = \"-n -c \/opt\/bacula\/etc\/bconsole.conf\"/bacula.bconsolecmd = \"-n -c \/etc\/bacula\/bconsole.conf\"/g" /var/www/webacula/application/config.ini

# Alterando as permissões dos arquivos necessários para o funcionamento do Webacula:
chown www-data /usr/sbin/bconsole

chmod u=rwx,g=rx,o= /usr/sbin/bconsole

chown www-data /etc/bacula/bconsole.conf

chmod u=rw,g=r,o= /etc/bacula/bconsole.conf

chown www-data /etc/bacula

# Efetuando cópia de segurança do arquivo de configuração original /var/www/webacula/html/index.php:
cp -a  /var/www/webacula/html/index.php  /var/www/webacula/html/index.php.orig

# Efetuando ajuste de versão do catálogo Webacula com a versão da base de dados Postgres (versão 16) atual no arquivo de configuração /var/www/webacula/html/index.php:
sed -i -e "s/define('BACULA_VERSION', 14); \/\/ Bacula Catalog version/define('BACULA_VERSION', 16); \/\/ Bacula Catalog version/g" /var/www/webacula/html/index.php

# Reiniciando o servidor Apache:
/etc/init.d/apache2 restart

# Finalmente acessar pela URL através de um navegador qualquer para acessar os relatórios e gráficos do bacula:
# http://$IP/webacula/
# Obs.: O login para acesso é root

echo -e
echo -e "**** A ferramenta Webacula foi instalado com sucesso! ****"
echo -e
echo -e "Se tudo ocorrer bem, conseguirá acessar com sucesso o Webacula através da URL:"
echo -e "http://$IP/webacula"
echo -e
echo -e "Username: root"
echo -e "Password: Senha do superusuário postgres do Banco de Dados (ver em /var/www/webacula/application/config.ini na linha: db.config.password)."
echo -e
echo -e
echo -e "* Caso não desejar prosseguir com a instalação, pressione as teclas Ctrl+c para Cancelar."
echo -e
echo -e "* O instalador do Bacula-web (relatórios e gráficos) estará sendo executados em alguns instantes..."
echo -e

/bin/sleep 4

# Limpando a tela do console:
/usr/bin/clear


#-----------------------------------------------------------------------------------#
# >>> Bacula-web (relatórios e gráficos) <<<                                        #
#-----------------------------------------------------------------------------------#
# Download e Cópia dos Pacotes (Debian):
apt-get install -y apache2 php5 libapache2-mod-php5 php5-gd php5-pgsql

# Limpando a tela do console:
/usr/bin/clear

echo -e "Instalando Bacula-web (relatórios e gráficos)..."
echo -e

/bin/sleep 4

# Baixando e Compilando o Fonte
cd /usr/src

# Utilizando wget:
wget http://www.bacula-web.org/download/articles/bacula-web-7-4-0.html?file=files/bacula-web.org/downloads/7.4.0/bacula-web-7.4.0.tgz

# Renomeando para bacula-web-7.4.0.tgz:
mv bacula-web-7-4-0.*.tgz bacula-web-7.4.0.tgz

# Descompactando:
mkdir /var/www/bacula-web

tar -xzf bacula-web*.tgz -C /var/www/bacula-web

# Criando o arquivo config.php em /var/www/bacula-web/application/config:
touch /var/www/bacula-web/application/config/config.php

# Adicionando as configurações / ajustes necessários para o bacula-web em /var/www/bacula-web/application/config/config.php:
echo -e "<?php"  > /var/www/bacula-web/application/config/config.php
echo -e >> /var/www/bacula-web/application/config/config.php
echo -e "// Show inactive clients (false by default)" >> /var/www/bacula-web/application/config/config.php
echo -e "\$config['show_inactive_clients'] = true;" >> /var/www/bacula-web/application/config/config.php
echo -e >> /var/www/bacula-web/application/config/config.php
echo -e "// Hide empty pools (displayed by default)" >> /var/www/bacula-web/application/config/config.php
echo -e "\$config['hide_empty_pools'] = false;" >> /var/www/bacula-web/application/config/config.php
echo -e >> /var/www/bacula-web/application/config/config.php
echo -e "// Jobs per page (Jobs report page)" >> /var/www/bacula-web/application/config/config.php
echo -e "\$config['jobs_per_page'] = 25;" >> /var/www/bacula-web/application/config/config.php
echo -e >> /var/www/bacula-web/application/config/config.php
echo -e "// Translations" >> /var/www/bacula-web/application/config/config.php
echo -e "\$config['language'] = 'pt_BR';" >> /var/www/bacula-web/application/config/config.php
echo -e >> /var/www/bacula-web/application/config/config.php
echo -e "// Custom datetime format (by default: Y-m-d H:i:s)" >> /var/www/bacula-web/application/config/config.php
echo -e "\$config['datetime_format'] = 'd/m/Y H:i:s';" >> /var/www/bacula-web/application/config/config.php
echo -e >> /var/www/bacula-web/application/config/config.php
echo -e "// Database connection parameters" >> /var/www/bacula-web/application/config/config.php
echo -e "// Copy/paste and adjust parameters according to your configuration" >> /var/www/bacula-web/application/config/config.php
echo -e >> /var/www/bacula-web/application/config/config.php
echo -e "// postGresql: do not define [0]['host']" >> /var/www/bacula-web/application/config/config.php
echo -e >> /var/www/bacula-web/application/config/config.php
echo -e "// PostgreSQL bacula catalog" >> /var/www/bacula-web/application/config/config.php
echo -e "\$config[0]['label'] = 'Backup Server';" >> /var/www/bacula-web/application/config/config.php
echo -e "//\$config[0]['host'] = '$IP';" >> /var/www/bacula-web/application/config/config.php
echo -e "\$config[0]['login'] = 'postgres';" >> /var/www/bacula-web/application/config/config.php
echo -e "\$config[0]['password'] = '$SENHA_POSTGRES';" >> /var/www/bacula-web/application/config/config.php
echo -e "\$config[0]['db_name'] = 'bacula';" >> /var/www/bacula-web/application/config/config.php
echo -e "\$config[0]['db_type'] = 'pgsql';" >> /var/www/bacula-web/application/config/config.php
echo -e "\$config[0]['db_port'] = '5432';" >> /var/www/bacula-web/application/config/config.php
echo -e >> /var/www/bacula-web/application/config/config.php
echo -e "?>" >> /var/www/bacula-web/application/config/config.php

# Ajustando as devidas permissões da pasta bacula-web:
chown -Rv www-data:www-data /var/www/bacula-web

chmod -Rv u=rx,g=rx,o=rx /var/www/bacula-web
chmod -v ug+w /var/www/bacula-web/application/view/cache

# Criando o arquivo bacula-web.conf em /etc/apache2/sites-enabled/bacula-web.conf para vhost:
touch /etc/apache2/sites-enabled/bacula-web.conf

# Adicionando as configurações / ajustes necessários do Bacula-web no Apache2 em /etc/apache2/sites-enabled/bacula-web.conf:
echo -e "LoadModule rewrite_module modules/mod_rewrite.so" > /etc/apache2/sites-enabled/bacula-web.conf
echo -e >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "SetEnv APPLICATION_ENV production" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "Alias /bacula-web  /var/www/bacula-web" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "<Directory /var/www/bacula-web>" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "   RewriteEngine On" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "   RewriteBase   /bacula-web" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "   RewriteCond %{REQUEST_FILENAME} -s [OR]" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "   RewriteCond %{REQUEST_FILENAME} -l [OR]" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "   RewriteCond %{REQUEST_FILENAME} -d" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "   RewriteRule ^.*$ - [NC,L]" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "   RewriteRule ^.*$ index.php [NC,L]" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "   php_flag magic_quotes_gpc off" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "   php_flag register_globals off" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e >> /etc/apache2/sites-enabled/bacula-web.conf>> /etc/apache2/sites-enabled/bacula-web.conf
echo -e >> /etc/apache2/sites-enabled/bacula-web.conf>> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "   #Deny from all" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "   Require all granted" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "   Allow from 127.0.0.1" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "   Allow from localhost" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "   Allow from ::1" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e "</Directory>" >> /etc/apache2/sites-enabled/bacula-web.conf
echo -e >> /etc/apache2/sites-enabled/bacula-web.conf

# Agora, configurando o mod_rewrite (necessário para o Debian):
echo rewrite | a2enmod

service apache2 restart

echo -e
echo -e "**** A ferramenta Bacula-web foi instalado com sucesso! ****"
echo -e
echo -e "Se tudo ocorrer bem, conseguirá acessar com sucesso o Bacula-web para acessar os relatórios e gráficos, através da URL:"
echo -e "http://$IP/bacula-web"
echo -e
echo -e
echo -e "* Caso não desejar prosseguir com a instalação, pressione as teclas Ctrl+c para Cancelar."
echo -e
echo -e "* O instalador do phpPgAdmin (Interface amigável para o SGBD PostgreSQL) estará sendo executados em alguns instantes..."
echo -e

/bin/sleep 4

# Limpando a tela do console:
/usr/bin/clear


#-----------------------------------------------------------------------------------#
# >>> Instalando phpPgAdmin <<<                                                     #
#-----------------------------------------------------------------------------------#
echo -e "Instalando phpPgAdmin (Interface amigável para Gerenciamento do Banco de Dados do PostgreSQL)..."
echo -e

/bin/sleep 4

# Como usuário root digite em seu terminal:
apt-get install -y phppgadmin
apt-get -y autoclean
apt-get -y autoremove

echo -e

# Configurar Apache:
# Você precisa configurar o Apache para poder acessar a interface de administração web do PostgreSQL, o phpPgAdmin.

# Antes de copiar o arquivo, é verificado se o arquivo /etc/apache2/conf-available/phppgadmin.conf.orig já existe:
if [ -f /etc/apache2/conf-available/phppgadmin.conf.orig ]; then
	echo "O arquivo /etc/apache2/conf-available/phppgadmin.conf.orig já existe!"
	/bin/sleep 2
else
	# Fazer uma cópia de segurança do arquivo original phppgadmin.conf:
	cp -a /etc/apache2/conf-available/phppgadmin.conf /etc/apache2/conf-available/phppgadmin.conf.orig
fi

# Substituindo a linha que contém “Require local” pela linha “Allow From All”:
sed -i -e 's/Require local/Allow From All/g' /etc/apache2/conf-available/phppgadmin.conf

# Configurar phpPgAdmin:

# Antes de copiar o arquivo, é verificado se o arquivo /etc/phppgadmin/config.inc.php.orig já existe:
if [ -f /etc/phppgadmin/config.inc.php.orig ]; then
	echo "O arquivo /etc/phppgadmin/config.inc.php.orig já existe!"
	/bin/sleep 2
else
	# Fazer uma cópia de segurança do arquivo original config.inc.php:
	cp -a /etc/phppgadmin/config.inc.php /etc/phppgadmin/config.inc.php.orig
fi

# Substituindo o parâmetro $conf['extra_login_security'] = true; para $conf['extra_login_security'] = false; no arquivo /etc/phppgadmin/config.inc.php
sed -i "s/$conf\['extra_login_security'\] = true;/$conf\['extra_login_security'\] = false;/g" /etc/phppgadmin/config.inc.php

echo -e

# Agora reinicie os serviços:
/etc/init.d/postgresql restart
/etc/init.d/apache2 restart

echo -e
echo -e " **** A ferramenta phpPgAdmin foi instalado com sucesso! ****"
echo -e 
echo -e "Se tudo ocorrer bem, conseguirá acessar com sucesso o phpPgAdmin através da URL:"
echo -e "http://$IP/phppgadmin"
echo -e
echo -e "Username: postgres"
echo -e "Password: Senha do superusuário (postgres) do banco de dados"
echo -e
echo -e
echo -e "* O instalador está sendo encerrado agora..."
echo -e
echo -e
/bin/sleep 4
