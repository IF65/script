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
my $nomeFileInvio = "ExportSage.txt";

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
                if (@record == 25) {
                    my $marcatore = $record[0];
                    my $codiceSM = $record[1];
                    my $codiceMondo= $record[2];
                    my $codiceSettore = $record[3];
                    my $codiceReparto = $record[4];
                    my $codiceFamiglia = $record[5];
                    my $codiceSottofamiglia = $record[6];
                    my $descrizione1 = $record[7];
                    my $descrizione2 = $record[8];
                    my $descrizione3 = $record[9];
                    my $modello= $record[10];
                    my $marchio = $record[11];
                    my $codicePadre = $record[12];
                    my $canale = $record[13];
                    my $ediel01 = $record[14];
                    my $ediel02 = $record[15];
                    my $ediel03 = $record[16];
                    my $ediel04 = $record[17];
                    my $barcode = $record[18];
                    my $codiceFornitore = $record[19];
                    my $codiceGcc = $record[20];
                    my $giacenza = $record[21];
                    my $inOrdine = $record[22];
                    my $doppioNetto = $record[23];
                    my $nettoNetto = $record[24];
                    
                    if ($barcode eq '') {$barcode = '999'}
                   # $doppioNetto =~ s/\./,/ig;
                   # $nettoNetto =~ s/\./,/ig;
                    
                    # scrittura dati
                    # ------------------------------------------------------------------------
                    print $fileHandler "$marcatore;";
                    print $fileHandler "$codiceSM;";
                    print $fileHandler "$codiceMondo;";
                    print $fileHandler "$codiceSettore;";
                    print $fileHandler "$codiceReparto;";
                    print $fileHandler "$codiceFamiglia;";
                    print $fileHandler "$codiceSottofamiglia;";
                    print $fileHandler "$descrizione1;";
                    print $fileHandler "$descrizione2;";
                    print $fileHandler "$descrizione3;";
                    print $fileHandler "$modello;";
                    print $fileHandler "$marchio;";
                    print $fileHandler "$codicePadre;";
                    print $fileHandler "$canale;";
                    print $fileHandler "$ediel01;";
                    print $fileHandler "$ediel02;";
                    print $fileHandler "$ediel03;";
                    print $fileHandler "$ediel04;";
                    print $fileHandler "$barcode;";
                    print $fileHandler "$codiceFornitore;";
                    print $fileHandler "$codiceGcc;";
                    print $fileHandler "$giacenza;";
                    print $fileHandler "$inOrdine;";
                    print $fileHandler "$doppioNetto;";
                    print $fileHandler "$nettoNetto;\n";
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
							
	$sth = $dbh->prepare(qq{select 
	'ELE',
	m.`codice`,
	m.`codice_mondo`,
	m.`codice_settore`,
	m.`codice_reparto`,
	m.`codice_famiglia`,
	m.`codice_sottofamiglia`,
	substr(case when t.`descrizione`<>'' then t.`descrizione` else m.`descrizione` end,1,30) `descrizione1`,
	substr(case when t.`descrizione`<>'' then t.`descrizione` else m.`descrizione` end,31,30)`descrizione2`,
	substr(case when t.`descrizione`<>'' then t.`descrizione` else m.`descrizione` end,61,30)`descrizione3`,
	case when t.`modello`<>'' then t.`modello` else m.`modello` end `modello`,
	case when t.`marchio`<>'' then t.`marchio` else m.`linea` end `marchio`,
	'',
	case when t.`canale`<>0 then t.`canale` else 0 end `canale`,
	ifnull(t.`ediel01`,'') `ediel01` ,
	ifnull(t.`ediel02`,'') `ediel02` ,
	ifnull(t.`ediel03`,'') `ediel03` ,
	ifnull(t.`ediel04`,'') `ediel04` ,
	ifnull(t.`barcode`,'') `barcode`,
	'FCOPRE',
	ifnull(t.`codice`,'') `codice`,
	ifnull(t.`giacenza`,0) `giacenza`,
	ifnull(t.`inOrdine`,0) `inOrdine`,
	round(ifnull(t.`doppioNetto`,0),2) `doppioNetto`,
	round(ifnull(t.`nettoNetto`,0),2) `nettoNetto`
from db_sm.magazzino as m left join (select codice_articolo_fornitore,codice_articolo from db_sm.fornitore_articolo where codice_fornitore='FCOPRE') as f on f.codice_articolo=m.codice left join  copre.tabulatoCopre as t on t.codice = f.codice_articolo_fornitore
where m.`codice_reparto`<> '0177' and m.`codice_famiglia` <> '99' and m.`codice_settore`<>'SV2'
order by 2;});
		
    return 1;
}
