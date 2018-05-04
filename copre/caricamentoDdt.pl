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
my $requestUrl =  'https://cogeso.copre.it/DownloadServiceOnDemand';
my $requestParams = 'user=200507&password=19673&cliente=200507&file=BOLLE';

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sth_delete;

my $fh;

my %pnd;
my %ricarico;
my %ricaricoVendita;
my %clienti;

my $nomeFile = '/BOLLE.TXT';

if (&ConnessioneDB) {
    my $client = REST::Client->new();
    
    # nel caso di collegamento https non verifico il certificato
    $client->getUseragent()->ssl_opts(verify_hostname => 0);
    
    $client->POST($requestUrl);
    
    my $datiRicevuti = $client->POST($requestUrl, $requestParams, {'Content-type' => 'application/x-www-form-urlencoded'})->responseContent;
    my $tabulato = qq{$datiRicevuti};
    
    open($fh, "+>:crlf", $nomeFile)    || die "can't open $nomeFile: $!";
	binmode($fh);               # for raw; else set the encoding
	print $fh "$tabulato\n";
	close($fh);
    
    my $linea;
    open my $fh, '<:crlf', $nomeFile or die "can't open $nomeFile: $!";
    
    my $numeroBollaInCaricamento = '';
    my $dataBollaInCaricamento = '';
    
    while(! eof ($fh)) {
        $linea = <$fh>;
        $linea =~ s/\n$//ig;
        
        if ($linea =~ /^(\d{5})(\d\d)(\d\d)(\d\d)(\d{6})(.{15})(.{11})(.{43})(.{6})(.{15})(\d{8})(\d{11})(\d{2})(.{13})(.*)$/) {
            my $numeroBolla = rtrim($1);
            my $dataBolla = '20'.$4.'-'.$3.'-'.$2;
            my $codiceCliente = rtrim($5);
            my $codiceArticolo = rtrim($6);
            my $modello = rtrim($7);
            my $descrizioneArticolo = rtrim($8);
            my $filler = rtrim($9);
            my $descrizioneMarchio = rtrim($10);
            my $quantita = $11*1;
            my $prezzoNetto = $12/100;
            my $aliquotaIva = $13*1;
            my $barcode = trim($14);
            my $riferimento = $15;
            $riferimento =~ s/\s+$//;
            
            if ($numeroBollaInCaricamento ne $numeroBolla || $dataBollaInCaricamento ne $dataBolla) {
                $sth_delete->execute($numeroBolla, $dataBolla) or die;
                
                $numeroBollaInCaricamento = $numeroBolla;
                $dataBollaInCaricamento = $dataBolla;
            }
            
            if (! $sth->execute($numeroBolla, $dataBolla, $codiceCliente, $codiceArticolo, $modello, $descrizioneArticolo, $descrizioneMarchio, $quantita, $prezzoNetto, $aliquotaIva, $barcode, $riferimento)) {
                print "Errore di caricamento!\n";
            }
        }
    }
    $sth->finish();
    close $fh;
}

sub ConnessioneDB {
	# connessione al database negozi
	$dbh = DBI->connect("DBI:mysql:copre:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database!\n";
		return 0;
	}
    
    # creazione della table pnd
    $dbh->do(qq{
                create table if not exists`ddt` (
                    `numeroBolla` int(10) NOT NULL,
                    `data` date NOT NULL,
                    `codiceSede` varchar(6) NOT NULL DEFAULT '',
                    `codiceArticolo` varchar(15) NOT NULL DEFAULT '',
                    `modello` varchar(11) NOT NULL DEFAULT '',
                    `descrizioneArticolo` varchar(60) NOT NULL DEFAULT '',
                    `descrizioneMarchio` varchar(15) NOT NULL DEFAULT '',
                    `quantita` int(10) NOT NULL,
                    `prezzoNetto` float NOT NULL,
                    `aliquotaIva` float NOT NULL,
                    `barcode` varchar(13) NOT NULL DEFAULT '',
                    `riferimento` varchar(255) NOT NULL DEFAULT '',
                    KEY `numeroBolla` (`numeroBolla`,`data`)
                ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });

    # elimina il ddt se giˆ presente
    $sth_delete = $dbh->prepare(qq{delete from `ddt` where `numeroBolla` = ? and `data` = ?});
    
    # caricamento della table ddt
    $sth = $dbh->prepare(qq{insert into `ddt`
                                (numeroBolla, data, codiceSede, codiceArticolo, modello, descrizioneArticolo, descrizioneMarchio, quantita, prezzoNetto, aliquotaIva, barcode, riferimento)
                            values
                                (?,?,?,?,?,?,?,?,?,?,?,?)
                            });
                                
    return 1;
}

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };
