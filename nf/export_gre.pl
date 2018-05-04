#!/usr/bin/perl -w
use strict;

use DBI;
use DateTime;
use List::MoreUtils qw(firstidx);

# date
#------------------------------------------------------------------------------------------------------------
my $current_date  = DateTime->today(time_zone=>'local');
my $starting_date = $current_date->clone()->truncate(to => 'month')->subtract(months => 1);

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
my $hostname = "localhost";
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
my @giornate_da_inviare = ();

#handler
my $dbh;
my $sth;
my $sth_negozi_chiusi;
my $sth_insert;

if (&ConnessioneDB) {
	# query sulle tabelle log_invio_dati e scontrini x caricare le giornate/negozio da inviare
	$sth = $dbh->prepare(qq{select distinct l.data
						 from $database_vendite.`$table_log` as l left join $database_vendite.`$table_scontrini` as s on l.`codice_interno`=s.`negozio` and l.`data`=s.`data`
						 where invio_gre=0 and s.`data` is not null});
	if ($sth->execute()) {
		while(my @row = $sth->fetchrow_array()) {
			push @giornate_da_inviare, $row[0];
		}
	}
	$sth->finish();
	
	$sth = $dbh->prepare(qq{select 	r.`data`, 
							substr(r.`ora`,1,2) `ora`,
							s.`numero_upb`,
							s.`numero`,
							r.`negozio`,
							ifnull((select e.`ean` from $database_vendite.`ean` as e where e.`codice`=r.`codice` order by 1 desc limit 1),'2999999999999') as `ean`,
							ma.`codice`,
							mr.`marca`, 
							ma.`modello`,
							round(r.`quantita`,0) `quantita`,
							round(case when r.`quantita` <> 0 then r.`importo_totale`/r.`quantita` else 0 end ,2) `prezzo_unitario`,
							round(r.`importo_totale`,2) `totale`,
							round(r.`importo_totale`*100/(100+r.`aliquota_iva`),2) `totale no iva`,
							case when r.`quantita`>=0 then 'VEN' else 'RES' end `tipo`,
							case when substr(s.`carta`,1,3)='043' then s.`carta` else '' end `carta`
							from 	$database_vendite.`marche` as mr join $database_vendite.`magazzino` as ma on mr.`linea`=ma.`linea` join
									$database_vendite.`righe_vendita` as r on r.`codice`=ma.`codice` join
									$database_vendite.`scontrini` as s on r.`id_scontrino`=s.`id_scontrino` 
							where mr.`invio_gre`=1 and ma.`invio_gre`=1 and r.`data`= ? and r.`riga_non_fiscale`=0 and  r.`riparazione`=0 and r.`importo_totale`<>0 and
								r.`codice` not in ('0560440','0560459','0560468','0619218','0560477','0560486','0560495','0575504','0575513') and
								r.`negozio` in (select distinct codice_interno from $database_vendite.`log_invio_dati` where data = ?)
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
		my @carta = ();
		if ($sth->execute($giornate_da_inviare[$i],$giornate_da_inviare[$i])) {
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
				push @carta, $row[14];
				
				push @idx, $row[2].'/'.$row[4];
			}
		}
		
		#per i negozi chiusi o i magazzini creo una vendita fittizia partendo dallo scontrino numero=999999 che viene sempre creato in mancanza di vendite reali
		$sth_negozi_chiusi= $dbh->prepare(qq{select negozio	from $database_vendite.`$table_scontrini` where `data` = ? and `numero` = 999999 and `negozio` in
											(select distinct codice_interno	from $database_vendite.`log_invio_dati`	where data = ?)});
		if ($sth_negozi_chiusi->execute($giornate_da_inviare[$i],$giornate_da_inviare[$i])) {
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
				push @carta, '';
				
				push @idx, '999999/'.$row[0];
			}
			$sth_negozi_chiusi->finish();
		}
		$sth->finish();
		
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
				print $file_handler "$negozio[$j]|SUPERMEDIA|02147260174||$carta[$j]|||||||DET|";
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
	
	#aggiornamento log 
	$sth = $dbh->prepare(qq{update $database_vendite.`log_invio_dati` as l left join $database_vendite.`scontrini` as s on l.`codice_interno`=s.`negozio` and l.`data`=s.`data`
						 set l.`invio_gre`=1
						 where invio_gre=0 and s.`data` is not null});
	$sth->execute() or die "Aggiornamento log non riuscito\n";
	$sth->finish();
	
	# esportazione giacenze
	#--------------------------------------------------------------------------------------------------------
	$sth = $dbh->prepare(qq{call `controllo`.`report_stock_gre`();});
	
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
	
	#creazione del file "semaforo"
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

	#creo nella tabella di log i record per ogni negozio/data a partira dalla data di partenza predefinita
	$sth = $dbh->prepare(qq{insert into $database_vendite.`$table_log`
							select n.`codice`,n.`codice_interno`, ? `data`,ifnull(l.`invio_gre`,0) `invio_gre` ,ifnull(l.`solo_giacenze`,0) `solo_giacenze`
							from $database_negozi.`$table_negozi` as n left join $database_vendite.`$table_log` as l on n.`codice`=l.`codice` and l.`data`=?
							where n.`data_inizio`<=? and (n.`data_fine` is null or n.`data_fine`>=?) and n.`societa`='08' and n.`tipo` in (2,3,4) and l.`codice` is null
							order by lpad(substr(n.`codice_interno`,3),4,'0')}
						);
	my $data = $starting_date->clone(); 
	while (DateTime->compare( $data, $current_date ) <= 0) {
		$sth->execute($data->ymd('-'),$data->ymd('-'),$data->ymd('-'),$data->ymd('-')) or die "creazione dei record log fallita";
		$data->add(days =>1);
	}
	
	$sth->finish();
	
	return 1;
}

sub Dot2Comma {
	my($numero) = @_;
	
	$numero = sprintf('%.2f', $numero);
	 
	$numero =~ s/\./,/ig;
	
	return $numero;
}
