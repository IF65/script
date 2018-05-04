#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

DATA=$(date +%Y-%m-%d)

cd /

rm -f report_vendite* 1>/dev/null 2>/dev/null
#rm -f progress_vendite* 1>/dev/null 2>/dev/null

perl /script/nf/report_vendite.pl -t 6 -d $DATA
perl /script/nf/report_vendite.pl -t 7 -d $DATA

zip -9m report.zip report_vendite_mensili_gfk.xlsm report_vendite_annuali_gfk.xlsm 1>/dev/null 2>/dev/null

BODY="<html><body>\n<b>REPORT VENDITE GFK MENSILE E ANNUALE<BR>$DATA</b><BR><BR>\n"
ADDRESS="luisa.bertoni@supermedia.it,marco.gnecchi@if65.it"

SUBJECT="REPORT VENDITE GFK"

/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a /report.zip

