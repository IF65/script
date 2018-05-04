#!/usr/bin/perl -w
use strict;
use DBI; 
use File::HomeDir;
use DateTime;

# data corrente
#------------------------------------------------------------------------------------------------------------
my $current_date = DateTime->today(time_zone=>'local');

# data minima
#------------------------------------------------------------------------------------------------------------
my $data_inizio_periodo = DateTime->new(day=>'01',month=>'01',year=>'2015');

# serve per scrivere un eventuale file di log
#------------------------------------------------------------------------------------------------------------
my $desktop 			= File::HomeDir->my_desktop;
my $local_data_folder 	= "/dati";
my $image_folder		= "$local_data_folder/immagini";
my $datacollect_folder	= "$local_data_folder/datacollect";

# parametri di collegamento
#------------------------------------------------------------------------------------------------------------
my $hostname                = "127.0.0.1";
my $username                = "root";
my $password                = "mela";

# parametri di configurazione dei database
#------------------------------------------------------------------------------------------------------------
my $database                = 'archivi';
my $table_negozi            = 'negozi';
my $table_ricezione_dati    = 'ricezione_dati';

# negozi attivi
#------------------------------------------------------------------------------------------------------------
my @negozi_codice;
my @negozi_descrizione;
my @negozi_ip;
my @negozi_utente;
my @negozi_password;
my @negozi_percorso;
my @negozi_data_inizio;
my @negozi_data_fine;

# query
#------------------------------------------------------------------------------------------------------------
my $sth_file_da_ricevere;
my $sth_file_ricevuti;
my $sth_totale;
my $sth_carica_giornata;
my $sth_aggiorna_giornata;

my %record;

# Creazione cartelle locali (se non esistono)
#------------------------------------------------------------------------------------------------------------
unless(-e $local_data_folder or mkdir $local_data_folder) {die "Impossibile creare la cartella $local_data_folder: $!\n";};
unless(-e $image_folder or mkdir $image_folder) {die "Impossibile creare la cartella $image_folder: $!\n";};
unless(-e $datacollect_folder or mkdir $datacollect_folder) {die "Impossibile creare la cartella $datacollect_folder: $!\n";};

if (&ConnessioneDB()) {
	my @elenco_cartelle;
    opendir my($DIR), $datacollect_folder or die "Non  stato possibile aprire la cartella $datacollect_folder: $!\n";
    @elenco_cartelle = sort grep { /^2\d{7}$/ } readdir $DIR;
    closedir $DIR;
		
	foreach my $cartella (@elenco_cartelle) {
	
		#elimino i datacollect incompleti
		if (opendir my $DIR, "$datacollect_folder/$cartella") {
				my @elenco_file = sort grep { /^.*\.CTL$/ } readdir $DIR;
				closedir $DIR;
				foreach (@elenco_file) {
					my $file_ctl = $_;
					my $file_txt = s/\.CTL$/\.TXT/ig; 
					if (! unlink "$datacollect_folder/$cartella/$file_txt") {
						unlink "$datacollect_folder/$cartella/$file_ctl";
					}
				}
		}
		
		#elimino i file immagine incompleti
		if (opendir $DIR, "$image_folder/$cartella") {
			my @elenco_file = sort grep { /^.*\.CTL$/ } readdir $DIR;
			closedir $DIR;
			foreach (@elenco_file) {
				my $file_ctl = $_;
				my $file_jrn = s/\.CTL$/\.JRN/ig; 
				if (! unlink "$image_folder/$cartella/$file_jrn") {
					unlink "$image_folder/$cartella/$file_ctl";
				}
			}
		}

		
		if (opendir $DIR, "$datacollect_folder/$cartella") {
			my @elenco_file = sort grep { /^.*\.TXT$/ } readdir $DIR;
			closedir $DIR;
	
			foreach (@elenco_file) {
				my $data = '';
				my $negozio = '';
				if ($_ =~ /^(\d{4})_\d{8}_(\d{2})(\d{2})(\d{2})_.*\.TXT$/) {
					$data = '20'.$2.'-'.$3.'-'.$4;
					$negozio = $1;
				} 
				
				if ($data ge $data_inizio_periodo->ymd('-')) {
				
					my $datacollect = 1;
					
					my $nome_file_immagine = $_;
					$nome_file_immagine =~ s/TXT$/JRN/ig;
					
					my $immagine = 0;
					if (-e "$image_folder/$cartella/$nome_file_immagine") {
						$immagine = 1
					}
					
					my $verificato = 0;
					my $totale = 0;
					if ($sth_totale->execute($data, $negozio)) {
						 while(my @row = $sth_totale->fetchrow_array()) {
							$totale = $row[0];
							$verificato = $row[1]; 
						 }
					}
					
					if ($sth_file_ricevuti->execute($datacollect, $immagine, $data, $negozio)) {
						if ($totale == 0 and $verificato == 0) {                
							&CalcolaIncasso("$datacollect_folder/$cartella/$_");
						}
					} else {
						print "record $negozio, $data non presente\n";
					}
				}
			}
		}
	}
    $sth_file_da_ricevere->finish();
    $sth_file_ricevuti->finish();
    $sth_totale->finish();
}

sub ConnessioneDB {
	my $dbh;
	my $sth;
    
	# connessione al database di default
	$dbh = DBI->connect("DBI:mysql:mysql:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database di default!\n";
		return 0;
	}
	# creazione del database archivi
	$sth = $dbh->prepare(qq{
		CREATE DATABASE IF NOT EXISTS `$database`
		DEFAULT CHARACTER SET = latin1
		DEFAULT COLLATE       = latin1_swedish_ci
	});
	if (!$sth->execute()) {
		print "Errore durante la creazione del database `$database`! " .$dbh->errstr."\n";
		return 0;
	}
	$dbh->disconnect();
    
    
	# connessione al database
	$dbh = DBI->connect("DBI:mysql:$database:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database `$database`!\n";
		return 0;
	}
    
	# creazione della tabella negozi
	$sth = $dbh->prepare(qq{
		CREATE TABLE IF NOT EXISTS `$table_negozi` (
		`codice` varchar(4) NOT NULL DEFAULT '',
		`codice_interno` varchar(4) NOT NULL,
		`societa` varchar(2) NOT NULL,
		`societa_descrizione` varchar(100) NOT NULL DEFAULT '',
		`negozio` varchar(2) NOT NULL,
		`negozio_descrizione` varchar(100) NOT NULL DEFAULT '',
		`ip` varchar(15) NOT NULL,
		`ip_mtx` varchar(15) NOT NULL,
		`utente` varchar(50) NOT NULL,
		`password` varchar(50) NOT NULL,
		`percorso` varchar(255) NOT NULL,
		`data_inizio` date DEFAULT NULL,
		`data_fine` date DEFAULT NULL,
		`abilita` tinyint(1) NOT NULL DEFAULT '1',
		`recupero_anagdafi` tinyint(1) NOT NULL DEFAULT '0',
		`invio_dati_gre` tinyint(1) NOT NULL DEFAULT '0',
		`invio_dati_copre` tinyint(1) NOT NULL DEFAULT '0'
		) ENGINE=InnoDB DEFAULT CHARSET=latin1;
	});
	if (!$sth->execute()) {
		print "Errore durante la creazione della tabella `$table_negozi`! " .$dbh->errstr."\n";
		return 0;
	}
	$sth->finish();
    
	# creazione della tabella ricezione_dati
	$sth = $dbh->prepare(qq{
			CREATE TABLE IF NOT EXISTS`ricezione_dati` (
			`negozio` varchar(4) NOT NULL default '',
			`data` date NOT NULL,
			`giorno_settimana` tinyint(4) unsigned NOT NULL default '0',
			`settimana` tinyint(4) unsigned NOT NULL default '0',
			`datacollect` tinyint(1) unsigned NOT NULL default '0',
			`immagine` tinyint(1) unsigned NOT NULL default '0',
			`verificato` tinyint(1) unsigned NOT NULL default '0',
			`dc_epipoli_creato` tinyint(1) unsigned NOT NULL default '0',
			`dc_epipoli_errato` tinyint(1) unsigned NOT NULL default '0',
			`dc_epipoli_inviato` tinyint(1) unsigned NOT NULL default '0',
			`dc_catalina_creato` tinyint(1) unsigned NOT NULL default '0',
			`dc_catalina_inviato` tinyint(1) unsigned NOT NULL default '0',
			`riepvegi_creato` tinyint(1) unsigned NOT NULL default '0',
			`riepvegi_inviato` tinyint(1) unsigned NOT NULL default '0',
			`anagdafi_caricato` tinyint(1) unsigned NOT NULL default '0',
			`incasso_totale` float NOT NULL default '0',
			`scontrini_totali` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_totale` float NOT NULL default '0',
			`scontrini_nimis_totali` int(11) unsigned NOT NULL default '0',
			`incasso_0` float NOT NULL default '0',
			`scontrini_0` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_0` float NOT NULL default '0',
			`scontrini_nimis_0` int(11) unsigned NOT NULL default '0',
			`incasso_1` float NOT NULL default '0',
			`scontrini_1` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_1` float NOT NULL default '0',
			`scontrini_nimis_1` int(11) unsigned NOT NULL default '0',
			`incasso_2` float NOT NULL default '0',
			`scontrini_2` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_2` float NOT NULL default '0',
			`scontrini_nimis_2` int(11) unsigned NOT NULL default '0',
			`incasso_3` float NOT NULL default '0',
			`scontrini_3` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_3` float NOT NULL default '0',
			`scontrini_nimis_3` int(11) unsigned NOT NULL default '0',
			`incasso_4` float NOT NULL default '0',
			`scontrini_4` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_4` float NOT NULL default '0',
			`scontrini_nimis_4` int(11) unsigned NOT NULL default '0',
			`incasso_5` float NOT NULL default '0',
			`scontrini_5` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_5` float NOT NULL default '0',
			`scontrini_nimis_5` int(11) unsigned NOT NULL default '0',
			`incasso_6` float NOT NULL default '0',
			`scontrini_6` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_6` float NOT NULL default '0',
			`scontrini_nimis_6` int(11) unsigned NOT NULL default '0',
			`incasso_7` float NOT NULL default '0',
			`scontrini_7` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_7` float NOT NULL default '0',
			`scontrini_nimis_7` int(11) unsigned NOT NULL default '0',
			`incasso_8` float NOT NULL default '0',
			`scontrini_8` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_8` float NOT NULL default '0',
			`scontrini_nimis_8` int(11) unsigned NOT NULL default '0',
			`incasso_9` float NOT NULL default '0',
			`scontrini_9` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_9` float NOT NULL default '0',
			`scontrini_nimis_9` int(11) unsigned NOT NULL default '0',
			`incasso_10` float NOT NULL default '0',
			`scontrini_10` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_10` float NOT NULL default '0',
			`scontrini_nimis_10` int(11) unsigned NOT NULL default '0',
			`incasso_11` float NOT NULL default '0',
			`scontrini_11` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_11` float NOT NULL default '0',
			`scontrini_nimis_11` int(11) unsigned NOT NULL default '0',
			`incasso_12` float NOT NULL default '0',
			`scontrini_12` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_12` float NOT NULL default '0',
			`scontrini_nimis_12` int(11) unsigned NOT NULL default '0',
			`incasso_13` float NOT NULL default '0',
			`scontrini_13` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_13` float NOT NULL default '0',
			`scontrini_nimis_13` int(11) unsigned NOT NULL default '0',
			`incasso_14` float NOT NULL default '0',
			`scontrini_14` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_14` float NOT NULL default '0',
			`scontrini_nimis_14` int(11) unsigned NOT NULL default '0',
			`incasso_15` float NOT NULL default '0',
			`scontrini_15` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_15` float NOT NULL default '0',
			`scontrini_nimis_15` int(11) unsigned NOT NULL default '0',
			`incasso_16` float NOT NULL default '0',
			`scontrini_16` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_16` float NOT NULL default '0',
			`scontrini_nimis_16` int(11) unsigned NOT NULL default '0',
			`incasso_17` float NOT NULL default '0',
			`scontrini_17` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_17` float NOT NULL default '0',
			`scontrini_nimis_17` int(11) unsigned NOT NULL default '0',
			`incasso_18` float NOT NULL default '0',
			`scontrini_18` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_18` float NOT NULL default '0',
			`scontrini_nimis_18` int(11) unsigned NOT NULL default '0',
			`incasso_19` float NOT NULL default '0',
			`scontrini_19` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_19` float NOT NULL default '0',
			`scontrini_nimis_19` int(11) unsigned NOT NULL default '0',
			`incasso_20` float NOT NULL default '0',
			`scontrini_20` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_20` float NOT NULL default '0',
			`scontrini_nimis_20` int(11) unsigned NOT NULL default '0',
			`incasso_21` float NOT NULL default '0',
			`scontrini_21` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_21` float NOT NULL default '0',
			`scontrini_nimis_21` int(11) unsigned NOT NULL default '0',
			`incasso_22` float NOT NULL default '0',
			`scontrini_22` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_22` float NOT NULL default '0',
			`scontrini_nimis_22` int(11) unsigned NOT NULL default '0',
			`incasso_23` float NOT NULL default '0',
			`scontrini_23` int(11) unsigned NOT NULL default '0',
			`incasso_nimis_23` float NOT NULL default '0',
			`scontrini_nimis_23` int(11) unsigned NOT NULL default '0',
			PRIMARY KEY  (`negozio`,`data`)
			) ENGINE=InnoDB DEFAULT CHARSET=latin1;
	});
	if (!$sth->execute()) {
		print "Errore durante la creazione della tabella `$table_ricezione_dati`! " .$dbh->errstr."\n";
		return 0;
	}
	$sth->finish();
    
	# recupero l'elenco dei negozi da cui prelevare i dati
	my $data_corrente = $current_date->ymd('-');
	$sth = $dbh->prepare(qq{SELECT codice, negozio_descrizione, ip, utente, password, percorso, data_inizio, ifnull(data_fine,'0000-00-00') from `$table_negozi` where data_fine is null and abilita = 1 ORDER BY codice});
	if ($sth->execute()) {
		while(my @row = $sth->fetchrow_array()) {
        push @negozi_codice, $row[0];
        push @negozi_descrizione, $row[1];
        push @negozi_ip, $row[2];
        push @negozi_utente, $row[3];
        push @negozi_password, $row[4];
        push @negozi_percorso, $row[5];
        if ($row[6] =~ /^(\d{4})\-(\d{2})\-(\d{2})$/) {
                push @negozi_data_inizio, DateTime->new(day=>$3,month=>$2,year=>$1);
        }
        if ($row[7] eq '0000-00-00') {
                push @negozi_data_fine, DateTime->new(day=>'01',month=>'01',year=>'2050');
        } else {
                if ($row[7] =~ /^(\d{4})\-(\d{2})\-(\d{2})$/) {
                        push @negozi_data_fine, DateTime->new(day=>$3,month=>$2,year=>$1);
                }
        }
		}
	}
	
	# preparo le query
	$sth = $dbh->prepare(qq{INSERT IGNORE INTO`$table_ricezione_dati` (`negozio`, `data`, `datacollect`, `immagine`, `verificato`, `giorno_settimana`, `settimana`)
						    VALUES (?,?,0,0,0,?,?)});
	my $sth_count = $dbh->prepare(qq{SELECT COUNT(*) FROM `$table_ricezione_dati` WHERE `negozio` = ?});
	my $sth_ultima_data = $dbh->prepare(qq{SELECT MAX(`data`) FROM `$table_ricezione_dati` WHERE `negozio` = ?});
    
    # verifico che nella tabella ricezione_dati siano presenti i record di ogni giornata per ogni negozio
	for (my $i=0;$i<@negozi_codice;$i++) {
        my $date = $data_inizio_periodo->clone();
		while ( DateTime->compare( $date, $current_date ) <= 0  ) {
                if (DateTime->compare($date, $negozi_data_inizio[$i]) >= 0 and DateTime->compare($date, $negozi_data_fine[$i]) <= 0) {
                        $sth->execute($negozi_codice[$i],$date->ymd('-'), $date->day_of_week(), $date->week_number());
                }
				$date->add(days =>1);
		}
	}
  
	$sth_ultima_data->finish();
	$sth_count->finish();
	$sth->finish();
	
	$sth_file_da_ricevere = $dbh->prepare(qq{SELECT `data`, `datacollect`, `immagine` FROM `$table_ricezione_dati` WHERE `negozio` = ? AND `verificato` = 0 ORDER BY `data`});
	$sth_file_ricevuti = $dbh->prepare(qq{UPDATE `$table_ricezione_dati` SET `datacollect` = ?, `immagine` = ?, `verificato` = (`datacollect`+`immagine` = 2)
											     WHERE `data` = ? AND `negozio` = ?});
  $sth_totale = $dbh->prepare(qq{SELECT `incasso_totale`, `verificato` FROM `$table_ricezione_dati` WHERE `data` = ? AND `negozio` = ?});

	$sth_carica_giornata = $dbh->prepare(qq{SELECT * FROM `$table_ricezione_dati` WHERE `data` = ? AND `negozio` = ?});
	$sth_aggiorna_giornata = $dbh->prepare(qq{UPDATE `$table_ricezione_dati` SET
												incasso_totale = ?,
												scontrini_totali = ?,
												incasso_nimis_totale = ?,
												scontrini_nimis_totali = ?,
												incasso_0 = ?,
												scontrini_0 = ?,
												incasso_nimis_0 = ?,
												scontrini_nimis_0 = ?,
												incasso_1 = ?,
												scontrini_1 = ?,
												incasso_nimis_1 = ?,
												scontrini_nimis_1 = ?,
												incasso_2 = ?,
												scontrini_2 = ?,
												incasso_nimis_2 = ?,
												scontrini_nimis_2 = ?,
												incasso_3 = ?,
												scontrini_3 = ?,
												incasso_nimis_3 = ?,
												scontrini_nimis_3 = ?,
												incasso_4 = ?,
												scontrini_4 = ?,
												incasso_nimis_4 = ?,
												scontrini_nimis_4 = ?,
												incasso_5 = ?,
												scontrini_5 = ?,
												incasso_nimis_5 = ?,
												scontrini_nimis_5 = ?,
												incasso_6 = ?,
												scontrini_6 = ?,
												incasso_nimis_6 = ?,
												scontrini_nimis_6 = ?,
												incasso_7 = ?,
												scontrini_7 = ?,
												incasso_nimis_7 = ?,
												scontrini_nimis_7 = ?,
												incasso_8 = ?,
												scontrini_8 = ?,
												incasso_nimis_8 = ?,
												scontrini_nimis_8 = ?,
												incasso_9 = ?,
												scontrini_9 = ?,
												incasso_nimis_9 = ?,
												scontrini_nimis_9 = ?,
												incasso_10 = ?,
												scontrini_10 = ?,
												incasso_nimis_10 = ?,
												scontrini_nimis_10 = ?,
												incasso_11 = ?,
												scontrini_11 = ?,
												incasso_nimis_11 = ?,
												scontrini_nimis_11 = ?,
												incasso_12 = ?,
												scontrini_12 = ?,
												incasso_nimis_12 = ?,
												scontrini_nimis_12 = ?,
												incasso_13 = ?,
												scontrini_13 = ?,
												incasso_nimis_13 = ?,
												scontrini_nimis_13 = ?,
												incasso_14 = ?,
												scontrini_14 = ?,
												incasso_nimis_14 = ?,
												scontrini_nimis_14 = ?,
												incasso_15 = ?,
												scontrini_15 = ?,
												incasso_nimis_15 = ?,
												scontrini_nimis_15 = ?,
												incasso_16 = ?,
												scontrini_16 = ?,
												incasso_nimis_16 = ?,
												scontrini_nimis_16 = ?,
												incasso_17 = ?,
												scontrini_17 = ?,
												incasso_nimis_17 = ?,
												scontrini_nimis_17 = ?,
												incasso_18 = ?,
												scontrini_18 = ?,
												incasso_nimis_18 = ?,
												scontrini_nimis_18 = ?,
												incasso_19 = ?,
												scontrini_19 = ?,
												incasso_nimis_19 = ?,
												scontrini_nimis_19 = ?,
												incasso_20 = ?,
												scontrini_20 = ?,
												incasso_nimis_20 = ?,
												scontrini_nimis_20 = ?,
												incasso_21 = ?,
												scontrini_21 = ?,
												incasso_nimis_21 = ?,
												scontrini_nimis_21 = ?,
												incasso_22 = ?,
												scontrini_22 = ?,
												incasso_nimis_22 = ?,
												scontrini_nimis_22 = ?,
												incasso_23 = ?,
												scontrini_23 = ?,
												incasso_nimis_23 = ?,
												scontrini_nimis_23 = ?
											WHERE `data` = ? AND `negozio` = ?});
}

sub CalcolaIncasso {
	my ($file_name) = @_; # nome file completo di percorso
	my $id;
	my $negozio;
	my $data;
	my $giorno;
	my $mese;
	my $anno;
	my $dow;
	my $settimana;
	my $ora;
	my $nimis;
	my $incasso;
	
	my $line;
	
	if (open my $file_handler, "<:crlf", "$file_name") {
		my $data_precedente 	= '';
		my $negozio_precedente 	= '';
		
		while(! eof ($file_handler))  {
			$line = <$file_handler>;
			$line =~ s/\n$//ig;
			
			# scontrino
			if ($line =~ /^(\d{4}):(\d{3}):(\d{2})(\d{2})(\d{2}):(\d{2})\d{4}:\d{4}:\d{3}:F:1.{11}(.{3}).{19}(\+|\-)(\d{7})(\d{2})$/) {
				$data		= '20'.$3.'-'.$4.'-'.$5;
				$giorno		= $5;
				$mese		= $4;
				$anno		= '20'.$3;
				$dow		= DateTime->new(day=>$giorno, month=>$mese ,year=>$anno)->day_of_week();
				$settimana	= DateTime->new(day=>$giorno, month=>$mese ,year=>$anno)->week_number();
				$ora		= $6;
				$nimis		= ($7 eq '046');
				$incasso	= ($8.$9.".".$10)*1;
				
				# aggiunto per ovviare alla presenza dei vecchi codice nei dc Family, Zerbi, Brescia..
				# ------------------------------------------------------------------------------------
				if ($file_name =~ /^.*(\d{4})_\d{8}_\d{6}_DC\.TXT$/) {
					$negozio = $1;
				}
				
				if (($data ne $data_precedente) || ($negozio ne $negozio_precedente)){
				
					&new_record();
					if ($sth_carica_giornata->execute($data, $negozio)) {
						# carico il record
						if (my @db_record = $sth_carica_giornata->fetchrow_array()) {
							$record{'incasso_totale'} = $db_record[8];
							$record{'scontrini_totali'} = $db_record[9];
							$record{'incasso_nimis_totale'} = $db_record[10];
							$record{'scontrini_nimis_totali'} = $db_record[11];
							$record{'incasso_0'} = $db_record[12];
							$record{'scontrini_0'} = $db_record[13];
							$record{'incasso_nimis_0'} = $db_record[14];
							$record{'scontrini_nimis_0'} = $db_record[15];
							$record{'incasso_1'} = $db_record[16];
							$record{'scontrini_1'} = $db_record[17];
							$record{'incasso_nimis_1'} = $db_record[18];
							$record{'scontrini_nimis_1'} = $db_record[19];
							$record{'incasso_2'} = $db_record[20];
							$record{'scontrini_2'} = $db_record[21];
							$record{'incasso_nimis_2'} = $db_record[22];
							$record{'scontrini_nimis_2'} = $db_record[23];
							$record{'incasso_3'} = $db_record[24];
							$record{'scontrini_3'} = $db_record[25];
							$record{'incasso_nimis_3'} = $db_record[26];
							$record{'scontrini_nimis_3'} = $db_record[27];
							$record{'incasso_4'} = $db_record[28];
							$record{'scontrini_4'} = $db_record[29];
							$record{'incasso_nimis_4'} = $db_record[30];
							$record{'scontrini_nimis_4'} = $db_record[31];
							$record{'incasso_5'} = $db_record[32];
							$record{'scontrini_5'} = $db_record[33];
							$record{'incasso_nimis_5'} = $db_record[34];
							$record{'scontrini_nimis_5'} = $db_record[35];
							$record{'incasso_6'} = $db_record[36];
							$record{'scontrini_6'} = $db_record[37];
							$record{'incasso_nimis_6'} = $db_record[38];
							$record{'scontrini_nimis_6'} = $db_record[39];
							$record{'incasso_7'} = $db_record[40];
							$record{'scontrini_7'} = $db_record[41];
							$record{'incasso_nimis_7'} = $db_record[42];
							$record{'scontrini_nimis_7'} = $db_record[43];
							$record{'incasso_8'} = $db_record[44];
							$record{'scontrini_8'} = $db_record[45];
							$record{'incasso_nimis_8'} = $db_record[46];
							$record{'scontrini_nimis_8'} = $db_record[47];
							$record{'incasso_9'} = $db_record[48];
							$record{'scontrini_9'} = $db_record[49];
							$record{'incasso_nimis_9'} = $db_record[50];
							$record{'scontrini_nimis_9'} = $db_record[51];
							$record{'incasso_10'} = $db_record[52];
							$record{'scontrini_10'} = $db_record[53];
							$record{'incasso_nimis_10'} = $db_record[54];
							$record{'scontrini_nimis_10'} = $db_record[55];
							$record{'incasso_11'} = $db_record[56];
							$record{'scontrini_11'} = $db_record[57];
							$record{'incasso_nimis_11'} = $db_record[58];
							$record{'scontrini_nimis_11'} = $db_record[59];
							$record{'incasso_12'} = $db_record[60];
							$record{'scontrini_12'} = $db_record[61];
							$record{'incasso_nimis_12'} = $db_record[62];
							$record{'scontrini_nimis_12'} = $db_record[63];
							$record{'incasso_13'} = $db_record[64];
							$record{'scontrini_13'} = $db_record[65];
							$record{'incasso_nimis_13'} = $db_record[66];
							$record{'scontrini_nimis_13'} = $db_record[67];
							$record{'incasso_14'} = $db_record[68];
							$record{'scontrini_14'} = $db_record[69];
							$record{'incasso_nimis_14'} = $db_record[70];
							$record{'scontrini_nimis_14'} = $db_record[71];
							$record{'incasso_15'} = $db_record[72];
							$record{'scontrini_15'} = $db_record[73];
							$record{'incasso_nimis_15'} = $db_record[74];
							$record{'scontrini_nimis_15'} = $db_record[75];
							$record{'incasso_16'} = $db_record[76];
							$record{'scontrini_16'} = $db_record[77];
							$record{'incasso_nimis_16'} = $db_record[78];
							$record{'scontrini_nimis_16'} = $db_record[79];
							$record{'incasso_17'} = $db_record[80];
							$record{'scontrini_17'} = $db_record[81];
							$record{'incasso_nimis_17'} = $db_record[82];
							$record{'scontrini_nimis_17'} = $db_record[83];
							$record{'incasso_18'} = $db_record[84];
							$record{'scontrini_18'} = $db_record[85];
							$record{'incasso_nimis_18'} = $db_record[86];
							$record{'scontrini_nimis_18'} = $db_record[87];
							$record{'incasso_19'} = $db_record[88];
							$record{'scontrini_19'} = $db_record[89];
							$record{'incasso_nimis_19'} = $db_record[90];
							$record{'scontrini_nimis_19'} = $db_record[91];
							$record{'incasso_20'} = $db_record[92];
							$record{'scontrini_20'} = $db_record[93];
							$record{'incasso_nimis_20'} = $db_record[94];
							$record{'scontrini_nimis_20'} = $db_record[95];
							$record{'incasso_21'} = $db_record[96];
							$record{'scontrini_21'} = $db_record[97];
							$record{'incasso_nimis_21'} = $db_record[98];
							$record{'scontrini_nimis_21'} = $db_record[99];
							$record{'incasso_22'} = $db_record[100];
							$record{'scontrini_22'} = $db_record[101];
							$record{'incasso_nimis_22'} = $db_record[102];
							$record{'scontrini_nimis_22'} = $db_record[103];
							$record{'incasso_23'} = $db_record[104];
							$record{'scontrini_23'} = $db_record[105];
							$record{'incasso_nimis_23'} = $db_record[106];
							$record{'scontrini_nimis_23'} = $db_record[107];
						}
					}
				} else {
						# ora aggiorno il record
						$sth_aggiorna_giornata->execute(
								$record{'incasso_totale'} ,
								$record{'scontrini_totali'} ,
								$record{'incasso_nimis_totale'} ,
								$record{'scontrini_nimis_totali'} ,
								$record{'incasso_0'} ,
								$record{'scontrini_0'} ,
								$record{'incasso_nimis_0'} ,
								$record{'scontrini_nimis_0'} ,
								$record{'incasso_1'} ,
								$record{'scontrini_1'} ,
								$record{'incasso_nimis_1'} ,
								$record{'scontrini_nimis_1'} ,
								$record{'incasso_2'} ,
								$record{'scontrini_2'} ,
								$record{'incasso_nimis_2'} ,
								$record{'scontrini_nimis_2'} ,
								$record{'incasso_3'} ,
								$record{'scontrini_3'} ,
								$record{'incasso_nimis_3'} ,
								$record{'scontrini_nimis_3'} ,
								$record{'incasso_4'} ,
								$record{'scontrini_4'} ,
								$record{'incasso_nimis_4'} ,
								$record{'scontrini_nimis_4'} ,
								$record{'incasso_5'} ,
								$record{'scontrini_5'} ,
								$record{'incasso_nimis_5'} ,
								$record{'scontrini_nimis_5'} ,
								$record{'incasso_6'} ,
								$record{'scontrini_6'} ,
								$record{'incasso_nimis_6'} ,
								$record{'scontrini_nimis_6'} ,
								$record{'incasso_7'} ,
								$record{'scontrini_7'} ,
								$record{'incasso_nimis_7'} ,
								$record{'scontrini_nimis_7'} ,
								$record{'incasso_8'} ,
								$record{'scontrini_8'} ,
								$record{'incasso_nimis_8'} ,
								$record{'scontrini_nimis_8'} ,
								$record{'incasso_9'} ,
								$record{'scontrini_9'} ,
								$record{'incasso_nimis_9'} ,
								$record{'scontrini_nimis_9'} ,
								$record{'incasso_10'} ,
								$record{'scontrini_10'} ,
								$record{'incasso_nimis_10'} ,
								$record{'scontrini_nimis_10'} ,
								$record{'incasso_11'} ,
								$record{'scontrini_11'} ,
								$record{'incasso_nimis_11'} ,
								$record{'scontrini_nimis_11'} ,
								$record{'incasso_12'} ,
								$record{'scontrini_12'} ,
								$record{'incasso_nimis_12'} ,
								$record{'scontrini_nimis_12'} ,
								$record{'incasso_13'} ,
								$record{'scontrini_13'} ,
								$record{'incasso_nimis_13'} ,
								$record{'scontrini_nimis_13'} ,
								$record{'incasso_14'} ,
								$record{'scontrini_14'} ,
								$record{'incasso_nimis_14'} ,
								$record{'scontrini_nimis_14'} ,
								$record{'incasso_15'} ,
								$record{'scontrini_15'} ,
								$record{'incasso_nimis_15'} ,
								$record{'scontrini_nimis_15'} ,
								$record{'incasso_16'} ,
								$record{'scontrini_16'} ,
								$record{'incasso_nimis_16'} ,
								$record{'scontrini_nimis_16'} ,
								$record{'incasso_17'} ,
								$record{'scontrini_17'} ,
								$record{'incasso_nimis_17'} ,
								$record{'scontrini_nimis_17'} ,
								$record{'incasso_18'} ,
								$record{'scontrini_18'} ,
								$record{'incasso_nimis_18'} ,
								$record{'scontrini_nimis_18'} ,
								$record{'incasso_19'} ,
								$record{'scontrini_19'} ,
								$record{'incasso_nimis_19'} ,
								$record{'scontrini_nimis_19'} ,
								$record{'incasso_20'} ,
								$record{'scontrini_20'} ,
								$record{'incasso_nimis_20'} ,
								$record{'scontrini_nimis_20'} ,
								$record{'incasso_21'} ,
								$record{'scontrini_21'} ,
								$record{'incasso_nimis_21'} ,
								$record{'scontrini_nimis_21'} ,
								$record{'incasso_22'} ,
								$record{'scontrini_22'} ,
								$record{'incasso_nimis_22'} ,
								$record{'scontrini_nimis_22'} ,
								$record{'incasso_23'} ,
								$record{'scontrini_23'} ,
								$record{'incasso_nimis_23'} ,
								$record{'scontrini_nimis_23'},
								$data,
								$negozio
					);
				}
				
				$data_precedente 	= $data;
				$negozio_precedente = $negozio;
				
				# aggiungo alla giornata esistente/appena creata i dati dello scontrino corrente
				$record{'incasso_totale'} += $incasso;
				$record{'scontrini_totali'} += 1;
				if ($nimis) {
					$record{'incasso_nimis_totale'} += $incasso;
					$record{'scontrini_nimis_totali'} += 1;
				}
				
				if ($ora eq '00') {
					$record{'incasso_0'} += $incasso;
					$record{'scontrini_0'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_0'} += $incasso;
						$record{'scontrini_nimis_0'} += 1;
					}
				} elsif ($ora eq '01') {
					$record{'incasso_1'} += $incasso;
					$record{'scontrini_1'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_1'} += $incasso;
						$record{'scontrini_nimis_1'} += 1;
					}
				} elsif ($ora eq '02') {
					$record{'incasso_2'} += $incasso;
					$record{'scontrini_2'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_2'} += $incasso;
						$record{'scontrini_nimis_2'} += 1;
					}
				} elsif ($ora eq '03') {
					$record{'incasso_3'} += $incasso;
					$record{'scontrini_3'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_3'} += $incasso;
						$record{'scontrini_nimis_3'} += 1;
					}
				} elsif ($ora eq '04') {
					$record{'incasso_4'} += $incasso;
					$record{'scontrini_4'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_4'} += $incasso;
						$record{'scontrini_nimis_4'} += 1;
					}
				} elsif ($ora eq '05') {
					$record{'incasso_5'} += $incasso;
					$record{'scontrini_5'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_5'} += $incasso;
						$record{'scontrini_nimis_5'} += 1;
					}
				} elsif ($ora eq '06') {
					$record{'incasso_6'} += $incasso;
					$record{'scontrini_6'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_6'} += $incasso;
						$record{'scontrini_nimis_6'} += 1;
					}
				} elsif ($ora eq '07') {
					$record{'incasso_7'} += $incasso;
					$record{'scontrini_7'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_7'} += $incasso;
						$record{'scontrini_nimis_7'} += 1;
					}
				} elsif ($ora eq '08') {
					$record{'incasso_8'} += $incasso;
					$record{'scontrini_8'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_8'} += $incasso;
						$record{'scontrini_nimis_8'} += 1;
					}
				} elsif ($ora eq '09') {
					$record{'incasso_9'} += $incasso;
					$record{'scontrini_9'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_9'} += $incasso;
						$record{'scontrini_nimis_9'} += 1;
					}
				} elsif ($ora eq '10') {
					$record{'incasso_10'} += $incasso;
					$record{'scontrini_10'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_10'} += $incasso;
						$record{'scontrini_nimis_10'} += 1;
					}
				} elsif ($ora eq '11') {
					$record{'incasso_11'} += $incasso;
					$record{'scontrini_11'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_11'} += $incasso;
						$record{'scontrini_nimis_11'} += 1;
					}
				} elsif ($ora eq '12') {
					$record{'incasso_12'} += $incasso;
					$record{'scontrini_12'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_12'} += $incasso;
						$record{'scontrini_nimis_12'} += 1;
					}
				} elsif ($ora eq '13') {
					$record{'incasso_13'} += $incasso;
					$record{'scontrini_13'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_13'} += $incasso;
						$record{'scontrini_nimis_13'} += 1;
					}
				} elsif ($ora eq '14') {
					$record{'incasso_14'} += $incasso;
					$record{'scontrini_14'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_14'} += $incasso;
						$record{'scontrini_nimis_14'} += 1;
					}
				} elsif ($ora eq '15') {
					$record{'incasso_15'} += $incasso;
					$record{'scontrini_15'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_15'} += $incasso;
						$record{'scontrini_nimis_15'} += 1;
					}
				} elsif ($ora eq '16') {
					$record{'incasso_16'} += $incasso;
					$record{'scontrini_16'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_16'} += $incasso;
						$record{'scontrini_nimis_16'} += 1;
					}
				} elsif ($ora eq '17') {
					$record{'incasso_17'} += $incasso;
					$record{'scontrini_17'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_17'} += $incasso;
						$record{'scontrini_nimis_17'} += 1;
					}
				} elsif ($ora eq '18') {
					$record{'incasso_18'} += $incasso;
					$record{'scontrini_18'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_18'} += $incasso;
						$record{'scontrini_nimis_18'} += 1;
					}
				} elsif ($ora eq '19') {
					$record{'incasso_19'} += $incasso;
					$record{'scontrini_19'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_19'} += $incasso;
						$record{'scontrini_nimis_19'} += 1;
					}
				} elsif ($ora eq '20') {
					$record{'incasso_20'} += $incasso;
					$record{'scontrini_20'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_20'} += $incasso;
						$record{'scontrini_nimis_20'} += 1;
					}
				} elsif ($ora eq '21') {
					$record{'incasso_21'} += $incasso;
					$record{'scontrini_21'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_21'} += $incasso;
						$record{'scontrini_nimis_21'} += 1;
					}
				} elsif ($ora eq '22') {
					$record{'incasso_22'} += $incasso;
					$record{'scontrini_22'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_22'} += $incasso;
						$record{'scontrini_nimis_22'} += 1;
					}
				} elsif ($ora eq '23') {
					$record{'incasso_23'} += $incasso;
					$record{'scontrini_23'} += 1;
					if ($nimis) {
						$record{'incasso_nimis_23'} += $incasso;
						$record{'scontrini_nimis_23'} += 1;
					}
				}
			}  
		}
		close($file_handler);
	
		$sth_aggiorna_giornata->execute(
									$record{'incasso_totale'} ,
									$record{'scontrini_totali'} ,
									$record{'incasso_nimis_totale'} ,
									$record{'scontrini_nimis_totali'} ,
									$record{'incasso_0'} ,
									$record{'scontrini_0'} ,
									$record{'incasso_nimis_0'} ,
									$record{'scontrini_nimis_0'} ,
									$record{'incasso_1'} ,
									$record{'scontrini_1'} ,
									$record{'incasso_nimis_1'} ,
									$record{'scontrini_nimis_1'} ,
									$record{'incasso_2'} ,
									$record{'scontrini_2'} ,
									$record{'incasso_nimis_2'} ,
									$record{'scontrini_nimis_2'} ,
									$record{'incasso_3'} ,
									$record{'scontrini_3'} ,
									$record{'incasso_nimis_3'} ,
									$record{'scontrini_nimis_3'} ,
									$record{'incasso_4'} ,
									$record{'scontrini_4'} ,
									$record{'incasso_nimis_4'} ,
									$record{'scontrini_nimis_4'} ,
									$record{'incasso_5'} ,
									$record{'scontrini_5'} ,
									$record{'incasso_nimis_5'} ,
									$record{'scontrini_nimis_5'} ,
									$record{'incasso_6'} ,
									$record{'scontrini_6'} ,
									$record{'incasso_nimis_6'} ,
									$record{'scontrini_nimis_6'} ,
									$record{'incasso_7'} ,
									$record{'scontrini_7'} ,
									$record{'incasso_nimis_7'} ,
									$record{'scontrini_nimis_7'} ,
									$record{'incasso_8'} ,
									$record{'scontrini_8'} ,
									$record{'incasso_nimis_8'} ,
									$record{'scontrini_nimis_8'} ,
									$record{'incasso_9'} ,
									$record{'scontrini_9'} ,
									$record{'incasso_nimis_9'} ,
									$record{'scontrini_nimis_9'} ,
									$record{'incasso_10'} ,
									$record{'scontrini_10'} ,
									$record{'incasso_nimis_10'} ,
									$record{'scontrini_nimis_10'} ,
									$record{'incasso_11'} ,
									$record{'scontrini_11'} ,
									$record{'incasso_nimis_11'} ,
									$record{'scontrini_nimis_11'} ,
									$record{'incasso_12'} ,
									$record{'scontrini_12'} ,
									$record{'incasso_nimis_12'} ,
									$record{'scontrini_nimis_12'} ,
									$record{'incasso_13'} ,
									$record{'scontrini_13'} ,
									$record{'incasso_nimis_13'} ,
									$record{'scontrini_nimis_13'} ,
									$record{'incasso_14'} ,
									$record{'scontrini_14'} ,
									$record{'incasso_nimis_14'} ,
									$record{'scontrini_nimis_14'} ,
									$record{'incasso_15'} ,
									$record{'scontrini_15'} ,
									$record{'incasso_nimis_15'} ,
									$record{'scontrini_nimis_15'} ,
									$record{'incasso_16'} ,
									$record{'scontrini_16'} ,
									$record{'incasso_nimis_16'} ,
									$record{'scontrini_nimis_16'} ,
									$record{'incasso_17'} ,
									$record{'scontrini_17'} ,
									$record{'incasso_nimis_17'} ,
									$record{'scontrini_nimis_17'} ,
									$record{'incasso_18'} ,
									$record{'scontrini_18'} ,
									$record{'incasso_nimis_18'} ,
									$record{'scontrini_nimis_18'} ,
									$record{'incasso_19'} ,
									$record{'scontrini_19'} ,
									$record{'incasso_nimis_19'} ,
									$record{'scontrini_nimis_19'} ,
									$record{'incasso_20'} ,
									$record{'scontrini_20'} ,
									$record{'incasso_nimis_20'} ,
									$record{'scontrini_nimis_20'} ,
									$record{'incasso_21'} ,
									$record{'scontrini_21'} ,
									$record{'incasso_nimis_21'} ,
									$record{'scontrini_nimis_21'} ,
									$record{'incasso_22'} ,
									$record{'scontrini_22'} ,
									$record{'incasso_nimis_22'} ,
									$record{'scontrini_nimis_22'} ,
									$record{'incasso_23'} ,
									$record{'scontrini_23'} ,
									$record{'incasso_nimis_23'} ,
									$record{'scontrini_nimis_23'},
									$data,
									$negozio
						);
	}
}	

sub new_record {
	undef(%record);
	
	$record{'giorno'} = '';
	$record{'giorno_settimana'} = '';
	$record{'settimana'} = 0;
	$record{'mese'} = '';
	$record{'anno'} = '';
	$record{'tipo_giornata'} = '';
	$record{'negozio_chiuso'} = 0;
	$record{'incasso_totale'} = 0;
	$record{'scontrini_totali'} = 0;
	$record{'incasso_nimis_totale'} = 0;
	$record{'scontrini_nimis_totali'} = 0;
	$record{'incasso_0'} = 0;
	$record{'scontrini_0'} = 0;
	$record{'incasso_nimis_0'} = 0;
	$record{'scontrini_nimis_0'} = 0;
	$record{'incasso_1'} = 0;
	$record{'scontrini_1'} = 0;
	$record{'incasso_nimis_1'} = 0;
	$record{'scontrini_nimis_1'} = 0;
	$record{'incasso_2'} = 0;
	$record{'scontrini_2'} = 0;
	$record{'incasso_nimis_2'} = 0;
	$record{'scontrini_nimis_2'} = 0;
	$record{'incasso_3'} = 0;
	$record{'scontrini_3'} = 0;
	$record{'incasso_nimis_3'} = 0;
	$record{'scontrini_nimis_3'} = 0;
	$record{'incasso_4'} = 0;
	$record{'scontrini_4'} = 0;
	$record{'incasso_nimis_4'} = 0;
	$record{'scontrini_nimis_4'} = 0;
	$record{'incasso_5'} = 0;
	$record{'scontrini_5'} = 0;
	$record{'incasso_nimis_5'} = 0;
	$record{'scontrini_nimis_5'} = 0;
	$record{'incasso_6'} = 0;
	$record{'scontrini_6'} = 0;
	$record{'incasso_nimis_6'} = 0;
	$record{'scontrini_nimis_6'} = 0;
	$record{'incasso_7'} = 0;
	$record{'scontrini_7'} = 0;
	$record{'incasso_nimis_7'} = 0;
	$record{'scontrini_nimis_7'} = 0;
	$record{'incasso_8'} = 0;
	$record{'scontrini_8'} = 0;
	$record{'incasso_nimis_8'} = 0;
	$record{'scontrini_nimis_8'} = 0;
	$record{'incasso_9'} = 0;
	$record{'scontrini_9'} = 0;
	$record{'incasso_nimis_9'} = 0;
	$record{'scontrini_nimis_9'} = 0;
	$record{'incasso_10'} = 0;
	$record{'scontrini_10'} = 0;
	$record{'incasso_nimis_10'} = 0;
	$record{'scontrini_nimis_10'} = 0;
	$record{'incasso_11'} = 0;
	$record{'scontrini_11'} = 0;
	$record{'incasso_nimis_11'} = 0;
	$record{'scontrini_nimis_11'} = 0;
	$record{'incasso_12'} = 0;
	$record{'scontrini_12'} = 0;
	$record{'incasso_nimis_12'} = 0;
	$record{'scontrini_nimis_12'} = 0;
	$record{'incasso_13'} = 0;
	$record{'scontrini_13'} = 0;
	$record{'incasso_nimis_13'} = 0;
	$record{'scontrini_nimis_13'} = 0;
	$record{'incasso_14'} = 0;
	$record{'scontrini_14'} = 0;
	$record{'incasso_nimis_14'} = 0;
	$record{'scontrini_nimis_14'} = 0;
	$record{'incasso_15'} = 0;
	$record{'scontrini_15'} = 0;
	$record{'incasso_nimis_15'} = 0;
	$record{'scontrini_nimis_15'} = 0;
	$record{'incasso_16'} = 0;
	$record{'scontrini_16'} = 0;
	$record{'incasso_nimis_16'} = 0;
	$record{'scontrini_nimis_16'} = 0;
	$record{'incasso_17'} = 0;
	$record{'scontrini_17'} = 0;
	$record{'incasso_nimis_17'} = 0;
	$record{'scontrini_nimis_17'} = 0;
	$record{'incasso_18'} = 0;
	$record{'scontrini_18'} = 0;
	$record{'incasso_nimis_18'} = 0;
	$record{'scontrini_nimis_18'} = 0;
	$record{'incasso_19'} = 0;
	$record{'scontrini_19'} = 0;
	$record{'incasso_nimis_19'} = 0;
	$record{'scontrini_nimis_19'} = 0;
	$record{'incasso_20'} = 0;
	$record{'scontrini_20'} = 0;
	$record{'incasso_nimis_20'} = 0;
	$record{'scontrini_nimis_20'} = 0;
	$record{'incasso_21'} = 0;
	$record{'scontrini_21'} = 0;
	$record{'incasso_nimis_21'} = 0;
	$record{'scontrini_nimis_21'} = 0;
	$record{'incasso_22'} = 0;
	$record{'scontrini_22'} = 0;
	$record{'incasso_nimis_22'} = 0;
	$record{'scontrini_nimis_22'} = 0;
	$record{'incasso_23'} = 0;
	$record{'scontrini_23'} = 0;
	$record{'incasso_nimis_23'} = 0;
	$record{'scontrini_nimis_23'} = 0;
}
