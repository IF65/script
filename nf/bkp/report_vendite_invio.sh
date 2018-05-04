#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

DATA=$(date +%Y-%m-%d)

cd /

rm -f report_vendite* 1>/dev/null 2>/dev/null
#rm -f progress_vendite* 1>/dev/null 2>/dev/null

perl /script/nf/report_vendite.pl -t 2 -d $DATA
perl /script/nf/report_vendite.pl -t 3 -d $DATA
perl /script/nf/report_vendite.pl -t 4 -d $DATA

zip -9m report.zip report_vendite_settimanali.xlsm report_vendite_mensili.xlsm report_vendite_annuali.xlsm 1>/dev/null 2>/dev/null

BODY="<html><body>\n<b>REPORT VENDITE SETTIMANALE, MENSILE E ANNUALE<BR>$DATA</b><BR><BR>\n"
ADDRESS="luisa.bertoni@supermedia.it,marco.gnecchi@if65.it"
SUBJECT="REPORT SETTIMANALI"

/sendEmail-v1.56/sendEmail -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a /report.zip

# perl /script/nf/report_vendite.pl -t 5 -d $DATA
# perl /script/nf/report_vendite.pl -t 6 -d $DATA
# perl /script/nf/report_vendite.pl -t 7 -d $DATA
# 
# zip -9m progress.zip progress_vendite_settimanali.xlsm progress_vendite_mensili.xlsm progress_vendite_annuali.xlsm 1>/dev/null 2>/dev/null

#(echo "Il file compattato contiene i report settimanale, mensile e annuale secondo la ripartizione dei periodi standard GFK!"; uuencode /report.zip report.zip) \
#| mailx -r "edp@if65.it" -s "Report Vendite Supermedia" -S smtp=10.11.14.234 maurizio.benedetti@if65.it
#nicola.pirovano@supermedia.it,umberto.trainini@supermedia.it,daniele.fedrigo@supermedia.it,luisa.bertoni@supermedia.it,marco.gnecchi@if65.it,paolo.odolini@supermedia.it

rm -f report.zip 1>/dev/null 2>/dev/null
#rm -f progress_vendite* 1>/dev/null 2>/dev/null


# ECOBRICO

# rm -f report_vendite* 1>/dev/null 2>/dev/null
# 
# perl /script/nf/report_vendite.pl -t 2 -d $DATA -s EB
# perl /script/nf/report_vendite.pl -t 3 -d $DATA -s EB
# perl /script/nf/report_vendite.pl -t 4 -d $DATA -s EB
# 
# zip -9m report.zip report_vendite_settimanali.xlsm report_vendite_mensili.xlsm report_vendite_annuali.xlsm 1>/dev/null 2>/dev/null
# 
# (echo "Il file compattato contiene i report settimanale, mensile e annuale secondo la ripartizione dei periodi standard GFK!"; uuencode /report.zip report.zip) \
# | mailx -r "edp@if65.it" -s "Report Vendite Ecobrico" -S smtp=10.11.14.234 gianluca.gerevasi@ecobrico.it,marco.gnecchi@if65.it,andrea.odolini@if65.it
# 
# rm -f report.zip 1>/dev/null 2>/dev/null
