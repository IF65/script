#!/usr/bin/perl
use strict;
use warnings;
use File::HomeDir;
use File::Basename;
use File::Listing qw(parse_dir);
use File::Find;
use DBI;
use DateTime;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
use List::MoreUtils qw(firstidx);

#if (@ARGV != 1 && $ARGV[0] !~ /^\d{6}$/) {
#	die "Il periodo nella forma yyyymm deve essere specificato.";
#}

# periodo da analizzare
#------------------------------------------------------------------------------------------------------------
my $periodo = $ARGV[0];

# date
#------------------------------------------------------------------------------------------------------------
my $data_corrente 	= DateTime->now(time_zone=>'local');
my $data_partenza	= DateTime->new(year=>2018, month=>1,day=> 1);

# definizione cartelle/file
#------------------------------------------------------------------------------------------------------------
my $cartella_dati = '/dati/datacollect';
my $excel_file_name = 'report_pago_nimis.xlsx';

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "10.11.14.78";
my $username = "root";
my $password = "mela";

# parametri di configurazione dei database
#------------------------------------------------------------------------------------------------------------
my $database_report = 'report';
my $table_pago_nimis = 'pago_nimis';

# handler/variabili
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $file_handler;
my $sth_get_ep_promo_ref;
my $sth_codice;

if (@ARGV != 2) {die "Numero di parametri non corretto\n"};

my $dalla_data = $ARGV[0];
my $alla_data = $ARGV[1];

my @file_da_caricare = ();
	
if (&ConnessioneDB) {
	foreach my $file (@file_da_caricare) {
		if (open my $file_handler, "<:crlf", "$cartella_dati/".substr($file, 5, 8)."/$file") {
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
			
			my @ar_plu = ();
			my @ar_quantita = ();
			my @ar_sconto_C = ();
			my @ar_punti_G = ();
			my @ar_valore_S = ();
			my @ar_campagna = ();
			my @ar_promozione = ();
			
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
						print "$negozio\t$data\t$plu\t$quantita\t$sconto_C\t$punti_G\t$valore_S\n";
						print "$linea_C\n$linea_G\n"
					} else {
						my $idx = firstidx { $_ eq $plu } @ar_plu;
						if ($idx < 0) {
							my ($codice_campagna,$codice_promozione) = &GetCodicePromozione($data, $plu, $negozio);
							
							#solo se non trova la campagna
							if ($codice_campagna !~ /^\d{5}$/ ) {
								if ($data lt '2015-02-12') {
			 						$codice_campagna = '10253'
								} elsif ($data ge '2015-02-12' && $data le '2016-01-31') {
									$codice_campagna = '10321'
								} else {
									$codice_campagna = '10363'
								}
							}
							
							push @ar_plu , $plu;
							push @ar_quantita, $quantita;
							push @ar_sconto_C, $sconto_C;
							push @ar_punti_G, $punti_G;
							push @ar_valore_S, $valore_S;
							push @ar_campagna, $codice_campagna;
							push @ar_promozione, $codice_promozione;
						} else {
							$ar_quantita[$idx] += $quantita;
							$ar_sconto_C[$idx] += $sconto_C;
							$ar_punti_G[$idx] += $punti_G;
							$ar_valore_S[$idx] += $valore_S;
						}
					}
									
					$valore_S = 0;
					$sconto_C = 0;
					$punti_G = 0;
					$plu = '';
					$quantita = 0
				}
			}
			close($file_handler);
			
			for (my $i=0;$i<@ar_plu;$i++) {
				$sth->execute($negozio, $data, $ar_plu[$i], $ar_quantita[$i], $ar_sconto_C[$i], $ar_punti_G[$i], $ar_valore_S[$i], $ar_campagna[$i], $ar_promozione[$i]) or die "articolo duplicato $negozio, $data, $ar_plu[$i]\n";
			}
		}
	}

	
	#Italmark/Family
	$sth = $dbh->prepare(qq{
		select n.societa 'società', n.`societa_descrizione` 'nome società', year(p.`data`) 'anno', month(p.`data`) 'mese', day(p.`data`) 'giorno', 
		p.`data`, week(p.`data`, 1) 'settimana', p.`codice_campagna` `campagna`,b.`CODCIN-BAR2` ' codice', a.`DES-ART2` 'descrizione', round(a.`IVA-ART2`,0) 'iva',sum(p.quantita) 'qta', 
		sum(round(p.valore+p.sconto, 2)) 'contributo',sum(abs(p.punti))'punti articolo', 0 'punti target',sum(round(abs(p.sconto),2)) 'quota non pagata' 
		from `$table_pago_nimis` as p join archivi.barartx2 as b on p.ean = b.`BAR13-BAR2` join archivi.negozi as n on p.negozio = n.codice join archivi.articox2 as a on 
		b.`CODCIN-BAR2` = a.`COD-ART2` group by 1,2,3,4,5,6,7,8,9,10 order by 1,2,6,8
	});
	if ($sth->execute()) {
		#creo il workbook
		my $workbook = Excel::Writer::XLSX->new("/$excel_file_name");
		
		#creo il worksheet
		my $report = $workbook->add_worksheet( 'report' );
		
		#aggiungo un formato
    	my $format = $workbook->add_format();
    	$format->set_bold();
    	my $date_format = $workbook->add_format();
    	$date_format->set_num_format('dd/mm/yy');
		
		#titoli colonne
		$format->set_color( 'Black' );
		$report->write( 0, 0, "societa", $format );
		$report->write( 0, 1, "nome societa", $format );
		$report->write( 0, 2, "anno", $format );
		$report->write( 0, 3, "mese", $format );
		$report->write( 0, 4, "giorno", $format );
		$report->write( 0, 5, "data", $format );
		$report->write( 0, 6, "settimana", $format );
		$report->write( 0, 7, "campagna", $format );
		$report->write( 0, 8, "codice", $format );
		$report->write( 0, 9, "descrizione", $format );
		$report->write( 0, 10, "iva", $format );
		$report->write( 0, 11, "q.ta", $format );
		$report->write( 0, 12, "contributo", $format );
		$report->write( 0, 13, "punti articolo", $format );
		$report->write( 0, 14, "punti target", $format );
		$report->write( 0, 15, "quota non pagata", $format );
		
		my $row_counter = 0;
		while(my @row = $sth->fetchrow_array()) {
			$row_counter++;
			 
			$report->write_string( $row_counter, 0, "$row[0]");
			$report->write_string( $row_counter, 1, "$row[1]");
			$report->write_string( $row_counter, 2, "$row[2]");
			$report->write_string( $row_counter, 3, "$row[3]");
			$report->write_string( $row_counter, 4, "$row[4]");
			$report->write_date_time( $row_counter, 5, "$row[5]".'T', $date_format );
			$report->write( $row_counter, 6, "$row[6]");
			$report->write_string( $row_counter, 7, "$row[7]");
			$report->write_string( $row_counter, 8, "$row[8]");
			$report->write_string( $row_counter, 9, "$row[9]");
			$report->write( $row_counter, 10, "$row[10]");
			$report->write( $row_counter, 11, "$row[11]");
			$report->write( $row_counter, 12, "$row[12]");
			$report->write( $row_counter, 13, "$row[13]");
			$report->write( $row_counter, 14, "$row[14]");
			$report->write( $row_counter, 15, "$row[15]");
		}
		$sth->finish();
		
		#Supermedia
		$sth = $dbh->prepare(qq{
			select
				n.`societa`,
				n.`societa_descrizione`,
				year(b.`data`) `anno`,
				month(b.`data`) `mese`,
				day(b.`data`) `giorno`,
				b.`data` `data`,
				week(b.`data`,1) `settimana`,
				b.codice_campagna `campagna`,
				r.codice,
				r.descrizione,
				r.aliquota_iva `iva`,
				sum(r.quantita) `q.ta`,
				round(sum(r.importo_totale),2) `contributo`,
				sum(b.valore) `punti articolo`,
				0 `punti target`,
				round(sum((select b1.`valore` from db_sm.benefici as b1 where b.`id_riga_vendita`=b1.`id_riga_vendita` and b1.`tipo`='B1')),2) `quota non pagata`
			from db_sm.benefici AS b join db_sm.righe_vendita AS r on r.progressivo = b.id_riga_vendita left join archivi.negozi as n on b.`negozio`=n.`codice_interno`
			WHERE b.data >= ? AND b.data <= ? AND b.tipo = 'BM'
			group by 1,2,3,4,5,6,7,8,9,10
			ORDER BY b.data ASC
		});
		
		if ($sth->execute($dalla_data, $alla_data)) {
			while(my @row = $sth->fetchrow_array()) {
				$row_counter++;
			 
				$report->write_string( $row_counter, 0, "$row[0]");
				$report->write_string( $row_counter, 1, "$row[1]");
				$report->write_string( $row_counter, 2, "$row[2]");
				$report->write_string( $row_counter, 3, "$row[3]");
				$report->write_string( $row_counter, 4, "$row[4]");
				$report->write_date_time( $row_counter, 5, "$row[5]".'T', $date_format );
				$report->write( $row_counter, 6, "$row[6]");
				$report->write_string( $row_counter, 7, "$row[7]");
				$report->write_string( $row_counter, 8, "$row[8]");
				$report->write_string( $row_counter, 9, "$row[9]");
				$report->write( $row_counter, 10, "$row[10]");
				$report->write( $row_counter, 11, "$row[11]");
				$report->write( $row_counter, 12, "$row[12]");
				$report->write( $row_counter, 13, "$row[13]");
				$report->write( $row_counter, 14, "$row[14]");
				$report->write( $row_counter, 15, "$row[15]");
			}
		}
		
		#Sportland
		$sth = $dbh->prepare(qq{
			select
				n.`societa`,
				n.`societa_descrizione`,
				year(b.`data`) `anno`,
				month(b.`data`) `mese`,
				day(b.`data`) `giorno`,
				b.`data` `data`,
				week(b.`data`,1) `settimana`,
				b.codice_campagna `campagna`,
				r.codice,
				r.descrizione,
				r.aliquota_iva `iva`,
				sum(r.quantita) `q.ta`,
				round(sum(r.importo_totale),2) `contributo`,
				sum(b.valore) `punti articolo`,
				0 `punti target`,
				round(sum((select b1.`valore` from db_sp.benefici as b1 where b.`id_riga_vendita`=b1.`id_riga_vendita` and b1.`tipo`='B1')),2) `quota non pagata`
			from db_sp.benefici AS b join db_sp.righe_vendita AS r on r.progressivo = b.id_riga_vendita left join archivi.negozi as n on b.`negozio`=n.`codice_interno`
			WHERE b.data >= ? AND b.data <= ? AND b.tipo = 'BM'
			group by 1,2,3,4,5,6,7,8,9,10
			ORDER BY b.data ASC
		});
		
		if ($sth->execute($dalla_data, $alla_data)) {
			while(my @row = $sth->fetchrow_array()) {
				$row_counter++;
			 
				$report->write_string( $row_counter, 0, "$row[0]");
				$report->write_string( $row_counter, 1, "$row[1]");
				$report->write_string( $row_counter, 2, "$row[2]");
				$report->write_string( $row_counter, 3, "$row[3]");
				$report->write_string( $row_counter, 4, "$row[4]");
				$report->write_date_time( $row_counter, 5, "$row[5]".'T', $date_format );
				$report->write( $row_counter, 6, "$row[6]");
				$report->write_string( $row_counter, 7, "$row[7]");
				$report->write_string( $row_counter, 8, "$row[8]");
				$report->write_string( $row_counter, 9, "$row[9]");
				$report->write( $row_counter, 10, "$row[10]");
				$report->write( $row_counter, 11, "$row[11]");
				$report->write( $row_counter, 12, "$row[12]");
				$report->write( $row_counter, 13, "$row[13]");
				$report->write( $row_counter, 14, "$row[14]");
				$report->write( $row_counter, 15, "$row[15]");
			}
		}
		
		#Rugiada
		$sth = $dbh->prepare(qq{
			select
				n.`societa`,
				n.`societa_descrizione`,
				year(b.`data`) `anno`,
				month(b.`data`) `mese`,
				day(b.`data`) `giorno`,
				b.`data` `data`,
				week(b.`data`,1) `settimana`,
				b.codice_campagna `campagna`,
				r.codice,
				r.descrizione,
				r.aliquota_iva `iva`,
				sum(r.quantita) `q.ta`,
				round(sum(r.importo_totale),2) `contributo`,
				sum(b.valore) `punti articolo`,
				0 `punti target`,
				round(sum((select b1.`valore` from db_ru.benefici as b1 where b.`id_riga_vendita`=b1.`id_riga_vendita` and b1.`tipo`='B1')),2) `quota non pagata`
			from db_ru.benefici AS b join db_ru.righe_vendita AS r on r.progressivo = b.id_riga_vendita left join archivi.negozi as n on b.`negozio`=n.`codice_interno`
			WHERE b.data >= ? AND b.data <= ? AND b.tipo = 'BM'
			group by 1,2,3,4,5,6,7,8,9,10
			ORDER BY b.data ASC
		});
		
		if ($sth->execute($dalla_data, $alla_data)) {
			while(my @row = $sth->fetchrow_array()) {
				$row_counter++;
			 
				$report->write_string( $row_counter, 0, "$row[0]");
				$report->write_string( $row_counter, 1, "$row[1]");
				$report->write_string( $row_counter, 2, "$row[2]");
				$report->write_string( $row_counter, 3, "$row[3]");
				$report->write_string( $row_counter, 4, "$row[4]");
				$report->write_date_time( $row_counter, 5, "$row[5]".'T', $date_format );
				$report->write( $row_counter, 6, "$row[6]");
				$report->write_string( $row_counter, 7, "$row[7]");
				$report->write_string( $row_counter, 8, "$row[8]");
				$report->write_string( $row_counter, 9, "$row[9]");
				$report->write( $row_counter, 10, "$row[10]");
				$report->write( $row_counter, 11, "$row[11]");
				$report->write( $row_counter, 12, "$row[12]");
				$report->write( $row_counter, 13, "$row[13]");
				$report->write( $row_counter, 14, "$row[14]");
				$report->write( $row_counter, 15, "$row[15]");
			}
		}
		
		#Ecobrico
		$sth = $dbh->prepare(qq{
			select
				n.`societa`,
				n.`societa_descrizione`,
				year(b.`data`) `anno`,
				month(b.`data`) `mese`,
				day(b.`data`) `giorno`,
				b.`data` `data`,
				week(b.`data`,1) `settimana`,
				b.codice_campagna `campagna`,
				r.codice,
				r.descrizione,
				r.aliquota_iva `iva`,
				sum(r.quantita) `q.ta`,
				round(sum(r.importo_totale),2) `contributo`,
				sum(b.valore) `punti articolo`,
				0 `punti target`,
				round(sum((select b1.`valore` from db_eb.benefici as b1 where b.`id_riga_vendita`=b1.`id_riga_vendita` and b1.`tipo`='B1')),2) `quota non pagata`
			from db_eb.benefici AS b join db_eb.righe_vendita AS r on r.progressivo = b.id_riga_vendita left join archivi.negozi as n on b.`negozio`=n.`codice_interno`
			WHERE b.data >= ? AND b.data <= ? AND b.tipo = 'BM'
			group by 1,2,3,4,5,6,7,8,9,10
			ORDER BY b.data ASC
		});
		
		if ($sth->execute($dalla_data, $alla_data)) {
			while(my @row = $sth->fetchrow_array()) {
				$row_counter++;
			 
				$report->write_string( $row_counter, 0, "$row[0]");
				$report->write_string( $row_counter, 1, "$row[1]");
				$report->write_string( $row_counter, 2, "$row[2]");
				$report->write_string( $row_counter, 3, "$row[3]");
				$report->write_string( $row_counter, 4, "$row[4]");
				$report->write_date_time( $row_counter, 5, "$row[5]".'T', $date_format );
				$report->write( $row_counter, 6, "$row[6]");
				$report->write_string( $row_counter, 7, "$row[7]");
				$report->write_string( $row_counter, 8, "$row[8]");
				$report->write_string( $row_counter, 9, "$row[9]");
				$report->write( $row_counter, 10, "$row[10]");
				$report->write( $row_counter, 11, "$row[11]");
				$report->write( $row_counter, 12, "$row[12]");
				$report->write( $row_counter, 13, "$row[13]");
				$report->write( $row_counter, 14, "$row[14]");
				$report->write( $row_counter, 15, "$row[15]");
			}
		}
	}
};

$sth->finish();
$dbh->disconnect();
	
sub ConnessioneDB {
	# connessione al database negozi
	$dbh = DBI->connect("DBI:mysql:$database_report:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database `$database_report`!\n";
		return 0;
	}

	$sth = $dbh->prepare(qq{SELECT count(*) from `$table_pago_nimis` WHERE `data` = ? and `negozio` = ?});
	
	# recupero l'elenco dei file disponibili	
	my @elenco_cartelle;
	opendir my($DIR), $cartella_dati or die "Non è stato possibile aprire la cartella $cartella_dati: $!\n";
	@elenco_cartelle = grep { /^20\d{6}$/ } readdir $DIR;
	closedir $DIR;
	
	my @elenco_documenti;
	my @documenti;
	foreach my $cartella (@elenco_cartelle) {
		opendir my($DIR), "$cartella_dati/$cartella" or die "Non è stato possibile aprire la cartella $cartella: $!\n";
		@elenco_documenti = grep { /^\d{4}_.*\.TXT$/ } readdir $DIR;
		closedir $DIR;

		foreach my $documento (@elenco_documenti) {
			if ($documento =~ /^(\d{4})_(20\d{2})(\d{2})(\d{2})_.*DC\.TXT$/) {
				
				my $negozio = $1;
				my $data = DateTime->new(
					year      => $2,
					month     => $3,
					day       => $4,
					time_zone => 'Europe/Rome'
				);
				
				if (DateTime->compare( $data, $data_partenza ) >= 0) {
					if ($sth->execute($data->ymd('-'), $negozio)) {
						my @count = $sth->fetchrow_array();
						
						if ($count[0] == 0) {
							push @file_da_caricare, $documento;
						}				
					}
				}	
			}
		}
	}
	$sth->finish();
	
	$sth = $dbh->prepare(qq{insert into `$table_pago_nimis` (`negozio`,`data`,`ean`,`quantita`,`sconto`,`punti`,`valore`, `codice_campagna`, `codice_promozione`) values (?,?,?,?,?,?,?,?,?)});
	
	$sth_codice = $dbh->prepare(qq{select `CODCIN-BAR2` from archivi.barartx2 where `BAR13-BAR2` = ? limit 1});
	
	#cerco il codice promozione/campagna di epipoli
	$sth_get_ep_promo_ref = $dbh->prepare(qq{select p.`codice_campagna`, p.`codice_promozione`, p.`classe`
						from cm.promozioni as p, cm.negozi_promozioni as n
						where p.`data_inizio` <= ? and p.`data_fine` >= ? and
						p.`tipo` = ? and p.`codice_articolo` = ? and 
						p.`codice_promozione`=n.`promozione_codice` and n.`negozio_codice`= ?
						order by p.classe});
	
	return 1;
}

sub GetCodicePromozione() {
	my ($data_movimento, $barcode, $negozio) = @_;
	
	my $codice_campagna 	= '     ';
	my $codice_promozione 	= '         ';
	my $codice_classe		= '0';
	
	my $codice_articolo = '';
	if ($sth_codice->execute($barcode)) {
		while (my @record = $sth_codice->fetchrow_array()) {
			$codice_articolo = $record[0];
		}
	}
	
	# cerco la promozione
	if ($sth_get_ep_promo_ref->execute($data_movimento, $data_movimento, 'BM', $codice_articolo, $negozio)) {
		while (my @record = $sth_get_ep_promo_ref->fetchrow_array()) {
			$codice_campagna 	= $record[0];
			$codice_promozione	= $record[1];
			$codice_classe		= $record[2];
		}
	}
	
	return ($codice_campagna, $codice_promozione);
}

#SQL
#select n.societa 'società', n.`societa_descrizione` 'nome società', year(p.`data`) 'anno', month(p.`data`) 'mese', day(p.`data`) 'giorno', 
#p.`data`, week(p.`data`, 1) 'settimana',b.`CODCIN-BAR2` ' codice', a.`DES-ART2` 'descrizione', round(a.`IVA-ART2`,0) 'iva',sum(p.quantita) 'qta', 
#sum(round(p.valore+p.sconto,2)) 'contributo',sum(abs(p.punti))'punti articolo', 0 'punti target',sum(round(abs(p.sconto),2)) 'quota non pagata' 
#from pago_nimis as p join archivi.barartx2 as b on p.ean = b.`BAR13-BAR2` join archivi.negozi as n on p.negozio = n.codice join archivi.articox2 as a on 
#b.`CODCIN-BAR2` = a.`COD-ART2` group by 1,2,3,4,5,6,7,8,9,10

#DB
# CREATE TABLE `pago_nimis` (
#   `negozio` varchar(4) NOT NULL DEFAULT '',
#   `data` date NOT NULL,
#   `ean` varchar(13) NOT NULL DEFAULT '',
#   `quantita` float NOT NULL,
#   `sconto` float NOT NULL,
#   `punti` float NOT NULL,
#   `valore` float NOT NULL,
#   `codice_campagna` varchar(5) NOT NULL DEFAULT '',
#   `codice_promozione` varchar(9) NOT NULL DEFAULT '',
#   PRIMARY KEY (`negozio`,`data`,`ean`)
# ) ENGINE=InnoDB DEFAULT CHARSET=latin1;

# select	n.`societa`,
# 		n.`societa_descrizione`,
# 		year(b.`data`) `anno`,
# 		month(b.`data`) `mese`,
# 		day(b.`data`) `giorno`,
# 		week(b.`data`,1) `settimana`,
# 		b.`data` `data`,
# 		b.codice_campagna `campagna`,
# 		r.codice,r.descrizione,
# 		r.aliquota_iva `iva`,
# 		sum(r.quantita) `q.ta`,
# 		round(sum(r.importo_totale),2) `contributo`,
# 		sum(b.valore) `punti articolo`,
# 		0 `punti target`,
# 		round(sum((select b1.`valore` from db_sm.benefici as b1 where b.`id_riga_vendita`=b1.`id_riga_vendita` and b1.`tipo`='B1')),2) `quota non pagata`
# from db_sm.benefici AS b join db_sm.righe_vendita AS r on r.progressivo = b.id_riga_vendita left join archivi.negozi as n on b.`negozio`=n.`codice_interno`
# WHERE b.data >= '2015-01-01' AND b.data <= '2015-09-30' AND b.tipo = 'BM'
# group by 1,2,3,4,5,6,7,8,9,10
# ORDER BY b.data ASC
