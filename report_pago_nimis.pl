#!/usr/bin/perl
use strict;
use warnings;
use File::HomeDir;
use File::Basename;
use File::Listing qw(parse_dir);
use File::Find;

if (@ARGV != 1 && $ARGV[0] !~ /^\d{6}$/) {
	die "Il periodo nella forma yyyymm deve essere specificato.";
}

# periodo da analizzare
my $periodo = $ARGV[0];

# variabili di ambiente
my $cartella_dati = '/dati/datacollect';

# ricerco le cartelle che contengono i documenti
my @elenco_cartelle;
opendir my($DIR), $cartella_dati or die "Non è stato possibile aprire la cartella $cartella_dati: $!\n";
@elenco_cartelle = grep { /^${periodo}\d\d$/ } readdir $DIR;
closedir $DIR;

# ricerco i documenti contenuti in ognuna delle cartelle trovate
if ((open my $report_handler, "+>", File::HomeDir->my_desktop."/report_pago_nimis_$ARGV[0].txt") &&
	(open my $error_handler, "+>", File::HomeDir->my_desktop."/report_pago_nimis_$ARGV[0].err")) {

	my @elenco_documenti;
	my @documenti;
	foreach my $cartella (@elenco_cartelle) {
		opendir my($DIR), "$cartella_dati/$cartella" or die "Non è stato possibile aprire la cartella $cartella: $!\n";
		@elenco_documenti = grep { /^\d{4}_.*\.TXT$/ } readdir $DIR;
		closedir $DIR;

		foreach my $file (@elenco_documenti) {
			if (open my $file_handler, "<:crlf", "$cartella_dati/$cartella/$file") {
				my $negozio = '';
				my $data = '';
				if ($file =~ /^(\d{4})_(\d{4})(\d\d)(\d\d)/) {
					$negozio = $1;
					$data = $2.'-'.$3.'-'.$4;
				}
			
				my $linea_G = '';
				my $linea_C = '';
			
				my $valore_S = 0;
				my $sconto_C = 0;
				my $punti_G = 0;
				my $plu = '';
				my $quantita = 0;
				while(! eof ($file_handler))  {
					my $linea = <$file_handler>;
					$linea =~ s/\n$//ig;
				
					if ($linea =~ /^.{31}:C:142.{22}(.{5}).{4}(.)(\d{9})/) {
						$quantita     = $1*1;
						my $segno     = $2;
						$sconto_C     = $3/100;
					
						if ($segno eq '<' or $segno eq '>') {
							$sconto_C = '-'.$sconto_C;
							$sconto_C *= $quantita;
						} else {
							$sconto_C = $segno.$sconto_C;
						}
					
						$sconto_C *= 1;
					
						$linea_C =$linea;
					}
				
					if ($linea =~ /^.{31}:G:131.{9}(.{13}).{3}(.{6})(.{10})$/) {
						$plu = $1;
						$punti_G = $2*1;
						$valore_S = $3/100;
					
						$plu =~ s/\s//ig;
					
						$linea_G =$linea;
					}
				
					if ($linea =~ /^.{31}:m:1.{8}0027/) {
						if ($valore_S == 0 or $sconto_C == 0 or $punti_G == 0 or $plu eq '') {
							print $error_handler "$negozio\t$data\t$plu\t$quantita\t$sconto_C\t$punti_G\t$valore_S\n";
							print $error_handler "$linea_C\n$linea_G\n"
						} else {
							print $report_handler "$negozio\t$data\t$plu\t$quantita\t$sconto_C\t$punti_G\t$valore_S\n"
						}
										
						$valore_S = 0;
						$sconto_C = 0;
						$punti_G = 0;
						$plu = '';
						$quantita = 0
					}
				}
				close($file_handler)
			}
		}
	}
	close($error_handler);
	close($report_handler);
}


#SQL
#select n.societa 'società', n.`societa_descrizione` 'nome società', year(p.`data`) 'anno', month(p.`data`) 'mese', day(p.`data`) 'giorno', 
#p.`data`, week(p.`data`, 1) 'settimana',b.`CODCIN-BAR2` ' codice', a.`DES-ART2` 'descrizione', round(a.`IVA-ART2`,0) 'iva',sum(p.quantita) 'qta', 
#sum(round(p.valore+p.sconto,2)) 'contributo',sum(abs(p.punti))'punti articolo', 0 'punti target',sum(round(abs(p.sconto),2)) 'quota non pagata' 
#from pago_nimis as p join archivi.barartx2 as b on p.ean = b.`BAR13-BAR2` join archivi.negozi as n on p.negozio = n.codice join archivi.articox2 as a on 
#b.`CODCIN-BAR2` = a.`COD-ART2` group by 1,2,3,4,5,6,7,8,9,10
#
#DB
#CREATE TABLE `pago_nimis` (
#  `negozio` varchar(4) NOT NULL DEFAULT '',
#  `data` date NOT NULL,
#  `ean` varchar(13) NOT NULL DEFAULT '',
#  `quantita` float NOT NULL,
#  `sconto` float NOT NULL,
#  `punti` float NOT NULL,
#  `valore` float NOT NULL
#) ENGINE=InnoDB DEFAULT CHARSET=latin1;
