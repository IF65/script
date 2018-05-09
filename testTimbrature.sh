
export TIMB='root@10.11.14.92'

DATA=$(date -d "1 day ago" '+%Y%m%d')

TEST=$(ssh $TIMB "ls /hr-app/webapps/timbrature/*$DATA*.err 2>/dev/null")

if [ ! -z "$TEST" ]
then
	DATA=$(date -d "1 day ago" '+%d/%m/%Y')
	ADDRESS="gestione.presenze@if65.it, alberto.ombelli@if65.it, marco.gnecchi@if65.it"
	BODY="<html><body>\n<b>Data: $DATA<BR>Elenco file errati: $TEST</b><BR><BR>\n"
	SUBJECT="SEGNALAZIONE ERRORI FILE TIMBRATURE"

/sendEmail-v1.56/sendEmail -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.233:25

fi
