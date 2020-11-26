#!/bin/bash
# 
# Criado por Ricardo Ferreira / Nov.2020
# Material complementar do curso "Docker do Zero - Introdução a administração de containers"
# http://bit.ly/cursoAprendaDockerdoZero
#

# ALTERE AQUI - SE FOR O CASO#
############################
##
app="Teste" 					# nome da Aplicação
service="mariadb-backup"			# nome do service do compose da instância slave do banco
app_db="app_db"					# a mesma do arquivo backup.conf
user="root"					# a mesma do arquivo backup.conf
pass="main_root_secret"				# a mesma do arquivo backup.conf
nb="50"                 	                # numero maximo de arquivos de backup a serem mantidos
##
###########################

######
#################### EVITE ALTERAR DAQUI PARA BAIXO #######################
#
#

bk="files"      				# diretorio de destino dos dumps - é preciso criar o diretório primeiro!
nw=$(date +%d%m%Y.%H%M%S)               # variavel de hora

### verificando se existe o diretorio para armazenar os logs #############################

        if [ ! -d $bl ]; then
                echo -e "\nErro: o diretorio de logs nao existe!" 
                echo -e "Ajuda: ajuste o conteudo da variavel bl\n"
                exit 1
        fi

### verificando se existe o diretorio para armazenar os dumps #############################

        if [ ! -d $bk ]; then
                echo -e "\nErro: o diretorio de destino nao existe!" | tee -a $ln
                echo -e "Ajuda: ajuste o conteudo da variavel bk\n" | tee -a $ln
                exit 1
        fi


cd $bk
echo -e "\nBACKUP da app $app inciado em $(date +%d/%m/%Y.%H:%M:%S)\n" | tee -a $ln
echo -e "------------------------------------------------------------------------\n\n" | tee -a $ln

# Apaga backups anteriores - pasta compactada com todos os backups
find . -name "*.sql" -mtime +$nb -type f -exec rm -f {} \;
# Apaga logs anteriores
find logs/ -name "*.log" -mtime +$nb -type f -exec rm -f {} \;
echo -e "DUMPS e LOGS com mais de $nb dias foram apagados\n\n"|tee -a $ln

#retorna 2 níveis de diretórios
cd ..

echo -e "Efetuando backup...\n" | tee -a $ln

echo -e "1. Parando Slave\n" | tee -a $ln
if docker-compose exec -T $service mysqladmin -u$user -p$pass stop-slave
then
  echo -e "1.1 Slave Parado\n" | tee -a $ln
else
  echo -e "ERRO ao parar Slave\n" | tee -a $ln
  exit 1
fi

echo -e "2. Realizando DUMP...\n" | tee -a $ln
if docker-compose exec -T $service mysqldump -u$user -p$pass $app_db > $bk/$app-$nw.sql
then
  echo -e "2.1 DUMP concluído\n" | tee -a $ln
else
  echo -e "ERRO ao realizar o DUMP\n" | tee -a $ln
  exit 1
fi

echo -e "3. Reiniciando Slave\n" | tee -a $ln
if docker-compose exec -T $service mysqladmin -u$user -p$pass start-slave
then
  echo -e "3.1 Slave ativo novamente\n" | tee -a $ln
else
  echo -e "ERRO ao iniciar Slave\n" | tee -a $ln
  exit 1
fi

echo -e "\nBackup concluído com sucesso em $(date +%d/%m/%Y.%H:%M:%S)"|tee -a $ln

cd
exit 0
