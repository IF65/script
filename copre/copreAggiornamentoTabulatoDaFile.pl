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
my $requestParams = 'user=200507&password=19673&cliente=200507&file=ARTICOLI_S';

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sth_cliente;
my $sth_giacenze;

my %pnd;
my %ricarico;
my %ricaricoVendita;
my %clienti;

my $nomeFile = '/ARTICOLI_S.TXT';

if (&ConnessioneDB) {
    my $client = REST::Client->new();
    
    # nel caso di collegamento https non verifico il certificato
    $client->getUseragent()->ssl_opts(verify_hostname => 0);
    
    $client->POST($requestUrl);
    
    my $datiRicevuti = $client->POST($requestUrl, $requestParams, {'Content-type' => 'application/x-www-form-urlencoded'})->responseContent;
    my $tabulato = qq{$datiRicevuti};

    open(my $fh, ">:crlf", $nomeFile)    || die "can't open $nomeFile: $!";
	binmode($fh);               # for raw; else set the encoding
	print $fh "$tabulato\n";
	close($fh);
	#die "stop\n";
    #if ( $client->responseCode() eq '200' ) {
    if ( 0 ) {
        my $linea;
        #open my $fh, '<:crlf', \$tabulato or die $!;
        open my $fh, '<:crlf', $nomeFile or die "can't open $nomeFile: $!";
        
        while(! eof ($fh)) {
            $linea = <$fh>;
            $linea =~ s/\n$//ig;
            
            if ($linea =~ /^(\d{10}).{5}(.{11})(.{49})(\d{8})(\d{8})(\d{11})(\d{11})(\d{11})(.{2})(\w|\s)(\w|\s)(.{13})(.{15})(..)(.).(\d{2})(\d{2})(.{2})(.{2}).(.{3}).(\d{11})(\d{11})..(.)(.)..$/) {
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
                my $marchioCopre = rtrim($13);
                my $griglia = rtrim($14);
                my $grigliaObbligo = (rtrim($15) ne '');
                my $ediel01 = rtrim($16);
                my $ediel02 = rtrim($17);
                my $ediel03 = rtrim($18);
                my $ediel04 = rtrim($19);
                
                my $marchio = rtrim($20);
                my $doppioNetto = $21/100;
                my $triploNetto = $22/100;
                my $ordinabile = (rtrim($23) eq 'Y');
                my $canale = $24;
                
                
                if ($sth->execute($codice, $giacenza, $inOrdine)) {
                    while (my @record = $sth->fetchrow_array()) {
                        if (! $record[0]) {
                            #print $record[0]."=$codice\t$giacenza\t$inOrdine\n";
                            $sth_giacenze->execute($timestamp, $giacenza, $inOrdine, $codice);
                        }
                    }
                }
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
    
    # verifica se la giacenza  aggiornata
    $sth = $dbh->prepare(qq{select count(*) from tabulatoCopre where codice =? and giacenza=? and inOrdine=?});
    
    # aggiornamento giacenze della table tabulato copre
    $sth_giacenze = $dbh->prepare(qq{update tabulatoCopre set idTime = ?, giacenza = ?, inOrdine = ? where codice = ?});
                                
    
    return 1;
}

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };
