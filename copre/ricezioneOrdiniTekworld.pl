#!/usr/bin/perl -w
use strict;

use lib '/root/perl5/lib/perl5';

use DBI;
use Net::FTP;
use Net::FTP::File;
use File::Util;
use File::Copy;
use DateTime;
use Log::Log4perl;

use UUID;

# date
#------------------------------------------------------------------------------------------------------------
my $currentDate 	= DateTime->now(time_zone=>'local');
my $current_time 	= DateTime->now(time_zone=>'local');
my $test = DateTime->now(time_zone=>'local')->iso8601();

# parametri database
#----------------------------------------------------------------------------------------------------------------------
my $dbHost = 'localhost';#'10.11.14.78';
my $dbUser = 'root';
my $dbPassword = 'mela';
my $db = 'copre';
my $tbl = 'ordini';
my $dbH;
my $stH;
my $stHT;
my $stHR;
my $stHCodiceArticolo;
my $stOk;

# parametri ftp
#------------------------------------------------------------------------------------------------------------
my $url = 'ftp.tekworld.it';
my $user = 'ftp_tekworldforn|tekworldforn';
my $password = 'FKr43$87fdSsD';
my $path = '/Super/Ordini';


# definizione cartelle
#------------------------------------------------------------------------------------------------------------
my $mainDataFolder = '/B2BOrdini'; #Supermedia
my $inDataFolder = $mainDataFolder.'/IN/TEKWORLD';
my $bkpDataFolder = $mainDataFolder.'/BKP/TEKWORLD';
my $mainLogFolder = "/log";
my $logFolder = "$mainLogFolder/".substr($currentDate->ymd(''),0,6);

# Creazione cartelle locali (se non esistono)
#------------------------------------------------------------------------------------------------------------
my($f) = File::Util->new();
unless(-e $logFolder or $f->make_dir( $logFolder)) {die "Impossibile creare la cartella $logFolder: $!\n";};
unless(-e $inDataFolder or $f->make_dir( $inDataFolder)) {die "Impossibile creare la cartella $inDataFolder: $!\n";};
unless(-e $bkpDataFolder or $f->make_dir( $bkpDataFolder)) {die "Impossibile creare la cartella $bkpDataFolder: $!\n";};

# configurazione log
#------------------------------------------------------------------------------------------------------------
my $configurazione = q(
    log4perl.category.if65log            = DEBUG, Logfile

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
$logger->info("ricezione Ordini B2B Tekworld");
$logger->info("-" x 76);
$logger->info("inizio");

my $fileHandler;
    
if (&ConnessioneDB) {
    if (my $ftp = Net::FTP->new($url)) {
        if ($ftp->login($user,$password)) {
            $logger->debug("FTP TEKWORLD ($url)->collegamento avvenuto con successo");
            $ftp->binary();
            $ftp->cwd($path);
    
            my @fileList = $ftp->ls();
            for (my $i=0;$i<@fileList;$i++) {
                if ($ftp->isfile($fileList[$i])) {
                    if ($fileList[$i] =~ /^(\d+\.TXT)$/) {
                        my $fileName = $1;
                        if ($ftp->get($fileList[$i], "$inDataFolder/$fileName")) {
                            $logger->info("FTP TEKWORLD:  stato caricato il file ".$fileList[$i]);
    
                            $ftp->delete($fileList[$i]);
                        } else {
                            $logger->error("FTP TEKWORLD: il file ".$fileList[$i]." non  stato caricato");
                        }
                    }
                }
            }
            $ftp->quit();
        } else {
            $logger->warn("FTP TEKWORLD ($url)->collegamento fallito");
        }
    }

    if (opendir my $DIR, $inDataFolder) {
        my @fileList = sort grep { /^\d+\.TXT$/ } readdir $DIR;
        closedir $DIR;

        foreach my $fileName (@fileList) {
            if (-e "$inDataFolder/$fileName") {
                if (open my $fileHandler, "<:crlf", "$inDataFolder/$fileName") {
                    if ($fileName =~ /^(\d+)\.TXT$/) {
                        my $codiceCliente = 'TEKWORLD';
                        my $riferimento = $1;
                        my $tipo = 2;
                        my $data = $currentDate;
                        my $codiceVettore = '';
                        my $numeroRighe = 0;
                        my $valoreContrassegno = 0;
                        my $destinatario = 'Tekworld S.r.l';
                        my $indirizzo = 'Via Nona Strada, 23/Q';
                        my $cap = '35129';
                        my $localita = 'Padova';
                        my $provincia = 'PD';
                        my $telefono = '';
                        my $note = '';
                        
                        my $line;
                        while (!eof($fileHandler)) {
                            $line = <$fileHandler> ;
                            $line =~  s/\n$//ig;
                            if ($line =~ /^([^;]*);([^;]*);(\d+);([^;]*)$/) {
                                $numeroRighe++;
                                        
                                my $codiceCliente = 'TEKWORLD';
                                my $numeroRiga = $numeroRighe;
                                my $codiceArticolo = '';
                                my $barcode = $3;
                                my $quantita = $2*1;
                                my $prezzo = $4;
                                $prezzo =~ s/\,/./ig;
                                $prezzo *= 1;
                                
                                if ($stHCodiceArticolo->execute($barcode)) {
                                    while (my @record = $stHCodiceArticolo->fetchrow_array()) {
                                        $codiceArticolo = $record[0];
                                    }
                                }
    
                                if (! $stHR->execute($codiceCliente,$riferimento,$numeroRiga,$codiceArticolo,$quantita,$prezzo,$barcode,'')){
                                    print "Errore\n";
                                }
                            } 
                        }
                        if (! $stHT->execute($codiceCliente,$riferimento,$tipo,$data->ymd('-'),$codiceVettore,$numeroRighe,$valoreContrassegno,$destinatario,$indirizzo,$cap,$localita,$provincia,$telefono,$note)) {
                            print "Errore\n";
                        }
                    }
                    close( $fileHandler);
                    move("$inDataFolder/$fileName", "$bkpDataFolder/$fileName");
                }
            } else {
                $logger->warn("File $fileName mancante!");
            }
        }
    }
}

$logger->info("fine");
$logger->info("-" x 76);

#FINE
#---------------------------------------------------------------------------------------------------
sub ConnessioneDB {
    # connessione al database negozi
    $dbH = DBI->connect("DBI:mysql:$db:$dbHost", $dbUser, $dbPassword);
    if (! $dbH) {
        print "Errore durante la connessione al database `$db`!\n";
        return 0;
    }

    # creazione della tabella ordinTestata
    $stH = $dbH->prepare(qq{
                            CREATE TABLE IF NOT EXISTS `ordiniTestata` (
                            `codiceCliente` varchar(20) NOT NULL DEFAULT '',
                            `riferimento` varchar(40) NOT NULL DEFAULT '',
                            `tipo` tinyint(4) NOT NULL DEFAULT '1',
                            `data` date NOT NULL,
                            `codiceVettore` varchar(255) NOT NULL DEFAULT '',
                            `numeroRighe` int(11) NOT NULL DEFAULT '0',
                            `valoreContrassegno` decimal(10,2) NOT NULL DEFAULT '0.00',
                            `destinatario` varchar(255) NOT NULL DEFAULT '',
                            `indirizzo` varchar(255) NOT NULL DEFAULT '',
                            `cap` int(11) NOT NULL DEFAULT '0',
                            `localita` varchar(255) NOT NULL DEFAULT '',
                            `provincia` varchar(2) NOT NULL DEFAULT '',
                            `telefono` varchar(255) NOT NULL DEFAULT '',
                            `note` varchar(255) NOT NULL DEFAULT '',
                            `id4D` int(11) NOT NULL DEFAULT '0',
                            `notificato` tinyint(4) NOT NULL DEFAULT '1',
                            PRIMARY KEY (`codiceCliente`,`riferimento`)
                          ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });
    if (!$stH->execute()) {
        print "Errore durante la creazione della tabella `ordiniTestata`! " .$dbH->errstr."\n";
        return 0;
    }
    $stH->finish();

  # creazione della tabella ordinRighe
    $stH = $dbH->prepare(qq{
                            CREATE TABLE IF NOT EXISTS `ordiniRighe` (
                            `codiceCliente` varchar(20) NOT NULL DEFAULT '',
                            `riferimento` varchar(40) NOT NULL DEFAULT '',
                            `numeroRiga` int(11) NOT NULL,
                            `codiceArticolo` varchar(10) NOT NULL DEFAULT '',
                            `quantita` int(11) NOT NULL DEFAULT '1',
                            `prezzo` decimal(10,2) NOT NULL DEFAULT '0.00',
  							`barcode1` varchar(13) NOT NULL DEFAULT '',
  							`barcode2` varchar(13) NOT NULL DEFAULT '',
                            PRIMARY KEY (`codiceCliente`,`riferimento`,`numeroRiga`)
                          ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });
    if (!$stH->execute()) {
        print "Errore durante la creazione della tabella `ordiniRighe`! " .$dbH->errstr."\n";
        return 0;
    }
    $stH->finish();

    # inserimento nuovo record testata
    $stHT = $dbH->prepare(qq{   insert ignore into `ordiniTestata`
                                    (`codiceCliente`,`riferimento`,`tipo`,`data`,`codiceVettore`,`numeroRighe`,`valoreContrassegno`,`destinatario`,`indirizzo`,`cap`,`localita`,`provincia`,`telefono`,`note`)
                                values (?,?,?,?,?,?,?,?,?,?,?,?,?,?);
    });

    # inserimento nuovo record righe
    $stHR = $dbH->prepare(qq{   insert ignore into `ordiniRighe`
                                    (`codiceCliente`,`riferimento`,`numeroRiga`,`codiceArticolo`,`quantita`,`prezzo`,`barcode1`,`barcode2`)
                                values
                                    (?,?,?,?,?,?,?,?);
    });
    
    # ricerca codice articolo
    $stHCodiceArticolo = $dbH->prepare(qq{ select codice from tabulatoCopre where tabulatoCopre.barcode = ? limit 1 });

    return 1;
}

sub string2date { #trasformo una data in un oggetto DateTime
	my ($data) =@_;

	my $giorno = 1;
	my $mese = 1;
	my $anno = 1900;
	if ($data =~ /^(\d{4})(\d{2})(\d{2})$/) {
        $anno = $1*1;
		$mese = $2*1;
		$giorno = $3*1;
    }

	return DateTime->new(year=>$anno, month=>$mese, day=>$giorno);
}

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub getUUID {
    my $uuid;
    my $string;
    UUID::generate($uuid); # generates a 128 bit uuid
    UUID::unparse($uuid, $string); # change $uuid to 36 byte string

    return $string;
}

sub log_file_name{
    return "$logFolder/".$currentDate->ymd('').'_'.$current_time->hms('')."_ricezione_eprice.log";
}
