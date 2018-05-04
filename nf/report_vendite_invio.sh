#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

DATA=$(date +%Y-%m-%d)

cd /

rm -f report_vendite* 1>/dev/null 2>/dev/null

perl /script/nf/report_vendite.pl -t 2 -d $DATA
perl /script/nf/report_vendite.pl -t 3 -d $DATA
perl /script/nf/report_vendite.pl -t 4 -d $DATA
zip -9m report.zip report_vendite_settimanali.xlsm report_vendite_mensili.xlsm report_vendite_annuali.xlsm 1>/dev/null 2>/dev/null

#ADDRESS="luisa.bertoni@supermedia.it,nicola.pirovano@supermedia.it, marco.gnecchi@supermedia.it, paolo.odolini@supermedia.it"
ADDRESS="luisa.bertoni@supermedia.it, marco.gnecchi@supermedia.it"
BODY="<html><body>\n<b>REPORT VENDITE SETTIMANALE, MENSILE E ANNUALE<BR>$DATA</b><BR><BR>\n"
SUBJECT="REPORT VENDITE"

/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a /report.zip
