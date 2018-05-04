#!/usr/bin/perl
use strict;
use warnings;
use File::HomeDir;
use Net::FTP;

my $path = File::HomeDir->my_home;

my $out = "COPRE_ESPORTAZIONE";
  
my $ftp_site = 'ftp.intranet.copre.it';
my $user = "copre_sellout";
my $password = "!coprem?";
  
my $directory = "$path/Desktop/$out";
  
# Se la directory OUT esiste
if (-e $directory) {
  if (! -e "$directory/SEMAFORO.TXT") {
    my @local_files;
    my $ftp = Net::FTP->new($ftp_site) or die "Mancata connessione al sito $ftp_site: $!\n";

    $ftp->login("$user","$password") or die "Login al sito $ftp_site fallito per l'utente $user: $!\n";
    
    # Carico la lista dei file presenti nella directory di invio senza i file
    # che iniziano con il "."
    opendir my($local_directory), "$directory" or die "Non è stato possibile aprire la directory $directory: $!\n";
    @local_files = grep {!/^\./} readdir $local_directory;
    closedir $local_directory;
   
    # Ora procedo all'invio
    foreach my $file (@local_files) {
      $ftp->put("$directory/$file") or die "Invio file $file non riuscito: $!\n";
      # E una volta inviato il file lo elimino
      unlink "$directory/$file";
    };
     
    $ftp->quit();  
  };
};

exit 0;