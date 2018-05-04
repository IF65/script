#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

mysqldump -h 10.11.14.154 -u cedadmin -pced archivi articox2 barartx2 fidelity artinego_vert tabel256 tabvarie offertx2 offnxmx2 fornitx2 | mysql -u root -pmela archivi
mysqldump -h 10.11.14.154 -u cedadmin -pced dimensioni articolo | mysql -u root -pmela dimensioni
mysqldump -h 10.11.14.154 -u cedadmin -pced archivi incggeur riepazz2 | mysql -u root -pmela controllo
mysql -u root -pmela < /script/quadrature.sql

#mysql -u root -pmela < /script/cancellazione_eliminati.sql

echo $(date) >> /mysql_last_update.txt

#perl /script/caricamento_da_lrp.pl
