#!/usr/bin/perl -w
use strict;

use DBI;
use DateTime;
use List::MoreUtils qw(firstidx);

# date
#------------------------------------------------------------------------------------------------------------
my $current_date 	= DateTime->now(time_zone=>'local');
my $starting_date	= DateTime->new(year=>2015, month=>11,day=> 22);

# definizione cartelle
#------------------------------------------------------------------------------------------------------------
my $cartella_gre = '/copre';
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
my $table_log = 'log_invio_dati_new';
my $table_ean = 'ean';

# variabili
#------------------------------------------------------------------------------------------------------------
my @giornate_da_inviare = ();

#handler
my $dbh;
my $sth;

if (&ConnessioneDB) {
	if (@giornate_da_inviare>0) {
		#esportazione righe_vendita
		$sth = $dbh->prepare(qq{select 	r.`data`,
								substr(r.`ora`,1,2) `ora`,
								s.`numero_upb`,
								s.`numero`,
								ifnull((select e.`ean` from $database_vendite.`$table_ean` as e where e.`codice`=r.`codice` order by 1 desc limit 1),'2999999999999') as `ean`,
								ma.`codice`,
								mr.`marca`,
								ma.`modello`,
								round(r.`quantita`,0) `quantita`,
								round(case when r.`quantita` <> 0 then r.`importo_totale`/r.`quantita` else 0 end ,2) `prezzo_unitario`,
								round(r.`importo_totale`,2) `totale`,
								round(r.`importo_totale`*100/(100+r.`aliquota_iva`),2) `totale no iva`,
								case when r.`quantita`>=0 then 'VEN' else 'RES' end `tipo`
								from 	$database_vendite.`marche` as mr join $database_vendite.`magazzino` as ma on mr.`linea`=ma.`linea` join
										$database_vendite.`righe_vendita` as r on r.`codice`=ma.`codice` join
										$database_vendite.`scontrini` as s on r.`id_scontrino`=s.`id_scontrino`
								where mr.`invio_gre`=1 and ma.`invio_gre`=1 and r.`data`= ? and r.`riga_non_fiscale`=0 and  r.`riparazione`=0 and r.`importo_totale`<>0 and
									r.`codice` not in ('0560440','0560459','0560468','0619218','0560477','0560486','0560495','0575504','0575513') and
									r.`negozio` in (select distinct codice_interno from $database_vendite.`$table_log` where data = ?)
								order by  r.`data`, substr(r.`ora`,1,2);
		});

		for (my $i=0;$i<@giornate_da_inviare;$i++) {
			my @idx = ();
			my @ora = ();
			my @upb = ();
			my @scontrino = ();
			my @ean = ();
			my @codice = ();
			my @marca = ();
			my @modello = ();
			my @quantita = ();
			my @prezzo_unitario = ();
			my @totale = ();
			my @totale_no_iva = ();
			my @tipo = ();
			if ($sth->execute($giornate_da_inviare[$i],$giornate_da_inviare[$i])) {
				while(my @row = $sth->fetchrow_array()) {
					push @ora, $row[1];
					push @upb, $row[2];
					push @scontrino, $row[3];
					push @ean, $row[4];
					push @codice, $row[5];
					push @marca, $row[6];
					push @modello, $row[7];
					push @quantita, $row[8];
					push @prezzo_unitario, $row[9];
					push @totale, $row[10];
					push @totale_no_iva, $row[11];
					push @tipo, $row[12];
				}
			}

			my $nome_file = $cartella_invio.'/SO_02147260174_SM_'.substr($giornate_da_inviare[$i],0,4).substr($giornate_da_inviare[$i],5,2).substr($giornate_da_inviare[$i],8,2).'.txt';
			if (open my $file_handler, "+>:crlf", "/$nome_file") {
				my $contatore = 1;
				for (my $j=0;$j<@ora;$j++) {
					print $file_handler $current_date->dmy('').' '.substr($current_date->hms(':'), 0, 5).'|';
					print $file_handler substr($giornate_da_inviare[$i],8,2).substr($giornate_da_inviare[$i],5,2).substr($giornate_da_inviare[$i],0,4)."|";
					print $file_handler "$ora[$j]|";
					print $file_handler "$contatore|";
					print $file_handler "$contatore|||";
					print $file_handler "200507|SUPERMEDIA|02147260174|||||||||DET|";
					print $file_handler dot2comma($totale[$j])."|";
					print $file_handler dot2comma($totale_no_iva[$j])."|";
					print $file_handler dot2comma($totale[$j])."|0|0|0|0|0|0|0|0|";
					print $file_handler "$contatore||";
					print $file_handler "$ean[$j]|";
					print $file_handler "$codice[$j]|";
					print $file_handler "$marca[$j]|";
					print $file_handler "$modello[$j]|";
					print $file_handler "$quantita[$j]|";
					print $file_handler dot2comma($prezzo_unitario[$j])."|0|";
					print $file_handler dot2comma($totale[$j])."|";
					print $file_handler dot2comma($totale_no_iva[$j])."|";
					print $file_handler "$tipo[$j]||0\n";

					$contatore++;
				}
				close $file_handler;
			}
		}

		#imposto a 1 il flag invio_copre
		$sth = $dbh->prepare(qq{update `$database_vendite`.`$table_log` as l join
									(select s.`negozio` as `negozio`, s.`data` as `data` from `$database_vendite`.`$table_scontrini` as s  group by 1,2) as g
									on l.`data`=g.`data` and l.`codice_interno`=g.`negozio`
								set l.`invio_copre` = 1
								where l.`invio_copre` = 0});
		if (! $sth->execute()) {
			die "Errore l'aggiornamento della tabella `$table_log`!\n";
		}

		# esportazione giacenze
		$sth = $dbh->prepare(qq{select
									'200507',
									ifnull((select ean.`ean` from `$database_vendite`.ean where ean.`codice`= giac.`codice` order by ean.`ean` limit 1),'2999999999999') `ean`,
									giac.codice, mar.`marca`, mag.`modello`, giac.`giacenza`
								from
									(select g.`codice`, sum(g.`giacenza`) `giacenza` from
										(select `negozio`, max(`data`) as `data` from `$database_vendite`.`giacenze` where `data` <=? group by 1) as gd join `$database_vendite`.`giacenze` as g on gd.`negozio`=g.`negozio` and gd.`data`=g.`data`
										where g.`negozio` in (select l.`codice_interno` from `$database_vendite`.`$table_log` as l where l.`data` = ?) group by 1 order by 1
									) as giac join `$database_vendite`.`magazzino` as mag on giac.`codice`= mag.`codice` join `$database_vendite`.`marche` as mar on mag.`linea`=mar.`linea`
								where mag.`invio_gre`=1 and mar.`invio_gre`=1
								having giac.`giacenza`>0});

		my $data_invio = $giornate_da_inviare[@giornate_da_inviare-1];
		$data_invio =~ s/\-//ig;

		my $nome_file = $cartella_invio.'/ST_02147260174_SM_'.$data_invio.'.txt';
		if (open my $file_handler, "+>:crlf", "/$nome_file") {
			if ($sth->execute($giornate_da_inviare[@giornate_da_inviare-1],$giornate_da_inviare[@giornate_da_inviare-1])) {
				while (my @row = $sth->fetchrow_array()) {
					print $file_handler $current_date->dmy('').' '.substr($current_date->hms(':'), 0, 5).'|';
					print $file_handler substr($data_invio,6,2).substr($data_invio,4,2).substr($data_invio,0,4)."|";
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

			$sth->finish();
		}
}

$dbh->disconnect();

#FINE
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

sub ConnessioneDB {


	# connessione al database negozi
	$dbh = DBI->connect("DBI:mysql:$database_negozi:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database `$database_negozi`!\n";
		return 0;
	}

	#creo la tabella di log se non esiste
	$sth = $dbh->prepare(qq{create table if not exists `$database_vendite`.`$table_log` (
							`codice` varchar(4) not null default '',
							`codice_interno` varchar(4) not null default '',
							`descrizione` varchar(100) not null default '',
							`data` date not null,
							`invio_gre` tinyint(1) unsigned not null default '0',
							`invio_copre` tinyint(1) unsigned not null default '0',
							`solo_giacenze` tinyint(1) unsigned not null default '0',
							primary key (`codice`,`codice_interno`,`data`)
							) engine=innodb default charset=latin1;});
	if (! $sth->execute()) {
		print "Errore durante la creazione della tabella `$table_log`!\n";
		return 0;
	}

	#creo i record di log
	$sth = $dbh->prepare(qq{insert into `$database_vendite`.`$table_log`
							select n.`codice`, n.`codice_interno`, n.`negozio_descrizione`, ?, 0, 0, case when n.`tipo` = 2 then 1 else 0 end
							from `$database_negozi`.`$table_negozi` as n left join `$database_vendite`.`$table_log` as l on n.`codice_interno`=l.`codice_interno` and l.`data`=?
							where n.`societa` = '08' and (n.`data_fine` is null or n.`data_fine`>=?) and n.`tipo` in (2,3,4) and l.`codice` is null
							order by lpad(substr(n.`codice_interno`,3),3,'0')});

	my $data = $starting_date->clone();
	while (DateTime->compare($data, $current_date)<0) {
		if (! $sth->execute($data->ymd('-'), $data->ymd('-'), $data->ymd('-'))) {
			print "Errore durante la creazione dei record della tabella `$table_log` del giorno ".$data->ymd('-')."!\n";
			return 0;
		}
        $data->add(days => 1);
    }

	#cerco le giornate da inviare: sono le giornate dove esistono scontrini (compresi quelli fittizi mandati quando il negozio è chiuso) ed il flag invio_copre è uguale a 0
	$sth = $dbh->prepare(qq{select distinct l.`data`
							from `$database_vendite`.`$table_log` as l join
								(select s.`negozio` as `negozio`, s.`data` as `data` from `$database_vendite`.`$table_scontrini` as s  group by 1,2) as g
								on l.`data`=g.`data` and l.`codice_interno`=g.`negozio`
							where l.`invio_copre` = 0
							order by 1});
	if ($sth->execute()) {
		while (my @row = $sth->fetchrow_array()) {
			push @giornate_da_inviare, $row[0];
		}
	}

	$sth->finish();

	return 1;
}

sub dot2comma {
	my($numero) = @_;

	$numero = sprintf('%.2f', $numero);

	$numero =~ s/\./,/ig;

	return $numero;
}
