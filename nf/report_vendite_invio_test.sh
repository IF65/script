#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

DATA=$(date +%Y-%m-%d)

cd /

rm -f report_vendite* 1>/dev/null 2>/dev/null

perl /script/nf/report_vendite_test.pl -t 2 -d $DATA

zip -9m report.zip report_vendite.xlsm 1>/dev/null 2>/dev/null

BODY="<html><body>\n<b>REPORT VENDITE GIORNALIERO DISTRICT 1<BR>$DATA</b><BR><BR>\n"
ADDRESS="luca.gogna@supermedia.it, marco.gnecchi@supermedia.it"
#ADDRESS="marco.gnecchi@supermedia.it"

SUBJECT="REPORT VENDITE GIORNALIERO DISTRICT 1"

/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a /report.zip

