#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

#parametri di collegamento ftp
#-----------------------------------------------------------------------------------------
FTP_USERNAME='copre'
FTP_PASSWORD='ftp-copre'
FTP_IP='11.0.1.231'

#parametri di invio email
#-----------------------------------------------------------------------------------------
BODY="<html><body>\n<b>File fatture C.A. recuperato<BR>$DATA</b><BR><BR>\n"
ADDRESS="gloria.cirelli@if65.it,marco.gnecchi@if65.it"
SUBJECT="Rucupero file fatture C.A."

#parametri di collegamento db mysql
#-----------------------------------------------------------------------------------------
IP='localhost'
USERNAME='root'
PASSWORD='mela'

#cartelle di backup/lavoro
#-----------------------------------------------------------------------------------------
BKP=/fatture_ca/bkp
LAV=/fatture_ca/da_caricare

mkdir -p $BKP
mkdir -p $LAV

ftp -in $FTP_IP >/dev/null 2>&1 <<SCRIPT
 	user $FTP_USERNAME $FTP_PASSWORD
 	binary
 	
 	lcd $LAV
 	
 	mget FATVEN*
 	mdelete FATVEN*
 	
 	bye
SCRIPT

for f in $(ls $LAV/FATVEN*.txt); do
	perl /script/nf/fatture2txt.pl $f $LAV/fatture_ca.txt
	mysqlimport -u root -pmela -h 10.11.14.78 --ignore --local db_sm $LAV/fatture_ca.txt >/dev/null 2>&1
	rm -f $LAV/fatture_ca.txt
	
	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a  $f >/dev/null 2>&1
	
	mv $f $BKP
done
