#!/usr/bin/perl
use strict;
use warnings;
use File::HomeDir;
use File::Copy;
use List::MoreUtils qw(firstidx);

my $path = '/dati/datacollect';

# Carico la lista dei file presenti nelle cartele
#-------------------------------------------------------------------------------------------
my @elenco_cartelle;
opendir my($DIR), $path or die "Non  stato possibile aprire la directory $ARGV[0]: $!\n";
@elenco_cartelle = grep { /^2015\d{4}/ } readdir $DIR;
closedir $DIR;

foreach my $cartella (@elenco_cartelle) {
	my @elenco_files = ();
	opendir $DIR, "$path/$cartella" or die "Non  stato possibile aprire la directory $cartella: $!\n";
	@elenco_files = grep { /^\d{4}_\d{8}_\d{6}_DC\.TXT$/ } readdir $DIR;
	closedir $DIR;
	
	foreach my $file (@elenco_files) {
		&analisi_file("$path/$cartella", $file);
	}
}

# Analizzo ognuno dei file
#-------------------------------------------------------------------------------------------


sub analisi_file {
	my ($path, $file_name) = @_;
  
	my $line;
	my @transazione = ();
	
	my $file_name_new = $file_name;
	$file_name_new =~ s/^(.*)\.TXT/$1\.TMP/;
	
	my $transazione_aperta = 0;
	if (open my $new_file_handler, "+>:crlf", "$path/$file_name_new" ) {;	
		if (open my $old_file_handler, "<:crlf", "$path/$file_name") {
			
			my $negozio = '';
			my $data		= '';
			if ($file_name =~ /^(\d{4})_\d{8}_(\d{6})/) {
				$negozio	= $1;
				$data		= $2;
			}
			
			my $tessera = '';
			while (!eof($old_file_handler)) {
				$line = <$old_file_handler> ;
				$line =~  s/\n$//ig;
				
				if ($line =~ /^.{31}:H:.{44}$/) {
					$transazione_aperta = 1;
					$tessera = '';
					@transazione = ();
				};
				
				if ($line =~ /^.{31}:k:.{12}(\d{13})/) {
					$tessera = $1;
				};
				
				if ($transazione_aperta) {
					push(@transazione, $line);
				}
				
				if ($line =~ /^.{31}:F:.{44}$/) {
					$transazione_aperta = 0;
					
					if ($tessera ne '') {			
						my $cassa = '';
						my $transazione = '';
						my $ora = '';
						if ($line =~ /^\d{4}:(\d{3}):\d{6}:(\d{6}):(\d{4})/) {
							$cassa = $1;
							$transazione = $2;
							$ora = $2;
						}
						
						for	(my $i=0;$i<@transazione;$i++) {
							if ($transazione[$i] =~ /^.{31}:S:.{12}(2120280|2121300|2122610).{6}(.{9})(.{10})$/) {
								print "$tessera\t$negozio\t$data\t$cassa\t$transazione\t$1\t$2\t$3\n"
							}
							
						}
					}
					
					@transazione = ();
				};
			}
			close ($old_file_handler);
		}
		close ($new_file_handler);
	}
	

};

