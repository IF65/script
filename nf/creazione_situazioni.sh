#!/bin/bash

#parametri di collegamento db mysql
IP='localhost'
USERNAME='root'
PASSWORD='mela'

echo $(date)

php /script/ricalcolo/ricalcolo.php

echo $(date)

mysql -u $USERNAME -p$PASSWORD -h $IP < /script/nf/creazione_situazioni.sql 

echo $(date)


