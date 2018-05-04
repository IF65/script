#!/usr/bin/perl -w
use strict;

use lib '/script/moduli';
use lib '/root/perl5/lib/perl5';

use DBI;
use DateTime;
use Log::Log4perl;
use List::MoreUtils qw(uniq);

use ITM_lavori;

# date
#------------------------------------------------------------------------------------------------------------
my $current_date 	= DateTime->now(time_zone=>'local');
my $current_time 	= DateTime->now(time_zone=>'local');
my $starting_date	= DateTime->new(year=>2015, month=>1, day=>1);

# definizione cartelle
#------------------------------------------------------------------------------------------------------------
my $local_data_folder = "/dati";
my $datacollect_folder = "$local_data_folder/datacollect";
my $local_log_folder = "/log";
my $log_folder = "$local_log_folder/".substr($current_date->ymd(''),0,6);

# giornate da recuperare
#------------------------------------------------------------------------------------------------------------
my @log_codice;;
my @log_data;
	
# handler/variabili globali
#------------------------------------------------------------------------------------------------------------
my $db;
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

my %attributes = (
					PrintWarn => 0,
					PrintError => 0,
					RaiseError => 1,
					ShowErrorStatement => 1,
				);

if ($db = new ITM_lavori(default_starting_date => $starting_date)) {

	#sistemo i flag prima di iniziare nel caso dei file fossero stati aggiunti manualmente
	$logger->info("verifica esistenza file e relativa impostazione flag (prima del caricamento)");
	&imposta_flag_presenza_file;

	my ($_codice, $_data, $_ip_mtx) = $db->elenco_datacollect_ncr_da_caricare_mtx();
				
	for (my $i=0; $i<=@$_codice; $i++) {
		my $data = string2date($$_data[$i])->ymd('-');
		
		my $dbh_sybase = DBI->connect("DBI:Sybase:server=$$_ip_mtx[$i]", "mtxadmin", 'mtxadmin',\%attributes);
		if ($dbh_sybase) {
			my $file_name = $$_codice[$i].'_'.string2date($$_data[$i])->ymd('').'_'.substr(string2date($$_data[$i])->ymd(''),2).'_DC.TXT';
			my $file_path = $datacollect_folder.'/'.string2date($$_data[$i])->ymd('');
		
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
													where ddate = '$data' 
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
						$db->datacollect_ncr_mtx_ok();
						$logger->info("FTP $$_codice[$i]: caricato il file del giorno ".string2date($$_data[$i])->dmy('/')." ($$_ip_mtx[$i])");
					} else {
						unlink "$file_path/$file_name";
						$logger->info("FTP $$_codice[$i]: nessun record presente sulla tabella EOD di mtx per il giorno ".string2date($$_data[$i])->dmy('/')." ($$_ip_mtx[$i])");
					}
				}
				$sth_sybase->finish();
			
			} else {
				$logger->warn("FTP $$_codice[$i]: esecuzione query per recupero datacollect non riuscita! ($$_ip_mtx[$i])");
			}
			$dbh_sybase->disconnect();
		}
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

sub imposta_flag_presenza_file() {
	
	my ($_log_codice, $_log_data, $_codice, $_ip, $_utente, $_password, $_percorso) = $db->elenco_datacollect_ncr_da_caricare();
	
	my @date = uniq(@$_log_data);
	
	#elimino i file per cui è ancora presente il semaforo cercando nelle cartelle dove c'è almeno un file mancante
	for (my $i=0; $i<@date; $i++) {
		if (opendir my $DIR, "$datacollect_folder/".string2date($date[$i])->ymd('')) {
			my @elenco_file = sort grep { /^.*\.CTL$/ } readdir $DIR;
			closedir $DIR;
			foreach (@elenco_file) {
				my $file_ctl = $_;
				my $file_txt = $file_ctl;
				$file_txt =~ s/\.CTL$/\.TXT/ig; 
				unlink "$datacollect_folder/".string2date($date[$i])->ymd('')."/$file_ctl";
				if (-e "$datacollect_folder/".string2date($date[$i])->ymd('')."/$file_txt") {
					unlink "$datacollect_folder/".string2date($date[$i])->ymd('')."/$file_txt";
					$logger->warn("File di controllo $file_ctl ancora presente. File $file_txt eliminato!");
				}
			}
		}
	}

	#verifico che i file siano presenti e in caso affermativo imposto il flag nella tabella di log		
	#i file sono nella forma: ssnn_yyyymmdd_yymmdd_DC.TXT (es. 0171_20151211_151211_DC.TXT)
	for (my $i=0; $i<@$_log_codice; $i++) {
		my $giornata = "$datacollect_folder/".string2date($$_log_data[$i])->ymd('');
		if (! -e $giornata) {
			if (! mkdir $giornata) {
				$logger->error("Impossibile creare la cartella: $giornata, $!");
			}
		}
		my $file = $giornata."/".$$_log_codice[$i].'_'.string2date($$_log_data[$i])->ymd('').'_'.substr(string2date($$_log_data[$i])->ymd(''),2).'_DC.TXT';
		if (-e $giornata && -e $file ) {
			$db->datacollect_ncr_mtx_ok($$_log_data[$i], $$_log_codice[$i]);
		};
	}
	
}

sub log_file_name{
    return "$log_folder/".$current_date->ymd('').'_'.$current_time->hms('')."_ricezione_datacollect.log";
}
