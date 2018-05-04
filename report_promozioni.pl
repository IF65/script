#!/usr/bin/perl
use strict;
use warnings;
use File::HomeDir;
use File::Basename;
use File::Listing qw(parse_dir);
use File::Find;
use Date::Calc qw(:all);

# variabili di ambiente
my $cartella_dati = '/dati/datacollect';

# variabili globali
my $input_file_handler;
my $output_file_handler;
my $linea;

#my $id_promozione = 1;
#my $barcode_confronto = '29908035|29908073|29908110';
#my $dalla_data = '2015-04-09';
#my $alla_data = '2015-04-15';

#my $id_promozione = 2;
#my $barcode_confronto = '29908042|29908080|29908127';
#my $dalla_data = '2015-04-16';
#my $alla_data = '2015-04-22';

#my $id_promozione = 3;
#my $barcode_confronto = '29908059|29908097|29908134';
#my $dalla_data = '2015-04-23';
#my $alla_data = '2015-04-29';

#my $id_promozione = 4;
#my $barcode_confronto = '29908066|29908103|29908141';
#my $dalla_data = '2015-04-30';
#my $alla_data = '2015-05-06';

#my $id_promozione = 5;
#my $barcode_confronto = '9882721901009|9882722401003|9882722901008';
#my $dalla_data = '2015-03-26';
#my $alla_data = '2015-04-08';

#my $id_promozione = 6;
#my $barcode_confronto = '9882722000503|9882722500508|9882723000502';
#my $dalla_data = '2015-04-09';
#my $alla_data = '2015-04-15';

#my $id_promozione = 7;
#my $barcode_confronto = '9882722100500|9882722600505|9882723100509';
#my $dalla_data = '2015-04-16';
#my $alla_data = '2015-04-22';

#my $id_promozione = 8;
#my $barcode_confronto = '9882722200507|9882722700502|9882723200506';
#my $dalla_data = '2015-04-23';
#my $alla_data = '2015-04-29';

my $id_promozione = 9;
my $barcode_confronto = '9882722300504|9882722800509|9882723300503';
my $dalla_data = '2015-04-30';
my $alla_data = '2015-05-06';

open $output_file_handler, "+>:crlf", "/Users/italmark/Desktop/report_promozione.txt" or die $!;

my @elenco_cartelle;
opendir my($DIR), $cartella_dati or die "Non è stato possibile aprire la cartella $cartella_dati: $!\n";
@elenco_cartelle = grep { /^2015(03|04|05)\d\d$/ } readdir $DIR;
closedir $DIR;

foreach my $cartella (@elenco_cartelle) {
    my @elenco_file;
    opendir my($DIR), "$cartella_dati/$cartella" or die "Non è stato possibile aprire la cartella $cartella_dati/$cartella: $!\n";
    @elenco_file = grep { /^(0108|0115|0178).*\.TXT$/ } readdir $DIR;
    closedir $DIR;
    
    foreach my $file (@elenco_file) {
        if (open $input_file_handler, "<:crlf", "$cartella_dati/$cartella/$file") {
            my $scontrino_aperto = 0;
            
            my $negozio = '';
            my $data = '';
            if ($file =~ /^(\d{4})_(\d{4})(\d{2})(\d{2})_\d{6}_DC\.TXT/) {
                $negozio = $1;
                $data = "$2-$3-$4";
            }
            
            #my $barcode = '';
            #my $sconto = 0;
            #my $barcode_trovato = 0;
            #my $sconto_trovato = 0;
            #my $promozione_trovata = 0;
            #while(! eof ($input_file_handler))  {
            #    
            #    $linea = <$input_file_handler>;
            #    $linea =~ s/\n$//ig;
            #    
            #    if ($linea =~ /:H:1/) {
            #        $scontrino_aperto = 1;
            #    } elsif ($linea =~ /:F:1.{33}(.{10})$/) {
            #        $scontrino_aperto = 0;
            #        
            #        if ($barcode_trovato and $sconto_trovato and $promozione_trovata and $data ge $dalla_data and $data le $alla_data) {
            #           print $output_file_handler "$id_promozione\t$negozio\t$data\t$barcode\t$sconto\t$1\n";
            #        }              
            #        
            #        $barcode = '';
            #        $sconto = 0;
            #        $barcode_trovato = 0;
            #        $sconto_trovato = 0;
            #        $promozione_trovata = 0;
            #    }
            #    
            #    if ($scontrino_aperto) {
            #        if ($linea =~ /:S:.{17}($barcode_confronto)/) {
            #            $barcode = $1;
            #            $barcode_trovato = 1;
            #        }
            #        if ($linea =~ /:d:.{17}($barcode_confronto)/) {
            #            $promozione_trovata = 1;
            #        }
            #        if ($linea =~ /:D:196.{31}(.{10})/) {
            #            $sconto = $1;
            #            $sconto_trovato = 1;
            #        }
            #    }
            #}
            #close($input_file_handler);
            
            
            
            my $barcode = '';
            my $sconto = 0;
            my $barcode_trovato = 0;
            my $sconto_trovato = 0;
            my $promozione_trovata = 0;
            while(! eof ($input_file_handler))  {
                
                $linea = <$input_file_handler>;
                $linea =~ s/\n$//ig;
                
                if ($linea =~ /:H:1/) {
                    $scontrino_aperto = 1;
                } elsif ($linea =~ /:F:1.{33}(.{10})$/) {
                    $scontrino_aperto = 0;
                    
                    if ($promozione_trovata and $data ge $dalla_data and $data le $alla_data) {
                       print $output_file_handler "$id_promozione\t$negozio\t$data\t$barcode\t$sconto\t$1\n";
                    }              
                    
                    $barcode = '';
                    $sconto = 0;
                    $promozione_trovata = 0;
                }
                
                if ($scontrino_aperto) {
                    if ($linea =~ /:S:.{17}($barcode_confronto)/) {
                        $barcode = $1;
                        $barcode_trovato = 1;
                    }
                    if ($linea =~ /:w:1.{11}($barcode_confronto).{9}(.{10})$/) {
                        if ($promozione_trovata) {
                            print "multiplo\n";
                        }
                        
                        $promozione_trovata = 1;
                        $barcode =$1;
                        $sconto = $2;
                    }
                }
            }
            close($input_file_handler);
        } else {die "Impossibile aprire il file $file: errore $!\n"}
    }
}

close($output_file_handler);

# select 	p.`id`, 
# 		concat(p.`descrizione`,' (dal ',p.`dalla_data`,' al ',p.`alla_data`,')') `descrizione`, 
# 		e.`data`,concat(n.`codice`,' - ',n.`negozio_descrizione`) `negozio`, 
# 		sum(e.`sconto`)/100 `sconti/buoni`, 
# 		sum(e.`totale_scontrino`)/100 `tot.scontr.`, 
# 		count(*) `#` 
# 		from esito_promozioni as e join promozioni as p on e.`id_promozione`=p.`id` join archivi.negozi as n on e.`negozio`=n.`codice` 
# 		group by 1,3,4;

# CREATE TABLE `esito_promozioni` (
#   `id_promozione` int(11) NOT NULL,
#   `negozio` varchar(4) NOT NULL DEFAULT '',
#   `data` date NOT NULL,
#   `barcode` varchar(13) NOT NULL DEFAULT '',
#   `sconto` float NOT NULL,
#   `totale_scontrino` float NOT NULL
# ) ENGINE=InnoDB DEFAULT CHARSET=latin1;


# CREATE TABLE `promozioni` (
#   `id` int(11) unsigned NOT NULL,
#   `descrizione` varchar(255) NOT NULL DEFAULT '',
#   `dalla_data` date NOT NULL,
#   `alla_data` date NOT NULL,
#   PRIMARY KEY (`id`)
# ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
