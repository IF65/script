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
my $stOk;

# parametri ftp
#------------------------------------------------------------------------------------------------------------
my $url = '11.0.1.231';
my $user = 'copre';
my $password = 'ftp-copre';
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
my %sediCOPRE = ();
my %barcodeCOPRE = ();
my %articoliSM = ();
my %articoliCOPRE = ();

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
            $logger->debug("FTP COPRE ($url)->collegamento avvenuto con successo");
            $ftp->binary();
            $ftp->cwd($path);

            my @fileList = $ftp->ls();

            for (my $i=0;$i<@fileList;$i++) {
                if ($ftp->isfile($fileList[$i])) {
                    if ($fileList[$i] =~ /^(BOLL_)(.*)$/) {
                        my $fileName = "DDT_COPRE_$2";
                        if ($ftp->get($fileList[$i], "$inDataFolder/$fileName")) {
                            open($fileHandler, '>', "$inDataFolder/$fileName.CTL");
                            close($fileHandler);
                            $logger->info("FTP COPRE: caricato il file ".$fileList[$i]);

                            $ftp->delete($fileList[$i]);
                        } else {
                            $logger->error("FTP COPRE: il file ".$fileList[$i]." non  stato caricato");
                        }
                    }
                }
            }
            $ftp->quit();
        } else {
            $logger->warn("FTP COPRE ($url)->collegamento fallito");
        }
    }

    if (opendir my $DIR, $inDataFolder) {
        my @fileList = sort grep { /^.*\.CTL$/ } readdir $DIR;
        closedir $DIR;

        foreach my $fileCTL (@fileList) {
        	my $idCaricamento = getUUID();
            my $fileName = $fileCTL;
            $fileName =~ s/\.CTL$//ig;
            if (-e "$inDataFolder/$fileName") {
                if (open my $fileHandler, "<", "$inDataFolder/$fileName") {
                    my $line;
                    while (!eof($fileHandler)) {
                        $line = <$fileHandler> ;
                        $line =~  s/\n$//ig;
                        if ($line =~ /^(.{10})(\d\d)(\d\d)(\d\d)(.{15})(\d{10}).{6}(\d{6})(.{7})(\d{9})(\d\d)(\d\d)(.{11})(.{49})(.{15})(.{13})/) {
                            my $codiceSocieta = '08';
                            my $codiceFornitore = 'FCOPRE';
                            my $numeroDDT = trim($1);
                            my $dataDDT = "20$2-$3-$4";
                            my $prezzoVendita = 0;
                            my $codiceArticoloCOPRE = trim($5);
                            my $quantita = $6*1;
                            my $codiceSede = trim($7);
                            my $progressivo = $8*1;
                            my $listino = ($9.'.'.$10)*1;
                            my $aliquotaIva = $11*1;
                            my $modello = uc trim($12);
                            my $descrizione = uc trim($13);
                            my $linea = uc trim($14);
                            my $barcode = trim($15);

                            my $settore = '';
                            my $reparto = '';
                            my $famiglia = '';
                            my $sottoFamiglia = "";

                            if(exists($sediCOPRE{$codiceSede})) {
                                $codiceSede = $sediCOPRE{$codiceSede};
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

                            my $codiceArticolo = '';
                            if (exists($barcodeCOPRE{$barcode})) {
                                $codiceArticolo = $barcodeCOPRE{$barcode};
                            }
                            if($codiceArticolo eq '') {
                                if (exists($articoliCOPRE{$codiceArticoloCOPRE})) {
                                    $codiceArticolo = $articoliCOPRE{$codiceArticoloCOPRE};
                                }
                            }

                            if ($codiceArticolo ne '') {
                                if (exists($articoliSM{$codiceArticolo})) {
                                    $settore = $articoliSM{$codiceArticolo}{'codice_settore'};
                                    $reparto = $articoliSM{$codiceArticolo}{'codice_reparto'};
                                    $famiglia = $articoliSM{$codiceArticolo}{'codice_famiglia'};
                                    $sottoFamiglia = $articoliSM{$codiceArticolo}{'codice_sottofamiglia'};
                                    $descrizione = $articoliSM{$codiceArticolo}{'descrizione'};
                                    $modello = $articoliSM{$codiceArticolo}{'modello'};
                                    $linea = $articoliSM{$codiceArticolo}{'linea'};
                                    $aliquotaIva = $articoliSM{$codiceArticolo}{'aliquota_iva'};
                                    $tipoIva = $articoliSM{$codiceArticolo}{'tipo_iva'};
                                    $prezzoVendita = $articoliSM{$codiceArticolo}{'listino_1'};
                                }
                            }

                            if ($stOk->execute($codiceSocieta,$codiceFornitore,$numeroDDT,$dataDDT,$idCaricamento)) {
                                my $count = 0;
                                while(my @row = $stOk->fetchrow_array()) {
                                    $count = $row[0];
                                }
                                if ($count == 0) {
                                    if (!$stH->execute($codiceSocieta,$codiceFornitore,$numeroDDT,$dataDDT,$codiceSede,
                                                                     $settore,$reparto,$famiglia,$sottoFamiglia,$codiceArticolo,$codiceArticoloCOPRE,$barcode,
                                                                     $descrizione,$modello,$linea,$aliquotaIva,$tipoIva,$quantita,$listino,$prezzoVendita,$idCaricamento,$progressivo)) {
                                         print "Errore\n";
                                    }
                                }
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
                            `progressivo` int(11) NOT NULL DEFAULT '0',
  							PRIMARY KEY (`id`),
  							KEY `idCaricamento` (`idCaricamento`)
                            ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });


    if (!$stH->execute()) {
        print "Errore durante la creazione della tabella `$tbl`! " .$dbH->errstr."\n";
        return 0;
    }
    $stH->finish();

    $stH = $dbH->prepare(qq{select n.`codice_interno`, n.`codice_ca` from archivi.negozi as n where n.`societa`='08' and n.`codice_ca`<>''});
    if (!$stH->execute()) {
        return 0;
    } else {
         while(my @row = $stH->fetchrow_array()) {
            $sediCOPRE{$row[1]} = $row[0];
        }
    }
    $stH->finish();

    $stH = $dbH->prepare(qq{select f.`codice_articolo`,f.`codice_articolo_fornitore` from db_sm.fornitore_articolo as f where f.`codice_fornitore` = 'FCOPRE';});
    if (!$stH->execute()) {
        return 0;
    } else {
         while(my @row = $stH->fetchrow_array()) {
            if ( $row[1] =~ /^\d{10}$/ ) {
                $articoliCOPRE{$row[1]} = $row[0];
            }
        }
    }
    $stH->finish();

    $stH = $dbH->prepare(qq{select codice, ean from db_sm.ean});
    if (!$stH->execute()) {
        return 0;
    } else {
         while(my @row = $stH->fetchrow_array()) {
            if ($row[1] =~ /^\d{13}$/) {
                $barcodeCOPRE{$row[1]} = $row[0];
            } elsif ($row[1] =~ /^\d{8}$/) {
                $barcodeCOPRE{$row[1]} = $row[0];
            }

        }
    }
    $stH->finish();

    $stH = $dbH->prepare(qq{select m.codice, m.codice_settore, m.codice_reparto,m.codice_famiglia, m.codice_sottofamiglia, m.descrizione,
                            m.modello, m.linea, m.aliquota_iva, m.tipo_iva, m.listino_1 from db_sm.magazzino as m });
    if (!$stH->execute()) {
        return 0;
    } else {
        while(my @row = $stH->fetchrow_array()) {
            $articoliSM{$row[0]}={  'codice_settore' => $row[1],'codice_reparto'=>$row[2],'codice_famiglia'=>$row[3],'codice_sottofamiglia'=>$row[4],
                                    'descrizione'=>$row[5],'modello'=>$row[6],'linea'=>$row[7],'aliquota_iva'=>$row[8],'tipo_iva'=>$row[9],'listino_1'=>$row[10]
                                };
        }
    }
    $stH->finish();

    # inserimento nuovo recort
    $stH = $dbH->prepare(qq{
                                insert ignore into `$tbl` ( `id`,`codiceSocieta`,`codiceFornitore`,`numeroDDT`,`dataDDT`,`codiceSede`,
                                                            `settore`,`reparto`,`famiglia`,`sottofamiglia`,`codiceArticolo`,`codiceArticoloFornitore`,`barcode`,
                                                            `descrizione`,`modello`,`linea`,`aliquotaIva`,`tipoIva`,`quantita`,`prezzo`,`prezzoVendita`,`idCaricamento`,`progressivo`)
                                values (uuid(),?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
    });

    # verifica se il ddt  giˆ stato caricato in precedenza
    $stOk = $dbH->prepare(qq{select count(*) from ddt.ddt where codiceSocieta = ? and codiceFornitore = ? and numeroDDT = ? and dataDDT = ? and idCaricamento <> ?});

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
