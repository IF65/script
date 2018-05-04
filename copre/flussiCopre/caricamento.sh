#!/bin/bash

#parametri di collegamento db mysql (può essere diverso dal db dove sono caricati i log)
IP='10.11.14.78'
USERNAME='root'
PASSWORD='mela'

#posizione degli script
DIR_SCRIPT="/script/copre/flussiCopre"

FILE_NAME=$(php $DIR_SCRIPT/aggiornamento.php 2>/dev/null)
echo $FILE_NAME
#mysql -u $USERNAME -p$PASSWORD -h $IP < $DIR_SCRIPT/crea.sql 1>/dev/null 2>&1
mysqlimport -u $USERNAME -p$PASSWORD -h $IP --delete --local "copreFlussi" $FILE_NAME 1>/dev/null 2>&1

exit
