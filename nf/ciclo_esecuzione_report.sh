#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

#parametri di collegamento db mysql
IP='10.11.14.78'
USERNAME='root'
PASSWORD='mela'

#verifico che non ci siano report in esecuzione
STMT='select count(*) from log.report_coda_esecuzione where stato = 500;'
#eseguo la query e salvo il risultato
REPORT_IN_ESECUZIONE=$(mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "$STMT")
if [ $REPORT_IN_ESECUZIONE -eq "0" ]; then
	
	#verifico che ci siano report da eseguire
	STMT='select count(*) from log.report_coda_esecuzione where stato = 0;'
	#eseguo la query e salvo il risultato
	REPORT_DA_ESEGUIRE=$(mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "$STMT")
	if [ $REPORT_DA_ESEGUIRE -ne "0" ]; then
	
		#query per estrarre i parametri di esecuzione
		STMT='	select concat( \
							lpad(id,10,"'"0"'"), \
							societa, \
							lpad(tipo,3,"'"0"'"), \
							date_format(data_corrente,"'"%Y-%m-%d"'"), \
							date_format(data_inizio,"'"%Y-%m-%d"'"), \
							date_format(data_fine,"'"%Y-%m-%d"'"), \
							date_format(data_corrente_ap,"'"%Y-%m-%d"'"), \
							date_format(data_inizio_ap,"'"%Y-%m-%d"'"), \
							date_format(data_fine_ap,"'"%Y-%m-%d"'"), \
							destinatari \
							) `` from log.report_coda_esecuzione where stato = 0 order by priorita desc, timestamp_apertura limit 1;'
					
		#eseguo la query e salvo il risultato
		COMANDO=$(mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "$STMT")

		#spezzo il comando nei parametri
		ID=$(echo ${COMANDO:0:10} | sed 's/^0*//')
		SOCIETA=${COMANDO:10:2}
		TIPO=$(echo ${COMANDO:12:3} | sed 's/^0*//')
		DATA_CORRENTE=${COMANDO:15:10}
		DATA_INIZIO=${COMANDO:25:10}
		DATA_FINE=${COMANDO:35:10}
		DATA_CORRENTE_AP=${COMANDO:45:10}
		DATA_INIZIO_AP=${COMANDO:55:10}
		DATA_FINE_AP=${COMANDO:65:10}
		DESTINATARI=${COMANDO:75}
	
		#marco il record come "in esecuzione"
		STMT="update log.report_coda_esecuzione set stato=500 where id=$ID;"
		mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "$STMT"
	
		cd /
	
		rm -f report_vendite* 1>/dev/null 2>/dev/null
		rm -f report.zip 1>/dev/null 2>/dev/null
		
		BODY="<html><body>\n<b>REPORT VENDITE DAL $DATA_INIZIO, AL $DATA_FINE<BR>$DATA</b><BR><BR>\n"
		SUBJECT="(ID:$ID) REPORT VENDITE INIZIO ELABORAZIONE: "
		/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $DESTINATARI -s 10.11.14.234:25
	
		perl /script/nf/report_vendite.pl -t 8 -s $SOCIETA -d $DATA_INIZIO $DATA_FINE $DATA_INIZIO_AP $DATA_FINE_AP
	
		BODY="<html><body>\n<b>REPORT VENDITE DAL $DATA_INIZIO, AL $DATA_FINE<BR>$DATA</b><BR><BR>\n"
		SUBJECT="(ID:$ID) REPORT VENDITE ELABORAZIONE COMPLETATA"
		zip -9m report.zip report_vendite.xlsm 1>/dev/null 2>/dev/null
		/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $DESTINATARI -s 10.11.14.234:25 -a /report.zip

		#marco il record come "eseguito"
		STMT="update log.report_coda_esecuzione set stato=999, timestamp_chiusura = current_timestamp() where id=$ID;"
		mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "$STMT"
	fi
fi
