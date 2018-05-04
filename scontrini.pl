#!/usr/bin/perl
use strict;
use warnings;
use File::HomeDir;
use File::Copy;
use List::MoreUtils qw(firstidx);
use Getopt::Long;

my $desktop = File::HomeDir->my_desktop;

#path dati
#---------------------------------------------------------------------------------------------
my $dir_dati = "/dati";
my $dir_datacollect = "$dir_dati/datacollect";
my $dir_immagini = "$dir_dati/immagini";

my $var_data_inizio	= '';
my $var_data_fine	= '';
my $var_sede		= '';
my $var_cassa		= '';
my $var_transazione	= '';
my $var_nimis		= '';
my $var_valore_da	= -1;
my $var_valore_a	= -1;
my $var_pezzi_da	= -1;
my $var_pezzi_a		= -1;
my $var_ricerca		= '';

my @ar_sede = ();
my @ar_data = ();
my @ar_cassa = ();
my @ar_transazione = ();
my @ar_nimis = ();
my @ar_ricerca = ();
my @ar_valore = ();
my @ar_pezzi = ();
my $ncr = 0;
GetOptions(
	's=s{1,1}'	=> \@ar_sede,
	'd=s{1,2}'	=> \@ar_data,
	'c=s{1,1}'	=> \@ar_cassa,
	't=s{1,1}'	=> \@ar_transazione,
	'n=s{1,1}'	=> \@ar_nimis,
	'r=s{1,1}'	=> \@ar_ricerca,
	'v=s{1,2}'	=> \@ar_valore,
	'p=s{1,2}'	=> \@ar_pezzi,
	'ncr!'	=> \$ncr,
) or die "Uso errato!\n";

if (@ar_sede > 0) {
	if ($ar_sede[0] !~ /^(01|30|31|36)\d\d/) {
		die "Codice Negozio Errato: $ar_sede[0]\n";
	}
	$var_sede = $ar_sede[0];
}

for (my $i=0;$i<@ar_data;$i++) {
	$ar_data[$i] =~ s/[^\d\-]/\-/ig;
	if ($ar_data[$i] =~ /^(\d{4})(\d{2})(\d{2})$/) {
		$ar_data[$i] = $1.'-'.$2.'-'.$3;
	} elsif ($ar_data[$i] =~ /^(\d+)\-(\d+)\-(\d+)$/) {
		$ar_data[$i] = sprintf('%04d-%02d-%02d',$1,$2,$3);
	} else {die "Formato data errato: $ar_data[$i]\n"};
	
	$ar_data[$i] =~ s/\-//ig;
}
if (@ar_data > 0) {
	$var_data_inizio = $ar_data[0];
	$var_data_fine = $var_data_inizio;
	if (@ar_data > 1) {
		$var_data_fine = $ar_data[1];
	}
}

if (@ar_cassa > 0) {
	if ($ar_cassa[0] !~ /^\d{3}$/) {
		die "Codice Cassa Errato: $ar_cassa[0]\n";
	}
	$var_cassa = $ar_cassa[0];
}

if (@ar_transazione > 0) {
	if ($ar_transazione[0] !~ /^\d{4}$/) {
		die "Codice Scontrino Errato: $ar_transazione[0]\n";
	}
	$var_transazione = $ar_transazione[0];
}

if (@ar_nimis > 0) {
	if ($ar_nimis[0] !~ /^04(6|9)\d{10}$/) {
		die "Codice Carta Errato: $ar_nimis[0]\n";
	}
	$var_nimis = $ar_nimis[0];
}

if (@ar_ricerca > 0) {
	$var_ricerca = $ar_ricerca[0];
}

if (@ar_valore > 0) {
	if ($ar_valore[0] < 0) {
		die "Importo Negativo: $ar_valore[0]\n";
	}
	$var_valore_da = $ar_valore[0]*1;
	$var_valore_a = $var_valore_da;
	if (@ar_valore > 1) {
		if ($ar_valore[1] < 0) {
			die "Importo Negativo: $ar_valore[1]\n";
		}
		$var_valore_a = $ar_valore[1]*1;
	}
}

if (@ar_pezzi > 0) {
	if ($ar_pezzi[0] < 0) {
		die "Numero Pezzi Negativo: $ar_pezzi[0]\n";
	}
	$var_pezzi_da = $ar_pezzi[0]*1;
	$var_pezzi_a = $var_pezzi_da;
	if (@ar_pezzi > 1) {
		if ($ar_pezzi[1] < 0) {
			die "Numero Pezzi Negativo: $ar_pezzi[1]\n";
		}
		$var_pezzi_a = $ar_pezzi[1]*1;
	}
}

#carico la lista delle cartelle presenti nella cartella di invio
#---------------------------------------------------------------------------------------------
opendir my($DIR), "$dir_datacollect" or die "Non  stato possibile aprire la directory $dir_datacollect: $!\n";
my @elenco_cartelle = grep { /\d{8}$/ } readdir $DIR;
closedir $DIR;

#tra le cartelle selezionate selezione quelle che soddisfano l'intervallo temporale
#---------------------------------------------------------------------------------------------
if ($var_data_inizio ne '') {
	my $i = 0;
	while ($i<@elenco_cartelle) {
		if ($var_data_inizio ne '' and $elenco_cartelle[$i] lt $var_data_inizio or $elenco_cartelle[$i] gt $var_data_fine) {
			splice @elenco_cartelle, $i, 1;
		} else {
			$i++;
		}
	}
}

#seleziono i file dei negozi selezionati che sono nelle cartelle selezionate
#---------------------------------------------------------------------------------------------
my @file_selezionati = ();
for (my $i=0;$i<@elenco_cartelle;$i++) {
	my $search_string = "$var_sede".'_\d{8}_\d{6}_DC.TXT$';
	opendir my($DIR), "$dir_datacollect/$elenco_cartelle[$i]" or die "Non  stato possibile aprire la directory $dir_datacollect: $!\n";
	my @elenco_file = grep { /$search_string/ } readdir $DIR;
	closedir $DIR;
	
	foreach my $file (@elenco_file) {
		if (@ar_sede > 0) {
			if ($file =~ /^(\d{4})/) {
				my $idx = firstidx { $_ eq $1 } @ar_sede;
				if ($idx >= 0) {
					push(@file_selezionati, "$dir_datacollect/$elenco_cartelle[$i]/$file");
				}
			}
		} else {
			push(@file_selezionati, "$dir_datacollect/$elenco_cartelle[$i]/$file");
		}
	}
}

my @ar_elementi;
foreach my $file (@file_selezionati) {
	if (open my $file_handler, "<:crlf", $file) {
		my $linea;
		
		my $sede = '';
		my $data = '';
		my $cassa = '';
		my $transazione = '';
		my $nimis = '';
		my $valore = 0;
		my $pezzi = 0;
		if ($file =~ /(\d{4})_(\d{8})_.{6}_DC\.TXT$/) {
			$sede = $1;
			$data = $2;
			
			while(! eof ($file_handler)) {
				$linea = <$file_handler>;
				$linea =~ s/\n//ig;
			
				if ($linea =~ /^\d{4}:(\d{3}):\d{6}:\d{6}:(\d{4}):\d{3}:H:/) {
					$cassa = $1;
					$transazione = $2;
				}
				
				if ($linea =~ /^.{31}:k:.{12}(04(6|9)\d{10})/) {
					$nimis = $1;
				}
				
				if ($linea =~ /^.{31}:F:1.{27}(.{6})(.{10})$/) {
					$pezzi = $1*1;
					$valore = $2/100;
					
					if ((($var_cassa ne '' and $var_cassa eq $cassa) or $var_cassa eq '') and
					    (($var_transazione ne '' and $var_transazione eq $transazione) or $var_transazione eq '') and
					    (($var_nimis ne '' and $var_nimis eq $nimis) or $var_nimis eq '') and
						(($var_valore_da != -1 and $valore >= $var_valore_da and $valore <= $var_valore_a ) or $var_valore_da == -1) and
						(($var_pezzi_da != -1 and $pezzi >= $var_pezzi_da and $pezzi <= $var_pezzi_a ) or $var_pezzi_da == -1)) {
						push @ar_elementi, {
							'negozio'=>$sede,
							'data'=>$data,
							'cassa'=>$cassa,
							'scontrino'=>$transazione
						};
						$cassa = '';
						$transazione = '';
						$nimis = '';
					}
				}
			}
		}
		close($file_handler);
	}	
}

@ar_elementi = sort {
	$a->{'negozio'} cmp $b->{'negozio'} ||
	$a->{'data'} cmp $b->{'data'} ||
	$a->{'cassa'} cmp $b->{'cassa'} ||
	$a->{'scontrino'} cmp $b->{'scontrino'}
} @ar_elementi;

for (my $i=0;$i<@ar_elementi;$i++) {
	&ricerca_transazione($ar_elementi[$i]{'data'}, $ar_elementi[$i]{'negozio'}, $ar_elementi[$i]{'cassa'}, $ar_elementi[$i]{'scontrino'}, $var_ricerca, $ncr);
}

exit 0;

sub ricerca_transazione() {
	my ($data, $negozio, $cassa, $transazione, $testo, $ncr) = @_;
	
	my $line;
	my $file_datacollect = $dir_datacollect.'/'.$data.'/'.$negozio.'_'.$data.'_'.substr($data,2).'_DC.TXT';
	my $file_immagini = $dir_immagini.'/'.$data.'/'.$negozio.'_'.$data.'_'.substr($data,2).'_DC.JRN';
	my $trovato = 0;
	
	my @ar_transazione = ();
	if (-e $file_immagini) {
		open my $file_handler, "<:crlf", $file_immagini or die $!;
		while (!eof($file_handler) and ! $trovato) {
			$line = <$file_handler> ;
			$line =~  s/\n$//ig;
			
			push(@ar_transazione, $line);
			
			if ($line =~ /^\*/) {
				if ($line =~ /^\*(\d{4})\s\d{4}\/(\d{3})/) {
					if ($1 eq $transazione and $2 eq $cassa) {
						if ($testo eq '') {
							$trovato = 1;	
						} else {
							for (my $i=1;$i<@ar_transazione and ! $trovato;$i++) {
								if ($ar_transazione[$i] =~ /\Q$testo/) {
									$trovato = 1;
								}
							}
						}

						if ($trovato) {
							print "Data: ".substr($data,6,2)."/".substr($data,4,2)."/".substr($data,0,4)."\n";
							print "Negozio: $negozio\n";
							print "Cassa: $cassa\n";
							print "Scontrino: $transazione\n";
							print 'INIZIO '.'-' x 35;
							print "\n";
							for (my $i=1;$i<@ar_transazione;$i++) {  #salto la riga 0
								print "$ar_transazione[$i]\n";
							}
							print "\n\n";
						}
					}
				}
				@ar_transazione = ();
			}
		}
		close ($file_handler);
	}
	
	if ($trovato and $ncr){
		$trovato = 0;
		@ar_transazione = ();
		if (-e $file_datacollect) {
			open my $file_handler, "<:crlf", $file_datacollect or die $!;
			while (!eof($file_handler) and ! $trovato) {
				$line = <$file_handler> ;
				$line =~  s/\n$//ig;
				
				if ($line =~ /^.{4}:(\d{3}):.{6}:.{6}:(\d{4})/) {
					if ($cassa eq $1 and $transazione eq $2) {
						push(@ar_transazione, $line);
					}
				}
				
				if ($line =~ /^.{4}:(\d{3}):.{6}:.{6}:(\d{4}):\d{3}:F:1/) {
					if ($cassa eq $1 and $transazione eq $2) {
						for (my $i=0;$i<@ar_transazione;$i++) {  #salto la riga 0
							print "$ar_transazione[$i]\n";
						}
						print "\n\n";
						
						$trovato = 1;
					}
					@ar_transazione = ();
				}
			}
			close ($file_handler);
		}
	}
}
