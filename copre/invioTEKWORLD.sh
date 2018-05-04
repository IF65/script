#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

DATA=$(date +%Y-%m-%d)

DIR=/catalogoB2B
DIR_BKP=$DIR/bkp

#creo le cartelle
mkdir -p $DIR_BKP

#mi posiziono nella cartella principale
cd $DIR

#la ripulisco di eventuali file vecchi
rm -f *.txt 1>/dev/null 2>/dev/null

#nome file excel
FILE_EXCEL="$DIR/Catalogo.xlsx"

#aggiorno il tabulato e creo i nuovi file
#perl /script/copre/copreAggiornamentoTabulato.pl
perl /script/copre/esportazioneTxt.pl
perl /script/copre/esportazioneExcel.pl

# bisogna usare gli escape x i caratteri speciali
UTENTE="ftp_tekworldforn\|tekworldforn"
PASSWORD="FKr43\$87fdSsD"
FILE_TEKWORLD="$DIR/TEKWORLD_Catalogo.txt"
FILE_FTP=Catalogo_Supermedia.txt
if [ -s "$FILE_TEKWORLD" ]; then
   	ftp -in ftp.tekworld.it 1>/dev/null <<SCRIPT
		user $UTENTE $PASSWORD
		cd Super
		binary
		put $FILE_TEKWORLD $FILE_FTP
		bye
SCRIPT
fi
