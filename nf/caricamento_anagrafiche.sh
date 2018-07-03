#!/bin/bash

#verifico che il caricamento non sia già in esecuzione
if [ ! -e "/CARICAMENTO_NF_IN_CORSO" ]; then
	touch /CARICAMENTO_NF_IN_CORSO
	
	for SOCIETA in SM SP RU EB; do 
		case $SOCIETA in
			'SM')	DB='db_sm';;
			'SP')	DB='db_sp';;
			'RU')	DB='db_ru';;
			'EB')	DB='db_eb';;
		esac

		#parametri di collegamento db mysql
		IP='localhost'
		USERNAME='root'
		PASSWORD='mela'

		#posizione dei dati gre
		DIR_BASE=/nf

		#posizione cartelle di caricamento e invio
		DIR_FILE_DA_CARICARE="$DIR_BASE/file_da_caricare"
		DIR_FILE_CARICATI="$DIR_BASE/file_caricati"

		#creo le cartelle
		mkdir -p $DIR_FILE_DA_CARICARE
		mkdir -p $DIR_FILE_CARICATI
		
		rm -f $DIR_FILE_DA_CARICARE/*_STO_* > /dev/null 2>&1

		#creo il database se non esiste
		mysql -u $USERNAME -p$PASSWORD -h $IP < /script/nf/creazione_db.sql

		#caricamento magazzino
		NOME_FILE='magazzino.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_MAG* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
	
			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_MAG* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi

		#caricamento marche
		NOME_FILE='marche.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_MAR* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
	
			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_MAR* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi

		#tabulato_copre
		NOME_FILE='tabulato_copre.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_TCO* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
	
			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_TCO* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi
		
		#caricamento mondi
		NOME_FILE='mondi.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_MON* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
	
			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_MON* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi

		#caricamento settori
		NOME_FILE='settori.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_SET* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
	
			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_SET* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi

		#caricamento reparti
		NOME_FILE='reparti.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_REP* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f

			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_REP* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi

		#caricamento famiglie
		NOME_FILE='famiglie.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_FAM* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f

			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_FAM* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi
		
		#caricamento sottofamiglie
		NOME_FILE='sottofamiglie.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_SFM* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f

			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_SFM* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi

		#caricamento ean
		NOME_FILE='ean.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_EAN* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f

			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_EAN* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi

		#caricamento righe vendita
		NOME_FILE='righe_vendita.txt'
		#carico solo i file che hanno il file di controllo
		for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_RVE* 2>/dev/null | grep -vE "\."); do
			CHIUSURA_NEGOZIO=${f:7:4}
			if [ "${CHIUSURA_NEGOZIO:3:1}" == "_" ]; then
				CHIUSURA_NEGOZIO=${f:7:3}
				CHIUSURA_DATA=${f:11:4}-${f:15:2}-${f:17:2}
			else
				CHIUSURA_DATA=${f:12:4}-${f:16:2}-${f:18:2}
			fi
			
			if [ -s $DIR_FILE_DA_CARICARE/$f.gz ]; then
				gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
				mysqlimport -u $USERNAME -p$PASSWORD --ignore --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
				rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
				
				mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e \
					"insert ignore into $DB.logCaricamento (sede,data,tipo,descrizione,vuoto) \
					 values('$CHIUSURA_NEGOZIO','$CHIUSURA_DATA','RVE','RIGHE VENDITA',0)" #> /dev/null 2>&1
			else
				mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e \
					"insert ignore into $DB.scontrini (id_scontrino,negozio,data,ora,numero,numero_upb,scontrino_non_fiscale,carta,totale,ip) \
					 values('$CHIUSURA_NEGOZIO"_"$CHIUSURA_DATA','$CHIUSURA_NEGOZIO','$CHIUSURA_DATA','00:00:00',999999,999999,1,'',0,'')" > /dev/null 2>&1
					 
				mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e \
					"insert ignore into $DB.logCaricamento (sede,data,tipo,descrizione,vuoto) \
					 values('$CHIUSURA_NEGOZIO','$CHIUSURA_DATA','RVE','RIGHE VENDITA',1)" > /dev/null 2>&1
			fi
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
		done

		#caricamento scontrini
		NOME_FILE='scontrini.txt'
		#carico solo i file che hanno il file di controllo
		for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_RVT* 2>/dev/null | grep -vE "\."); do
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --replace --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
		done

		#caricamento margini
		NOME_FILE='margini.txt'
		#carico solo i file che hanno il file di controllo
		for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_RVM* 2>/dev/null | grep -vE "\." | sort); do
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --replace --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
		done
		
		#caricamento contributi
		NOME_FILE='contributi.txt'
		#carico solo i file che hanno il file di controllo
		for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_RVC* 2>/dev/null | grep -vE "\." | sort); do
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
		done
	
		# caricamento arrivi
		NOME_FILE='arrivi.txt'
		# carico solo i file che hanno il file di controllo
		for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_ARX* 2>/dev/null | grep -vE "\." | sort); do
			NEGOZIO=${f:7:4}
			if [ "${NEGOZIO:3:1}" == "_" ]; then
				NEGOZIO=${f:7:3}
			fi
			
			#cancello i vecchi record prima del caricamento
			mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "delete from $DB.arrivi where negozio = '$NEGOZIO'" #2>/dev/null
			
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE #> /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
		done

		# caricamento righe arrivi
		NOME_FILE='righe_arrivi.txt'
		# carico solo i file che hanno il file di controllo
		for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_ARR* 2>/dev/null | grep -vE "\." | sort); do
			NEGOZIO=${f:7:4}
			if [ "${NEGOZIO:3:1}" == "_" ]; then
				NEGOZIO=${f:7:3}
			fi
			
			#cancello i vecchi record prima del caricamento
			echo "delete from $DB.righe_arrivi where $DB.righe_arrivi.id_arrivi in (select id from $DB.arrivi where negozio = '$NEGOZIO')"
			mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "delete from $DB.righe_arrivi where $DB.righe_arrivi.id_arrivi in (select id from $DB.arrivi where negozio = '$NEGOZIO')" #2>/dev/null
			
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE #> /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
		done

		#caricamento ordini
		NOME_FILE='ordini.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_ORD* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
	
			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_ORD* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi
		
		#caricamento ordini righe
		NOME_FILE='ordini_righe.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_ORR* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
	
			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_ORR* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi
		
		#caricamento ordini righe quantita
		NOME_FILE='ordini_righe_quantita.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_ORQ* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
	
			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_ORQ* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi

		#caricamento ordini righe quantita ventilazione
		NOME_FILE='ordini_righe_quantita_ventilazione.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_ORV* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
	
			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_ORV* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi

		#caricamento ordini sedi
		NOME_FILE='ordini_sedi.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_ORS* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
	
			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_ORS* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi

		# caricamento trasferimenti in
		NOME_FILE='trasferimenti_in.txt'
		# carico solo i file che hanno il file di controllo
		for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_TIN* 2>/dev/null | grep -vE "\." | sort); do
			NEGOZIO=${f:7:4}
			if [ "${NEGOZIO:3:1}" == "_" ]; then
				NEGOZIO=${f:7:3}
			fi
			
			#cancello i vecchi record prima del caricamento
			mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "delete from $DB.trasferimenti_in where negozio_arrivo = '$NEGOZIO'" 2>/dev/null
			
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
		done

		# caricamento righe trasferimenti in
		NOME_FILE='righe_trasferimenti_in.txt'
		# carico solo i file che hanno il file di controllo
		for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_TRI* 2>/dev/null | grep -vE "\." | sort); do
			NEGOZIO=${f:7:4}
			if [ "${NEGOZIO:3:1}" == "_" ]; then
				NEGOZIO=${f:7:3}
			fi
			
			#cancello i vecchi record prima del caricamento
			mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "delete from $DB.righe_trasferimenti_in where $DB.righe_trasferimenti_in.link_trasferimento in (select link from $DB.trasferimenti_in where negozio_arrivo = '$NEGOZIO')" 2>/dev/null
			
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
		done
		
		# caricamento trasferimenti out
		NOME_FILE='trasferimenti_out.txt'
		# carico solo i file che hanno il file di controllo
		for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_TOU* 2>/dev/null | grep -vE "\." | sort); do
			NEGOZIO=${f:7:4}
			if [ "${NEGOZIO:3:1}" == "_" ]; then
				NEGOZIO=${f:7:3}
			fi
			
			#cancello i vecchi record prima del caricamento
			mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "delete from $DB.trasferimenti_out where negozio_partenza = '$NEGOZIO'" 2>/dev/null
			
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
		done
		
		# caricamento righe trasferimenti out
		NOME_FILE='righe_trasferimenti_out.txt'
		# carico solo i file che hanno il file di controllo
		for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_TRO* 2>/dev/null | grep -vE "\." | sort); do
			NEGOZIO=${f:7:4}
			if [ "${NEGOZIO:3:1}" == "_" ]; then
				NEGOZIO=${f:7:3}
			fi
			
			#cancello i vecchi record prima del caricamento
			mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "delete from $DB.righe_trasferimenti_out where $DB.righe_trasferimenti_out.link_trasferimento in (select link from $DB.trasferimenti_out where negozio_partenza = '$NEGOZIO')" 2>/dev/null
			
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
		done
		
		# caricamento diversi
		NOME_FILE='diversi.txt'
		# carico solo i file che hanno il file di controllo
		for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_DIV* 2>/dev/null | grep -vE "\." | sort); do
			NEGOZIO=${f:7:4}
			if [ "${NEGOZIO:3:1}" == "_" ]; then
				NEGOZIO=${f:7:3}
			fi
			
			#cancello i vecchi record prima del caricamento
			mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "delete from $DB.diversi where negozio = '$NEGOZIO'" 2>/dev/null
			
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
		done
		
		# caricamento righe diversi
		NOME_FILE='righe_diversi.txt'
		# carico solo i file che hanno il file di controllo
		for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_DIR* 2>/dev/null | grep -vE "\." | sort); do
			NEGOZIO=${f:7:4}
			if [ "${NEGOZIO:3:1}" == "_" ]; then
				NEGOZIO=${f:7:3}
			fi
			
			#cancello i vecchi record prima del caricamento
			mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "delete from $DB.diversi where $DB.diversi.link_diversi in (select link from $DB.diversi where negozio = '$NEGOZIO')" 2>/dev/null
			
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
		done
		
		#caricamento giacenze iniziali
		NOME_FILE='giacenze_iniziali.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_GIN* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			NEGOZIO=${f:7:4}
			if [ "${NEGOZIO:3:1}" == "_" ]; then
				NEGOZIO=${f:7:3}
			fi
			
			#cancello i vecchi record prima del caricamento
			mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "delete from $DB.giacenze_iniziali where negozio = '$NEGOZIO'" 2>/dev/null
		
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --replace --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
	
			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_MAG* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi
		
		# caricamento benefici
		NOME_FILE='benefici.txt'
		# carico solo i file che hanno il file di controllo
		for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_BEN* 2>/dev/null | grep -vE "\." | sort); do
			NEGOZIO=${f:7:4}
			if [ "${NEGOZIO:3:1}" == "_" ]; then
				NEGOZIO=${f:7:3}
			fi
			
			#cancello i vecchi record prima del caricamento
			mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "delete from $DB.benefici where negozio = '$NEGOZIO'" 2>/dev/null
			
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
		done

		#caricamento venditori
		NOME_FILE='venditori.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_VEN* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
	
			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_VEN* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi
			
		#caricamento verifica arrivi
		NOME_FILE='verifica_arrivi.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_VAR* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
	
			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_VAR* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi
		
		# fornitore articolo
		NOME_FILE='fornitore_articolo.txt'
		f=$(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_FAR* 2>/dev/null | grep -vE "\." | sort -r | head -1)
		if [ -n "$f" ]; then
			#carico solo il file più nuovo tra quelli che hanno il file di controllo
			gzip -dc $DIR_FILE_DA_CARICARE/$f.gz > $DIR_FILE_DA_CARICARE/$NOME_FILE
			mysqlimport -u $USERNAME -p$PASSWORD --delete --local $DB $DIR_FILE_DA_CARICARE/$NOME_FILE > /dev/null 2>&1
			rm -f $DIR_FILE_DA_CARICARE/$NOME_FILE
			mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
			rm -f $DIR_FILE_DA_CARICARE/$f
	
			#ora, se ne esistono, rimuovo i file più vecchi senza caricarli (non tocco i file a cui manca
			#il file di controllo)
			for f in $(cd $DIR_FILE_DA_CARICARE;ls -1 "$SOCIETA"_FAR* 2>/dev/null | grep -vE "\."); do
				mv $DIR_FILE_DA_CARICARE/$f.gz $DIR_FILE_CARICATI/$f.gz
				rm -f $DIR_FILE_DA_CARICARE/$f
			done
		fi
		
		mysql -u $USERNAME -p$PASSWORD -h $IP -ss -e "DROP TABLE IF EXISTS $DB.temp_stock"
	done
	
	rm -f /CARICAMENTO_NF_IN_CORSO
fi
