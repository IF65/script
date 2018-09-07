#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

ADDRESS="andrea.vellucci@sony.com, maurizioconte@lfmgroup.it, sceit_data@scee.net, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="SONY_GAME"
FILE_NAME="/2017_W47_SONY_GAME.xlsx"
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi




