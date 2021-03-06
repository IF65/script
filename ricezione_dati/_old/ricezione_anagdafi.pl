#!/usr/bin/perl -w
use strict;
use DBI; 
use Net::FTP;
use Net::FTP::File;
use DateTime;
use Log::Log4perl;
use threads;
use threads::shared;

# date
#------------------------------------------------------------------------------------------------------------
my $current_date 	= DateTime->now(time_zone=>'local');
my $current_time 	= DateTime->now(time_zone=>'local');
my $starting_date	= DateTime->new(year=>2015, month=>1, day=>1);

# definizione cartelle
#------------------------------------------------------------------------------------------------------------
my $local_data_folder = "/dati";
my $anagdafi_folder: shared = "$local_data_folder/anagdafi";
my $local_log_folder = "/log";
my $log_folder = "$local_log_folder/".substr($current_date->ymd(''),0,6);

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "localhost";
my $username = "root";
my $password = "mela";

# parametri di configurazione dei database
#------------------------------------------------------------------------------------------------------------
my $database = 'archivi';
my $table_negozi = 'negozi';
my $table_log = 'log_ricezione';

# giornate da recuperare
#------------------------------------------------------------------------------------------------------------
my @log_codice: shared;
my @log_data: shared;
	
# handler/variabili globali
#------------------------------------------------------------------------------------------------------------
my $sth;
my $dbh;
my @thr;

# Creazione cartelle locali (se non esistono)
#------------------------------------------------------------------------------------------------------------
unless(-e $local_data_folder or mkdir $local_data_folder) {die "Impossibile creare la cartella $local_data_folder: $!\n";};
unless(-e $anagdafi_folder or mkdir $anagdafi_folder) {die "Impossibile creare la cartella $anagdafi_folder: $!\n";};
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
$logger->info("ricezione anagdafi");
$logger->info("-" x 76);
$logger->info("inizio");

if (&ConnessioneDB()) {
	
	#sistemo i flag prima di iniziare nel caso dei file fossero stati aggiunti manualmente
	$logger->info("verifica esistenza file e relativa impostazione flag (prima del caricamento)");
	&imposta_flag_presenza_file;

	#carico le giornate/negozio mancanti per recuperare i file
	$sth = $dbh->prepare(qq{select `codice`, `data`
							from `$database`.`$table_log`
							where `anagdafi`= 0 and `verificato`= 0
							}
						);
	if ($sth->execute()) {
		while (my @row = $sth->fetchrow_array()) {
			push @log_codice, $row[0];
			push @log_data, $row[1];
		}
	}
	$sth->finish();

	#creo i threads per le giornate/negozio da caricare
	$sth = $dbh->prepare(qq{select distinct l.`codice`,n.`ip`, n.`utente`, n.`password`,n.`percorso`
							from `$database`.`$table_log` as l  join `$database`.`$table_negozi` as n on l.`codice`=n.`codice`
							where l.`anagdafi`= 0 and l.`verificato`= 0
							}
						);
	if ($sth->execute()) {
		while (my @row = $sth->fetchrow_array()) {
			push @thr, threads->create('GetFiles', $row[0], $row[1], $row[2], $row[3], $row[4]);
		}
	}
	$sth->finish();
	
	#mando in esecuzione i threads
	for (my $j=0; $j< @thr;$j++) {
		$thr[$j]->join();
	}
	
	#sistemo i flag in modo da tener conto dei file appena importati
	$logger->info("verifica esistenza file e relativa impostazione flag (dopo il caricamento)");
	&imposta_flag_presenza_file;
	
	$dbh->disconnect;
};

$logger->info("fine");
$logger->info("-" x 76);

#FINE
#---------------------------------------------------------------------------------------------------
sub string2date { #trasformo una data un oggetto DateTime
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

sub GetFiles {
	my ($negozio, $ip, $utente, $password, $percorso) = @_;
		
	my $file_handler;

	if (my $ftp = Net::FTP->new($ip)) {
		if ($ftp->login($utente,$password)) { 
			$ftp->binary();
			$ftp->cwd($percorso);
					
			for (my $i=0;$i<@log_codice;$i++) {
				if ($negozio eq $log_codice[$i]) {
			
					my $data = string2date($log_data[$i]);
			
					my $nome_file_remoto = substr($data->ymd('').'_A.ZIP',2);
					my $nome_file_locale = $data->ymd('').'_'.$negozio.'.zip';

					if ($ftp->isfile($nome_file_remoto)) {
						my $path_file_locale = $anagdafi_folder.'/'.$data->ymd('');
						if (! $ftp->get($nome_file_remoto, $path_file_locale.'/'.$nome_file_locale)) {
							unlink($path_file_locale.'/'.$nome_file_locale);
							$logger->warn("FTP $negozio: caricamento incompleto file locale del giorno ".$data->dmy('/')." eliminato ($ip)");
						} else {
							$logger->info("FTP $negozio: caricato il file del giorno ".$data->dmy('/')." ($ip)");
						}
					} else {
						$logger->info("FTP $negozio: non trovato il file del giorno ".$data->dmy('/')." ($ip)");
					}
				}
			}
			$ftp->quit();
		} else {
			$logger->warn("FTP $negozio ($ip)->collegamento fallito");
		}
	}
	return 1;
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
							primary key (`codice`,`data`)
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
	$sth = $dbh->prepare(qq{select distinct `data`
							from `$database`.`$table_log` 
							where `data` not in
								(	select distinct `data`
									from `$database`.`$table_log`
									where `anagdafi` = 1
								) and
								`verificato` = 0
							}
						);
	if ($sth->execute()) {
		while (my @row = $sth->fetchrow_array()) {
			my $giornata = "$anagdafi_folder/".string2date($row[0])->ymd('');
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
	#verifico che i file siano presenti e in caso affermativo imposto il flag nella tabella di log
	$sth = $dbh->prepare(qq{select `codice`, `data`
							from `$database`.`$table_log` 
							where `anagdafi`= 0 and `verificato` = 0
							order by 2,1
							}
						);
	if ($sth->execute()) {
		while (my @row = $sth->fetchrow_array()) {
			
			#i file sono nella forma: yyyymmdd_ssnn.zip (es. 20151211_0171.zip)
			my $file = "$anagdafi_folder/".string2date($row[1])->ymd('')."/".string2date($row[1])->ymd('')."_$row[0].zip";
			if (-e $file ) {
				$dbh->do(qq{update `$database`.`$table_log` set `anagdafi` = 1
							where `codice` = '$row[0]' and `data`= '$row[1]'})
			};
		}
	}
	$sth->finish();
}

sub log_file_name{
    return  "$log_folder/".$current_date->ymd('').'_'.$current_time->hms('')."_ricezione_anagdafi.log";
}
