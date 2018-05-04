#!/bin/bash

export PATH="/usr/local/mysql/bin":$PATH

DATA=$(date +"%Y%m%d%H%M%S")

#utente
USER=filiale
PW=filiale
IP=10.11.14.111
REMOTE_PATH=/Quadrature

#definizione cartelle
MAIN=/tabelle
SENT=$MAIN/sent
SOURCE=$MAIN/source

#creazione cartelle
mkdir -p $MAIN
mkdir -p $SENT
mkdir -p $SOURCE

#nome dei file
CLINCCOL="CLINCCOL.txt"
CLSOSCOL="CLSOSCOL.txt"
NEWCLCOL="NEWCLCOL.txt"

NEW_CLINCCOL="CLINCCOL_"$DATA".txt"
NEW_CLSOSCOL="CLSOSCOL_"$DATA".txt"
NEW_NEWCLCOL="NEWCLCOL_"$DATA".txt"

ftp -in $IP <<SCRIPT 1>/dev/null 2>&1
	user $USER $PW
	binary
	
	cd $REMOTE_PATH/tabelle

	lcd $SOURCE
	
	get "$CLINCCOL" "$NEW_CLINCCOL"
	get "$CLSOSCOL" "$NEW_CLSOSCOL"
	get "$NEWCLCOL" "$NEW_NEWCLCOL"
	
	delete "$CLINCCOL"
	delete "$CLSOSCOL"
	delete "$NEWCLCOL"
	
	bye
SCRIPT


# invio dati nelle cartelle delle societa'
ftp -in $IP <<SCRIPT 1>/dev/null 2>&1
	user $USER $PW
	binary
	
	cd $REMOTE_PATH/07

	lcd $SOURCE
	put "$NEW_CLINCCOL" "$CLINCCOL"
	put "$NEW_CLSOSCOL" "$CLSOSCOL"
	put "$NEW_NEWCLCOL" "$NEWCLCOL"
	bye
SCRIPT

ftp -in $IP <<SCRIPT 1>/dev/null 2>&1
	user $USER $PW
	binary
	
	cd $REMOTE_PATH/08

	lcd $SOURCE
	put "$NEW_CLINCCOL" "$CLINCCOL"
	put "$NEW_CLSOSCOL" "$CLSOSCOL"
	put "$NEW_NEWCLCOL" "$NEWCLCOL"
	bye
SCRIPT

ftp -in $IP <<SCRIPT 1>/dev/null 2>&1
	user $USER $PW
	binary
	
	cd $REMOTE_PATH/10

	lcd $SOURCE
	put "$NEW_CLINCCOL" "$CLINCCOL"
	put "$NEW_CLSOSCOL" "$CLSOSCOL"
	put "$NEW_NEWCLCOL" "$NEWCLCOL"
	bye
SCRIPT

ftp -in $IP <<SCRIPT 1>/dev/null 2>&1
	user $USER $PW
	binary
	
	cd $REMOTE_PATH/19

	lcd $SOURCE
	put "$NEW_CLINCCOL" "$CLINCCOL"
	put "$NEW_CLSOSCOL" "$CLSOSCOL"
	put "$NEW_NEWCLCOL" "$NEWCLCOL"
	bye
SCRIPT

ftp -in $IP <<SCRIPT 1>/dev/null 2>&1
	user $USER $PW
	binary
	
	cd $REMOTE_PATH/53

	lcd $SOURCE
	put "$NEW_CLINCCOL" "$CLINCCOL"
	put "$NEW_CLSOSCOL" "$CLSOSCOL"
	put "$NEW_NEWCLCOL" "$NEWCLCOL"
	bye
SCRIPT

mv $SOURCE/* $SENT
