#!/usr/bin/perl -w
use strict;
use DBI;
use File::HomeDir;
use Getopt::Long;

# opzioni sulla linea di comando
#---------------------------------------------------------------------------------------
my @ar_ncr_path;
my @ar_riepvego_path;
GetOptions(
	'n=s{1,1}'	=> \@ar_ncr_path,
	'r=s{1,1}'	=> \@ar_riepvego_path,
) or die "Uso errato!\n";

my $var_ncr_path = '';
if (@ar_ncr_path > 0) {
	$var_ncr_path = $ar_ncr_path[0];
}

my $var_riepvego_path = '';
if (@ar_ncr_path > 0) {
	$var_riepvego_path = $ar_riepvego_path[0];
}

my @elenco_file = ();
opendir my $DIR, "$var_ncr_path" or die "Non è stato possibile aprire la directory $var_ncr_path: $!\n";
@elenco_file = grep { /^\d{4}_\d{8}_\d{6}_DC\.TXT$/ } readdir $DIR;
closedir $DIR;

my @ar_negozio = ();
my @ar_data = ();
my @ar_importo_ncr = ();
my @ar_importo_riepvego = ();

foreach my $file (@elenco_file) {
	my $negozio = '';
	my $data = '';
	my $importo = 0;
	if (open my $file_handler, "<:crlf", "$var_ncr_path/$file") {
		if ($file =~ /^(\d{4})_(\d{4})(\d\d)(\d\d)/) {
			$negozio = $1;
			$data = $2.'-'.$3.'-'.$4;
		}
	
		while(! eof ($file_handler))  {
			my $linea = <$file_handler>;
			$linea =~ s/\n$//ig;
			if ($linea =~ /:F:1.*(.{10})$/) {
				$importo += $1;
			}     
		}
		close($file_handler);
		
		push @ar_negozio, $negozio;
		push @ar_data, $data;
		push @ar_importo_ncr, $importo;
		push @ar_importo_riepvego, 0;
	}
};

if (open my $file_handler, "<:crlf", "$var_riepvego_path/RIEPVEGO") {
	my $negozio = '';
	my $data = '';
	my $importo = 0;
	my $reso = 0;
	while(! eof ($file_handler))  {
		my $linea = <$file_handler>;
		$linea =~ s/\n$//ig;
		if ($linea =~ /^0(\d{4}).{20}(\d{4})(\d\d)(\d\d).{93}(\d{12}).*(.)$/) {
			$negozio = $1;
			$data = $2.'-'.$3.'-'.$4;
			$importo = $5;
			$reso = $6;
			
			for (my $i=0;$i<@ar_negozio;$i++) {
				if ($negozio eq $ar_negozio[$i] && $data eq $ar_data[$i]) {
					if ($reso eq 'R') {
						$importo *= -1;
					}
					$ar_importo_riepvego[$i] += $importo;	
				}
			}
		}     
	}
	close($file_handler);
}

if (open my $file_handler, "+>:crlf", "/controllo.txt") {
	for(my $i=0;$i<@ar_negozio;$i++) {
		print $file_handler "$ar_negozio[$i]\t$ar_data[$i]\t".sprintf("%.2f",$ar_importo_ncr[$i]/100)."\t".sprintf("%.2f",$ar_importo_riepvego[$i]/100)."\n";
	}
	close($file_handler);
}