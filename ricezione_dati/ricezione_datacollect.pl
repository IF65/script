#!/usr/bin/perl -w
use strict;

# by Marco Gnecchi

use lib '/script/moduli';
use lib '/root/perl5/lib/perl5';

use Net::FTP;
use Net::FTP::File;
use DateTime;
use Log::Log4perl;
use threads;
use threads::shared;
use List::MoreUtils qw(uniq);

use ITM_lavori;

# date
#------------------------------------------------------------------------------------------------------------
my $current_date 	= DateTime->now(time_zone=>'local');
my $current_time 	= DateTime->now(time_zone=>'local');
my $starting_date	= DateTime->new(year=>2016, month=>1, day=>1);

# definizione cartelle
#------------------------------------------------------------------------------------------------------------
my $local_data_folder = "/dati";
my $datacollect_folder: shared = "$local_data_folder/datacollect";
my $local_log_folder = "/log";
my $log_folder = "$local_log_folder/".substr($current_date->ymd(''),0,6);

# giornate da recuperare
#------------------------------------------------------------------------------------------------------------
my @log_codice: shared;
my @log_data: shared;
	
# handler/variabili globali
#------------------------------------------------------------------------------------------------------------
my @thr;
my $db;

# Creazione cartelle locali (se non esistono)
#------------------------------------------------------------------------------------------------------------
unless(-e $local_data_folder or mkdir $local_data_folder) {die "Impossibile creare la cartella $local_data_folder: $!\n";};
unless(-e $datacollect_folder or mkdir $datacollect_folder) {die "Impossibile creare la cartella $datacollect_folder: $!\n";};
unless(-e $local_log_folder or mkdir $local_log_folder) {die "Impossibile creare la cartella $local_log_folder: $!\n";};
unless(-e $log_folder or mkdir $log_folder) {die "Impossibile creare la cartella $log_folder: $!\n";};

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
$logger->info("ricezione datacollect");
$logger->info("-" x 76);
$logger->info("inizio");

if ($db = new ITM_lavori(default_starting_date => $starting_date)) {
	
	#sistemo i flag prima di iniziare nel caso uno o più file fossero stati aggiunti manualmente
	$logger->info("verifica esistenza file e relativa impostazione flag (prima del caricamento)");
	&imposta_flag_presenza_file;

	my ($_log_codice, $_log_data, $_codice, $_ip, $_utente, $_password, $_percorso) = $db->elenco_datacollect_ncr_da_caricare();

	#li copio perché mi servono variabili "shared"
	@log_codice = @$_log_codice;
	@log_data = @$_log_data;
	
	for (my $i=0; $i<@$_codice; $i++) {
		push @thr, threads->create('GetFiles', $$_codice[$i], $$_ip[$i], $$_utente[$i], $$_password[$i], $$_percorso[$i]);
	}

	#con l'istruzione join faccio in modo che l'esecuzione aspetti fino a che l'ultimo thread sia terminato
	for (my $j=0; $j<@thr; $j++) {
		$thr[$j]->join();
	}
	
	#sistemo i flag in modo da tener conto dei file appena importati
	$logger->info("verifica esistenza file e relativa impostazione flag (dopo il caricamento)");
	&imposta_flag_presenza_file;

};

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

sub GetFiles {
	my ($negozio, $ip, $utente, $password, $percorso) = @_;
		
	my $file_handler;
	
	if (my $ftp = Net::FTP->new($ip)) {
		if ($ftp->login($utente,$password)) { 
			$logger->debug("FTP $negozio ($ip)->collegamento avvenuto con successo");
			$ftp->binary();
			$ftp->cwd($percorso);
					
			for (my $i=0;$i<@log_codice;$i++) {
				if ($negozio eq $log_codice[$i]) {
			
					my $data = string2date($log_data[$i]);
			
					my $nome_file_remoto_it = substr($data->ymd(''),2).'_DC.TXT';
					my $nome_file_remoto_fm = substr($data->ymd(''),2).'.idc';
					
					my $nome_file_semaforo = $negozio.'_'.$data->ymd('').'_'.substr($data->ymd(''),2).'_DC.CTL';
					my $nome_file_locale = $negozio.'_'.$data->ymd('').'_'.substr($data->ymd(''),2).'_DC.TXT';
					my $path_file_locale = $datacollect_folder.'/'.$data->ymd('');

					if ($ftp->isfile($nome_file_remoto_it)) {
						open($file_handler, '>', $path_file_locale.'/'.$nome_file_semaforo);
						close($file_handler);
						if ($ftp->get($nome_file_remoto_it, $path_file_locale.'/'.$nome_file_locale)) {
							unlink($path_file_locale.'/'.$nome_file_semaforo);
							$logger->info("FTP $negozio: caricato il file del giorno ".$data->dmy('/')." ($ip)");
						}
					} elsif  ($ftp->isfile($nome_file_remoto_fm)) {
						open($file_handler, '>', $path_file_locale.'/'.$nome_file_semaforo);
						close($file_handler);
						if ($ftp->get($nome_file_remoto_fm, $path_file_locale.'/'.$nome_file_locale)) {
							unlink($path_file_locale.'/'.$nome_file_semaforo);
							$logger->info("FTP $negozio: caricato il file del giorno ".$data->dmy('/')." ($ip)");
						}
					} else {
						$logger->warn("FTP $negozio: non trovato il file del giorno ".$data->dmy('/')." ($ip)");
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
			$db->datacollect_ncr_ok($$_log_data[$i], $$_log_codice[$i]);
		};
	}
	
}

sub log_file_name{
    return "$log_folder/".$current_date->ymd('').'_'.$current_time->hms('')."_ricezione_datacollect.log";
}
