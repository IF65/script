#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

DATA=$(date +%Y-%m-%d)

cd /

rm -f report* 1>/dev/null 2>/dev/null

perl /script/nf/report_marche.pl

zip -9m report.zip report_marche.xlsx 1>/dev/null 2>/dev/null

BODY="<html><body>\n<b>REPORT MARCHEE ANNUALE<BR>$DATA</b><BR><BR>\n"
ADDRESS="luisa.bertoni@supermedia.it,marco.gnecchi@if65.it"

SUBJECT="REPORT MARCHE"

/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a /report.zip

