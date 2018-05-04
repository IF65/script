#!/perl/bin/perl
use strict;     # pragma che dice all'interprete di essere rigido nel controllo della sintassi
use warnings;   # pragma che dice all'interprete di mostrare eventuali warnings
use DBI;        # permette di comunicare con il database
#use DBD::Oracle;
use DateTime;
use Net::FTP;

my $current_date 	= DateTime->today(time_zone=>'local');
my $starting_date = '20160101';
if ($current_date->add(months => -1 )->ymd('') =~ /^(\d{6})\d{2}$/) {$starting_date = $1.'01'}
$starting_date = '20161001';
		
my $ftp_url 		= 'repo.eprice.it';
my $ftp_utente 		= "00IF65";
my $ftp_password 	= "sQL55I5Qr";

my $cartella_locale 		= "/byte";
my $cartella_remota 		= "/byte";
my $file_name_timbrature	= "timbrature.txt";
my $file_name_venditori		= "venditori.txt";
my $file_name_contratti		= "contratti.txt";
my $file_handler;

# Creazione della cartella locale
#---------------------------------------------------------------------------------------------
unless(-e $cartella_locale or mkdir $cartella_locale) {die "Impossibile creare la cartella $cartella_locale: $!\n";};





# Creazione del file per lo scambio dati "timbrature"
#---------------------------------------------------------------------------------------------
open $file_handler, "+>:crlf", "$cartella_locale/$file_name_timbrature";


# Chiusura del file per lo scambio dati "timbrature"
#---------------------------------------------------------------------------------------------
close($file_handler);	


# Creazione del file per lo scambio dati "venditori"
#---------------------------------------------------------------------------------------------
open $file_handler, "+>:crlf", "$cartella_locale/$file_name_venditori";


# Chiusura del file per lo scambio dati "venditori"
#---------------------------------------------------------------------------------------------
close($file_handler);	




# Creazione del file per lo scambio dati "contratti"
#---------------------------------------------------------------------------------------------
open $file_handler, "+>:crlf", "$cartella_locale/$file_name_contratti";

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
$ftp->passive(0);
$ftp->login("$ftp_utente","$ftp_password") or die "Login al sito $ftp_url fallito per l'utente $ftp_utente: $!,".$ftp->message."\n";
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
