#!/bin/bash

#parametri di collegamento db mysql
IP='10.11.14.78'
USERNAME='root'
PASSWORD='mela'

#posizione degli script
DIR_SCRIPT="/script/checkWeb"

ID_CONNESSIONE=$(php $DIR_SCRIPT/checkWeb.php)

STMT="select ts `timeStamp`, funzione `tipo`, errori `# errori`, descrizione from checkWeb.checkLog where idConnessione = (select max(idConnessione) from checkWeb.checkLog)"
ELENCO_ANOMALIE=$(mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "$STMT" 2>/dev/null)
for f in $ELENCO_ANOMALIE; do
	echo $f
done
