#!/usr/bin/perl -w

use strict;
use Spreadsheet::ParseExcel;
use File::HomeDir;
  
my $desktop  = File::HomeDir->my_desktop;
my $parser   = Spreadsheet::ParseExcel->new();
my $workbook = $parser->parse("$desktop/QBerg.xls");
my $output = "$desktop/QBerg.txt";

open FILE, ">$output" or die $!;

if (!defined $workbook) {die $parser->error(), ".\n";}

# Seleziono il secondo foglio di lavoro nel file QBerg
my $worksheet = $workbook->worksheet(1);

# Una volta selezionato ne calcolo le dimensioni
my ($row_min, $row_max) = $worksheet->row_range();
my ($col_min, $col_max) = $worksheet->col_range();

my $cell;
my $codice_articolo;
my $prezzo_supermedia;
my $prezzo_comet;
my $prezzo_euronics;
my $prezzo_marcopolo;
my $prezzo_mediaworld;
my $prezzo_saturn;
my $prezzo_trony;
my $prezzo_unieuro;

 for my $row ($row_min .. $row_max) {
 	$cell = $worksheet->get_cell($row, 2);
 	if (defined $cell) {
 			$codice_articolo = sprintf("%07d",$cell->value());
 			
 			$cell = $worksheet->get_cell($row, 3);
 			if (defined $cell) {$prezzo_supermedia = $cell->value();} else {$prezzo_supermedia = 0};
 			$cell = $worksheet->get_cell($row, 4);
 			if (defined $cell) {$prezzo_comet = $cell->value();} else {$prezzo_comet = 0};
 			$cell = $worksheet->get_cell($row, 5);
 			if (defined $cell) {$prezzo_euronics = $cell->value();} else {$prezzo_euronics = 0};
 			$cell = $worksheet->get_cell($row, 6);
 			if (defined $cell) {$prezzo_marcopolo = $cell->value();} else {$prezzo_marcopolo = 0};
 			$cell = $worksheet->get_cell($row, 7);
 			if (defined $cell) {$prezzo_mediaworld = $cell->value();} else {$prezzo_mediaworld = 0};
 			$cell = $worksheet->get_cell($row, 8);
 			if (defined $cell) {$prezzo_saturn = $cell->value();} else {$prezzo_saturn = 0};
 			$cell = $worksheet->get_cell($row, 9);
 			if (defined $cell) {$prezzo_trony = $cell->value();} else {$prezzo_trony = 0};
 			$cell = $worksheet->get_cell($row, 10);
 			if (defined $cell) {$prezzo_unieuro = $cell->value();} else {$prezzo_unieuro = 0};
 			
 			print FILE "$codice_articolo\t";
 			print FILE $prezzo_supermedia =~ s/\./,/r, "\t";
 			print FILE $prezzo_comet =~ s/\./,/r, "\t";
 			print FILE $prezzo_euronics =~ s/\./,/r, "\t";
 			print FILE $prezzo_marcopolo =~ s/\./,/r, "\t";
 			print FILE $prezzo_mediaworld =~ s/\./,/r, "\t";
 			print FILE $prezzo_saturn =~ s/\./,/r, "\t";
 			print FILE $prezzo_trony =~ s/\./,/r, "\t";
 			print FILE $prezzo_unieuro =~ s/\./,/r, "\n";
 		};
    
    
 }
 
print FILE "\t";
close FILE;
exit 0

