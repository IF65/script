#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

#parametri di collegamento FTP
FTP_IP='ftp.grespa.com'
FTP_USERNAME="sellout"
FTP_PASSWORD="Sell20Out2009"

#cartelle
BASE='/gre'
INVIO="$BASE/file_da_inviare"
BKP="$BASE/file_inviati"

mkdir -p $INVIO
mkdir -p $BKP

#creazione file
perl /script/nf/export_gre.pl

#invio ftp
if [ -e $INVIO/CO_02147260174_SM.txt ]; then
	ftp -in $FTP_IP 1>/dev/null <<SCRIPT
		user $FTP_USERNAME $FTP_PASSWORD
		binary
		
		lcd $INVIO
		mput *
		bye
SCRIPT
fi

mv $INVIO/* $BKP
