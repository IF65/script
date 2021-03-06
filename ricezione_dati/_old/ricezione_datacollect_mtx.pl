#!/usr/bin/perl

use DBI;
use DateTime;
use Log::Log4perl;

# date
#------------------------------------------------------------------------------------------------------------
my $current_date 	= DateTime->now(time_zone=>'local');
my $current_time 	= DateTime->now(time_zone=>'local');
my $starting_date	= DateTime->new(year=>2015, month=>12, day=>17);

# definizione cartelle
#------------------------------------------------------------------------------------------------------------
my $local_data_folder = "/dati";
my $datacollect_folder = "$local_data_folder/datacollect";
my $local_log_folder = "/log";
my $log_folder = "$local_log_folder/".substr($current_date->ymd(''),0,6);

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "localhost";
my $username = "root";
my $password = "mela";

# database/tabelle in uso
#------------------------------------------------------------------------------------------------------------
my $database = 'archivi';
my $table_negozi = 'negozi';
my $table_log = 'log_ricezione';

# giornate da recuperare
#------------------------------------------------------------------------------------------------------------
my @log_codice;;
my @log_data;
	
# handler/variabili globali
#------------------------------------------------------------------------------------------------------------
my $sth;
my $dbh;
my $dbh_sybase;
my $sth_sybase;

# Creazione cartelle locali (se non esistono)
#------------------------------------------------------------------------------------------------------------
unless(-e $local_data_folder or mkdir $local_data_folder) {die "Impossibile creare la cartella $local_data_folder: $!\n";};
unless(-e $datacollect_folder or mkdir $datacollect_folder) {die "Impossibile creare la cartella $datacollect_folder: $!\n";};
unless(-e $local_log_folder or mkdir $local_log_folder) {die "Impossibile creare la cartella $local_log_folder: $!\n";};
unless(-e $log_folder or mkdir $log_folder) {die "Impossibile creare la cartella $log_folder: $!\n";};

# configurazione log
#------------------------------------------------------------------------------------------------------------
my $configurazione = q(
    log4perl.category.if65log            = INFO, Logfile, Screen

    log4perl.appender.Logfile           = Log::Log4perl::Appender::File
    log4perl.appender.Logfile.filename  = sub{log_file_name();};
    log4perl.appender.Logfile.mode      = append
    log4perl.appender.Logfile.layout    = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Logfile.layout.ConversionPattern = [%d] [%p{3}] %m %n

    log4perl.appender.Screen            = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr     = 0
    log4perl.appender.Screen.layout    = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Screen.layout.ConversionPattern = [%d] [%p{3}] %m %n
);

Log::Log4perl::init( \$configurazione ) or die "configurazione log non riuscita: $!\n";
my $logger = Log::Log4perl::get_logger("if65log");

$logger->info("-" x 76);
$logger->info("ricezione datacollect mtx");
$logger->info("-" x 76);
$logger->info("inizio");

if (&ConnessioneDB()) {
	#sistemo i flag prima di iniziare nel caso dei file fossero stati aggiunti manualmente
	$logger->info("verifica esistenza file e relativa impostazione flag (prima del caricamento)");
	&imposta_flag_presenza_file;

	#cerco le giornate/negozio da caricare
	$sth = $dbh->prepare(qq{select l.`codice`,l.`data`,concat(n.`ip_mtx`,':1433')
							from `$database`.`$table_log` as l  join `$database`.`$table_negozi` as n on l.`codice`=n.`codice`
							where l.`datacollect`= 0 and l.`verificato`= 0
							}
						);
	
	if ($sth->execute()) {
		while (my @row = $sth->fetchrow_array()) {
			my $dbh_sybase = DBI->connect("DBI:Sybase:server=$row[2]", "mtxadmin", 'mtxadmin');
			if ($dbh_sybase) {
				my $file_name = $row[0].'_'.string2date($row[1])->ymd('').'_'.substr(string2date($row[1])->ymd(''),2).'_DC.TXT';
				my $file_path = $datacollect_folder.'/'.string2date($row[1])->ymd('');
				
				$dbh_sybase->do("use mtx");
	
				$sth_sybase = $dbh_sybase->prepare (qq{	select 
															reg, 
															store, 
															replace(substring(convert(varchar, ddate, 120),3,8),'-',''), 
															ttime, 
															sequencenumber, 
															trans, 
															transstep, 
															recordtype, 
															recordcode,
															userno,
															misc,
															data
														from idc_eod 
														where ddate = '$row[1]' 
														order by ddate, reg, sequencenumber}
													);
				# *idc_eod se la giornata non è chiusa */
				if ($sth_sybase->execute()) { 
					if (open my $file_handler, "+>:crlf", "$file_path/$file_name") {
						my $row_count = 0;
						while (my @record = $sth_sybase->fetchrow_array()) {
							my $reg = $record[0];
							my $store = $record[1];
							my $ddate = $record[2];
							my $ttime = $record[3];
							my $sequencenumber = $record[4];
							my $trans = $record[5];
							my $transstep = $record[6];
							my $recordtype = $record[7];
							my $recordcode = $record[8];
							my $userno = $record[9];
							my $misc = $record[10];
							my $data = $record[11];
						
							my $mixed_field = sprintf('%04d',$userno).':'.$misc.$data;
						
							if ($recordtype =~ /z/) {
								if ($misc =~ /^(..\:)(.*)$/) {
									$mixed_field = '00'.$1.$2.$data.'000';
								}
							}
						
							if ($recordtype =~ /m/) {
								if ($misc =~ /^(..\:)(.*)$/) {
									$mixed_field = '  '.$1.$2.$data.'   ';
									if ($mixed_field =~ /^....:(0492.*)$/) {
										$mixed_field = '0000:'.$1;
									} 
								}
							}
						
							print $file_handler sprintf('%04s:%03d:%06s:%06s:%04d:%03d:%1s:%03s:',$store,$reg,$ddate,$ttime,$trans,$transstep,$recordtype,$recordcode).$mixed_field."\n";
							
							$row_count++;
						}
						close($file_handler);
						if ($row_count) {
							#sistemo i flag
							$dbh->do(qq{update `$database`.`$table_log` set `datacollect` = 2 where `codice` = '$row[0]' and `data`= '$row[1]'});
							$logger->info("FTP $row[0]: caricato il file del giorno ".string2date($row[1])->dmy('/')." ($row[2])");
						} else {
							unlink "$file_path/$file_name";
							$logger->info("FTP $row[0]: nessun record presente sulla tabella EOD di mtx per il giorno ".string2date($row[1])->dmy('/')." ($row[2])");
						}
					}
					$sth_sybase->finish();
					
				} else {
					$logger->warn("FTP $row[0]: esecuzione query per recupero datacollect non riuscita! ($row[2])");
				}
				$dbh_sybase->disconnect();
			}
		}
		$sth->finish();
	}
	
	#sistemo i flag in modo da tener conto dei file appena importati
	$logger->info("verifica esistenza file e relativa impostazione flag (dopo il caricamento)");
	&imposta_flag_presenza_file;
	
	$dbh->disconnect();
}

$logger->info("fine");
$logger->info("-" x 76);

#FINE
#---------------------------------------------------------------------------------------------------
sub string2date { #trasformo una data in un oggetto DateTime
	my ($data) =@_;
	
	my $giorno = 1;
	my $mese = 1;
	my $anno = 1900;
	if ($data =~ /^(\d{4}).(\d{2}).(\d{2})$/) {
        $anno = $1*1;
		$mese = $2*1;
		$giorno = $3*1;
    }
    
	return DateTime->new(year=>$anno, month=>$mese, day=>$giorno);
}

sub ConnessioneDB {
	
	# connessione al database negozi
	$dbh = DBI->connect("DBI:mysql:$database:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database `$database`!\n";
		return 0;
	}
	
	#creo la tabella di log se non esiste
	$logger->info("verifica/creazione tabella $table_log");
	$sth = $dbh->prepare(qq{create table if not exists `$database`.`$table_log` (
							`codice` varchar(4) not null default '',
							`descrizione` varchar(100) not null default '',
							`data` date not null,
							`giorno` tinyint(1) unsigned not null default '1',
							`anagdafi` tinyint(1) unsigned not null default '0',
							`journal` tinyint(1) unsigned not null default '0',
							`datacollect` tinyint(1) unsigned not null default '0',
							`verificato` tinyint(1) unsigned not null default '0',
							primary key (`codice`,`data`),
  							KEY `anagdafi` (`anagdafi`,`datacollect`,`journal`,`verificato`)
							) engine=innodb default charset=latin1;});
	if (! $sth->execute()) {
		$logger->warn("Errore durante la creazione della tabella $table_log");
		return 0;
	}
	$sth->finish();
	
	#preparo la query per creare i record di log
	$logger->info("creazione record tabella $table_log");
	$sth = $dbh->prepare(qq{insert into `$database`.`$table_log`
							select n.`codice`, n.`negozio_descrizione`, ?, weekday(?)+1, 0, 0, 0, 0
							from `$database`.`$table_negozi` as n left join `$database`.`$table_log` as l on n.`codice`=l.`codice` and l.`data`=?
							where n.`societa` in ('01','31','36') and (n.`data_fine` is null or n.`data_fine`>=?) and n.`data_inizio`<=? and l.`codice` is null
							order by n.`codice`});
	#creo i record di log partendo dalla data iniziale preimpostata
	my $data = $starting_date->clone();
	while (DateTime->compare($data, $current_date)<0) {
		if (! $sth->execute($data->ymd('-'), $data->ymd('-'), $data->ymd('-'), $data->ymd('-'), $data->ymd('-'))) {
			$logger->warn("Errore durante la creazione dei record della tabella $table_log del giorno: ".$data->dmy('/'));
			return 0;
		}
        $data->add(days => 1);
    }
    $sth->finish();
	
	#creo le cartelle per le giornate da caricare
	$logger->info("verifica/creazione cartelle delle giornate da caricare");
	$sth = $dbh->prepare(qq{select distinct `data`
							from `$database`.`$table_log` 
							where `data` not in
								(	select distinct `data`
									from `$database`.`$table_log`
									where `datacollect` > 0
								) and
								`verificato` = 0
							}
						);
	if ($sth->execute()) {
		while (my @row = $sth->fetchrow_array()) {
			my $giornata = "$datacollect_folder/".string2date($row[0])->ymd('');
			if (! -e $giornata) {
				if (! mkdir $giornata) {
					$logger->warn("Impossibile creare la cartella: $giornata, $!");
				}
			}
		}
	}
	$sth->finish();
	
	return 1;
}

sub imposta_flag_presenza_file() {
	
	#elimino i file per cui è ancora presente il semaforo cercando nelle cartelle dove c'è almeno un file mancante
	$sth = $dbh->prepare(qq{select distinct `data`
							from `$database`.`$table_log` 
							where `datacollect`= 0 and `verificato` = 0
							order by 1
							}
						);
	if ($sth->execute()) {
		while (my @row = $sth->fetchrow_array()) {
			if (opendir my $DIR, "$datacollect_folder/".string2date($row[0])->ymd('')) {
				my @elenco_file = sort grep { /^.*\.CTL$/ } readdir $DIR;
				closedir $DIR;
				foreach (@elenco_file) {
					my $file_ctl = $_;
					my $file_txt = $file_ctl;
					$file_txt =~ s/\.CTL$/\.TXT/ig; 
					unlink "$datacollect_folder/".string2date($row[0])->ymd('')."/$file_ctl";
					if (-e "$datacollect_folder/".string2date($row[0])->ymd('')."/$file_txt") {
                        unlink "$datacollect_folder/".string2date($row[0])->ymd('')."/$file_txt";
                        $logger->warn("File di controllo $file_ctl ancora presente. File $file_txt eliminato!");
					}
				}
			}
		}
	}
	$sth->finish();
		
	#verifico che i file siano presenti e in caso affermativo imposto il flag nella tabella di log
	$sth = $dbh->prepare(qq{select `codice`, `data`
							from `$database`.`$table_log` 
							where `datacollect`= 0 and `verificato` = 0
							order by 2,1
							}
						);
	if ($sth->execute()) {
		while (my @row = $sth->fetchrow_array()) {
			
			#i file sono nella forma: ssnn_yyyymmdd_yymmdd_DC.TXT (es. 0171_20151211_151211_DC.TXT)
			my $file = "$datacollect_folder/".string2date($row[1])->ymd('')."/".$row[0].'_'.string2date($row[1])->ymd('').'_'.substr(string2date($row[1])->ymd(''),2).'_DC.TXT';

			if (-e $file ) {
				$dbh->do(qq{update `$database`.`$table_log` set `datacollect` = 1
							where `codice` = '$row[0]' and `data`= '$row[1]'})
			};
		}
	}
	$sth->finish();
	
	#imposto il flag verificato a 1 quando sono presenti datacollect, journal e anagdafi
	$sth = $dbh->prepare(qq{update `$database`.`$table_log` 
							set `verificato` = 1
							where `verificato` = 0 and `datacollect` = 1 and `journal` = 1 and `anagdafi` = 1}
						);
	$sth->execute() or die "aggiornamento flag verificato tabella log fallito: $!\n";
}

sub log_file_name{
    return "$log_folder/".$current_date->ymd('').'_'.$current_time->hms('')."_ricezione_datacollect.log";
}
