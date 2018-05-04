#!/usr/bin/perl
use strict;
use warnings;

use DBI;
use REST::Client;

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "10.11.14.78";
my $username = "root";
my $password = "mela";


# parametri di chiamata REST
#------------------------------------------------------------------------------------------------------------
my $requestUrl =  'https://cogeso.copre.it/DownloadService';
my $requestParams = 'user=200507&password=19673&cliente=200507&file=ARTICOLI_S';

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;

if (&ConnessioneDB) {
    my $client = REST::Client->new();
    
    # nel caso di collegamento https non verifico il certificato
    $client->getUseragent()->ssl_opts(verify_hostname => 0);
    
    $client->POST($requestUrl);
    
    my $datiRicevuti = $client->POST($requestUrl, $requestParams, {'Content-type' => 'application/x-www-form-urlencoded'})->responseContent;
    my $tabulato = qq{$datiRicevuti};
    
    if ( $client->responseCode() eq '200' ) {
    #if ( 1 ) {
        my $linea;
        open my $fh, '<:crlf', \$tabulato or die $!;
        #open my $fh, '<:crlf', '/Users/if65/Desktop/ARTICOLI_S.ASC' or die $!;
        
        while(! eof ($fh)) {
            $linea = <$fh>;
            $linea =~ s/\n$//ig;
            
            if ($linea =~ /^(\d{10}).{5}(.{11})(.{49})(\d{8})(\d{8})(\d{11})(\d{11})(\d{11})(.{2})(\w|\s)(\w|\s)(.{13})(.{15})(..)(.).(.{8}).(.{3}).(\d{11})(\d{11})..(.)(.)..$/) {
                my $codice = rtrim($1);
                my $modello = rtrim($2);
                my $descrizione = rtrim($3);
                my $giacenza = $4 * 1;
                my $inOrdine = $5 * 1;
                my $prezzoAcquisto = $6 /100;
                my $prezzoRiordino = $7 /100;
                my $prezzoVendita = $8 /100;
                my $aliquotaIva = $9;
                my $novita = (rtrim($10) eq 'N');
                my $eliminato = (rtrim($10) eq 'X');
                my $esclusiva = (rtrim($11) ne '');
                my $ean = rtrim($12);
                my $marchio = rtrim($13);
                my $griglia = rtrim($14);
                my $grigliaObbligo = (rtrim($15) ne '');
                my $ediel = rtrim($16);
                my $marchioGCC = rtrim($17);
                my $doppioNetto = $18/100;
                my $triploNetto = $19/100;
                my $ordinabile = (rtrim($20) eq 'Y');
                my $canale = $21;
                
                if ($griglia eq 'C') {$griglia = ''};
                
                $sth->execute($codice, $modello, $descrizione, $giacenza, $inOrdine, $prezzoAcquisto, $prezzoRiordino, $prezzoVendita, $aliquotaIva, $novita, $eliminato, 
                               $esclusiva, $ean, $marchio, $griglia, $grigliaObbligo, $ediel, $marchioGCC, $doppioNetto, $triploNetto, $ordinabile, $canale);
            }
        }
        $sth->finish();
        close $fh;
    }
}

sub ConnessioneDB {
	# connessione al database negozi
	$dbh = DBI->connect("DBI:mysql:db_sm:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database!\n";
		return 0;
	}
    
    # cancellazione della tabella precedente
    $dbh->do(qq{drop table if exists `tabulatoCopreNew`});
    

    # creazione della table tabulato copre
    $dbh->do(qq{
                CREATE TABLE IF NOT EXISTS `tabulatoCopreNew` (
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
                  `marchio` varchar(15) DEFAULT NULL,
                  `griglia` varchar(2) DEFAULT NULL,
                  `grigliaObbligatorio` tinyint(2) DEFAULT NULL,
                  `ediel` varchar(8) DEFAULT NULL,
                  `marchioGcc` varchar(3) DEFAULT NULL,
                  `doppioNetto` float DEFAULT NULL,
                  `triploNetto` float DEFAULT NULL,
                  `ordinabile` tinyint(2) DEFAULT NULL,
                  `canale` int(2) DEFAULT NULL,
                  `pndAC` float DEFAULT NULL,
                  `pndAP` float DEFAULT NULL,
                PRIMARY KEY (`codice`)
                ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });
    
    # creazione della table tabulato copre
    $sth = $dbh->prepare(qq{insert into tabulatoCopreNew 
                                (codice, modello, descrizione, giacenza, inOrdine, prezzoAcquisto, prezzoRiordino, prezzoVendita, aliquotaIva, novita,
                                eliminato, esclusiva, barcode, marchio, griglia, grigliaObbligatorio, ediel, marchioGcc, doppioNetto, triploNetto,
                                ordinabile, canale)
                            values
                                (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                            });
    return 1;
}

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };
