#!/usr/bin/perl -w
use strict;

use lib "/rpm/ActivePerl-5.22.0.2200-x86_64-linux-glibc-2.15-299195/perl/lib";

use Getopt::Long;

# opzioni sulla linea di comando
#---------------------------------------------------------------------------------------
my @ar_ncr_file;
my @ar_rvg_file;
GetOptions(
	'n=s{1,1}'	=> \@ar_ncr_file,
	'r=s{1,1}'	=> \@ar_rvg_file,
) or die "Uso errato!\n";

my $var_ncr_file = '';
if (@ar_ncr_file > 0) {
	$var_ncr_file = $ar_ncr_file[0];
}

my $var_rvg_file = '';
if (@ar_ncr_file > 0) {
	$var_rvg_file = $ar_rvg_file[0];
}


my $importo_ncr = 0;
if (open my $file_handler, "<:crlf", "$var_ncr_file") {
	while(! eof ($file_handler))  {
		my $linea = <$file_handler>;
		$linea =~ s/\n$//ig;
		if ($linea =~ /:F:1.*(.{10})$/) {
			$importo_ncr += $1;
		}     
	}
	close($file_handler)
}


my $importo_rvg = 0;
if (open my $file_handler, "<:crlf", "$var_rvg_file") {
	while(! eof ($file_handler))  {
		my $linea = <$file_handler>;
		$linea =~ s/\n$//ig;
		if ($linea =~ /^0(\d{4}).{20}(\d{4})(\d\d)(\d\d).{93}(\d{12}).*(.)$/) {
			my $importo = $5;
			my $reso = $6;
			if ($reso eq 'R') {
				$importo *= -1;
			}
			$importo_rvg += $importo;	
		}     
	}
	close($file_handler)
}

my $delta = 10000;
if ($importo_ncr != 0 || $importo_rvg != 0) {
    $delta = abs($importo_ncr - $importo_rvg);
}

if ($delta > 1000) {
    print sprintf('%.2f',$delta/100)."\n";
}


