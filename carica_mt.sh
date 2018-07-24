#!/bin/bash

#export PERL5LIB=/root/perl5/lib/perl5

DATA=$(date +"%Y%m%d%H%M%S")

#utente
USER=supermediaddt
PW=ZC65U97-nk12
IP=mail.mtdistribution.it

#definizione cartelle
MAIN=/mt
IN=$MAIN/in
BKP=$MAIN/bkp
DA_CARICARE=$MAIN/da_caricare
REMOTE_PATH=GameTekk/Articoli

#creazione cartelle
mkdir -p $MAIN
mkdir -p $IN
mkdir -p $BKP
mkdir -p $DA_CARICARE

ftp -in $IP <<SCRIPT 1>/dev/null 2>&1
	user $USER $PW
	binary

	cd $REMOTE_PATH
	lcd $IN

	mget *.zip

	mdel *

	bye
SCRIPT

cd $IN 1>/dev/null 2>&1
LISTA_FILE=$(ls -1)
for f in $LISTA_FILE; do
	rm -fr "$DA_CARICARE/${f/.zip/}" 1>/dev/null 2>&1
	unzip "$IN/$f" web* -d "$DA_CARICARE/${f/.zip/}" 1>/dev/null 2>&1
done

cd $DA_CARICARE
LISTA_CARTELLE=$(ls -d * 2>/dev/null | sort -t "/" -k 1)
for d in $LISTA_CARTELLE; do
	cd $DA_CARICARE/$d
	LISTA_FILE=$(ls -1 web*)
	for f in $LISTA_FILE; do
		perl /script/articoliMt.pl -f $DA_CARICARE/$d/$f
	done
	cd $DA_CARICARE
	rm -fr $DA_CARICARE/$d 1>/dev/null 2>&1
done

mv $IN/* $BKP 1>/dev/null 2>&1
