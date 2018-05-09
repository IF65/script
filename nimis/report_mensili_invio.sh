#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

ALLA_DATA=$(date -d "-$(date +%d) days -0 month" +"%Y-%m-%d")
DALLA_DATA="${ALLA_DATA:0:4}-01-01"

ADDRESS="luigi.cherubini@italmark.com,andrea.pelizzari@italmark.com,alberto.forlini@italmark.com,manfredo.pasetti@supermedia.it,marco.gnecchi@if65.it"

rm -f /report_pago_nimis.* 1>/dev/null 2>/dev/null
perl /script/nimis/pago_nimis.pl $DALLA_DATA $ALLA_DATA
if [ -s /report_pago_nimis.xlsx ]  
then  
 	BODY="<html><body>\n<b>REPORT PAGO CON NIMIS MENSILE<BR>DAL: $DALLA_DATA<BR>AL: $ALLA_DATA</b><BR><BR>\n"
 	SUBJECT="Report Pago Nimis"
 	
 	cd /
 	zip -9m report_pago_nimis.zip report_pago_nimis.xlsx 1>/dev/null 2>/dev/null
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a /report_pago_nimis.zip
fi
rm -f /report_pago_nimis.* 1>/dev/null 2>/dev/null


rm -f /report_premiatissimi.* 1>/dev/null 2>/dev/null
perl /script/nimis/premiatissimi_valori.pl
if [ -s /report_premiatissimi.xlsx ]  
then  
	BODY="<html><body>\n<b>REPORT PREMIATISSIMI MENSILE<BR>AL: $ALLA_DATA</b><BR><BR>\n"
	SUBJECT="Report Premiatissimi"
	
	cd /
	zip -9m report_premiatissimi.zip report_premiatissimi.xlsx 1>/dev/null 2>/dev/null
	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a /report_premiatissimi.zip
fi
rm -f /report_premiatissimi.* 1>/dev/null 2>/dev/null
