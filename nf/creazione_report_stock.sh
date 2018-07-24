#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5


ADDRESS="laura_ferrari@acer-euro.com, pasquale.marzullo@acer.com, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="ACER"
FILE_NAME=$(perl /script/nf/report_stock_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="marcopolo@tradeprogramme.it, vincenzo.stani@hisense.com, info@tradeprogramme.it, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="HISENSE"
FILE_NAME=$(perl /script/nf/report_stock_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="pierantonio.loda@agenzialoda.it, r.boniardi@brondi.it, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="BRONDI"
FILE_NAME=$(perl /script/nf/report_stock_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="mabraga@tin.it, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="CANON"
FILE_NAME=$(perl /script/nf/report_stock_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="marcogelain@gmail.com, cristian.calderaro@nilox.com, claudio.grieco@nilox.com, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="NILOX"
FILE_NAME=$(perl /script/nf/report_stock_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="michela.venuti@dlink.com, marco.faraco@dlink.com, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="D-LINK_ACC"
FILE_NAME=$(perl /script/nf/report_stock_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="marzia.dallarosa@presidium.it, paolo.topuz@hp.com, walter.bonelli@hp.com, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="HEWLETT_PACKARD"
FILE_NAME=$(perl /script/nf/report_stock_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="mrinaldi@kobo.com, adrian.kania@rakuten.com, kobo-SCM-MA@mail.rakuten.com, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="KOBO"
FILE_NAME=$(perl /script/nf/report_stock_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="ffidelio@logitech.com, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="LOGITECH"
FILE_NAME=$(perl /script/nf/report_stock_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="report.it@sitecom.com, l.sanchini@sitecom.com, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="SITECOM_FRESH"
FILE_NAME=$(perl /script/nf/report_stock_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="cristian.goisis@telecomitalia.it, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="TIM"
FILE_NAME=$(perl /script/nf/report_stock_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="mariarosa.bulgarelli@mail.wind.it, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="WIND"
FILE_NAME=$(perl /script/nf/report_stock_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="francesco.ausania@microsoft.com, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="MICROSOFT"
FILE_NAME=$(perl /script/nf/report_stock_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME


#------------------------------------------------------------------------------------------------------------------------
ADDRESS="giovanni.bertella@kaspersky.it, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="KASPERSKY"
FILE_NAME=$(perl /script/nf/report_stock_e_vendite_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="canondata@purpleo-europe.com, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="CANON_COMPUTER"
FILE_NAME=$(perl /script/nf/report_stock_e_vendite_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="sara.velati@datamatic.it, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="DATAMATIC"
FILE_NAME=$(perl /script/nf/report_stock_e_vendite_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="paolo_bassanese@epson.it, giovanni_parisi@epson.it, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="EPSON"
FILE_NAME=$(perl /script/nf/report_stock_e_vendite_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="svcdocsin@esprinet.com, enrico.salani@celly.com, info@agenzialoda.it, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="CELLY"
FILE_NAME=$(perl /script/nf/report_stock_e_vendite_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="claudio.cambareri@huawei.com, g.barresi@aldinet.it, gmiraglia@hw-service.it, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="HUAWEI"
FILE_NAME=$(perl /script/nf/report_stock_e_vendite_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="marco.pompei@sbsmobile.it, simone.melchiori@sbsmobile.com, Mattia.MarchesaGrandi@sbsmobile.it, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="SBS"
FILE_NAME=$(perl /script/nf/report_stock_e_vendite_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="andrea.vellucci@sony.com, maurizioconte@lfmgroup.it, sceit_data@scee.net, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="SONY_GAME"
FILE_NAME=$(perl /script/nf/report_stock_e_vendite_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="jsama@wikomobile.com, gbellezze@wikomobile.com, chiara.spinelli@ingrammicro.com, ccolafrancesco@wikomobile.com, imari@wikomobile.com, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="WIKO"
FILE_NAME=$(perl /script/nf/report_stock_e_vendite_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="a.ardrizzi@reporteritalia.it, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="REPORTER"
FILE_NAME=$(perl /script/nf/report_stock_e_vendite_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="report@avm.de, r.mueller@avm.de, d.rosella@avm.de, sergio.guidi@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="FRITZ"
FILE_NAME=$(perl /script/nf/report_stock_e_vendite_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
fi
rm -f $FILE_NAME

ADDRESS="daniele.fedrigo@supermedia.it, stefano.facchini@supermedia.it, marco.gnecchi@if65.it"
SELETTORE="SAMSUNG"
FTP_IP="ftp3.samsung.it"
FTP_USERNAME="copre"
FTP_PASSWORD="Htr&ju65"
FILE_NAME=$(perl /script/nf/report_stock_txt_sm.pl -s $SELETTORE)
if [ -s $FILE_NAME ]  
then  
 	BODY="<html><body>\n<b>REPORT STOCK $SELETTORE<BR>\n"
 	SUBJECT="Report Stock $SELETTORE"
 	
 	cd /
 	/sendEmail-v1.56/sendEmail -o tls=no -u $SUBJECT -m $BODY -f edp@if65.it -t $ADDRESS -s 10.11.14.234:25 -a $FILE_NAME
 	
 		ftp -in $FTP_IP 1>/dev/null <<SCRIPT
		user $FTP_USERNAME $FTP_PASSWORD
		binary
		put $FILE_NAME
		bye
SCRIPT

fi
rm -f $FILE_NAME
