#!/usr/bin/perl
use strict;
use warnings;
use File::HomeDir;
use File::Basename;
use Net::FTP;
use File::Listing qw(parse_dir);
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

my $scrivania  = File::HomeDir->my_desktop;

my $cartella_remota_destinazione	= "/ddt_da_caricare";
my $cartella_remota_backup			= "/ddt_backup";
my $cartella_locale 				= "/temp_copre";

my $ftp_url = '11.0.1.231';
my $ftp_utente = "copre";
my $ftp_password = "ftp-copre";

my @elenco_files;

# Creazione cartelle locali (se non esistono)
#-------------------------------------------------------------------------------------------
my $directory = "$cartella_locale";
unless(-e $directory or mkdir $directory) {die "Impossibile creare la cartella $directory: $!\n";};

# elimino eventuali file presenti nella cartella locale
#-------------------------------------------------------------------------------------------
opendir my $DIR, "$cartella_locale" or die "Non è stato possibile aprire la cartella "."$cartella_locale".": $!\n";
@elenco_files = grep { !/^\./ } readdir $DIR;
closedir $DIR;
foreach my $file (@elenco_files) {
	unlink "$cartella_locale/$file"
}

# Creazione cartelle remote (se non esistono)
#-------------------------------------------------------------------------------------------
my $ftp = Net::FTP->new($ftp_url) or die "Mancata connessione al sito $ftp_url: $!\n";
$ftp->login("$ftp_utente","$ftp_password") or 
	die "Login al sito $ftp_url fallito per l'utente $ftp_utente: $!\n";
$ftp->binary();

if ( @{$ftp->dir("$cartella_remota_destinazione")} == 0 ) {$ftp->mkdir("$cartella_remota_destinazione");};
if ( @{$ftp->dir("$cartella_remota_backup")} == 0 ) {$ftp->mkdir("$cartella_remota_backup");};


# Carico la lista dei file presenti nella cartella di ricezione e li prelevo
#-------------------------------------------------------------------------------------------
@elenco_files = grep { /^BOLL_.*$/ } grep { !/^\./ } $ftp->ls("/");
$ftp->cwd("/");
foreach my $file (@elenco_files) {
	$ftp->get($file, "$cartella_locale/$file") or die "OPERAZIONE:get fallito ", $ftp->message;
	$ftp->delete($file);
}


opendir $DIR, "$cartella_locale" or die "Non è stato possibile aprire la cartella "."$cartella_locale".": $!\n";
@elenco_files = grep { /^BOLL_.*$/ } readdir $DIR;
closedir $DIR;

foreach my $file (@elenco_files) {
	my $bkp_file = $file;
	$bkp_file =~ s/^BOLL/BKP/ig;
	rename("$cartella_locale/$file","$cartella_locale/$bkp_file") or die "Copia fallita: $!";
	if (open my $input_file_handler, "<", "$cartella_locale/$bkp_file") {
		if (open my $output_file_handler, "+>", "$cartella_locale/$file") {
			my $line;
			while(! eof ($input_file_handler))  {
				$line = <$input_file_handler>;
				$line =~ s/\n$//ig;
				$line =~ s/[^\s!-~]/ /ig;
				print $output_file_handler "$line\n";
			}
			close($output_file_handler);
		}
		close($input_file_handler);
	}
}

# sposto i file di backp
#-------------------------------------------------------------------------------------------
opendir $DIR, "$cartella_locale" or die "Non è stato possibile aprire la cartella "."$cartella_locale".": $!\n";
@elenco_files = grep { /^BKP_.*$/ } grep { !/^\./ } readdir $DIR;
closedir $DIR;
$ftp->cwd($cartella_remota_backup);
foreach my $file (@elenco_files) {
	$ftp->put("$cartella_locale/$file") or die "OPERAZIONE:put x bkp fallito ", $ftp->message;
	unlink "$cartella_locale/$file"
}

# sposto i file ddt
#-------------------------------------------------------------------------------------------
opendir $DIR, "$cartella_locale" or die "Non è stato possibile aprire la cartella "."$cartella_locale".": $!\n";
@elenco_files = grep { /^BOLL_.*$/ } grep { !/^\./ } readdir $DIR;
closedir $DIR;
$ftp->cwd($cartella_remota_destinazione);
foreach my $file (@elenco_files) {
	$ftp->put("$cartella_locale/$file") or die "OPERAZIONE:put x ddt fallito ", $ftp->message;
	unlink "$cartella_locale/$file"
}


$ftp->quit(); 


exit 0;
