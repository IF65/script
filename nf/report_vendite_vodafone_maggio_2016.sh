#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

DATA=$(date --date "-1 day" +%d-%m-%Y)

cd /

rm -f /report_vendite_vodafone_maggio_2016.xlsx 1>/dev/null 2>/dev/null

perl /script/nf/report_vendite_vodafone_maggio_2016.pl

BODY="<html><body>\n<b>REPORT VENDUTO VODAFONE MAGGIO 2016 AGGIORNATO AL $DATA</b><BR><BR>\n"
ADDRESS="luca.gogna@supermedia.it, marco.gnecchi@supermedia.it"

SUBJECT="REPORT VENDUTO VODAFONE MAGGIO 2016"

/sendEmail-v1.56/sendEmail -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a /report_vendite_vodafone_maggio_2016.xlsx

