#!/usr/bin/perl -w
use strict;

use lib '/root/perl5/lib/perl5';

use DBI;
use Net::FTP;
use Net::FTP::File;
use File::Copy;
use DateTime;
use Log::Log4perl;

use UUID;

# date
#------------------------------------------------------------------------------------------------------------
my $current_date 	= DateTime->now(time_zone=>'local');
my $current_time 	= DateTime->now(time_zone=>'local');
my $test = DateTime->now(time_zone=>'local')->iso8601();

# parametri database
#----------------------------------------------------------------------------------------------------------------------
my $dbHost = '10.11.14.78';
my $dbUser = 'root';
my $dbPassword = 'mela';
my $db = 'copre';
my $tbl = 'ordini';
my $dbH;
my $stH;
my $stHT;
my $stHR;
my $stOk;

# parametri ftp
#------------------------------------------------------------------------------------------------------------
my $url = 'repo.eprice.it';
my $user = '00IF65';
my $password = 'sQL55I5Q';
my $path = '/Ordini';


# definizione cartelle
#------------------------------------------------------------------------------------------------------------
my $mainDataFolder = '/B2BOrdini'; #Supermedia
my $inDataFolder = $mainDataFolder.'/IN/EPRICE';
my $bkpDataFolder = $mainDataFolder.'/BKP/EPRICE';
my $mainLogFolder = "/log";
my $logFolder = "$mainLogFolder/".substr($current_date->ymd(''),0,6);

# Creazione cartelle locali (se non esistono)
#------------------------------------------------------------------------------------------------------------
unless(-e $mainDataFolder or mkdir $mainDataFolder) {die "Impossibile creare la cartella $mainDataFolder: $!\n";};
unless(-e $mainLogFolder or mkdir $mainLogFolder) {die "Impossibile creare la cartella $mainLogFolder: $!\n";};
unless(-e $logFolder or mkdir $logFolder) {die "Impossibile creare la cartella $logFolder: $!\n";};
unless(-e $inDataFolder or mkdir $inDataFolder) {die "Impossibile creare la cartella $inDataFolder: $!\n";};
unless(-e $bkpDataFolder or mkdir $bkpDataFolder) {die "Impossibile creare la cartella $bkpDataFolder: $!\n";};

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
$logger->info("ricezione Ordini B2B ePrice");
$logger->info("-" x 76);
$logger->info("inizio");

my $fileHandler;

    if (&ConnessioneDB) {
    if (my $ftp = Net::FTP->new($url)) {
        if ($ftp->login($user,$password)) {
            $logger->debug("FTP EPRICE ($url)->collegamento avvenuto con successo");
            $ftp->binary();
            $ftp->cwd($path);

            my @fileList = $ftp->ls();
            for (my $i=0;$i<@fileList;$i++) {
                if ($ftp->isfile($fileList[$i])) {
                    if ($fileList[$i] =~ /^(.*)\.txt$/) {
                        my $fileName = "$1.txt";
                        if ($ftp->get($fileList[$i], "$inDataFolder/$fileName")) {
                            $logger->info("FTP EPRICE:  stato caricato il file ".$fileList[$i]);

                            $ftp->delete($fileList[$i]);
                        } else {
                            $logger->error("FTP EPRICE: il file ".$fileList[$i]." non  stato caricato");
                        }
                    }
                }
            }
            $ftp->quit();
        } else {
            $logger->warn("FTP EPRICE ($url)->collegamento fallito");
        }
    }

    if (opendir my $DIR, $inDataFolder) {
        my @fileList = sort grep { /^.*\.txt$/ } readdir $DIR;
        closedir $DIR;

        foreach my $fileName (@fileList) {
        	if (-e "$inDataFolder/$fileName") {
                if (open my $fileHandler, "<:crlf", "$inDataFolder/$fileName") {
                    my $line;
                    while (!eof($fileHandler)) {
                        $line = <$fileHandler> ;
                        $line =~  s/\n$//ig;
                        if ($line =~ /^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/) {
                            if ($1 eq 'T') {
                                my $codiceCliente = 'EPRICE';
                                my $riferimento = $2;
                                my $tipo = 0;#$3;
                                my $data = string2date($4);
                                my $codiceVettore = $5;
                                my $numeroRighe = $6*1;
                                my $valoreContrassegno = $7*1;
                                my $destinatario = $8;
                                my $indirizzo = $9;
                                my $cap = $10;
                                my $localita = $11;
                                my $provincia = $12;
                                my $telefono = $13;
                                my $note = $14;

                                if (! $stHT->execute($codiceCliente,$riferimento,$tipo,$data->ymd('-'),$codiceVettore,$numeroRighe,$valoreContrassegno,$destinatario,$indirizzo,$cap,$localita,$provincia,$telefono,$note)) {
                                    print "Errore\n";
                                }
                            }
                        } elsif ($line =~ /^([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/) {
                            if ($1 eq 'R') {
                                my $codiceCliente = 'EPRICE';
                                my $riferimento = $2;
                                my $numeroRiga = $3*1;
                                my $codiceArticolo = $4;
                                my $quantita = $5*1;
                                my $prezzo = $6*1;

                                if (! $stHR->execute($codiceCliente,$riferimento,$numeroRiga,$codiceArticolo,$quantita,$prezzo)){
                                    print "Errore\n";
                                }
                            }
                        }
                    }
                }
                move("$inDataFolder/$fileName", "$bkpDataFolder/$fileName");
                #unlink "$inDataFolder/$fileName";
            } else {
                $logger->warn("File $fileName mancante!");
            }
        }
    }
}

#
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
                                    (`codiceCliente`,`riferimento`,`numeroRiga`,`codiceArticolo`,`quantita`,`prezzo`)
                                values
                                    (?,?,?,?,?,?);
    });

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
    return "$logFolder/".$current_date->ymd('').'_'.$current_time->hms('')."_ricezione_eprice.log";
}
