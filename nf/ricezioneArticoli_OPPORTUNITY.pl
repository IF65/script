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

# parametri database
#----------------------------------------------------------------------------------------------------------------------
my $dbHost = '10.11.14.78';
my $dbUser = 'root';
my $dbPassword = 'mela';
my $db = 'ddt';
my $tbl = 'articoli';
my $dbH;
my $stH;

my $stDdtH;

# parametri ftp
#------------------------------------------------------------------------------------------------------------
my $url = 'ftp.opportunityspa.it';
my $user = 'supermedia';
my $password = 'w34kj.c084c';
my $path = 'Out';

# definizione cartelle
#------------------------------------------------------------------------------------------------------------
my $mainDataFolder = '/DDT08'; #Supermedia
my $inDataFolder = $mainDataFolder.'/IN';
my $bkpDataFolder = $mainDataFolder.'/BKP';
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

my $barraSpaziatrice = "-" x 76;

$logger->info($barraSpaziatrice);
$logger->info("ricezione Opportunity Articoli");
$logger->info($barraSpaziatrice);
$logger->info("inizio");

my $fileHandler;

    if (&ConnessioneDB) {
    if (my $ftp = Net::FTP->new($url)) {
        if ($ftp->login($user,$password)) {
            $logger->debug("FTP Opportunity Articoli ($url)->collegamento avvenuto con successo");
            $ftp->binary();
            $ftp->cwd($path);

            my @fileList = $ftp->ls();

            for (my $i=0;$i<@fileList;$i++) {
                if ($ftp->isfile($fileList[$i])) {
                    if ($fileList[$i] =~ /^XMXCEL09.*$/) {
                        my $timeStamp = DateTime->now(time_zone=>'local')->iso8601();
                        $timeStamp =~ s/(\-|\:)//ig;
                        my $fileName = "OPP_ANAG_$timeStamp";
                        if ($ftp->get($fileList[$i], "$inDataFolder/$fileName.CSV")) {
                            open($fileHandler, '>', "$inDataFolder/$fileName.CTL");
                            close($fileHandler);
                            $logger->info("FTP Opportunity Articoli: caricato il file ".$fileList[$i]);

                            $ftp->delete($fileList[$i]);
                        } else {
                            $logger->error("FTP Opportunity Articoli: il file ".$fileList[$i]." non  stato caricato");
                        }
                    }
                }
            }
            $ftp->quit();
        } else {
            $logger->warn("FTP Opportunity Articoli ($url)->collegamento fallito");
        }
    }

    if (opendir my $DIR, $inDataFolder) {
        my @fileList = sort grep { /^.*\.CTL$/ } readdir $DIR;
        closedir $DIR;

        foreach my $fileCTL (@fileList) {
            my $fileName = $fileCTL;
            $fileName =~ s/\.CTL$/\.CSV/ig;
            if (-e "$inDataFolder/$fileName") {
                if (open my $fileHandler, "<", "$inDataFolder/$fileName") {
                	my $idCaricamento = getUUID();
                    my $line;
                    while (!eof($fileHandler)) {
                        $line = <$fileHandler> ;
                        $line =~  s/\n$//ig;
                        if ($line =~ /^.{10}(.{30}).{8}(\d{2})..(.{13}).{5}(\d{8})(\d{3})(\d{4})(\d{2})(\d{2})(\d{4})(\d{2})(\d{2})/) {
                            my $descrizione = rtrim($1);
                            my $aliquota = $2*1;
                            my $barcode = trim($3);
                            my $prezzoVendita = ($4.'.'.$5)*1;
                            my $inizioValidita = "$6-$7-$8";
                            my $fineValidita = "$9-$10-$11";

                            if ($fineValidita eq '9999-99-99') {$fineValidita = 'NULL'}

                            if (!$stH->execute($barcode, $descrizione, $aliquota, $prezzoVendita, $inizioValidita, $fineValidita)) {
                                print "Errore\n";
                            }
                        }
                    }
                }

                unlink "$inDataFolder/$fileCTL";
                move("$inDataFolder/$fileName", "$bkpDataFolder/$fileName")
            } else {
                $logger->warn("File di controllo $fileCTL ancora presente. File $fileName mancante!");
            }
        }
    }
}

#
$logger->info("fine");
$logger->info($barraSpaziatrice);

#FINE
#---------------------------------------------------------------------------------------------------
sub ConnessioneDB {
    # connessione al database negozi
    $dbH = DBI->connect("DBI:mysql:$db:$dbHost", $dbUser, $dbPassword);
    if (! $dbH) {
        print "Errore durante la connessione al database `$db`!\n";
        return 0;
    }

    # creazione della tabella articoli
    $stH = $dbH->prepare(qq{
                            CREATE TABLE IF not exists`$tbl` (
                            `codiceSocieta` varchar(2) NOT NULL DEFAULT '',
                            `codiceFornitore` varchar(40) NOT NULL DEFAULT '',
                            `barcode` varchar(13) NOT NULL,
                            `descrizione` varchar(255) NOT NULL DEFAULT '',
                            `aliquotaIva` float NOT NULL DEFAULT '0',
                            `prezzoVendita` float NOT NULL DEFAULT '0',
                            `dataInizioValidita` date NOT NULL,
                            `dataFineValidita` date DEFAULT NULL,
                            `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                            PRIMARY KEY (`barcode`)
                            ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });


    if (!$stH->execute()) {
        print "Errore durante la creazione della tabella `$tbl`! " .$dbH->errstr."\n";
        return 0;
    }
    $stH->finish();

     # insert nella tabella articoli
    $stH = $dbH->prepare(qq{replace into `$tbl` ( `codiceSocieta`,`codiceFornitore`,`barcode`,`descrizione`,`aliquotaIva`,`prezzoVendita`,`dataInizioValidita`,`dataFineValidita`)
                            values ('08','FMFINGROSS',?,?,?,?,?,?)
    });


    return 1;
}

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

sub getUUID {
    my $uuid;
    my $string;
    UUID::generate($uuid); # generates a 128 bit uuid
    UUID::unparse($uuid, $string); # change $uuid to 36 byte string

    return $string;
}

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub log_file_name{
    return "$logFolder/".$current_date->ymd('').'_'.$current_time->hms('')."_caricamento_articoli_opportunity_journal.log";
}
