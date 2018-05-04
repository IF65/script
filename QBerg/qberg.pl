#!/usr/bin/perl -w
use strict;
use warnings;

use lib '/root/perl5/lib/perl5';

use Mail::IMAPClient;
use MIME::Parser;
use Spreadsheet::XLSX;
use File::HomeDir;

my $desktop  = File::HomeDir->my_desktop;

my $imap = Mail::IMAPClient->new( 
        Server => "10.11.14.234",
        User => 'marco.gnecchi@supermedia.it',
        password => "MGnecchi1", 
        Port => 143, 
        Ssl=> 0,
        Uid=> 1) or die "IMAP Failure: $@";

my $box_in = "INBOX";
my $box_bkp = "QBERG";
my $local_folder = "$desktop/QBERG";

my @local_files;

# Creo le cartelle locali se non esistono
unless(-e $local_folder or mkdir $local_folder) 
	{die "Impossibile creare la cartella $local_folder: $!\n";};
unless(-e "$local_folder/IN" or mkdir "$local_folder/IN") 
	{die "Impossibile creare la cartella $local_folder/IN: $!\n";};
unless(-e "$local_folder/OUT" or mkdir "$local_folder/OUT") 
	{die "Impossibile creare la cartella $local_folder/OUT: $!\n";};

# Elimino i file eventualmente presenti nella cartella locale
opendir my($local_directory), "$local_folder/IN" or die "Couldn't open dir $local_folder/IN: $!";
@local_files = grep {!/^\./} readdir $local_directory;
closedir $local_directory;
foreach my $file (@local_files) {unlink("$local_folder/IN/$file");};

# Seleziono sul server la cartella di ricezione dei messaggi
$imap->select($box_in) or die "IMAP Select Error: $@";

# Cerco i messaggi provenienti da QBERG presenti nella cartella di ricezione
my @msgs = $imap->search('FROM','info@qberg.com');# or die "\n";

# Per ogni messaggio trovato......
foreach my $msg (@msgs) {
	# Scarico gli allegati del messaggio nella cartella locale predefinita
    my $parser = MIME::Parser->new;
	$parser->output_dir("$local_folder/IN");
	my $entity = $parser->parse_data($imap->message_string($msg));
	
	# Seleziono i file che non iniziano con il . e non sono del tipo .xls e li elimino
	opendir my($local_directory), "$local_folder/IN" or die "Couldn't open dir $local_folder/IN: $!";
	@local_files = grep {!/xls/} grep {!/^\./} readdir $local_directory;
	closedir $local_directory;
	foreach my $file (@local_files) {unlink("$local_folder/IN/$file");};
	
	# Muovo il messaggio appena utilizzato nella cartella di bkp remota
	my $newUid = $imap->move($box_bkp, $msg) or die "Could not move: $@\n";
    $imap->expunge;
};  

$imap->close($box_in);
$imap->logout();

$desktop  = File::HomeDir->my_desktop;
my $excel_parser   = Spreadsheet::ParseExcel->new();

opendir $local_directory, "$local_folder/IN" or die "Couldn't open dir $local_folder/IN: $!";
@local_files = grep {!/^\./} readdir $local_directory;
closedir $local_directory;
foreach my $file (@local_files) {

		my $output = "$local_folder/OUT/$file";
		$output =~ s/xls/txt/g;
		$output =~ s/Indici_SUPERMEDIA\.IT_//g;
		open FILE, ">$output" or die $!;

		my $workbook = $excel_parser->parse("$local_folder/IN/$file");
		if (!defined $workbook) {die $excel_parser->error(), ".\n";}

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
		my $prezzo_eprice;
		my $prezzo_onlinestore;
		
		my %testate_colonna = ();
		for my $column ($col_min .. $col_max) {
			$cell = $worksheet->get_cell(0, $column);
 			if (defined $cell) {
				my $value = $cell->value();
				if ($value !~ /SUPERMEDIA\.IT/) {
                    $testate_colonna{$value} = $column;
                }
			}
		}
		
 		for my $row ($row_min .. $row_max) {
 			$cell = $worksheet->get_cell($row, 2);
 			if (defined $cell) {
 				$codice_articolo = sprintf("%07d",$cell->value());
 			
 				$cell = $worksheet->get_cell($row, $testate_colonna{'Supermedia.it'});
 				if (defined $cell) {$prezzo_supermedia = $cell->value();} else {$prezzo_supermedia = 0};
 				$cell = $worksheet->get_cell($row, $testate_colonna{'Comet.it'});
 				if (defined $cell) {$prezzo_comet = $cell->value();} else {$prezzo_comet = 0};
 				$cell = $worksheet->get_cell($row, $testate_colonna{'Euronics.it'});
 				if (defined $cell) {$prezzo_euronics = $cell->value();} else {$prezzo_euronics = 0};
 				#$cell = $worksheet->get_cell($row, 6);
 				#if (defined $cell) {$prezzo_marcopolo = $cell->value();} else {$prezzo_marcopolo = 0};
 				$cell = $worksheet->get_cell($row, $testate_colonna{'Mediaworld.it'});
 				if (defined $cell) {$prezzo_mediaworld = $cell->value();} else {$prezzo_mediaworld = 0};
 				#$cell = $worksheet->get_cell($row, 8);
 				#if (defined $cell) {$prezzo_saturn = $cell->value();} else {$prezzo_saturn = 0};
 				$cell = $worksheet->get_cell($row, $testate_colonna{'Trony.it'});
 				if (defined $cell) {$prezzo_trony = $cell->value();} else {$prezzo_trony = 0};
 				$cell = $worksheet->get_cell($row, $testate_colonna{'Unieuro.it'});
 				if (defined $cell) {$prezzo_unieuro = $cell->value();} else {$prezzo_unieuro = 0};
 				
 				$cell = $worksheet->get_cell($row, $testate_colonna{'ePrice Direct'});
 				if (defined $cell) {$prezzo_eprice = $cell->value();} else {$prezzo_eprice = 0};
 				$cell = $worksheet->get_cell($row, $testate_colonna{'Onlinestore.it'});
 				if (defined $cell) {$prezzo_onlinestore = $cell->value();} else {$prezzo_onlinestore = 0};
 				
 				print FILE "$codice_articolo\t";
 				print FILE $prezzo_supermedia =~ s/\./,/r, "\t";
 				print FILE $prezzo_comet =~ s/\./,/r, "\t";
 				print FILE $prezzo_euronics =~ s/\./,/r, "\t";
 				print FILE "0\t";
 				print FILE $prezzo_mediaworld =~ s/\./,/r, "\t";
 				print FILE "0\t";
 				print FILE $prezzo_trony =~ s/\./,/r, "\t";
 				print FILE $prezzo_unieuro =~ s/\./,/r, "\t";
 				print FILE $prezzo_eprice =~ s/\./,/r, "\t";
 				print FILE $prezzo_onlinestore =~ s/\./,/r, "\n";
 			};
    };
    print FILE "\t";
	close FILE;
 };
 
 exit 0;




		
