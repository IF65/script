#!/usr/bin/perl
use strict;
use warnings;

my $input_file_handler;
my $output_file_handler;

# il paramemtro 0 deve contenere nome e path del file da trasformare mentre il parametro 1
# deve contenere il path del file trasformato
if ( @ARGV == 2 ) {
	my $prima_linea = 1;
	if (-e $ARGV[0]) {
		my $line = '';
		if (open($input_file_handler, "<:crlf", $ARGV[0])) {
			if (open($output_file_handler, "+>", $ARGV[1])) {
				while (!eof($input_file_handler)) {
					$line = <$input_file_handler> ;
					$line =~  s/\n$//ig;
				
					my @ar_field = split(/;/,$line);
					
					if (! $prima_linea) {
						print $output_file_handler "FCOPRE\t";
						for (my $i=0;$i<@ar_field;$i++) {
							$ar_field[$i] =~ s/\t//ig;
							
							print $output_file_handler $ar_field[$i]."\t";
							if	($i == 15) {print $output_file_handler "\t"}; # serve per aggiungere il campo_codice_articolo_if
						}				
						print $output_file_handler "\t\t\n";
					} else {
						$prima_linea = 0;
					}
				}
				close($output_file_handler);
			}
			close($input_file_handler);
		}
	}
}