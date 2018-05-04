#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

DATA=$(date -d "-1 days" +"%d-%m-%Y")

#parametri di collegamento db mysql
IP='localhost'
USERNAME='root'
PASSWORD='mela'

#impostazione email di spedizione
SUBJECT="Report Estendo"
ADDRESS="paolo.odolini@supermedia.it,carlo.cattaneo@supermedia.it,luca.gogna@supermedia.it,sergio.laschena@supermedia.it,nicola.pirovano@supermedia.it,marco.gnecchi@supermedia.it"
BODY="<html><body>\n<b>REPORT GIORNALIERO ESTENDO AL $DATA</b><BR><BR>\n"

#creazione ed aggiornamento db
mysql -u $USERNAME -p$PASSWORD -h $IP < /script/nf/estendo_creazione_db.sql 

#eliminazione vecchi report ancora presenti
rm -f /report_estendo.xlsx 1>/dev/null 2>/dev/null

#creo il report
perl /script/nf/estendo_creazione_report.pl

#se il report è correttamente creato lo invio
if [ -s /report_estendo.xlsx ]  
then  	
	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a /report_estendo.xlsx
fi
