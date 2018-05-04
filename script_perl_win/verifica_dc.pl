#!/usr/bin/perl
use strict;
use warnings;
#use Net::FTP;
use File::HomeDir;
  
my $desktop  = File::HomeDir->my_desktop;
  
my $directory = "$desktop/DATA_COLLECT/ST";

# Carico l'elenco dei file contenuti nella directory di lavoro
opendir DIR, $directory or die "Non è possibile aprire la directory $directory: $!";
my @elenco_file = grep {!/^\./} readdir DIR;
closedir DIR;

print join("\n", @elenco_file);
print "\n";

exit 0;