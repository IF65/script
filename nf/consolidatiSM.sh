#!/bin/bash

#parametri di collegamento db mysql
IP='10.11.14.78'
USERNAME='root'
PASSWORD='mela'

mysql -u $USERNAME -p$PASSWORD -h $IP < /script/nf/consolidatiSM.sql 1>/dev/null 2>&1

exit
