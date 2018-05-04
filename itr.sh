#!/bin/bash

#parametri di collegamento FTP
FTP_IP='10.11.14.111'
FTP_USERNAME="filiale"
FTP_PASSWORD="filiale"

/usr/local/bin/php /incassi24d.php 2>/errori.txt > /ITR/incassi.txt
>/ITR/incassi.ctl

#parametri di collegamento tabella incggeur
INC_IP='10.11.14.154'
INC_USERNAME='cedadmin'
INC_PASSWORD='ced'

DATA_INIZIO=$(date -d "-7 day" +%Y%m%d)
mysql -u $INC_USERNAME -p$INC_PASSWORD -h $INC_IP -ss -e 'select concat(lpad(cast(`INGE-CODSO` as char),2,'0'), lpad(cast(`INGE-CODNE` as char),2,'0')),\
`INGE-DATA`, `INGE-TOTCLIE`,`INGE-TOTINCEFF` from archivi.incggeur where `INGE-DATA` > '"'"$DATA_INIZIO"'"' order by 1,2' 2>>errori.txt  > /ITR/totali.txt

ftp -in $FTP_IP <<SCRIPT
	user $FTP_USERNAME $FTP_PASSWORD
	binary
	cd /ITR
	mdelete *
	put "/ITR/incassi.txt"
	put "/ITR/totali.txt"
	put "/ITR/incassi.ctl"
	bye
SCRIPT

rm /ITR/*