#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

#parametri di collegamento db mysql
IP='10.11.14.76'
USERNAME='root'
PASSWORD='mela'

perl /script/calcolo_forme_di_pagamento.pl 1>/dev/null 2>/dev/null
perl /script/calcolo_resi.pl 1>/dev/null 2>/dev/null

mysql -u $USERNAME -p$PASSWORD -h $IP < /script/resi_dettaglio.sql 1>/dev/null 2>/dev/null
