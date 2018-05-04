#!/usr/bin/perl
use strict;
use warnings;

use DBI;
use DateTime;
use File::HomeDir;

my $desktop = File::HomeDir->my_desktop;

# date
#------------------------------------------------------------------------------------------------------------
my $dataIniziale = string2Date('2017-01-01');
my $dataCorrente = DateTime->today(time_zone=>'local');

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "10.11.14.76";
my $username = "root";
my $password = "mela";

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh; #database handler
my $sth; #statement handler

my $sth_calendario;
my $sth_dettaglio;
my $sth_insert;

my %reparti = ();
my %negozi = ();

if (&ConnessioneDB) {
    
    my $dataCiclo = $dataIniziale->clone();
    
    # query che calcola da riepvegi i totali giornalieri x reparto
    $sth_dettaglio = $dbh->prepare(qq{
        select r.`RVG-CODSOC`, r.`RVG-CODNEG`, r.`RVG-DATA`, ifnull(d.`REPARTO_CASSE`,1), sum(r.`RVG-VAL-VEN-CASSE-E`)
        from archivi.riepvegi as r left join dimensioni.`articolo` as d on r.`RVG-CODICE`= d.`CODICE_ARTICOLO`
        where r.`RVG-DATA`=?
        group by 1,2,3,4}
    );
    
    # query di aggiornamento/inserimento
    $sth_insert = $dbh->prepare(qq{
        insert into archivi.consolidatiReparto (codice, codiceSocieta, codiceNegozio, data, settimana, settimanaCed, reparto, importo, ore, clienti)
        values (?,?,?,?,?,?,?,?,?,?) on duplicate key update importo = ?}
    );
    
    my $societa = '';
    my $negozio = '';
    my $data = '';
    my $reparto = 0;
    my $importo = 0;
    my $mese = 0;
    my $settimana = 0;
    while (DateTime->compare($dataCiclo, $dataCorrente) < 0) {
        if ($sth_dettaglio->execute($dataCiclo)) {
            while (my @record = $sth_dettaglio->fetchrow_array()) {
                $societa = $record[0];
                $negozio = $record[1];
                $data = $record[2];
                $reparto = $record[3];
                $importo = $record[4];
                
                ($settimana, $mese) = &getCalendario($dataCiclo->ymd('-'));
                
                #print "$societa, $negozio, $negozi{$societa.$negozio}, $data, $reparto, $reparti{$reparto}, $mese, $settimana, $importo\n";
                
                if (!$sth_insert->execute($societa.$negozio, $societa, $negozio, $data, $settimana, $settimana, $reparto, $importo, 0, 0, $importo)) {
                    print "Inserimento fallito: $DBI::errstr";
                }
            }
        }
        
        $dataCiclo->add(days => 1);
    }
}

$sth_insert->finish();
$sth_dettaglio->finish();
$sth_calendario->finish();
$sth->finish();
$dbh->disconnect();

exit;

sub string2Date { #trasformo una data stringa in un oggetto DateTime
	my ($data) = @_;
	
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

sub getCalendario {
    
    my ($data) = @_;
    
    my @mese = ();
    my @settimana = ();
    if ($sth_calendario->execute($data, $data)) {
        while (my @record = $sth_calendario->fetchrow_array()) {
            push @settimana, $record[0];
            push @mese, $record[1];
        }
        if (@mese == 1) {
            return $settimana[0], $mese[0];
        }
    }
    
    return 0, 0;
}

sub ConnessioneDB {
	# connessione al database negozi
	$dbh = DBI->connect("DBI:mysql:archivi:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database!\n";
		return 0;
	}
    
    # descrizione reparti
    $sth = $dbh->prepare(qq{select codice, descrizione from archivi.reparti order by codice});
    if ($sth->execute()) {
        while (my @record = $sth->fetchrow_array()) {
            $reparti{$record[0]} = $record[1];
        }
    }
    $sth->finish();
    
    # descrizione negozi
    $sth = $dbh->prepare(qq{select codice, negozio_descrizione from archivi.negozi as n where societa in ('01','04','31','36') order by 1; });
    if ($sth->execute()) {
        while (my @record = $sth->fetchrow_array()) {
            $negozi{$record[0]} = $record[1];
        }
    }
    $sth->finish();
    
    $sth_calendario = $dbh->prepare(qq{
        select settimana, mese
        from archivi.`calendario`
        where data_inizio <= ? and data_fine >= ?
        }
    );
  
    return 1;
}