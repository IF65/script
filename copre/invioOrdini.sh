#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

DATA=$(date +%Y-%m-%d)

perl /script/copre/ricezioneOrdiniEPrice.pl
perl /script/copre/ricezioneOrdiniOnline.pl
perl /script/copre/ricezioneOrdiniYeppon.pl
perl /script/copre/ricezioneOrdiniTekworld.pl
perl /script/copre/invioOrdiniB2b.pl


#ADDRESS="marco.gnecchi@supermedia.it"
#BODY="<html><body>\n<b>RICEZIONE ORDINI B2B<BR>$DATA</b><BR><BR>\n"
#SUBJECT="RICEZIONE ORDINI B2B"

#/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25

