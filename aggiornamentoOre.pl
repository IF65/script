#!/usr/bin/perl -w
use strict;
use REST::Client;
use JSON;
use JSON::Parse;
use DBI;
use Data::Dumper::Names;


# parametri di collegamento al database
#------------------------------------------------------------------------------------------------------------
my $indirizzoIp = '10.11.14.76';
my $utente  = 'root';
my $password = 'mela';

my $buffaloIp = '10.11.14.74';


# ricerca delle giornate negozio nelle quali almeno un'ora/reparto sia NULL
#------------------------------------------------------------------------------------------------------------
my @arCodiceNegozio = ();
my @arData = ();

my $dbh = DBI->connect("DBI:mysql:mysql:$indirizzoIp", $utente, $password);
if (! $dbh) {
    print "Errore durante la connessione al database IF!\n";
    return 0;
}

my $sth = $dbh->prepare(qq{select distinct concat(codiceSocieta, codiceNegozio) `negozio`, data from archivi.consolidatiReparto where ((clienti is null or clienti = 0) or (ore is null or ore = 0)) and data >= '2017-01-01' and reparto = 1});
if ($sth->execute()) {
    while(my @row = $sth->fetchrow_array()) {
        push(@arCodiceNegozio, $row[0]);
        push(@arData, $row[1]);
    }
}
$sth->finish();

$sth = $dbh->prepare(qq{update archivi.consolidatiReparto set ore = ?, clienti = ? where codiceSocieta = ? and codiceNegozio = ? and data = ? and reparto = ?});

# lettura da Buffalo dei dati ore/mese
#------------------------------------------------------------------------------------------------------------
my $client = REST::Client->new();
my $count = @arData;
#print "$count\n";

for(my $i=0;$i<@arData;$i++) {
    $client->GET("http://$buffaloIp/contabilita?funzione=oreGiornataSede&sede=".$arCodiceNegozio[$i]."&data=".$arData[$i]);
    
    
    if ($client->responseCode() == 200) {
        my $jsonText = $client->responseContent();
        
        my $societa = substr($arCodiceNegozio[$i],0,2);
        my $negozio = substr($arCodiceNegozio[$i],2);
        my $data = $arData[$i];
       
        #print "$societa$negozio, $data\n";
        my $decodedJson = decode_json($jsonText);
        my @oreLavorate = @{$decodedJson->{'oreLavorate'}};
        my $clienti = $decodedJson->{'clienti'};
        for (my $j=0; $j<@oreLavorate; $j++) {
            my $reparto = $oreLavorate[$j]->{'reparto'};
            my $ore = $oreLavorate[$j]->{'ore'};
            if ($reparto != 1) {$clienti = 0};
            #print "$societa$negozio, $data, $reparto\n";  
            $sth->execute($ore, $clienti, $societa, $negozio, $data, $reparto);
        }
    }
}

$sth->finish();
