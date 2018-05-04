#!/usr/bin/perl
use strict;
use warnings;

use lib '/root/perl5/lib/perl5';

use DBI;
use REST::Client;
use DateTime;
use POSIX;

# data e ora di caricamento dei dati
#------------------------------------------------------------------------------------------------------------
my $currentDate = DateTime->now(time_zone=>'local');
my $timestamp   = $currentDate->ymd().' '.$currentDate->hms();
my $data        = $currentDate->ymd('-');

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "10.11.14.78";
my $username = "root";
my $password = "mela";

# parametri di chiamata REST
#------------------------------------------------------------------------------------------------------------
my $requestUrl =  'https://cogeso.copre.it/DownloadService';
my $requestParams = 'user=200507&password=19673&cliente=200507&file=CIRCOLARI';

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;

my %pnd;
my %ricarico;
my %ricaricoVendita;
my %clienti;

if (&ConnessioneDB) {
    my $client = REST::Client->new();
    
    # nel caso di collegamento https non verifico il certificato
    $client->getUseragent()->ssl_opts(verify_hostname => 0);
    
    $client->POST($requestUrl);
    
    my $datiRicevuti = $client->POST($requestUrl, $requestParams, {'Content-type' => 'application/x-www-form-urlencoded'})->responseContent;
    my $tabulato = qq{$datiRicevuti};
    
    if ( $client->responseCode() eq '200' ) {
        my $linea;
        open my $fh, '<:crlf', \$tabulato or die $!;
       
        while(! eof ($fh)) {
            $linea = <$fh>;
            $linea =~ s/\n$//ig;
            
            if ($linea =~ /^(.{10})(\d\d)(\d\d)(\d{4})(.{3})(.)(\d\d)(\d\d)(\d{4})(\d\d)(\d\d)(\d{4})(.{20})(.{15})(.{13})(.)(\d{10})(\d{11})(\d{11})/) {
                
                my $codice = rtrim($1);
                my $data = $4.'-'.$3.'-'.$2;
                my $destinazione = $5;
                my $tipo = $6;
                my $dataInizio = $9.'-'.$8.'-'.$7;
                my $dataFine = $12.'-'.$11.'-'.$10;
                my $codiceArticoloInterno = $13;
                my $codiceArticoloCopre = $14;
                my $barcode = $15;
                my $tipoValore = $16;
                my $valoreCircolare = $17/100;
                my $prezzoVenditaPubblico = $18/100;
                my $prezzoAcquistoSocio = $19/100;
                
                $sth->execute($timestamp, $codice, $data, $destinazione, $tipo, $dataInizio, $dataFine, $codiceArticoloInterno, $codiceArticoloCopre, $barcode, $tipoValore,
                                 $valoreCircolare, $prezzoVenditaPubblico, $prezzoAcquistoSocio);
            }
        }
        $sth->finish();
        close $fh;
    }
}

sub ConnessioneDB {
	# connessione al database negozi
	$dbh = DBI->connect("DBI:mysql:copre:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database!\n";
		return 0;
	}

    # creazione della table circolari
    $dbh->do(qq{
                CREATE TABLE if not exists circolari (
                `idTime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
                `codice` varchar(10) NOT NULL DEFAULT '',
                `data` date NOT NULL,
                `destinazione` varchar(3) NOT NULL DEFAULT '',
                `tipo` varchar(1) NOT NULL DEFAULT '',
                `dataInizio` date NOT NULL,
                `dataFine` date NOT NULL,
                `codiceArticoloInterno` varchar(20) NOT NULL DEFAULT '',
                `codiceArticoloCopre` varchar(15) NOT NULL DEFAULT '',
                `barcode` varchar(13) NOT NULL DEFAULT '',
                `tipoValore` varchar(1) NOT NULL DEFAULT '',
                `valoreCircolare` float NOT NULL,
                `prezzoVenditaPubblico` float NOT NULL,
                `prezzoAcquistoSocio` float NOT NULL,
                PRIMARY KEY (`codice`,`codiceArticoloCopre`),
  				KEY `idTime` (`idTime`)
              ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });
                                
     $sth = $dbh->prepare(qq{replace into circolari (idTime, codice, data, destinazione, tipo, dataInizio, dataFine, codiceArticoloInterno, codiceArticoloCopre, barcode, tipoValore,
                                 valoreCircolare, prezzoVenditaPubblico, prezzoAcquistoSocio)
                            values
                                (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                            });
    return 1;
}

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };
