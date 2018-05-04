#!/usr/bin/perl
use strict;
use warnings;
use File::HomeDir;
use File::Basename;
use Net::FTP;
use File::Listing qw(parse_dir);
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

my $societa = 'SM';

my $scrivania  = File::HomeDir->my_desktop;
my $cartella_remota = "/$societa";
my $cartella_locale = "$scrivania/$societa";

my @negozi=('SM1','SM2','SM3','SM4','SM5','SM6','SM7','SM9','SM10',
	    'SM13','SM14','SM15','SM16','SM17','SM18','SM19',
	    'SM21','SM22','SM25','SM26','SM27','SM28',
	    'SM32','SM33','SM34','SM35','SM36','SM37','SM38','SM39','SM41','SMW1',
	    'SMM2','SMM3','SMC1','SMMD');
			
my $ftp_url = '10.11.14.111';
my $ftp_utente = "filiale";
my $ftp_password = "filiale";


# Creazione cartelle locali (se non esistono)
#-------------------------------------------------------------------------------------------
my $directory = "$cartella_locale";
unless(-e $directory or mkdir $directory) {die "Impossibile creare la cartella $directory: $!\n";};
$directory = "$cartella_locale/IN";
unless(-e $directory or mkdir $directory) {die "Impossibile creare la cartella $directory: $!\n";};
$directory = "$cartella_locale/OUT";
unless(-e $directory or mkdir $directory) {die "Impossibile creare la cartella $directory: $!\n";};
$directory = "$cartella_locale/STR";
unless(-e $directory or mkdir $directory) {die "Impossibile creare la cartella $directory: $!\n";};

my @elenco_files;

# Carico la lista dei file presenti nella cartella di invio e li compatto
#-------------------------------------------------------------------------------------------
opendir my($DIR), "$cartella_locale/OUT" or 
	die "Non è stato possibile aprire la directory $directory: $!\n";
@elenco_files = grep { !/\.zip$/ } grep { !/^\./ } readdir $DIR;
closedir $DIR;

foreach my $file (@elenco_files) {
	my ($name,$path,$suffix) = fileparse("$cartella_locale/OUT/$file",qr/\.[^.]*/);
	my $zip = Archive::Zip->new();
	my $file_member = $zip->addFile( "$cartella_locale/OUT/$file", "$file" );
	unless ( $zip->writeToFileNamed("$path/$name.zip") == AZ_OK ) {die 'write error';};
	unlink "$cartella_locale/OUT/$file";
};

# Creazione cartelle remote (se non esistono)
#-------------------------------------------------------------------------------------------
my $ftp = Net::FTP->new($ftp_url) or die "Mancata connessione al sito $ftp_url: $!\n";
$ftp->login("$ftp_utente","$ftp_password") or 
	die "Login al sito $ftp_url fallito per l'utente $ftp_utente: $!\n";
$ftp->binary();

if ( @{$ftp->dir("$cartella_remota")} == 0 ) {$ftp->mkdir("$cartella_remota");};
foreach my $directory (@negozi) {
	if ( @{$ftp->dir("$cartella_remota/$directory")} == 0 ) {$ftp->mkdir("$cartella_remota/$directory");};
	if ( @{$ftp->dir("$cartella_remota/$directory/IN")} == 0 ) {$ftp->mkdir("$cartella_remota/$directory/IN");};
	if ( @{$ftp->dir("$cartella_remota/$directory/OUT")} == 0 ) {$ftp->mkdir("$cartella_remota/$directory/OUT");};
	if ( @{$ftp->dir("$cartella_remota/$directory/STR")} == 0 ) {$ftp->mkdir("$cartella_remota/$directory/STR");};
}

# Carico la lista dei file compattati presenti nella cartella di invio e li spedisco
#-------------------------------------------------------------------------------------------
opendir $DIR, "$cartella_locale/OUT" or 
	die "Non è stato possibile aprire la directory $directory: $!\n";
@elenco_files = grep { /\.zip$/ } grep { !/^\./ } readdir $DIR;
closedir $DIR;

foreach my $file (@elenco_files) {
	foreach my $directory (@negozi) {
		$ftp->cwd("$cartella_remota/$directory/IN");
		$ftp->put("$cartella_locale/OUT/$file");
	}
	unlink "$cartella_locale/OUT/$file";
}

# Carico la lista dei file compattati presenti nelle cartelle di ricezione e li prelevo
#-------------------------------------------------------------------------------------------
foreach my $negozio (@negozi) {
	@elenco_files = grep { /\.zip$/ } grep { !/^\./ } $ftp->ls("$cartella_remota/$negozio/OUT");
	$ftp->cwd("$cartella_remota/$negozio/OUT");
	foreach my $file (@elenco_files) {
		$ftp->get($file, "$cartella_locale/IN/$file\_$negozio");
		$ftp->delete($file);
		my $zip = Archive::Zip->new("$cartella_locale/IN/$file\_$negozio");
		my @members = $zip->memberNames();
		foreach (@members) {$zip->extractMember("$_", "$cartella_locale/IN/$_\_$negozio");}
		unlink "$cartella_locale/IN/$file\_$negozio";
	}
}

$ftp->quit(); 



exit 0;