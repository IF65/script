#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

#cartelle
BASE='/copre'
INVIO="$BASE/file_da_inviare"
BKP="$BASE/file_inviati"

mkdir -p $INVIO
mkdir -p $BKP

#creazione file
perl /script/nf/export_copre.pl

#invio ftp

#parametri di collegamento FTP COPRE
FTP_IP='ftp.intranet.copre.it'
FTP_USERNAME="copre_sellout"
FTP_PASSWORD="!coprem?"

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
