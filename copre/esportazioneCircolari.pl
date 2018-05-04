#!/usr/bin/perl
use strict;
use warnings;

use lib "/usr/local/ActivePerl-5.18/site/lib";

use DBI;
use DateTime;
use List::MoreUtils qw(firstidx);
use File::HomeDir;
use POSIX;

# date
#------------------------------------------------------------------------------------------------------------
my $dataCorrente = DateTime->today(time_zone=>'local');
my $annoCorrente = $dataCorrente->year();
my $annoPrecedente = $annoCorrente - 1;
my $meseCorrente = $dataCorrente->month();

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "10.11.14.78";#"localhost";
my $username = "root";
my $password = "mela";

# definizione cartelle
#----------------------------------------------------------------------------------------------------------------------
my $desktop = File::HomeDir->my_desktop;
my $mainFolder = "/catalogoB2B";
my $bkpFolder = "$mainFolder/bkp";

# Creazione cartelle locali (se non esistono)
#----------------------------------------------------------------------------------------------------------------------
unless (-e $mainFolder or mkdir $mainFolder) {die "Impossibile creare la cartella $mainFolder: $!\n";};
unless (-e $bkpFolder or mkdir $bkpFolder) {die "Impossibile creare la cartella $bkpFolder: $!\n";};

# parametri del file txt di output
#------------------------------------------------------------------------------------------------------------
my $fileName = "_Catalogo.txt";

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh; 
my $sth; 

my @circolari = ();
my @dataInizio = ();
my @dataFine = ();

if (&ConnessioneDB) {
    if (open my $fileHandler, "+>:crlf", $mainFolder.'/circolari.txt') {
        for (my $i = 0; $i < @circolari; $i++) {
            if ($sth->execute($circolari[$i])) {
                print $fileHandler "E;20PRAV;;".string2Date($dataInizio[$i])->ymd('').";".string2Date($dataFine[$i])->ymd('').";".$circolari[$i]."\n";
                #print $fileHandler "E;20PROA;;".string2Date($dataInizio[$i])->ymd('').";".string2Date($dataFine[$i])->ymd('').";".$circolari[$i]."\n";
                while (my @record = $sth->fetchrow_array()) {
                    my $codice = $record[0];
                    my $prezzo = $record[1];
                    $prezzo =~ s/\./,/ig;
                    
                    print $fileHandler "L;$codice;;;;;PZ;EUR;$prezzo\n"
                }
            }
        }
        close($fileHandler);
    }
}               
                   

exit;

sub string2Date { #trasformo una data un oggetto DateTime
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

sub ConnessioneDB {
	# connessione al database negozi
	$dbh = DBI->connect("DBI:mysql:copre:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database!\n";
		return 0;
	}

    # caricamento elenco clienti
    $sth = $dbh->prepare(qq{select distinct codice, dataInizio, dataFine from circolari order by 1});
    if ($sth->execute()) {
        while (my @record = $sth->fetchrow_array()) {
            push(@circolari, $record[0]);
            push(@dataInizio, $record[1]);
            push(@dataFine,  $record[2]);
        }
    }
    
    $sth = $dbh->prepare(qq{select f.codice_articolo, c.valoreCircolare from copre.circolari as c left join (select codice_articolo_fornitore, codice_articolo
                         from db_sm.fornitore_articolo where codice_fornitore='FCOPRE') as f on c.`codiceArticoloCopre`=f.`codice_articolo_fornitore`
                         where tipoValore = 0 and f.codice_articolo is not null and c.codice = ?
                         order by 1 });
		
    return 1;
}
