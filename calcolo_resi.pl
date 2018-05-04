#!/usr/bin/perl
use strict;

# by Marco Gnecchi

use lib '/script/moduli';
use lib '/root/perl5/lib/perl5';

use DBI;
use File::HomeDir;
use Net::FTP;
use DateTime;
use Log::Log4perl;

use ITM_lavori;

# date
#------------------------------------------------------------------------------------------------------------
my $current_date 	= DateTime->now(time_zone=>'local');
my $current_time 	= DateTime->now(time_zone=>'local');
my $starting_date	= DateTime->new(year=>2016, month=>1, day=>1);

# definizione cartelle
#------------------------------------------------------------------------------------------------------------
my $local_data_folder 	= "/dati";
my $datacollect_folder	= "$local_data_folder/datacollect";
my $local_log_folder 	= "/log";
my $log_folder = "$local_log_folder/".substr($current_date->ymd(''),0,6);

# parametri database
#------------------------------------------------------------------------------------------------------------
my $hostname = '10.11.14.76';
my $username = 'root';
my $password = 'mela';
my $database = 'archivi';
my $table = 'resi';

# handler
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $dbh_lavori;
my $sth_lavori;

# configurazione log
#------------------------------------------------------------------------------------------------------------
my $configurazione = q(
    log4perl.category.if65log            = INFO, Logfile

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
$logger->info("calcolo resi");
$logger->info("-" x 76);
$logger->info("inizio");

if(&ConnessioneDB()) {
	$logger->info("apertura connessione con db: $hostname/$database/$table.");
	if (my $db = new ITM_lavori(default_starting_date => $starting_date)) {
		$logger->info("ricerca giornate/negozio da calcolare.");
		my ($_log_codice_sede, $_log_data, $_codice, $_ip, $_utente, $_password, $_percorso) = $db->elenco_resi_da_calcolare();
		
		my $array_size = @$_log_codice_sede;
		$logger->info("inizio elaborazione giornate ($array_size).");
		for (my $i=0; $i<@$_log_codice_sede;$i++) {
			my $nome_cartella = string2date($$_log_data[$i])->ymd('');
			my $nome_file = $$_log_codice_sede[$i].'_'.string2date($$_log_data[$i])->ymd('').'_'.substr(string2date($$_log_data[$i])->ymd(''),2).'_DC.TXT';
			
				if (-e $datacollect_folder.'/'.$nome_cartella.'/'.$nome_file) {
					if(&analisi_file($datacollect_folder.'/'.$nome_cartella,$nome_file)) {
						$logger->info("ealborazione negozio $$_log_codice_sede[$i], data ".string2date($$_log_data[$i])->ymd('-'));
						$db->calcolo_resi_ok($$_log_data[$i], $$_log_codice_sede[$i]);
					}
					#print "$datacollect_folder/$nome_cartella/$nome_file\n";
				} else {
					$logger->warn("Negozio: $$_log_codice_sede[$i], Data: ".string2date($$_log_data[$i])->ymd('-')." ->datacollect non presente");
				}
			}
		}
}

$logger->info("fine");
$logger->info("-" x 76);

#FINE
#------------------------------------------------------------------------------------------------------------
sub ConnessioneDB {
    # connessione al database negozi
    $dbh = DBI->connect("DBI:mysql:$database:$hostname", $username, $password);
    if (! $dbh) {
        print "Errore durante la connessione al database `$database`!\n";
        return 0;
    }
    $sth = $dbh->prepare(qq{ CREATE TABLE IF NOT EXISTS `$database`.`$table` (
							`data` date NOT NULL,
							`negozio` varchar(4) NOT NULL DEFAULT '',
							`cassa` varchar(3) NOT NULL DEFAULT '',
							`transazione` varchar(4) NOT NULL DEFAULT '',
                            `tipo` varchar(1) NOT NULL DEFAULT '',
							`reparto` varchar(4) NOT NULL DEFAULT '',
							`barcode` varchar(13) NOT NULL DEFAULT '',
							`importo` float NOT NULL DEFAULT '0',
							PRIMARY KEY (`data`,`negozio`,`cassa`,`transazione`,`tipo`,`reparto`,`barcode`)
							) ENGINE=InnoDB DEFAULT CHARSET=latin1;}
    );
	
	$sth->execute();

    $sth = $dbh->prepare(qq{insert into `$database`.`$table` (`data`, `negozio`, `cassa`, `transazione`,`tipo`,`reparto`, `barcode`, `importo`)
                        values (?,?,?,?,?,?,?,?) on duplicate key update `importo`=`importo` + ?});
    
    return 1;
}

sub analisi_file {
	my ($path, $file_name) = @_;
  
	my $line;
	my @transazione = ();
	my %forma_pagamento = ();
	
	my $transazione_aperta = 0;
	if (open my $file_handler, "<:crlf", "$path/$file_name") {
		
		my $negozio = '';
		my $data		= '';
		if ($file_name =~ /^(\d{4})_\d{8}_(\d{6})/) {
			$negozio	= $1;
			$data		= $2;
		}
		
		while (!eof($file_handler)) {
			$line = <$file_handler> ;
			$line =~  s/\n$//ig;
			
			if ($line =~ /^.{31}:H:1.{43}$/) {
				$transazione_aperta = 1;
				@transazione = ();
                %forma_pagamento = ();
			};
			
			if ($transazione_aperta) {
				if ($line =~ /^(.{31}:F:1.)(?:8|9)(.{41})$/) {
					$line = $1.'0'.$2;
				};
				
				push(@transazione, $line);
			}
			
			if ($line =~ /^\d{4}:(\d{3}):\d{6}:(\d{6}):(\d{4}):.{3}:F:1.{33}(.{10})$/) {
				$transazione_aperta = 0;
				
				my $cassa = $1;
                my $ora = $2;
				my $numero_transazione = $3;
                my $totale_transazione = $4*1;
				
				for(my $i=0;$i<@transazione;$i++) {
					if ($transazione[$i] =~ /:S:1(\d)\d:(\d{4}):.{3}(.{13})\-(\d{4})(.).{4}(\d{9})$/) {
						my $tipo = $1;
                        my $reparto = $2;
                        my $barcode = $3;
                        my $quantita = $4*1;
                        my $punto = $5;
                        my $importo = $6;
                        
                        if ($punto eq '.') {
                            $quantita = 1;
                        }
                        $importo *= $quantita;
                        $sth->execute($data, $negozio, $cassa, $numero_transazione, $tipo, $reparto, $barcode, $importo, $importo);
					}
				}
			} 
		}
		close($file_handler);
	}
	
	return 1;
}

sub string2date { #trasformo una data un oggetto DateTime
	my ($data) = @_;
	
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

sub log_file_name{
    return "$log_folder/".$current_date->ymd('').'_'.$current_time->hms('')."_resi.log";
}
