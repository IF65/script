#!/usr/bin/perl -w
use strict;

use DBI;
use DateTime;
use List::MoreUtils qw(firstidx);

# date
#------------------------------------------------------------------------------------------------------------
my $current_date 	= DateTime->now(time_zone=>'local');
my $starting_date	= DateTime->new(year=>2015, month=>8,day=> 1);

# definizione cartelle
#------------------------------------------------------------------------------------------------------------
my $cartella_gre = '/gre';
my $cartella_invio = "$cartella_gre/file_da_inviare";
my $cartella_bkp = "$cartella_gre/file_inviati";

unless(-e $cartella_gre or mkdir $cartella_gre) {die "Impossibile creare la cartella $cartella_gre: $!\n";};
unless(-e $cartella_invio or mkdir $cartella_invio) {die "Impossibile creare la cartella $cartella_invio: $!\n";};
unless(-e $cartella_bkp or mkdir $cartella_bkp) {die "Impossibile creare la cartella $cartella_bkp: $!\n";};

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "10.11.14.78";
my $username = "root";
my $password = "mela";

# parametri di configurazione dei database
#------------------------------------------------------------------------------------------------------------
my $database_negozi = 'archivi';
my $table_negozi = 'negozi';

my $database_vendite = 'db_sm';
my $table_vendite = 'righe_vendita';
my $table_scontrini = 'scontrini';
my $table_log = 'log_invio_dati';

# variabili
#------------------------------------------------------------------------------------------------------------
my @negozi_codice = ();
my @negozi_codice_interno = ();
my @negozi_descrizione = ();
my @negozi_data_inizio = ();
my @negozi_data_fine = ();
my @negozi_tipo = ();

my @da_inviare_negozio = ();
my @da_inviare_data = ();
my @da_inviare_solo_giacenze = ();

#handler
my $dbh;
my $sth;
my $sth_negozi_chiusi;
my $sth_insert;

if (&ConnessioneDB) {
	# query sulla tabella log x caricare le giornate/negozio da inviare
	$sth = $dbh->prepare(qq{select codice_interno, data, solo_giacenze from `$table_log` where `invio_gre` = 0});
	if ($sth->execute()) {
		while(my @row = $sth->fetchrow_array()) {
			push @da_inviare_negozio, $row[0];
			push @da_inviare_data, $row[1];
			push @da_inviare_solo_giacenze, $row[2];
		}
	}
	$sth->finish();
	
	# query sulla tabella vendite x verificare se i dati del negozio sono pervenuti
	$sth = $dbh->prepare(qq{select * from `$table_vendite` where `negozio` = ? and `data` = ?});
	for (my $i=@da_inviare_negozio-1;$i>=0;$i--) {
		$sth->execute($da_inviare_negozio[$i],$da_inviare_data[$i]) or die "Impossibile connettersi alla tabella vendite: " . $sth->errstr;
		if ($sth->rows == 0) {
			splice @da_inviare_negozio, $i, 1;
			splice @da_inviare_data, $i, 1;
		}
	}
	$sth->finish();
	
	# filtro le giornate perché và sempre inviata la giornata completa anche se manca solo un negozio
	my @giornate_da_inviare = ();
	for (my $i=0;$i<@da_inviare_data;$i++) {
		my $idx = firstidx { $_ eq "$da_inviare_data[$i]" } @giornate_da_inviare;
		if ($idx < 0) {
			push @giornate_da_inviare, $da_inviare_data[$i];
		}
	}
	
	@giornate_da_inviare = sort @giornate_da_inviare;
	
	$sth = $dbh->prepare(qq{select 	r.`data`, 
							substr(r.`ora`,1,2) `ora`,
							s.`numero_upb`,
							s.`numero`,
							r.`negozio`,
							ifnull((select e.`ean` from ean as e where e.`codice`=r.`codice` order by 1 desc limit 1),'2999999999999') as `ean`,
							ma.`codice`,
							mr.`marca`, 
							ma.`modello`,
							round(r.`quantita`,0) `quantita`,
							round(case when r.`quantita` <> 0 then r.`importo_totale`/r.`quantita` else 0 end ,2) `prezzo_unitario`,
							round(r.`importo_totale`,2) `totale`,
							round(r.`importo_totale`*100/(100+r.`aliquota_iva`),2) `totale no iva`,
							case when r.`quantita`>=0 then 'VEN' else 'RES' end `tipo`
							from 	marche as mr join magazzino as ma on mr.`linea`=ma.`linea` join
									righe_vendita as r on r.`codice`=ma.`codice` join
									scontrini as s on r.`id_scontrino`=s.`id_scontrino` 
							where mr.`invio_gre`=1 and ma.`invio_gre`=1 and r.`data`= ? and r.`riga_non_fiscale`=0 and r.`negozio`<>'SMW1'and r.`riparazione`=0 and r.`importo_totale`<>0
							order by  r.`data`,r.`negozio`, s.`numero_upb`;
	});
	
	for (my $i=0;$i<@giornate_da_inviare;$i++) {
		my @idx = ();
		my @ora = ();
		my @upb = ();
		my @scontrino = ();
		my @negozio = ();
		my @ean = ();
		my @codice = ();
		my @marca = ();
		my @modello = ();
		my @quantita = ();
		my @prezzo_unitario = ();
		my @totale = ();
		my @totale_no_iva = ();
		my @tipo = ();
		if ($sth->execute($giornate_da_inviare[$i])) {
			while(my @row = $sth->fetchrow_array()) {
				push @ora, $row[1];
				push @upb, $row[2];
				push @scontrino, $row[3];
				push @negozio, $row[4];
				push @ean, $row[5];
				push @codice, $row[6];
				push @marca, $row[7];
				push @modello, $row[8];
				push @quantita, $row[9];
				push @prezzo_unitario, $row[10];
				push @totale, $row[11];
				push @totale_no_iva, $row[12];
				push @tipo, $row[13];
				
				push @idx, $row[2].'/'.$row[4];
			}
		}
		
		$sth_negozi_chiusi= $dbh->prepare(qq{select negozio from `$table_scontrini` where `data` = ? and `numero` = 999999});
		if ($sth_negozi_chiusi->execute($giornate_da_inviare[$i])) {
			while(my @row = $sth_negozi_chiusi->fetchrow_array()) {
				push @ora, '08';
				push @upb, 9999;
				push @scontrino, 9999;
				push @negozio, $row[0];
				push @ean, '2999999999999';
				push @codice, '6672941';
				push @marca, 'SAMSUNG';
				push @modello, '1GB EGOKIT';
				push @quantita, 1;
				push @prezzo_unitario, 0.01;
				push @totale, 0.01;
				push @totale_no_iva, 0.01;
				push @tipo, 'VEN';
				
				push @idx, '999999/'.$row[0];
			}
			$sth_negozi_chiusi->finish();
		}
		
		my @scontrino_idx = ();
		my @scontrino_totale = ();
		my @scontrino_totale_no_iva = ();
		for (my $j=0;$j<@idx;$j++) {
			my $idx = firstidx { $_ eq $idx[$j] } @scontrino_idx;
			if ($idx < 0) {
				push @scontrino_idx, $idx[$j];
				push @scontrino_totale, $totale[$j];
				push @scontrino_totale_no_iva, $totale_no_iva[$j];
			} else {
				$scontrino_totale[$idx] += $totale[$j];
				$scontrino_totale_no_iva[$idx] += $totale_no_iva[$j];
			}
		}
		
		my $nome_file = $cartella_invio.'/SO_02147260174_SM_'.substr($giornate_da_inviare[$i],0,4).substr($giornate_da_inviare[$i],5,2).substr($giornate_da_inviare[$i],8,2).'.txt';
		if (open my $file_handler, "+>:crlf", "/$nome_file") {
			my $contatore = 1;
			my $negozio_old = '';
			my $scontrino_old = 0;
			for (my $j=0;$j<@idx;$j++) {
				
				if ($negozio_old ne $negozio[$j] or $scontrino_old  != $scontrino[$j]) {
					$negozio_old = $negozio[$j];
					$scontrino_old = $scontrino[$j];
					
					$contatore = 1;
				} else {
					$contatore += 1;
				}
				
				print $file_handler $current_date->dmy('').' '.substr($current_date->hms(':'), 0, 5).'|';
				print $file_handler substr($giornate_da_inviare[$i],8,2).substr($giornate_da_inviare[$i],5,2).substr($giornate_da_inviare[$i],0,4)."|";
				print $file_handler "$ora[$j]|";
				print $file_handler "$upb[$j]|";
				print $file_handler "$scontrino[$j]|||";
				print $file_handler "$negozio[$j]|SUPERMEDIA|02147260174|||||||||DET|";
				my $idx = firstidx { $_ eq "$idx[$j]" } @scontrino_idx;
				if ($idx >= 0) {
					print $file_handler Dot2Comma($scontrino_totale[$idx])."|";
					print $file_handler Dot2Comma($scontrino_totale_no_iva[$idx])."|";
					print $file_handler Dot2Comma($scontrino_totale[$idx])."|0|0|0|0|0|0|0|0|";
				} else {
					print $file_handler "0|";
					print $file_handler "0|";
					print $file_handler "0|0|0|0|0|0|0|0|0|";
				}
				print $file_handler "$contatore||";
				print $file_handler "$ean[$j]|";
				print $file_handler "$codice[$j]|";
				print $file_handler "$marca[$j]|";
				print $file_handler "$modello[$j]|";
				print $file_handler "$quantita[$j]|";
				print $file_handler Dot2Comma($prezzo_unitario[$j])."|0|";
				print $file_handler Dot2Comma($totale[$j])."|";
				print $file_handler Dot2Comma($totale_no_iva[$j])."|";
				print $file_handler "$tipo[$j]||0\n";
			}
			close $file_handler;
		}
		
	}
	$sth->finish();
	
	# query sulla tabella di log x inserire il flag quando la giornata è stata inviata
	$sth = $dbh->prepare(qq{update `$table_log` set `invio_gre` = 1 where codice_interno = ? and data = ?});
	for (my $i=0;$i<@da_inviare_data;$i++) {
		$sth->execute($da_inviare_negozio[$i], $da_inviare_data[$i]) or die "Impossibile aggiornare la tabella di log: " . $sth->errstr;;
	}
	$sth = $dbh->prepare(qq{update `$table_log` as l inner join `$table_scontrini` as s on l.`codice_interno`=s.`negozio` and l.`data`=s.`data` set l.`invio_gre` = 1 where s.`data` = ? and s.`numero` = 999999});
	for (my $i=0;$i<@giornate_da_inviare;$i++) {
		$sth->execute($giornate_da_inviare[$i]) or die "Impossibile aggiornare la tabella log: " . $sth->errstr;
	}
	
	# esportazione giacenze
	$sth = $dbh->prepare(qq{select 
								g1.`negozio`,
								ifnull((select e.`ean` from ean as e where e.`codice`=g1.`codice` order by 1 desc limit 1),'2999999999999') as `ean`,
								g1.`codice`,
								ifnull(ma.`marca`,''),
								mg.`modello`,
								round(g1.`giacenza`,0) 
							from `db_sm`.giacenze as g1 inner join `db_sm`.magazzino as mg on g1.`codice`=mg.`codice` left join `db_sm`.marche as ma on ma.`linea`=mg.`linea`
							where 
								g1.`data` = (select max(g2.`data`) from `db_sm`.giacenze as g2 where g2.`codice` = g1.`codice` and g2.`negozio`=g1.`negozio`) and 
								g1.`codice` in (select ma.`codice` from `db_sm`.marche as mr join `db_sm`.magazzino as ma on mr.`linea`=ma.`linea`where mr.`invio_gre`=1 and ma.`invio_gre`=1 order by 1) and
								g1.`giacenza` > 0 and g1.`negozio` <> 'SMW1' 
							order by g1.`negozio`, g1.`codice`;
	});
	
	my $data_finale = $current_date->clone();
	$data_finale->add(days =>-1);
	
	my $nome_file = $cartella_invio.'/ST_02147260174_SM_'.$data_finale->ymd('').'.txt';
	if (open my $file_handler, "+>:crlf", "/$nome_file") {
		if ($sth->execute()) {
			while (my @row = $sth->fetchrow_array()) {
				print $file_handler $current_date->dmy('').' '.substr($current_date->hms(':'), 0, 5).'|';
				print $file_handler $data_finale->dmy('')."|";
				print $file_handler 'SUPERMEDIA|02147260174|';
				print $file_handler $row[0]."||";
				print $file_handler $row[1]."|";
				print $file_handler $row[2]."|";
				print $file_handler $row[3]."|";
				print $file_handler $row[4]."|";
				print $file_handler $row[5]."|".$row[5]."|0||0,00\n";
			}
		}
		close $file_handler;
	}
	
	$nome_file = $cartella_invio.'/CO_02147260174_SM.txt';
	if (open my $file_handler, "+>:crlf", "/$nome_file") {close $file_handler};
}

$sth->finish();
$dbh->disconnect();

sub ConnessioneDB {
	
    
	# connessione al database negozi
	$dbh = DBI->connect("DBI:mysql:$database_negozi:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database `$database_negozi`!\n";
		return 0;
	}

	# recupero l'elenco dei negozi da cui prelevare i dati
	$sth = $dbh->prepare(qq{SELECT codice, codice_interno, negozio_descrizione, data_inizio, ifnull(data_fine,'0000-00-00'), tipo from `$table_negozi` WHERE societa = '08' and invio_dati_gre = 1 ORDER BY codice});
	if ($sth->execute()) {
		while(my @row = $sth->fetchrow_array()) {
			push @negozi_codice, $row[0];
			push @negozi_codice_interno, $row[1];
			push @negozi_descrizione, $row[2];
			push @negozi_data_inizio, $row[3];
			push @negozi_data_fine, $row[4];
			push @negozi_tipo, $row[5];
		}
	}
	
	$sth->finish();
	$dbh->disconnect();
	
	# connessione al database vendite
	$dbh = DBI->connect("DBI:mysql:$database_vendite:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database `$database_vendite`!\n";
		return 0;
	}
	# query sulla tabella di log x determinare se il record del giorno esiste
	$sth = $dbh->prepare(qq{SELECT * from `$table_log` WHERE codice_interno = ? and data = ?});
	
	# query sulla tabella di log x inserire il record del giorno se non esiste
	$sth_insert = $dbh->prepare(qq{insert ignore into `$table_log` (`codice`,`codice_interno`,`data`,`invio_gre`,`solo_giacenze`) values (?,?,?,?,?)});
	
	for (my $i=0;$i<@negozi_codice_interno;$i++) {
		
		# determino la data inziale per il negozio
		my $data;
		if (($negozi_data_inizio[$i] ne '0000-00-00') && ($negozi_data_inizio[$i] =~ /^(\d{4})\-(\d{2})\-(\d{2})$/)) {
			$data = DateTime->new(day=>$3,month=>$2,year=>$1);
			if (DateTime->compare( $data, $starting_date ) <= 0) {#$data <= $starting_date
				$data = $starting_date->clone();
			}
		} else {
			$data = $starting_date->clone();	
		}
		
		# determino la data finale per il negozio
		my $data_finale = $current_date -> clone();
		if (($negozi_data_fine[$i] ne '0000-00-00') && ($negozi_data_fine[$i] =~ /^(\d{4})\-(\d{2})\-(\d{2})$/)) {
			$data_finale = DateTime->new(day=>$3,month=>$2,year=>$1);
		}
		
		# verifico giorno per giorno se ci sono i record relativi al negozio e, se non esistono, li creo.
		while (DateTime->compare( $data, $data_finale ) <= 0) {
			$sth->execute($negozi_codice_interno[$i],$data->ymd('-') ) or die "Impossibile connettersi alla tabella di log: " . $sth->errstr;
			if ($sth->rows == 0) {
				$sth_insert->execute($negozi_codice[$i], $negozi_codice_interno[$i], $data->ymd('-'), 0, $negozi_tipo[$i] == 2) or die "Impossibile inserire il record nella tabella di log: " . $sth->errstr;
			}
			$data->add(days =>1);
		}
	}
	
	$sth_insert->finish();
	$sth->finish();
	
	return 1;
}

sub Dot2Comma {
	my($numero) = @_;
	
	$numero = sprintf('%.2f', $numero);
	 
	$numero =~ s/\./,/ig;
	
	return $numero;
}
