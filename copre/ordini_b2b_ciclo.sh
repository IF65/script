#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

#parametri di collegamento db mysql
IP='10.11.14.78'
USERNAME='root'
PASSWORD='mela'

#verifico che non ci siano import in esecuzione
STMT='select count(*) from log.ordini_b2b_coda_esecuzione where stato = 500;'
#eseguo la query e salvo il risultato
IMPORT_IN_ESECUZIONE=$(mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "$STMT")
if [ $IMPORT_IN_ESECUZIONE -eq "0" ]; then
	
	#verifico che ci siano import da eseguire
	STMT='select count(*) from log.ordini_b2b_coda_esecuzione where stato = 0;'
	#eseguo la query e salvo il risultato
	IMPORT_DA_ESEGUIRE=$(mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "$STMT")
	if [ $IMPORT_DA_ESEGUIRE -ne "0" ]; then
	
		#query per estrarre i parametri di esecuzione
		STMT='select id `` from log.ordini_b2b_coda_esecuzione where stato = 0 and tipo = 1 order by timestamp_apertura limit 1;'
					
		#eseguo la query e salvo il risultato
		COMANDO=$(mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "$STMT")

		#spezzo il comando nei parametri (per ora non ne uso)
		ID=$COMANDO
	
		#marco il record come "in esecuzione"
		STMT="update log.ordini_b2b_coda_esecuzione set stato=500 where id=$ID;"
		mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "$STMT"
	
		perl /script/copre/ricezioneOrdiniEPrice.pl
		perl /script/copre/ricezioneOrdiniOnline.pl
		perl /script/copre/ricezioneOrdiniYeppon.pl
		perl /script/copre/ricezioneOrdiniTekworld.pl
		perl /script/copre/invioOrdiniB2b.pl

		#marco il record come "eseguito"
		STMT="update log.ordini_b2b_coda_esecuzione set stato=999, timestamp_chiusura = current_timestamp() where id=$ID;"
		mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "$STMT"
	fi
fi
