#!/bin/bash

DATA=$(date +"%d-%m-%Y %H:%M:%S")

#parametri di collegamento db mysql
IP='10.11.14.78'
USERNAME='root'
PASSWORD='mela'

ADDRESS="ced@if65.it"

SUBJECT="Report Ricezione Dati dai Negozi"

STMT='select ucase(concat(date_format(i.`data`,"'"%Y-%m-%d"'"), "'" "'",i.`negozio_codice`, "'" "'",i.`negozio_descrizione`, "'"<BR>"'" )) from lavori.incarichi as i where i.`data`>"'"2016-01-01"'" and i.`data`>= SUBDATE(curdate(),7) and i.`data` < curdate() and i.`lavoro_codice` in (30) and i.`annullato`=0 and i.`eseguito`<> 1 order by i.`negozio_codice`, i.`data`, i.`lavoro_codice`;'
LISTA_ANAGDAFI=$(mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "$STMT" 2>/dev/null)
STMT='select ucase(concat(date_format(i.`data`,"'"%Y-%m-%d"'"), "'" "'",i.`negozio_codice`, "'" "'",i.`negozio_descrizione`, "'"<BR>"'" )) from lavori.incarichi as i where i.`data`>"'"2016-01-01"'" and i.`data`>= SUBDATE(curdate(),7) and i.`data` < curdate() and i.`lavoro_codice` in (20) and i.`annullato`=0 and i.`eseguito`<> 1 order by i.`negozio_codice`, i.`data`, i.`lavoro_codice`;'
LISTA_JOURNAL=$(mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "$STMT" 2>/dev/null)

BODY="<html><body><b>Report generato il : $DATA</b><BR><BR><BR>"
BODY=$BODY"---------------------------------------------------------------------------------------------------------------<BR>"
BODY=$BODY"NEGOZI CHE NON HANNO RECUPERATO L'ANAGDAFI NEGLI ULTIMI 7 GG<BR>"
BODY=$BODY"---------------------------------------------------------------------------------------------------------------<BR>"
BODY=$BODY$LISTA_ANAGDAFI

BODY=$BODY"<BR><BR><BR>"

BODY=$BODY"---------------------------------------------------------------------------------------------------------------<BR>"
BODY=$BODY"NEGOZI CHE NON HANNO RECUPERATO IL JOURNAL NEGLI ULTIMI 7 GG<BR>"
BODY=$BODY"---------------------------------------------------------------------------------------------------------------<BR>"
BODY=$BODY$LISTA_JOURNAL

BODY=$BODY"</body></html>"

/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25

