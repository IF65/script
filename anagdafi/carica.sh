#!/bin/bash

#parametri di collegamento db mysql x log
LOG_IP='10.11.14.78'
LOG_USERNAME='root'
LOG_PASSWORD='mela'

#parametri di collegamento db mysql (pu˜ essere diverso dal db dove sono caricati i log)
IP='10.11.14.78'
USERNAME='root'
PASSWORD='mela'

#posizione degli script
DIR_SCRIPT="/script/anagdafi"

#posizione dei file anagdafi
DIR_BASE="/dati/anagdafi"

#posizione cartelle di preparazione dati per l'invio
DIR_PREPARAZIONE="/anagdafi"

#creo le cartelle di preparazione se non esistono
mkdir -p $DIR_PREPARAZIONE 1>/dev/null 2>&1

#le ripulisco da eventuali file rimasti da precedenti caricamenti
rm -f $DIR_PREPARAZIONE/* 1>/dev/null 2>&1

#query per ottenere i nomi dei file da caricare e delle cartelle che li contengono
STMT='	select concat(date_format(i.`data`,"'"%Y%m%d"'"),i.`negozio_codice`) `` \
		from lavori.incarichi as i join \
		(select `negozio_codice`, `data` from lavori.incarichi where `lavoro_codice`=30 and `eseguito`>0) as g on i.`negozio_codice`=g.`negozio_codice` and i.`data`=g.`data` \
		where i.`lavoro_codice`=190 and i.`eseguito`=0 order by i.`negozio_codice`, i.`data`;'
LISTA_FILE=$(mysql -u $LOG_USERNAME -p$LOG_PASSWORD -h $LOG_IP -ss -e "$STMT" 2>/dev/null)

# nome icon cui ogni singolo anagdafi verrˆ  scompattato prima di essere trasformato nel file export.txt
FILE_ANAGDAFI="ANAGDAFI.CSV"

#preparo singolarmente ogni negozio
for f in $LISTA_FILE; do
	DATA="${f:0:8}"
	NEGOZIO="${f:8:4}"
	
	DATA_MYSQL="'${f:0:4}-${f:4:2}-${f:6:2}'"
	NEGOZIO_MYSQL="'${f:8:4}'"
	
	printf "$(date +%Y-%m-%d:%H:%M:%S): elaborazione negozio $NEGOZIO, ${DATA:0:4}-${DATA:4:2}-${DATA:6:2}:"
	
	CARICABILE=$(php $DIR_SCRIPT/caricabile.php $DATA $NEGOZIO 2>/dev/null)
	if [[ $CARICABILE == *"1"* ]] || [ "${DATA:4}" == "0101" ]
    then
		BKP_ANAGDAFI=$DATA"_"$NEGOZIO".zip"
		if [ -e "$DIR_BASE/$DATA/$BKP_ANAGDAFI" ]
		then			
			unzip -p "$DIR_BASE/$DATA/$BKP_ANAGDAFI" > "$DIR_PREPARAZIONE/$FILE_ANAGDAFI" 2>/dev/null

			# creo il file export.txt partendo da ANAGDAFI.CSV (export.txt corrisponde alla struttura della tabella export)
			php $DIR_SCRIPT/anagdafi2Export.php $DATA $NEGOZIO 1>/dev/null 2>&1
			mysql -u $USERNAME -p$PASSWORD -h $IP < $DIR_SCRIPT/crea.sql 1>/dev/null 2>&1
			mysqlimport -u $USERNAME -p$PASSWORD -h $IP --delete --local "dc" $DIR_PREPARAZIONE/export.txt 1>/dev/null 2>&1
			mysql -u $USERNAME -p$PASSWORD -h $IP -e "set @data=${DATA_MYSQL}; set @negozio=${NEGOZIO_MYSQL}; source $DIR_SCRIPT/carica.sql;" 

			STMT='update lavori.incarichi as i set i.`eseguito`=1 where i.`lavoro_codice`=190 and i.`data` = "'"$DATA"'" and i.`negozio_codice` = "'"$NEGOZIO"'";'
			mysql -u $LOG_USERNAME -p$LOG_PASSWORD -h $LOG_IP -ss -e "$STMT" 1>/dev/null 2>&1

			printf " Ok\n"
		else
			printf " anagdafi mancante\n"
		fi
	else
		printf " Non caricabile\n"
	fi
done

exit
