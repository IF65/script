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

# se il file esiste e ha dimensione maggior di zero lo invio
FILE_EPRICE="$DIR/EPRICE_Catalogo.txt"
FILE_FTP=Catalogo_Supermedia.txt
if [ -s "$FILE_EPRICE" ]; then
   	ftp -in repo.eprice.it <<SCRIPT
   		user 00IF65 sQL55I5Q
		binary
		put $FILE_EPRICE $FILE_FTP
		bye
SCRIPT
fi

# se il file esiste e ha dimensione maggior di zero lo invio
FILE_ONLINESTORE="$DIR/ONLINESTORE_Catalogo.txt"
FILE_FTP=Catalogo_Supermedia.txt
if [ -s "$FILE_ONLINESTORE" ]; then
   	ftp -in w00fcc4c.kasserver.com 1>/dev/null <<SCRIPT
		user f00dac8b kJ2e8hdguxBLzAz6
		binary
		put $FILE_ONLINESTORE $FILE_FTP
		bye
SCRIPT
fi

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

# se il file esiste e ha dimensione maggior di zero lo invio
FILE_YEPPON="$DIR/YEPPON_Catalogo.txt"
FILE_FTP=Catalogo_Supermedia.txt
if [ -s "$FILE_YEPPON" ]; then
   	ftp -in admin.yeppon.it 1>/dev/null <<SCRIPT
		user supermedia JHIeFkwZ7y
		binary
		put $FILE_YEPPON $FILE_FTP
		bye
SCRIPT
fi

FILE_Supermedia="$DIR/Supermedia_Catalogo.txt"

ADDRESS="alberto.lovison@supermedia.it, stefano.facchini@supermedia.it, massimo.dambrogio@supermedia.it, paolo.odolini@supermedia.it, marco.gnecchi@supermedia.it"
BODY="<html><body>\n<b>INVIO GIORNALIERO CATALOGO B2B<BR>$DATA</b><BR><BR>\n"
SUBJECT="CATALOGO B2B"

/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_EPRICE $FILE_ONLINESTORE $FILE_YEPPON $FILE_Supermedia $FILE_TEKWORLD $FILE_EXCEL
