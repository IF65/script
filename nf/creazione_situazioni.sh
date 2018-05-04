#!/bin/bash

#parametri di collegamento db mysql
IP='localhost'
USERNAME='root'
PASSWORD='mela'

mysql -u $USERNAME -p$PASSWORD -h $IP < /script/nf/creazione_situazioni.sql 
