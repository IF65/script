#!/perl/bin/perl
use strict;     # pragma che dice all'interprete di essere rigido nel controllo della sintassi
use warnings;   # pragma che dice all'interprete di mostrare eventuali warnings
use DBI;        # permette di comunicare con il database
use DateTime;
use Net::FTP;

my $current_date 	= DateTime->today(time_zone=>'local');
my $starting_date = '20160101';
if ($current_date->add(months => -1 )->ymd('') =~ /^(\d{6})\d{2}$/) {$starting_date = $1.'01'}
		
my $ftp_url 		= '10.11.14.111';
my $ftp_utente 		= "filiale";
my $ftp_password 	= "filiale";

my $cartella_locale 		= "/timbrature";
my $cartella_remota 		= "/timbrature";
my $file_name_timbrature	= "timbrature.txt";
my $file_handler;

# Creazione della cartella locale
#---------------------------------------------------------------------------------------------
unless(-e $cartella_locale or mkdir $cartella_locale) {die "Impossibile creare la cartella $cartella_locale: $!\n";};

# Apertura connessione con il database Oracle
#---------------------------------------------------------------------------------------------
# my $dbh = DBI->connect('dbi:Oracle:',q{ESTAR/estar@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST= 10.11.14.82)(PORT=1521))
# 										(CONNECT_DATA=(SID=ESTR)))},"") or die;
										
my $dbh = DBI->connect('dbi:Oracle:host=10.11.14.82;sid=ESTR;port=1521', 'ESTAR/estar', '') or die "Errore: $_\n";



# Preparazione della query "timbrature"
#---------------------------------------------------------------------------------------------
my $sth_timbrature = $dbh->prepare(qq{	select '01'||lpad(TIMB_BADGE,15, '0')||to_char(TIMB_DATE, 'DD/MM/YY')||to_char(TIMB_DATE, 'HH24:MI')||
										case when TIMB_VERSO = 'E' then 'I' else 'U' end||lpad(TO_CHAR(TERM_ID),5,'0')||substr(nvl(TIMB_INFO,'0000'),2)||TIMB_TYPE 
										from TIMB 
										where TIMB_DATE >= to_timestamp('2016-01-01', 'YYYY-MM-DD') and TIMB_TYPE = 'P' and TIMB_BADGE <>'00000000'
									});

# Esecuzione del query e scrittura dati sul file di interscambio 
#---------------------------------------------------------------------------------------------

if ($sth_timbrature->execute($starting_date)) {
	open $file_handler, "+>:crlf", "$cartella_locale/$file_name_timbrature";
	while ( my @row = $sth_timbrature->fetchrow_array() ) {
		print $file_handler "$row[0]\n";
	}
	close($file_handler);
}
	
# 
# # Carico la lista dei file presenti nella cartella di invio
# #---------------------------------------------------------------------------------------------
# opendir my($DIR), "$cartella_locale" or die "Non è stato possibile aprire la directory $cartella_locale: $!\n";
# my @elenco_files = grep { /\.txt$/ } readdir $DIR;
# closedir $DIR;
# 
# # Apro la connessione FTP
# #---------------------------------------------------------------------------------------------
# my $ftp = Net::FTP->new($ftp_url) or die "Mancata connessione al sito $ftp_url: $!\n";
# $ftp->login("$ftp_utente","$ftp_password") or die "Login al sito $ftp_url fallito per l'utente $ftp_utente: $!\n";
# $ftp->binary();
# 
# # Invio i file via FTP
# #---------------------------------------------------------------------------------------------
# my $file_ctl;
# 	
# $ftp->mkdir($cartella_remota);
# $ftp->cwd("$cartella_remota");
# foreach my $file (@elenco_files) {
# 	$file_ctl = $file;
# 	$file_ctl =~ s/\.txt$/\.ctl/ig;
# 	open my $log_handler, "+>:crlf", "$cartella_locale/$file_ctl" or die $!;
# 	close ($log_handler);
# 		
# 	$ftp->delete("$cartella_locale/$file_ctl");
# 	$ftp->delete("$cartella_locale/$file");
# 	if ($ftp->put("$cartella_locale/$file_ctl")) {
# 		if ($ftp->put("$cartella_locale/$file")) {
# 			unlink("$cartella_locale/$file_ctl");
# 			unlink("$cartella_locale/$file");
# 			$ftp->delete("$cartella_locale/$file_ctl");
# 		}
# 	}
# }
# 
# # Chiudo la connessione FTP
# #---------------------------------------------------------------------------------------------
# $ftp->quit();

END {
	
	#$dbh->disconnect if defined($dbh);
	print "collegamento terminato!\n";
}
