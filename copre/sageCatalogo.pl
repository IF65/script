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
my $sth_sage;
my %codiceCopre = ();

# Connessione al db
#---------------------------------------------------------------------------------------
if (&ConnessioneDB()) {
	if ($sth->execute()) {
		#if (open my $fileHandler, "+>:crlf", $folder.'/'.'test.txt') {
			while ( my @row = $sth->fetchrow_array() ) {
				if (exists $codiceCopre{$row[1]}) {
					$sth_sage->execute($row[0], $codiceCopre{$row[1]}, $row[1], $row[2], $row[3], $row[4], $row[5], $row[6], $row[7]);
#					print $fileHandler $row[0]."\t";
# 					print $fileHandler $codiceCopre{$row[1]}."\t";
# 					print $fileHandler $row[1]."\t";
# 					print $fileHandler $row[2]."\t";
# 					print $fileHandler $row[3]."\t";
# 					print $fileHandler $row[4]."\t";
# 					print $fileHandler $row[5]."\t";
# 					print $fileHandler $row[6]."\t";
# 					print $fileHandler $row[7]."\n";
				}
			}
		#}
	}
}
 

exit;

sub ConnessioneDB{
	$dbh = DBI->connect("DBI:mysql:copre:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database!\n";
		return 0;
	}

    # caricamento elenco clienti
    $sth = $dbh->prepare(qq{select f.`codice_articolo`, f.`codice_articolo_fornitore` from db_sm.fornitore_articolo as f where f.`codice_fornitore`='FCOPRE' });
    if ($sth->execute()) {
        while (my @row = $sth->fetchrow_array()) {
            $codiceCopre{$row[0]} = $row[1];
        }
    }
    
    # creazione della table sageTabulatoCliente
    $dbh->do(qq{
                CREATE TABLE IF NOT EXISTS copre.`sageTabulatoCliente` (
                    `cliente` varchar(20) NOT NULL DEFAULT '',
  					`codice` varchar(10) NOT NULL DEFAULT '',
  					`codiceSM` varchar(7) NOT NULL DEFAULT '',
  					`prezzoListino` float NOT NULL,
  					`aliquotaIva` float NOT NULL,
  					`prezzoNetto` float NOT NULL,
  					`dataInizio` date NOT NULL,
  					`dataFine` date NOT NULL,
  					`barcode` varchar(13) NOT NULL DEFAULT '',
  				PRIMARY KEY (`cliente`,`codice`)
				) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });
    
    # caricamento della table sageTabulatoCliente cliente
    $sth_sage = $dbh->prepare(qq{insert into copre.sageTabulatoCliente
                                        (cliente, codice, codiceSM, prezzoListino, aliquotaIva, prezzoNetto, dataInizio, dataFine, barcode)
                                    values
                                        (?,?,?,?,?,?,?,?,?);
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
