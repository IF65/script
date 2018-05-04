#!/bin/bash

DATA=$(date +"%Y%m%d%H%M%S")

#parametri di collegamento db mysql
IP='10.11.14.78'
USERNAME='root'
PASSWORD='mela'

#posizione degli anagdafi
DIR_BASE=/dati/anagdafi

#query per recuperare gli anagdafi mancanti
STMT='select concat(date_format(i1.data - INTERVAL 1 DAY, "'"%Y%m%d"'"),date_format(i1.data, "'"%Y%m%d"'"),i1.`negozio_codice`) 
      from lavori.incarichi as i1 join (select `data`,`negozio_codice`,`eseguito` from lavori.incarichi where `lavoro_codice` = 10) as i2 \
      on i1.`data`=i2.`data` and i1.`negozio_codice`=i2.`negozio_codice`
      where i1.`lavoro_codice`=30 and i1.`eseguito`=0 and i2.`eseguito`=1 and i1.`data`>="'"2016-01-01"'" and i1.`annullato`=0;'
LISTA=$(mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "$STMT" 2>/dev/null)

for f in $LISTA; do
	SOUR="${f:0:8}/${f:0:8}_${f:16:4}.zip"
	DEST="${f:8:8}/${f:8:8}_${f:16:4}.zip"
	
	cp "$DIR_BASE/$SOUR" "$DIR_BASE/$DEST"
	
	mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e \
		'update lavori.incarichi set eseguito = 2 where lavoro_codice = 30 and negozio_codice = "'"${f:16:4}"'" and data = "'"${f:8:4}-${f:12:2}-${f:14:2}"'"'
done

