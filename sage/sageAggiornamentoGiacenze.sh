#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

#parametri di collegamento FTP
FTP_IP='10.11.14.229'
FTP_USERNAME="sage"
FTP_PASSWORD="sage"

#posizione del file da inviare
DIR_OUT=/sage/out

#creo le cartelle di preparazione
mkdir -p $DIR_OUT

#ripulisco da vecchi file
rm -f $DIR_OUT/Giacenze*

#creazione listino
perl /script/sage/sageAggiornamentoGiacenze.pl

#se ci sono file epipoli da inviare li invio
cd $DIR_OUT

FILE_NAME="Giacenze.txt"
CARTELLA_INVIO_FTP="/tmp/GIACENZE"
	
ftp -in $FTP_IP 1>/dev/null <<SCRIPT
	user $FTP_USERNAME $FTP_PASSWORD
	binary
	lcd $DIR_OUT
	cd $CARTELLA_INVIO_FTP
	put $FILE_NAME
	bye
SCRIPT
	
