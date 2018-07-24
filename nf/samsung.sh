#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5


#ADDRESS="daniele.fedrigo@supermedia.it, stefano.facchini@supermedia.it, marco.gnecchi@if65.it"
ADDRESS="marco.gnecchi@if65.it"
SELETTORE="SAMSUNG"
FTP_IP="ftp3.samsung.it"
FTP_USERNAME="copre"
FTP_PASSWORD="Htr&ju65"
FILE_NAME=$(perl /script/nf/report_stock_txt_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.233:25 -a $FILE_NAME
 	echo $FTP_USERNAME
 	echo $FTP_PASSWORD
 	echo $FILE_NAME
 		ftp -in $FTP_IP <<SCRIPT
		user ""$FTP_USERNAME" ""$FTP_PASSWORD"
		binary
		put $FILE_NAME
		bye
SCRIPT

fi
#rm -f $FILE_NAME
#1>/dev/null
