#!/usr/bin/perl
use strict;
use warnings;
use Net::FTP;
use File::HomeDir;
  
my $desktop  = File::HomeDir->my_desktop;
  
my $in = "IN";
my $out = "OUT";
my @user=(
          "affbc_0122",
          "affbc_0131",
          "affbc_0135"
         );
my %password=(
			  "affbc_0122"=>"s9eYeway",
			  "affbc_0131"=>"9uxeRede",
			  "affbc_0135"=>"wAk2m2ST"
			 );
my @folder=(
            "articoli",
            "rifornito",
            "ordini",
            "listiniPV",
            "listiniPA",
            "facing",
            "corime",
            "fornitoriRel",
            "BC_ALL",
            "BC_ALL/reparti",
            "BC_ALL/fornitori",
            "BC_ALL/facing",
            "BC_ALL/articoli"
           ); 
my %folder_type=(
                 "articoli"=>0,
                 "rifornito"=>0,
                 "ordini"=>1, #cartella in cui và mantenuto lo storico
                 "listiniPV"=>0,
                 "listiniPA"=>0,
                 "facing"=>0,
                 "corime"=>0,
                 "fornitoriRel"=>0,
            	 "BC_ALL"=>0,
            	 "BC_ALL/reparti"=>0,
            	 "BC_ALL/fornitori"=>0,
            	 "BC_ALL/facing"=>0,
            	 "BC_ALL/articoli"=>0
            	);      

# Creazione cartelle (se non esistono)
#-------------------------------------------------------------------------------------------
my $path = "$desktop/BRICO";

# Creazione cartelle esterne
my $directory = "$path";
unless(-e $directory or mkdir $directory) {die "Impossibile creare la cartella $directory: $!\n";};
$directory = "$path/$in";
unless(-e $directory or mkdir $directory) {die "Impossibile creare la cartella $directory: $!\n";};
$directory = "$path/$out";
unless(-e $directory or mkdir $directory) {die "Impossibile creare la cartella $directory: $!\n";};

# Creazione cartelle locali
foreach my $user (@user) {
    $directory = "$path/$in/$user";
 	unless(-e $directory or mkdir $directory) {die "Impossibile creare la cartella $directory: $!\n";};
 	
 	foreach my $folder (@folder) {
 		$directory = "$path/$in/$user/$folder";
 		unless(-e $directory or mkdir $directory) {die "Impossibile creare la cartella $directory: $!\n";};
 	};
};


# Trasferimento file
#-------------------------------------------------------------------------------------------
my $ftp_site = 'fileaffiliatibc.sib-spa.it';
my @remote_files;
my @local_files;
my $ftp = Net::FTP->new($ftp_site) or die "Mancata connessione al sito $ftp_site: $!\n";

# E' necessario effettuare un login diverso per ogni negozio
foreach my $user (@user) {
    $ftp->login("$user","$password{$user}") or die "Login al sito $ftp_site fallito per l'utente $user: $!\n";
    
    foreach my $folder (@folder) {
    	# Leggo la lista dei file remoti da caricare
    	$ftp->cwd("/$user/$folder") or die "Impossibile cambiare directory di lavoro remota in /$user/$folder: $!\n";
    	@remote_files = $ftp->ls('*');
    	
    	# Quando la cartella è di tipo 0 (false) elimino il contenuto prima di procedere
        if (!$folder_type{$folder}) {
        	opendir my($local_directory), "$path/$in/$user/$folder" or die "Couldn't open dir: $!";
			@local_files = grep {!/^\./} readdir $$local_directory;
			closedir $$local_directory;
			
			# I file vengono eliminati solo se non fanno parte della nuova lista di caricamento (@remote_files)
			foreach my $file (@local_files) {if (!grep(/^$file$/, @remote_files)) {unlink("$path/$in/$user/$folder/$file");}};
        };
        
        # Ora procedo con il caricamento
    	foreach my $file (@remote_files) {
    	     unless (-e "$path/$in/$user/$folder/$file") {$ftp->get("/$user/$folder/$file","$path/$in/$user/$folder/$file") 
    	       or die "Ricezione file $file non riuscita: $!\n";};
    	};
    };
};
$ftp->quit();