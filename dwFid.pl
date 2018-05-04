#!/perl/bin/perl
use strict;     # pragma che dice all'interprete di essere rigido nel controllo della sintassi
use warnings;   # pragma che dice all'interprete di mostrare eventuali warnings
use DBI;        # permette di comunicare con il database
use DateTime;
use Net::FTP;

my $cartella_locale 		= "/datiDwFid";
my $file_name	= "dati.txt";
my $file_handler;

# Creazione della cartella locale
#---------------------------------------------------------------------------------------------
unless(-e $cartella_locale or mkdir $cartella_locale) {die "Impossibile creare la cartella $cartella_locale: $!\n";};

# Apertura connessione con il database Oracle
#---------------------------------------------------------------------------------------------
# my $dbh = DBI->connect('dbi:Oracle:',q{ESTAR/estar@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST= 10.11.14.82)(PORT=1521))
# 										(CONNECT_DATA=(SID=DW)))},"") or die;

my $dbh = DBI->connect('dbi:Oracle:host=10.11.14.110;sid=DW;port=1521', 'REP_IT', 'Inilodo') or die "Errore: $_\n";


# Preparazione della query "timbrature"
#---------------------------------------------------------------------------------------------
my $sql = "SELECT SALELIST_ID,
							  st.STORE_CODE,
							  st.Store_name,
							  to_char(to_date(CALENDAR_ID,'J'),'YYYY-MM-DD') AS data_vendita,
							  SALE_ID,
							  CARD_ID,
							  SL.PRODUCT_ID,
							  PR.PRODUCT_CODE,
							  nvl(SALE_WEIGHT,0),
							  nvl(SALE_ITEMS,0),
							  nvl(SALE_LIST_AMOUNT,0),
							  nvl(SALE_LIST_VAT,0),
							  nvl(SALE_LIST_NET_VAT_AMOUNT,0),
							  nvl(SALE_LIST_GENERIC_DISCOUNT,0),
							  nvl(SALE_LIST_PROD_DISCOUNT,0),
							  nvl(SALE_LIST_DEPT_DISCOUNT,0),
							  nvl(SALE_LIST_TICKET_DISCOUNT,0),
							  nvl(SALE_LIST_EARNED_POINTS,0),
							  nvl(SALE_LIST_REDEEMED_POINTS,0),
							  nvl(SALE_LIST_CASHBACK_DISCOUNT,0),
							  nvl(SALE_LIST_NOT_PAID_AMOUNT,0)
							FROM DW_FID.F_SALES_LIST SL
							left join  DW_FID.D_STORES ST on SL.Store_ID = ST.STORE_ID
							left join DW_FID.D_PRODUCTS PR on SL.PRODUCT_ID = PR.PRODUCT_ID
							WHERE to_char(to_date(CALENDAR_ID,'J'),'YYYY-MM-DD') BETWEEN '2017-04-01' AND '2018-03-31'
							and  (ST.STore_code like '01%' or ST.STore_code like '31%' or ST.STore_code like '36%' or ST.STore_code like '04%')";

my $sth = $dbh->prepare($sql);

# Esecuzione del query e scrittura dati sul file di interscambio
#---------------------------------------------------------------------------------------------

if ($sth->execute()) {
	open $file_handler, "+>:crlf", "$cartella_locale/$file_name";
	while ( my @row = $sth->fetchrow_array() ) {
		print $file_handler $row[0].";";
		print $file_handler $row[1].";";
		print $file_handler $row[2].";";
		print $file_handler $row[3].";";
		print $file_handler $row[4].";";
		print $file_handler $row[5].";";
		print $file_handler $row[6].";";
		print $file_handler $row[7].";";
		print $file_handler $row[8].";";
		print $file_handler $row[9].";";
		print $file_handler $row[10].";";
		print $file_handler $row[11].";";
		print $file_handler $row[12].";";
		print $file_handler $row[13].";";
		print $file_handler $row[14].";";
		print $file_handler $row[15].";";
		print $file_handler $row[16].";";
		print $file_handler $row[17].";";
		print $file_handler $row[18].";";
		print $file_handler $row[19].";";
		print $file_handler $row[20]."\n";
	}
	close($file_handler);
}

END {

	#$dbh->disconnect if defined($dbh);
	print "collegamento terminato!\n";
}
