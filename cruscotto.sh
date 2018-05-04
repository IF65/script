#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

DATA=$(date +%Y-%m-%d)

cd /

rm -f /cruscotto.xlsx 1>/dev/null 2>/dev/null

perl /script/caricamento_da_lrp.pl
perl /script/cruscotto.pl

BODY="<html><body>\n<b>SITUAZIONE CARICAMENTO DATI AL: <BR>$DATA</b><BR><BR>\n"
ADDRESS="marco.gnecchi@if65.it, maurizio.benedetti@if65.it, andrea.odolini@if65.it"

SUBJECT="Cruscotto Caricamento Dati"

/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a /cruscotto.xlsx

