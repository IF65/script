#!/usr/bin/perl
use strict;
use warnings;

use lib "/usr/local/ActivePerl-5.18/site/lib";

use DBI;
use DateTime;
use File::Util;
use List::MoreUtils qw(firstidx);
use File::HomeDir;
use POSIX;

# date
#------------------------------------------------------------------------------------------------------------
my $dataCorrente = DateTime->today(time_zone=>'local');
my $annoCorrente = $dataCorrente->year();
my $annoPrecedente = $annoCorrente - 1;
my $meseCorrente = $dataCorrente->month();

# definizione cartelle locali 
# -----------------------------------------------------------------------------------------------------------
my $desktop  = File::HomeDir->my_desktop;
my $cartellaPrincipale = "/sage/out";
my $nomeFileInvio = "Giacenze.txt";

# creazione cartelle
# -----------------------------------------------------------------------------------------------------------
unless(-e $cartellaPrincipale or File::Util->new()->make_dir( $cartellaPrincipale)) {
    die "Impossibile creare la cartella $cartellaPrincipale: $!\n"
}

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "10.11.14.78";#"localhost";
my $username = "root";
my $password = "mela";

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh; 
my $sth; 

if (&ConnessioneDB) {
    if ($sth->execute()) {
        if (open my $fileHandler, "+>:crlf", "$cartellaPrincipale/$nomeFileInvio") {
            while (my @record = $sth->fetchrow_array()) {
        
                # lettura dei dati
                # ------------------------------------------------------------------------
                if (@record == 3) {
                    my $codiceSM = $record[0];
                    my $giacenza = $record[1];
                    my $inOrdine = $record[2];
                    
                    # scrittura dati
                    # ------------------------------------------------------------------------
                    print $fileHandler "$codiceSM;";
                    print $fileHandler "FCOPRE;";
                    print $fileHandler "$giacenza;";
                    print $fileHandler "$inOrdine;\n";
                }
            }
            close($fileHandler);
        }
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
    
#     $sth = $dbh->prepare(qq{select 'ELE',m.`codice`,m.`codice_mondo`,m.`codice_settore`,m.`codice_reparto`,m.`codice_famiglia`,m.`codice_sottofamiglia`,substr(t.`descrizione`,1,30),substr(t.`descrizione`,31,30),substr(t.`descrizione`,61,30),t.`modello`,t.`marchio`,'',t.`canale`,t.`ediel01`,t.`ediel02`,t.`ediel03`,t.`ediel04`,t.`barcode`,'FCOPRE',t.`codice`,t.`giacenza`,t.`inOrdine`,t.`doppioNetto`,t.`nettoNetto`
#                             from copre.tabulatoCopre as t left join (select codice_articolo_fornitore,codice_articolo from db_sm.fornitore_articolo where codice_fornitore='FCOPRE') as f on f.codice_articolo_fornitore=t.codice left join db_sm.magazzino as m on m.codice = f.codice_articolo
#                             where t.`doppioNetto`<>0 and m.codice is not null order by 2;
# 							});
							
	$sth = $dbh->prepare(qq{select f.codice_articolo, t.`giacenza`, t.`inOrdine`
                            from copre.tabulatoCopre as t join (select codice_articolo, codice_articolo_fornitore from db_sm.fornitore_articolo
                            where codice_fornitore = 'FCOPRE') as f on t.`codice`= f.codice_articolo_fornitore order by 1;});
		
    return 1;
}
