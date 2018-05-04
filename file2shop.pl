#!/usr/bin/perl -w
use strict;
use DBI;
use File::HomeDir;
use Getopt::Long;
use Net::FTP;
use DateTime;
use Log::Log4perl;

# file da inviare
#----------------------------------------------------------------------------------------------------------------------
my $path_destination = '/';
my $file = ''; #compreso path sorgente

# parametri database
#----------------------------------------------------------------------------------------------------------------------

my $hostname = '10.11.14.78';
my $username = 'root';
my $password = 'mela';
my $database = 'archivi';

my $ftp_url;
my $ftp_user;
my $ftp_password;
my $ftp_sede_descrizione;

# date
#------------------------------------------------------------------------------------------------------------
my $current_date 	= DateTime->now(time_zone=>'local');

# definizione cartelle
#----------------------------------------------------------------------------------------------------------------------
my $desktop = File::HomeDir->my_desktop;
my $local_log_folder = "/log";
my $log_folder = "$local_log_folder/".substr($current_date->ymd(''),0,6);

# Creazione cartelle locali (se non esistono)
#----------------------------------------------------------------------------------------------------------------------
unless (-e $local_log_folder or mkdir $local_log_folder) {die "Impossibile creare la cartella $local_log_folder: $!\n";};
unless (-e $log_folder or mkdir $log_folder) {die "Impossibile creare la cartella $log_folder: $!\n";};

# configurazione log
#----------------------------------------------------------------------------------------------------------------------
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
$logger->info("invio file al negozo");
$logger->info("-" x 76);
$logger->info("inizio invio");
$logger->info("");

# handler
#----------------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sth_elenco_negozi;
my $sth_shop;
my $ftph;

# parametri da linea di comando
#----------------------------------------------------------------------------------------------------------------------
my $sede;

# recupero parametri dalla linea di comando
#----------------------------------------------------------------------------------------------------------------------
my $help;
if (@ARGV == 0) {
    $help = 1
}

my $filtro_negozio = '';

GetOptions(
    'n=s{,1}'	=> \$filtro_negozio,
    'f=s{,1}'	=> \$file,
    'p=s{,1}'	=> \$path_destination,
    'help'      => \$help,
) or die "parametri non corretti!\n";

if ($help) {
    print "Utilizzo: perl [path]file2shop.pl -f path/file_sorgente -p path_destinazione [--help]\n\n";
    print "significato:     -n           filtro su codice negozio es. 04 -> 0461, 0462,.....,\n";
    print "                 -f           file da inviare comprensivo di path in formato posix,\n";
    print "                 -p           path del file destinazione in formato posix\n";
    print "                --help        mostra queste istruzioni.\n";
    print "     i log di esecuzione sono posizionati nella cartella /log/aaaamm/.\n";
    
    die "\n";
}

if (-e $file) {
    if (&ConnessioneDB) {   
        $logger->info("connessione avvenuta con successo.");
        
        my @elenco_negozi = ();
        if ($sth_elenco_negozi->execute()) {
            while(my @row = $sth_elenco_negozi->fetchrow_array()) {
                push @elenco_negozi, $row[0];
            }
        }
        print "@elenco_negozi\n";
        for(my $i=0;$i<@elenco_negozi;$i++) {
            $logger->info("Negozio: $elenco_negozi[$i]");
            if ($sth_shop->execute($elenco_negozi[$i])) {
                while(my @row = $sth_shop->fetchrow_array()) {
                    $ftp_url = $row[0];
                    $ftp_user = 'manager';#$row[1];
                    $ftp_password = 'manager';#$row[2];
                    $ftp_sede_descrizione = $row[3];
            
                    $ftph = Net::FTP->new($ftp_url, Timeout => 30);
                    if ($ftph) {
                        $logger->debug("connessione riuscita a: $ftp_sede_descrizione, $ftp_url");								
                        if ( $ftph->login("$ftp_user","$ftp_password")) {
                            $logger->debug("login riuscito a: $ftp_sede_descrizione, $ftp_url");
                            $ftph->cwd($path_destination);
                            $ftph->binary();
                            
                            $logger->debug("tentativo di invio del file: $file");
                            if ($ftph->put("$file", "$file")) {#"$path_destination/$file")) {
                                $logger->debug("inviato il file: $file");
                            }
                        } else {
                            $logger->warn("Login fallito a: $ftp_sede_descrizione, $ftp_url: $!")
                        }
                        $ftph->quit;
                    } else {
                        $logger->warn("Mancata connessione a: $ftp_sede_descrizione, $ftp_url: $!")
                    }
                    $ftph->close;
                }
            }
        }
    }
} else {
    print("file $file non esistente!\n");
}

&chiusura_log();

sub ConnessioneDB {
    # connessione al database negozi
    $dbh = DBI->connect("DBI:mysql:$database:$hostname", $username, $password);
    if (! $dbh) {
        print "Errore durante la connessione al database `$database`!\n";
        return 0;
    }
    
    $sth_elenco_negozi = $dbh->prepare(qq{select n.`codice` from negozi as n where n.`societa` in ('01','04','31','36') and n.`data_fine` is null and n.`codice` like '$filtro_negozio%'order by 1});
    
	$sth_shop = $dbh->prepare(qq{select ip, utente, password, negozio_descrizione from archivi.negozi where codice = ?});

    return 1;
}

sub log_file_name {
    return "$log_folder/".$current_date->ymd('')."_invio_rvg_2_shop.log";
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

sub chiusura_log {
    $logger->info("");
    $logger->info("fine elaborazione");
    $logger->info("-" x 76);
    $logger->info("");
     
    return 1;
};

                    
