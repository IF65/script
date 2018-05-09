#!/usr/bin/perl -w
use strict;
use DBI;
use DBD::Oracle qw(:ora_session_modes);
use File::HomeDir;
use DateTime;

# data di partenza caricamento
#---------------------------------------------------------------------------------------
my $current_date = DateTime->today(time_zone=>'local');

# parametri di configurazione del database mysql
#---------------------------------------------------------------------------------------
my $hostname    = "localhost";
my $username    = "root";
my $password    = "mela";
my $database    = "";

# parametri di configurazione del database oracle
#---------------------------------------------------------------------------------------
my $hostname_or = "10.11.14.230";
my $username_or = "SYS";
my $password_or = "SageDBPass1";

# definizione cartelle
#----------------------------------------------------------------------------------------------------------------------
my $desktop = File::HomeDir->my_desktop;
my $folder = "/catalogoClientiB2B";

# Creazione cartelle locali (se non esistono)
#----------------------------------------------------------------------------------------------------------------------
unless (-e $folder or mkdir $folder) {die "Impossibile creare la cartella $folder: $!\n";};

# variabili globali
#---------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sthInsertTabulatoCliente;
my %codiceCopre = ();
my %importiCopre = ();

# Connessione al db
#---------------------------------------------------------------------------------------
if (&ConnessioneDB()) {
	if ($sth->execute()) {
		if (open my $fileHandler, "+>:crlf", $folder.'/'.'test.txt') {
			while ( my @row = $sth->fetchrow_array() ) {
				if (exists $codiceCopre{$row[1]}) {
					if (exists $importiCopre{$codiceCopre{$row[1]}}) {
						my $categoria = 'B2B';
						if ($row[0] eq 'Supermedia' ) {$categoria = 'B2C'};
						
						print $fileHandler $current_date->ymd('-')."\t"; 
						print $fileHandler $row[0]."\t"; # codiceCliente
						print $fileHandler $categoria."\t"; # categoria
	 					print $fileHandler $codiceCopre{$row[1]}."\t";
	 					print $fileHandler $importiCopre{$codiceCopre{$row[1]}}{'doppioNetto'}."\t";
	 					print $fileHandler $importiCopre{$codiceCopre{$row[1]}}{'nettoNetto'}."\t";
	 					print $fileHandler '0'."\t";
						print $fileHandler '0'."\t";
						print $fileHandler '0'."\t";
						print $fileHandler '0'."\t";
	 					print $fileHandler $row[2]."\t"; # prezzoCliente
	 					print $fileHandler $row[4]."\t"; # prezzoNettoCliente
	 					print $fileHandler $row[5]."\t"; # inPromoDa
	 					print $fileHandler $row[6]."\t"; # inPromoA
						print $fileHandler $row[1]."\n"; # codiceArticoloSM
						
						#$sthInsertTabulatoCliente->execute(	$current_date->ymd('-'), $row[0], $categoria, $codiceCopre{$row[1]}, $importiCopre{$codiceCopre{$row[1]}}{'doppioNetto'},
						#									$importiCopre{$codiceCopre{$row[1]}}{'nettoNetto'}, 0,0,0,0,$row[2], $row[4], $row[5], $row[6], $row[1]);
					}
				}
			}
		}
	}
}
 

exit;

sub ConnessioneDB{
	$dbh = DBI->connect("DBI:mysql:copre:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database!\n";
		return 0;
	}

    # caricamento corrispondeza articoli
    $sth = $dbh->prepare(qq{select f.`codice_articolo`, f.`codice_articolo_fornitore` from db_sm.fornitore_articolo as f where f.`codice_fornitore`='FCOPRE' });
    if ($sth->execute()) {
        while (my @row = $sth->fetchrow_array()) {
            $codiceCopre{$row[0]} = $row[1];
        }
    }
	
	# creazione della table tabulatoCopre
    $dbh->do(qq{
                CREATE TABLE IF NOT EXISTS `tabulatoCopre` (
                    `idTime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
                    `codice` varchar(10) NOT NULL DEFAULT '',
                    `modello` varchar(11) DEFAULT NULL,
                    `descrizione` varchar(49) DEFAULT NULL,
                    `giacenza` int(11) DEFAULT NULL,
                    `inOrdine` int(11) DEFAULT NULL,
                    `prezzoAcquisto` float DEFAULT NULL,
                    `prezzoRiordino` float DEFAULT NULL,
                    `prezzoVendita` float DEFAULT NULL,
                    `aliquotaIva` int(11) DEFAULT NULL,
                    `novita` tinyint(11) DEFAULT NULL,
                    `eliminato` tinyint(11) DEFAULT NULL,
                    `esclusiva` tinyint(11) DEFAULT NULL,
                    `barcode` varchar(13) DEFAULT NULL,
                    `marchioCopre` varchar(15) DEFAULT NULL,
                    `griglia` varchar(2) DEFAULT NULL,
                    `grigliaObbligatorio` tinyint(2) DEFAULT NULL,
                    `ediel01` varchar(2) DEFAULT NULL,
                    `ediel02` varchar(2) DEFAULT NULL,
                    `ediel03` varchar(2) DEFAULT NULL,
                    `ediel04` varchar(2) DEFAULT NULL,
                    `marchio` varchar(3) DEFAULT NULL,
                    `ricaricoPercentuale` float DEFAULT NULL,
                    `doppioNetto` float DEFAULT NULL,
                    `triploNetto` float DEFAULT NULL,
                    `nettoNetto` float DEFAULT NULL,
                    `ordinabile` tinyint(2) DEFAULT NULL,
                    `canale` int(2) DEFAULT NULL,
                    `pndAC` float DEFAULT NULL,
                    `pndAP` float DEFAULT NULL,
                PRIMARY KEY (`codice`),
  				KEY `ediel` (`ediel01`,`ediel02`,`ediel03`,`ediel04`),
  				KEY `marchio` (`marchio`),
  				KEY `idTime` (`idTime`)
                ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });
	
	# caricamento tabulato copre
	$sth = $dbh->prepare(qq{select codice, doppioNetto, nettoNetto from tabulatoCopre where doppioNetto <> 0});
	if ($sth->execute()) {
        while (my @row = $sth->fetchrow_array()) {
            $importiCopre{$row[0]} = {'doppioNetto' => $row[1], 'nettoNetto' => $row[2]};
        }
    }
    
    # creazione della table tabulatoCliente
    $dbh->do(qq{
                CREATE TABLE if not exists `tabulatoCliente` (
					  `data` date NOT NULL,
					  `codiceCliente` varchar(20) NOT NULL DEFAULT '',
					  `categoria` varchar(20) NOT NULL,
					  `codiceArticolo` varchar(10) NOT NULL DEFAULT '',
					  `doppioNetto` float DEFAULT '0',
					  `nettoNetto` float DEFAULT '0',
					  `ricarico01` float DEFAULT '0',
					  `ricarico02` float DEFAULT '0',
					  `ricarico03` float DEFAULT '0',
					  `ricarico04` float DEFAULT '0',
					  `prezzoCliente` float DEFAULT '0',
					  `prezzoNettoCliente` float DEFAULT '0',
					  `inPromoDa` date DEFAULT NULL,
					  `inPromoA` date DEFAULT NULL,
					  `codiceArticoloSM` varchar(7) NOT NULL DEFAULT '',
					  PRIMARY KEY (`data`,`codiceCliente`,`codiceArticolo`),
					  KEY `codiceCliente` (`codiceCliente`,`codiceArticolo`)
					) ENGINE=InnoDB DEFAULT CHARSET=latin1;
				});
    
    # caricamento della table tabulatoCliente cliente
    $sthInsertTabulatoCliente = $dbh->prepare(qq{insert into copre.tabulatoCliente
													(data, codiceCliente, categoria, codiceArticolo, doppioNetto, nettoNetto, ricarico01, ricarico02, ricarico03,
													 ricarico04, prezzoCliente, prezzoNettoCliente, inPromoDa, inPromoA, codiceArticoloSM)
												values
													(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);
											});
	
	
    
	$dbh = DBI->connect('dbi:Oracle:',qq{$username_or/$password_or@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$hostname_or)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=SAGEX3U9)))},"", { ora_session_mode => ORA_SYSDBA }) or die;
	
	$sth = $dbh->prepare("	select	case 
										when BPCORD_0 = 'A000002' then 'EPRICE' 
										when BPCORD_0 = 'A000003' then 'YEPPON' 
										when BPCORD_0 = 'A000004' then 'ONLINESTORE' 
										when BPCORD_0 = 'A000005' then 'TEKWORLD' 
										when BPCORD_0 = 'A000006' then 'Supermedia' 
										when BPCORD_0 = 'A000007' then 'BRANDON' 
									else
										'XXXXXXXX'
									end,
									ITMREF_0,
									PRZ_LISTINO_0,
									VATRAT_0,
									PRZ_NETTO_0,
									to_char(PLISTRDAT_0, 'RRRR-MM-DD'),
									to_char(PLIENDDAT_0, 'RRRR-MM-DD'),
									EANCOD_0 
							from	IF65.YCATALOGO");
	
	return 1;
}
