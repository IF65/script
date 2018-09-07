#!/bin/bash

#parametri di collegamento db mysql
IP='localhost'
USERNAME='root'
PASSWORD='mela'

#parametri di collegamento ftp
FTP_IP='mail.mtdistribution.it'
FTP_USERNAME='supermediaddt'
FTP_PASSWORD='ZC65U97-nk12'


STMT='select distinct i.data from lavori.incarichi as i where i.`lavoro_codice` = 240 and i.`eseguito` = 0 order by 1'

#eseguo la query e salvo il risultato
LISTA_GIORNATE=$(mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "$STMT")
for d in $LISTA_GIORNATE; do
	php gameTekk.php $d
done

# if [ -d /gameTekk/daInviare ]; then
# 	if [ "$(ls -A /gameTekk/daInviare)" ]; then
# 		ftp -in $FTP_IP 1>/dev/null <<SCRIPT
# 			user $FTP_USERNAME $FTP_PASSWORD
# 			binary
# 		
# 			mput /gameTekk/daInviare/*.txt
# 			bye
# SCRIPT
# 	fi
# fi

