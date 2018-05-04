#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

#parametri di collegamento FTP Catalina
FTP_CATALINA_IP='ftp.catalinamarketing.it'
FTP_CATALINA_USERNAME="italmark"
FTP_CATALINA_PASSWORD="it3452rk"

#posizione file da inviare
DIR_INVIO=/tessere_catalina

#creo le cartelle di preparazione
mkdir -p $DIR_INVIO

#creo il file
perl /script/tessere_sostituite.pl > $DIR_INVIO/hh.268.txt

# se ci sono file catalina da inviare li invio
cd $DIR_INVIO
if [ "$(ls -A $DIR_INVIO/*.txt 2>/dev/null)" ]
then
	ftp -in $FTP_CATALINA_IP 1>/dev/null <<SCRIPT
	user $FTP_CATALINA_USERNAME $FTP_CATALINA_PASSWORD
	binary
	put hh.268.txt
	bye
SCRIPT
fi