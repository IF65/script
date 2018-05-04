#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

DATA=$(date -d "-1 days" +"%d-%m-%Y")

#parametri di collegamento db mysql
FTP_IP='mail.mtdistribution.it'
FTP_USERNAME='supermediaddt'
FTP_PASSWORD='ZC65U97-nk12'

#impostazione email di spedizione
SUBJECT="Report M.T."
ADDRESS="nicola.pirovano@supermedia.it,sergio.guidi@supermedia.it,marco.gnecchi@supermedia.it,fulviorontini@mtdistribution.it, mauromaggione@mtdistribution.it, ugotomassetti@consuldir.com, alessandrodonzelli@mtdistribution.it"
BODY="<html><body>\n<b>REPORT SETTIMANALE MT INVIATO</b><BR><BR>\n" 

#eliminazione vecchi report ancora presenti
rm -f /report_vendite_mt.xlsx 1>/dev/null 2>/dev/null
rm -f /report_giacenze_mt.xlsx 1>/dev/null 2>/dev/null

#creazione giacenze correnti
#/script/nf/creazione_giacenze_correnti.sh

#creo i report
perl /script/nf/report_mt.pl

#se il report è correttamente creato lo invio
if [ -s /report_vendite_mt.xlsx ]  
then  	
	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a /report_vendite_mt.xlsx /report_giacenze_mt.xlsx 
fi

if [ -e /report_vendite_mt.xlsx ]; then
	ftp -in $FTP_IP 1>/dev/null <<SCRIPT
		user $FTP_USERNAME $FTP_PASSWORD
		binary
		
		lcd /
		put /report_vendite_mt.xlsx
		bye
SCRIPT
fi

if [ -e /report_giacenze_mt.xlsx ]; then
	ftp -in $FTP_IP 1>/dev/null <<SCRIPT
		user $FTP_USERNAME $FTP_PASSWORD
		binary
		
		lcd /
		put /report_giacenze_mt.xlsx
		bye
SCRIPT
fi
