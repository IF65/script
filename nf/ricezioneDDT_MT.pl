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
my $db = 'ddt';
my $tbl = 'ddt';
my $dbH;
my $stH;

my $stDdtH;

# parametri ftp
#------------------------------------------------------------------------------------------------------------
my $url = 'mail.mtdistribution.it';
my $user = 'supermediaddt';
my $password = 'ZC65U97-nk12';
my $path = '';

# definizione cartelle
#------------------------------------------------------------------------------------------------------------
my $mainDataFolder = '/DDT08'; #Supermedia
my $inDataFolder = $mainDataFolder.'/IN';
my $bkpDataFolder = $mainDataFolder.'/BKP';
my $mainLogFolder = "/log";
my $logFolder = "$mainLogFolder/".substr($current_date->ymd(''),0,6);

# hash per conversione codici sede
#------------------------------------------------------------------------------------------------------------
my %sediMT = ();
my %barcodeSM = ();

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
$logger->info("ricezione DDT");
$logger->info("-" x 76);
$logger->info("inizio");

my $fileHandler;

    if (&ConnessioneDB) {
    if (my $ftp = Net::FTP->new($url)) {
        if ($ftp->login($user,$password)) {
            $logger->debug("FTP MT ($url)->collegamento avvenuto con successo");
            $ftp->binary();
            $ftp->cwd($path);

            my @fileList = $ftp->ls();

            for (my $i=0;$i<@fileList;$i++) {
                if ($ftp->isfile($fileList[$i])) {
                    if ($fileList[$i] =~ /^(ddt_)(.*)$/) {
                        my $fileName = "DDT_MT_$2";
                        if ($ftp->get($fileList[$i], "$inDataFolder/$fileName")) {
                            open($fileHandler, '>', "$inDataFolder/$fileName.CTL");
                            close($fileHandler);
                            $logger->info("FTP MT: caricato il file ".$fileList[$i]);

                            $ftp->delete($fileList[$i]);
                        } else {
                            $logger->error("FTP MT: il file ".$fileList[$i]." non  stato caricato");
                        }
                    }
                }
            }
            $ftp->quit();
        } else {
            $logger->warn("FTP MT ($url)->collegamento fallito");
        }
    }

    if (opendir my $DIR, $inDataFolder) {
        my @fileList = sort grep { /^.*\.CTL$/ } readdir $DIR;
        closedir $DIR;

        foreach my $fileCTL (@fileList) {
            my $fileName = $fileCTL;
            $fileName =~ s/\.CTL$//ig;
            if (-e "$inDataFolder/$fileName") {
                if (open my $fileHandler, "<", "$inDataFolder/$fileName") {
                	my $idCaricamento = getUUID();
                    my $line;
                    while (!eof($fileHandler)) {
                        $line = <$fileHandler> ;
                        $line =~  s/\n$//ig;
                        if ($line =~ /^.{35}(.{17})(\d\d)\/(\d\d)\/(\d{4}).{168}(\d{5}),(\d\d).{62}(.{13})(.{40}).{4}(\d{4})(\d{5}),(\d\d)(\d{6}).{5}(.{40})(.{26})(.{10})(\d{3})/) {
                            my $codiceSocieta = '08';
                            my $codiceFornitore = 'FMT';
                            my $numeroDDT = trim($1);
                            my $dataDDT = "$4-$3-$2";
                            my $prezzoVendita = ($5.'.'.$6)*1;
                            my $barcode = trim($7);
                            my $titolo = uc trim($8);
                            my $quantita = $9*1;
                            my $listino = ($10.'.'.$11)*1;
                            my $autore = uc trim($13);
                            my $produttore = uc trim($14);
                            my $supporto = uc trim($15);
                            my $aliquotaIva = trim($16);

                            my $codiceSede = '';
                            if(exists($sediMT{trim($12)})) {
                                $codiceSede = $sediMT{trim($12)};
                            }

                            my $codiceArticolo = '';
                            if (exists($barcodeSM{$barcode})) {
                                $codiceArticolo = $barcodeSM{$barcode};
                            }

                            my $settore = 'SV2';
                            my $reparto = 'RV80';
                            my $famiglia = '67';
                            my $sottoFamiglia = "";
                            my $linea = '';
                            my $suffissoDescrizione = "";

                            if ( $supporto eq "ACCESSORI" or $supporto eq "EDITORIA") {
                                $sottoFamiglia = "10";
                                $linea = "MT ACC";
                                $suffissoDescrizione = "";
                                $aliquotaIva = 0;
                            } elsif ($supporto eq "CD" or $supporto eq "CDMT" or $supporto eq "CDPF") {
                                $sottoFamiglia = "1";
                                $linea = "MT AUDIO";
                                $suffissoDescrizione = "CD ";
                            } elsif ($supporto eq "DVD" or $supporto eq "DVD MT" or $supporto eq "DVD MUS.MT" or $supporto eq "DVD MUSICALI" or $supporto eq "DVD/BRD") {
                                $sottoFamiglia = "2";
                                $linea = "MT VIDEO";
                                $suffissoDescrizione = "DVD ";
                            } elsif ($supporto eq "BRD") {
                                $sottoFamiglia = "4";
                                $linea = "MT VIDEO";
                                $suffissoDescrizione = "BRD ";
                            } else {
                                $sottoFamiglia = "4";
                                $linea = "MT VIDEO";
                                $suffissoDescrizione = "";
                            }

                        	my $tipoIva;
                            if ($aliquotaIva == 20) {
                                $tipoIva = 6;
                            } elsif ($aliquotaIva == 21) {
                                $tipoIva = 11;
                            } elsif ($aliquotaIva == 10) {
                                $tipoIva = 5;
                            } elsif ($aliquotaIva == 4) {
                                $tipoIva = 4;
                            } elsif ($aliquotaIva == 22) {
                                $tipoIva = 16;
                            } else {
                                $tipoIva = 3;
                            	$aliquotaIva = 0;
                            }

                            my $descrizione = $suffissoDescrizione.$titolo;
                            if ($autore ne '') {
                                $descrizione .= ' - '.$autore;
                            }

                           if (!$stH->execute($codiceSocieta,$codiceFornitore,$numeroDDT,$dataDDT,$codiceSede,
                                                            $settore,$reparto,$famiglia,$sottoFamiglia,$codiceArticolo,$barcode,$barcode,
                                                            $descrizione,$produttore,$linea,$aliquotaIva,$tipoIva,$quantita,$listino,$prezzoVendita,$idCaricamento)) {
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

    # creazione della tabella campagne
    $stH = $dbH->prepare(qq{
                            CREATE TABLE IF not exists`$tbl` (
                            `id` varchar(36) NOT NULL DEFAULT '',
                            `codiceSocieta` varchar(2) NOT NULL DEFAULT '',
                            `codiceFornitore` varchar(40) NOT NULL DEFAULT '',
                            `numeroDDT` varchar(40) NOT NULL DEFAULT '',
                            `dataDDT` date NOT NULL,
                            `codiceSede` varchar(4) NOT NULL DEFAULT '',
                            `dataCaricamento` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            `settore` varchar(10) NOT NULL DEFAULT '',
                            `reparto` varchar(10) NOT NULL DEFAULT '',
                            `famiglia` varchar(10) NOT NULL DEFAULT '',
                            `sottofamiglia` varchar(10) NOT NULL DEFAULT '',
                            `codiceArticolo` varchar(7) NOT NULL DEFAULT '',
                            `codiceArticoloFornitore` varchar(40) NOT NULL DEFAULT '',
                            `barcode` varchar(13) NOT NULL DEFAULT '',
                            `descrizione` varchar(255) NOT NULL DEFAULT '',
                            `modello` varchar(255) NOT NULL DEFAULT '',
                            `linea` varchar(255) NOT NULL DEFAULT '',
                            `aliquotaIva` float NOT NULL DEFAULT 0.0,
                            `tipoIva` int(11) NOT NULL DEFAULT 0,
                            `quantita` int(11) NOT NULL DEFAULT 0,
                            `prezzo` float NOT NULL DEFAULT 0.0,
                            `prezzoVendita` float NOT NULL DEFAULT 0.0,
                            `stato` int(11) NOT NULL DEFAULT 0,
                            `idCaricamento` varchar(36) NOT NULL DEFAULT '',
  							PRIMARY KEY (`id`),
  							KEY `idCaricamento` (`idCaricamento`)
                            ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });


    if (!$stH->execute()) {
        print "Errore durante la creazione della tabella `$tbl`! " .$dbH->errstr."\n";
        return 0;
    }
    $stH->finish();

    $stH = $dbH->prepare(qq{select n.`codice_interno`, n.`codice_mt` from archivi.negozi as n where n.`societa`='08' and n.`codice_mt`<>''});
    if (!$stH->execute()) {
        return 0;
    } else {
         while(my @row = $stH->fetchrow_array()) {
            $sediMT{$row[1]} = $row[0];
        }
    }
    $stH->finish();

    $stH = $dbH->prepare(qq{select codice, ean from db_sm.ean});
    if (!$stH->execute()) {
        return 0;
    } else {
         while(my @row = $stH->fetchrow_array()) {
            $barcodeSM{$row[1]} = $row[0];
        }
    }
    $stH->finish();

     # creazione della tabella campagne
    $stH = $dbH->prepare(qq{
                                insert ignore into `$tbl` ( `id`,`codiceSocieta`,`codiceFornitore`,`numeroDDT`,`dataDDT`,`codiceSede`,
                                                            `settore`,`reparto`,`famiglia`,`sottofamiglia`,`codiceArticolo`,`codiceArticoloFornitore`,`barcode`,
                                                            `descrizione`,`modello`,`linea`,`aliquotaIva`,`tipoIva`,`quantita`,`prezzo`,`prezzoVendita`,`idCaricamento`)
                                values (uuid(),?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
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
    return "$logFolder/".$current_date->ymd('').'_'.$current_time->hms('')."_ricezione_journal.log";
}
