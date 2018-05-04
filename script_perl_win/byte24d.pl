#!/perl/bin/perl
use strict;     # pragma che dice all'interprete di essere rigido nel controllo della sintassi
use warnings;   # pragma che dice all'interprete di mostrare eventuali warnings
use DBI;        # permette di comunicare con il database
#use DBD::Oracle;
use DateTime;
use Net::FTP;

my $current_date 	= DateTime->today(time_zone=>'Europe/Rome');
my $starting_date = '20140101';
if ($current_date->add(months => -1 )->ymd('') =~ /^(\d{6})\d{2}$/) {$starting_date = $1.'01'}
$starting_date = '20141001';
		
my $ftp_url 		= '10.11.14.111';
my $ftp_utente 		= "filiale";
my $ftp_password 	= "filiale";

my $cartella_locale 		= "/byte";
my $cartella_remota 		= "/byte";
my $file_name_timbrature	= "timbrature.txt";
my $file_name_venditori		= "venditori.txt";
my $file_name_contratti		= "contratti.txt";
my $file_handler;

# Creazione della cartella locale
#---------------------------------------------------------------------------------------------
unless(-e $cartella_locale or mkdir $cartella_locale) {die "Impossibile creare la cartella $cartella_locale: $!\n";};

# Apertura connessione con il database Oracle
#---------------------------------------------------------------------------------------------
my $dbh = DBI->connect('dbi:Oracle:',q{visora/visora@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST= 10.11.14.81)(PORT=1521))
										(CONNECT_DATA=(SERVICE_NAME=sipe.italmark.lcl)))},"") or die;





# Creazione del file per lo scambio dati "timbrature"
#---------------------------------------------------------------------------------------------
open $file_handler, "+>:crlf", "$cartella_locale/$file_name_timbrature";

# Preparazione della query "timbrature"
#---------------------------------------------------------------------------------------------
my $sth_timbrature = $dbh->prepare(qq{SELECT CDAZIEND, CDDIPEND, CAST(CLTIMBRA AS VARCHAR(8)), CAST(MTTIMBRA AS VARCHAR(4)), CDVERSOT, CDLIDUSR, FLMANUAL
										FROM RPTIMI
										WHERE ((CDAZIEND = '00') OR(CDAZIEND = '01') OR (CDAZIEND = '08') OR (CDAZIEND = '07') OR (CDAZIEND = '53') OR (CDAZIEND = '19') OR (CDAZIEND = '10')) AND CLTIMBRA >= ?
										ORDER BY CLTIMBRA ASC});

# Esecuzione del query e scrittura dati sul file di interscambio 
#---------------------------------------------------------------------------------------------
if ($sth_timbrature->execute($starting_date)) {
	while ( my @row = $sth_timbrature->fetchrow_array() ) {
		print $file_handler "$row[0]\t";
		print $file_handler "$row[1]\t";
		print $file_handler "$row[2]\t";
		print $file_handler "$row[3]\t";
		print $file_handler "$row[4]\t";
		print $file_handler "$row[5]\t";
		print $file_handler "$row[6]\n";
	}
}

# Chiusura del file per lo scambio dati "timbrature"
#---------------------------------------------------------------------------------------------
close($file_handler);	





# Creazione del file per lo scambio dati "venditori"
#---------------------------------------------------------------------------------------------
open $file_handler, "+>:crlf", "$cartella_locale/$file_name_venditori";

# Preparazione della query "venditori"
#---------------------------------------------------------------------------------------------
my $sth_venditori = $dbh->prepare(qq{SELECT peangi.cddipend,
            peangi.ancognom,
            peangi.annomexx,
            CAST(peangi.cldatana AS VARCHAR(8)),
            peangi.cdaziend,
            peangi.cddicefi,
            peangi.cdcomuna,
            peangi.ancomuna,
            peangi.cdprovna,
            peangi.cdnazina,
            peangi.ancittad,
            peangi.ansessox,
            peangi.antitstu,
            peandi.cdcontri, 
            peandi.cdqualif,
            CAST(peandi.clqualda AS VARCHAR(8)),
            peandi.cdlivell,
            CAST(peandi.clliveda AS VARCHAR(8)),
            CAST(peandi.cldatass AS VARCHAR(8)),
            CAST(peandi.cldatces AS VARCHAR(8)),
            peandi.cdpartim, 
            peanoi.cdsedexx,
            peanoi.cdccosto,
            CAST(peanoi.cldecsed AS VARCHAR(8)),
            peanoi.cd1lvstr,
            CAST(peandi.clcontda AS VARCHAR(8)),
            CAST(peanai.fineprov AS VARCHAR(8)),
            peandi.cdposlav,
            CAST(peandi.clpolada AS VARCHAR(8)),
            CAST(peandi.clpolasc AS VARCHAR(8))
			FROM ((peangi inner join peandi on peangi.cddipend=peandi.cddipend) inner join peanoi on peangi.cddipend=peanoi.cddipend) inner join peanai on peangi.cddipend=peanai.cddipend
			WHERE (peangi.cdaziend = '08') OR (peangi.cdaziend = '07') OR (peangi.cdaziend = '53') OR (peangi.cdaziend = '19') OR (peangi.cdaziend = '10')
			ORDER BY peangi.cddipend ASC});
     
# Esecuzione della query "venditori" e scrittura dei dati sul file di interscambio 
#---------------------------------------------------------------------------------------------
if ($sth_venditori->execute()) {
	while ( my @row = $sth_venditori->fetchrow_array() ) {
		print $file_handler "$row[0]\t";
		print $file_handler "$row[1]\t";
		print $file_handler "$row[2]\t";
		print $file_handler "$row[3]\t";
		print $file_handler "$row[4]\t";
		print $file_handler "$row[5]\t";
		print $file_handler "$row[6]\t";
		print $file_handler "$row[7]\t";
		print $file_handler "$row[8]\t";
		print $file_handler "$row[9]\t";
		print $file_handler "$row[10]\t";
		print $file_handler "$row[11]\t";
		print $file_handler "$row[12]\t";
		print $file_handler "$row[13]\t";
		print $file_handler "$row[14]\t";
		print $file_handler "$row[15]\t";
		print $file_handler "$row[16]\t";
		print $file_handler "$row[17]\t";
		print $file_handler "$row[18]\t";
		print $file_handler "$row[19]\t";
		print $file_handler "$row[20]\t";
		print $file_handler "$row[21]\t";
		print $file_handler "$row[22]\t";
		print $file_handler "$row[23]\t";
		print $file_handler "$row[24]\t";
		print $file_handler "$row[25]\t";
		print $file_handler "$row[26]\t";
		print $file_handler "$row[27]\t";
		print $file_handler "$row[28]\t";
		print $file_handler "$row[29]\n";
	}
}

# Chiusura del file per lo scambio dati "venditori"
#---------------------------------------------------------------------------------------------
close($file_handler);	




# Creazione del file per lo scambio dati "contratti"
#---------------------------------------------------------------------------------------------
open $file_handler, "+>:crlf", "$cartella_locale/$file_name_contratti";

# Preparazione della query "contratti"
#---------------------------------------------------------------------------------------------
my $sth_contratti = $dbh->prepare(qq{SELECT RTRIM(cdkeyute), RTRIM(SUBSTR(andatixx, 4, 12))
									FROM sigetat
									WHERE cdapplic='PE' AND cdcodtab='364'});

# Esecuzione del query e scrittura dati sul file di interscambio 
#---------------------------------------------------------------------------------------------
if ($sth_contratti->execute()) {
	while ( my @row = $sth_contratti->fetchrow_array() ) {
		print $file_handler "$row[0]\t";
		print $file_handler "$row[1]\n";
	}
}

# Chiusura del file per lo scambio dati "contratti"
#---------------------------------------------------------------------------------------------
close($file_handler);



# Carico la lista dei file presenti nella cartella di invio
#---------------------------------------------------------------------------------------------
opendir my($DIR), "$cartella_locale" or die "Non è stato possibile aprire la directory $cartella_locale: $!\n";
my @elenco_files = grep { /\.txt$/ } readdir $DIR;
closedir $DIR;

# Apro la connessione FTP
#---------------------------------------------------------------------------------------------
my $ftp = Net::FTP->new($ftp_url) or die "Mancata connessione al sito $ftp_url: $!\n";
$ftp->login("$ftp_utente","$ftp_password") or die "Login al sito $ftp_url fallito per l'utente $ftp_utente: $!\n";
$ftp->binary();

# Invio i file via FTP
#---------------------------------------------------------------------------------------------
my $file_ctl;
	
$ftp->mkdir($cartella_remota);
$ftp->cwd("$cartella_remota");
foreach my $file (@elenco_files) {
	$file_ctl = $file;
	$file_ctl =~ s/\.txt$/\.ctl/ig;
	open my $log_handler, "+>:crlf", "$cartella_locale/$file_ctl" or die $!;
	close ($log_handler);
		
	$ftp->delete("$cartella_locale/$file_ctl");
	$ftp->delete("$cartella_locale/$file");
	if ($ftp->put("$cartella_locale/$file_ctl")) {
		if ($ftp->put("$cartella_locale/$file")) {
			unlink("$cartella_locale/$file_ctl");
			unlink("$cartella_locale/$file");
			$ftp->delete("$cartella_locale/$file_ctl");
		}
	}
}

# Chiudo la connessione FTP
#---------------------------------------------------------------------------------------------
$ftp->quit();

END {
	
	#$dbh->disconnect if defined($dbh);
	print "collegamento terminato!\n";
}
