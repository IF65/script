#!/usr/bin/perl -w
use strict;
use DBI; 
use File::HomeDir;
use Net::FTP;
use Net::FTP::File;
use DateTime;
use threads;
use threads::shared;
use List::Util qw(first);
				
# date
#------------------------------------------------------------------------------------------------------------
my $current_date 	= DateTime->today(time_zone=>'local');
my $starting_date	= DateTime->new(year=>2015, month=>12,day=> 1);

# definizione cartelle
#------------------------------------------------------------------------------------------------------------
my $desktop = File::HomeDir->my_desktop;
my $local_data_folder = "/dati";
my $image_folder = "$local_data_folder/immagini";
my $datacollect_folder = "$local_data_folder/datacollect";

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "localhost";
my $username = "root";
my $password = "mela";

# parametri di configurazione dei database
#------------------------------------------------------------------------------------------------------------
my $database = 'archivi';
my $table_negozi = 'negozi';
my $table_ricezione_dati = 'ricezione_dati';

# negozi attivi
#------------------------------------------------------------------------------------------------------------
my @negozi_attivi_codice: shared;
my @negozi_attivi_descrizione: shared;
my @negozi_attivi_ip: shared;
my @negozi_attivi_utente: shared;
my @negozi_attivi_password: shared;
my @negozi_attivi_percorso: shared;
my @negozi_attivi_data_inizio: shared;
my @negozi_attivi_data_fine: shared;

# date mancanti
#------------------------------------------------------------------------------------------------------------
my @date_mancanti_data: shared;
my @date_mancanti_negozio: shared;
	
# query
#------------------------------------------------------------------------------------------------------------
my $sth_datacollect_date_mancanti;
my $sth_immagini_date_mancanti;
my $sth_datacollect_verifica_record;

my %record;

# Creazione cartelle locali (se non esistono)
#------------------------------------------------------------------------------------------------------------
unless(-e $local_data_folder or mkdir $local_data_folder) {die "Impossibile creare la cartella $local_data_folder: $!\n";};
unless(-e $image_folder or mkdir $image_folder) {die "Impossibile creare la cartella $image_folder: $!\n";};
unless(-e $datacollect_folder or mkdir $datacollect_folder) {die "Impossibile creare la cartella $datacollect_folder: $!\n";};
	
my @thr;
if (&ConnessioneDB()) {
	# datacollect: carico in un array tutte le date mancanti
	if ($sth_datacollect_date_mancanti->execute()) {
		while(my @row = $sth_datacollect_date_mancanti->fetchrow_array()) {
			push @date_mancanti_data, $row[0];
			push @date_mancanti_negozio, $row[1];
		}
	}
	
	# carico i datacollect
	for (my $i=0;$i< @negozi_attivi_codice;$i++) {
		push @thr, threads->create('GetFiles',$negozi_attivi_codice[$i]);
	}
	for (my $j=0; $j< @thr;$j++) {
		$thr[$j]->join();
	}
	
	@thr = ();
	@date_mancanti_data = ();
	@date_mancanti_negozio = ();
	
	# immagini: carico in un array tutte le date mancanti
	if ($sth_immagini_date_mancanti->execute()) {
		while(my @row = $sth_immagini_date_mancanti->fetchrow_array()) {
			push @date_mancanti_data, $row[0];
			push @date_mancanti_negozio, $row[1];
		}
	}
	# carico le immagini
	for (my $i=0;$i< @negozi_attivi_codice;$i++) {
		push @thr, threads->create('GetFilesIMG',$negozi_attivi_codice[$i]);
	}
	for (my $j=0; $j< @thr;$j++) {
		$thr[$j]->join();
	}
	
	$sth_datacollect_verifica_record->execute();
}


sub GetFiles {
	my ($negozio) = @_;
		
	my $file_handler;
		
	my $index = first { $negozi_attivi_codice[$_] eq $negozio } 0..@negozi_attivi_codice;
	
	my $ftp_url = $negozi_attivi_ip[$index];
	my $ftp_utente = $negozi_attivi_utente[$index];
	my $ftp_password = $negozi_attivi_password[$index];
	my $ftp_percorso = $negozi_attivi_percorso[$index];

	opendir my($DIR), "$datacollect_folder" or die "Non è stato possibile aprire la cartella $datacollect_folder: $!\n";
	my @elenco_cartelle = sort {$a cmp $b} grep { /^\d{8}$/ } readdir $DIR;
	closedir $DIR;
	
	if (my $ftp = Net::FTP->new($ftp_url)) {
		if ($ftp->login("$ftp_utente","$ftp_password")) { 
			$ftp->binary();
			$ftp->cwd("/$ftp_percorso");
			
			for (my $i=0;$i<@date_mancanti_data;$i++) {
				if (($date_mancanti_data[$i] =~ /^20(\d{2}\-\d{2}\-\d{2})$/) && ($negozio eq $date_mancanti_negozio[$i])){
					my $data = $1;
					$data =~ s/\-//ig;
					
					my $destination_folder = "$datacollect_folder/20$data";
					if (-e $destination_folder or mkdir $destination_folder) {
						my $nome_file_locale = $negozio.'_20'.$data.'_'.$data.'_DC.TXT';
						my $nome_file_semaforo = $negozio.'_20'.$data.'_'.$data.'_DC.CTL';
						my $nome_file_remoto = $data.'_DC.TXT';
						if ($negozio =~ /^3/ and $negozio ne '3654') {
							$nome_file_remoto =~ s/_DC\.TXT/\.idc/ig;
						}
						
						if (-e "$destination_folder/$nome_file_semaforo") {
							unlink "$destination_folder/$nome_file_semaforo";
							unlink "$destination_folder/$nome_file_locale";
						}
						
						if ($ftp->isfile($nome_file_remoto)) {
							open $file_handler, ">", "$destination_folder/$nome_file_semaforo" or die $!;
							close($file_handler);
							if ($ftp->get($nome_file_remoto, "$destination_folder/$nome_file_locale")) {
								if (-e "$destination_folder/$nome_file_semaforo") {
									unlink "$destination_folder/$nome_file_semaforo";
								}
							}
						}
					}		
				}
			}
			$ftp->quit();
		}
	}
		
	return 1;
}

sub GetFilesIMG {
	my ($negozio) = @_;
		
	my $file_handler;
		
	my $index = first { $negozi_attivi_codice[$_] eq $negozio } 0..@negozi_attivi_codice;
	
	my $ftp_url = $negozi_attivi_ip[$index];
	my $ftp_utente = $negozi_attivi_utente[$index];
	my $ftp_password = $negozi_attivi_password[$index];
	my $ftp_percorso = $negozi_attivi_percorso[$index];

	opendir my($DIR), "$image_folder" or die "Non è stato possibile aprire la cartella $image_folder: $!\n";
	my @elenco_cartelle = sort {$a cmp $b} grep { /^\d{8}$/ } readdir $DIR;
	closedir $DIR;
	
	if (my $ftp = Net::FTP->new($ftp_url)) {
		if ($ftp->login("$ftp_utente","$ftp_password")) { 
			$ftp->binary();
			$ftp->cwd("/$ftp_percorso");
			
			for (my $i=0;$i<@date_mancanti_data;$i++) {
				if (($date_mancanti_data[$i] =~ /^20(\d{2}\-\d{2}\-\d{2})$/) && ($negozio eq $date_mancanti_negozio[$i])){
					my $data = $1;
					$data =~ s/\-//ig;

					my $destination_folder = "$image_folder/20$data";
					if (-e $destination_folder or mkdir $destination_folder) {
						my $nome_file_locale 		= $negozio.'_20'.$data.'_'.$data.'_DC.JRN';
						my $nome_file_semaforo = $negozio.'_20'.$data.'_'.$data.'_DC.CTL';
						my $nome_file_remoto 		= $data.'.JRN';
						if ($negozio =~ /^3/ and $negozio ne '3654') {
							$nome_file_remoto =~ s/\.JRN/\.jrn/ig;
						}

						if (-e "$destination_folder/$nome_file_semaforo") {
							unlink "$destination_folder/$nome_file_semaforo";
							unlink "$destination_folder/$nome_file_locale";
						}

						if ($ftp->isfile($nome_file_remoto)) {
							open $file_handler, ">", "$destination_folder/$nome_file_semaforo" or die $!;
							close($file_handler);
							if ($ftp->get($nome_file_remoto, "$destination_folder/$nome_file_locale")) {
								if (-e "$destination_folder/$nome_file_semaforo") {
									unlink "$destination_folder/$nome_file_semaforo";
								}
							} else {print "$negozio, $date_mancanti_data[$i], $nome_file_remoto\n";}
						}
					}
				}
			}
			$ftp->quit();
		}
	}
		
	return 1;
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
			CREATE TABLE IF NOT EXISTS `ricezione_dati` (
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
	$sth = $dbh->prepare(qq{SELECT codice, negozio_descrizione, ip, utente, password, percorso, data_inizio, ifnull(data_fine,'0000-00-00') from `$table_negozi` WHERE codice not like '30%' ORDER BY codice});
	if ($sth->execute()) {
		while(my @row = $sth->fetchrow_array()) {
			push @negozi_attivi_codice, $row[0];
			push @negozi_attivi_descrizione, $row[1];
			push @negozi_attivi_ip, $row[2];
			push @negozi_attivi_utente, $row[3];
			push @negozi_attivi_password, $row[4];
			push @negozi_attivi_percorso, $row[5];
			push @negozi_attivi_data_inizio, $row[6];
			push @negozi_attivi_data_fine, $row[7];
		}
	}
	
	my $sth_datacollect_esiste_record = $dbh->prepare(qq{SELECT count(*) from `$table_ricezione_dati` WHERE `negozio` = ? and `data` = ?});
	my $sth_datacollect_crea_record = $dbh->prepare(qq{INSERT IGNORE INTO `$table_ricezione_dati` (`negozio`,`data`,`giorno_settimana`,`settimana`) VALUES (?,?,?,?)});
	my $sth_datacollect_update_record = $dbh->prepare(qq{UPDATE `$table_ricezione_dati` SET `datacollect` = ?, `immagine` = ? WHERE `negozio` = ? AND `data` = ?});
	
	$sth_datacollect_verifica_record = $dbh->prepare(qq{UPDATE `$table_ricezione_dati` SET `verificato` = 1 WHERE `verificato`=0 AND `datacollect`=1 AND `immagine`=1 AND `incasso_totale`<>0});
	
	for (my $i=0;$i<@negozi_attivi_codice;$i++) {
		
		# determino la data inziale per il negozio
		my $data;
		if (($negozi_attivi_data_inizio[$i] ne '0000-00-00') && ($negozi_attivi_data_inizio[$i] =~ /^(\d{4})\-(\d{2})\-(\d{2})$/)) {
			$data = DateTime->new(day=>$3,month=>$2,year=>$1);
			if (DateTime->compare( $data, $starting_date ) <= 0) {#$data <= $starting_date
				$data = $starting_date->clone();
			}
		} else {
			$data = $starting_date->clone();	
		}
		
		# determino la data finale per il negozio
		my $data_finale = $current_date -> clone();
		if (($negozi_attivi_data_fine[$i] ne '0000-00-00') && ($negozi_attivi_data_fine[$i] =~ /^(\d{4})\-(\d{2})\-(\d{2})$/)) {
			$data_finale = DateTime->new(day=>$3,month=>$2,year=>$1);
		}
		
		# verifico giorno per giorno se ci sono i record relativi al negozio e, se non esistono, li creo. Poi verifico se i file ci sono ed aggiorno i flag.
		while (DateTime->compare( $data, $data_finale ) <= 0) {
			my $cc = '';
			my $yy = '';
			my $mm = '';
			my $dd = '';
			if ($data->ymd('') =~ /^(\d\d)(\d\d)(\d\d)(\d\d)$/) {
				$cc	= $1;
				$yy	= $2;
				$mm	= $3;
				$dd	= $4;
			}
		
			my $nome_file_dc = $negozi_attivi_codice[$i].'_'.$cc.$yy.$mm.$dd.'_'.$yy.$mm.$dd.'_DC';
			
			my $datacollect	= 0;
			if (-e "$datacollect_folder/".$cc.$yy.$mm.$dd."/$nome_file_dc".'.CTL') {
				unlink "$datacollect_folder/".$cc.$yy.$mm.$dd."/$nome_file_dc".'.CTL';
				if (-e "$datacollect_folder/".$cc.$yy.$mm.$dd."/$nome_file_dc".'.TXT') {
					unlink "$datacollect_folder/".$cc.$yy.$mm.$dd."/$nome_file_dc".'.TXT';
				}
			}
			if (-e "$datacollect_folder/".$cc.$yy.$mm.$dd."/$nome_file_dc".'.TXT') {
				$datacollect	= 1;
			}
			
			my $immagine	= 0;
			if (-e "$image_folder/".$cc.$yy.$mm.$dd."/$nome_file_dc".'.CTL') {
				unlink "$image_folder/".$cc.$yy.$mm.$dd."/$nome_file_dc".'.CTL';
				if (-e "$image_folder/".$cc.$yy.$mm.$dd."/$nome_file_dc".'.JRN') {
					unlink "$image_folder/".$cc.$yy.$mm.$dd."/$nome_file_dc".'.JRN';
				}
			}
			if (-e "$image_folder/".$cc.$yy.$mm.$dd."/$nome_file_dc".'.JRN') {
				$immagine	= 1;
			}
			
			if ($sth_datacollect_esiste_record->execute($negozi_attivi_codice[$i], $data->ymd('-'))) {
				if (! $sth_datacollect_esiste_record->fetchrow_array()) {
					$sth_datacollect_crea_record->execute($negozi_attivi_codice[$i],$data->ymd('-'), $data->day_of_week(), $data->week_number());
				}
			}
			$sth_datacollect_update_record->execute($datacollect, $immagine, $negozi_attivi_codice[$i],$data->ymd('-'));
			
			$data->add(days =>1);
		}
	}
	
	$sth_datacollect_verifica_record->execute();
	
	$sth_datacollect_date_mancanti = $dbh->prepare(qq{SELECT `data`, `negozio` FROM `$table_ricezione_dati` WHERE datacollect = 0 and verificato = 0 ORDER BY `data`});
	$sth_immagini_date_mancanti = $dbh->prepare(qq{SELECT `data`,`negozio` FROM `$table_ricezione_dati` WHERE immagine = 0 and verificato = 0 ORDER BY `data`});
}
