#!/bin/bash

export PATH="/usr/local/mysql/bin":$PATH

DATA=$(date +"%Y%m%d%H%M%S")

#utente
USER=filiale
PW=filiale
IP=10.11.14.111
REMOTE_PATH=/QBerg

#definizione cartelle
MAIN=/root/QBERG
OUT=$MAIN/OUT
IN=$MAIN/IN
SENT=$MAIN/SENT

#creazione cartelle
mkdir -p $MAIN
mkdir -p $OUT
mkdir -p $IN
mkdir -p $SENT

perl /script/QBerg/qberg.pl 

ftp -in $IP <<SCRIPT 1>/dev/null 2>&1
	user $USER $PW
	binary
	
	cd $REMOTE_PATH

	lcd $OUT
	
	mput *
	
	bye
SCRIPT

mv $IN/* $SENT 1>/dev/null 2>&1
rm -f $OUT/* 1>/dev/null 2>&1
