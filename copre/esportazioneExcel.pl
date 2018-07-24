#!/usr/bin/perl
use strict;
use warnings;

use lib "/usr/local/ActivePerl-5.18/site/lib";

use DBI;
use DateTime;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
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
my $hostname = "10.11.14.78";
my $username = "root";
my $password = "mela";

# parametri del file Excel di output
#------------------------------------------------------------------------------------------------------------
my $excelFileName = "Catalogo.xlsx";

# definizione cartelle
#----------------------------------------------------------------------------------------------------------------------
my $mainFolder = "/catalogoB2B";
my $bkpFolder = "$mainFolder/bkp";

# Creazione cartelle locali (se non esistono)
#----------------------------------------------------------------------------------------------------------------------
unless (-e $mainFolder or mkdir $mainFolder) {die "Impossibile creare la cartella $mainFolder: $!\n";};
unless (-e $bkpFolder or mkdir $bkpFolder) {die "Impossibile creare la cartella $bkpFolder: $!\n";};

# parametri di configurazione foglio excel
#------------------------------------------------------------------------------------------------------------
my $righe_bloccate = 2;
my $colonne_bloccate = 5;

my $larghezza_colonna_area = 10;
my $larghezza_colonna_negozio = 25;
my $larghezza_colonna_importo = 13;
my $larghezza_colonna_estendo = 12;
my $larghezza_colonna_peso= 7;

# dichiarazione formati
#------------------------------------------------------------------------------------------------------------
my $formatTitoli;
my $formatTitoliBorderDay;
my $formatTitoliBorderMonth;
my $formatTitoliBorderYear;
my $formatEmpty;
my $formatEmptyLeft;
my $formatPerc2DecimalDigit;
my $formatPerc2DecimalDigitBold;
my $formatNum0DecimalDigit;
my $formatNum0DecimalDigitBold;
my $formatNum1DecimalDigit;
my $formatNum1DecimalDigitBold;
my $formatNum2DecimalDigit;
my $formatNum2DecimalDigitBold;

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sth_tabulato;
my $riga;

my %clienti;

if (&ConnessioneDB) {

    #creo il workbook
    my $workbook = Excel::Writer::XLSX->new("$mainFolder/$excelFileName");

    #formati
    #-------------------------------------------------------------------------------------------------
    my $format = $workbook->add_format();
    $format->set_bold();
    my $date_format = $workbook->add_format();
    $date_format->set_num_format('dd/mm/yy');

    &impostaFormati(\$workbook);

    #tabulato con politica vendita filtrato
    #-------------------------------------------------------------------------------------------------
     my @elencoClienti = ( keys %clienti );

    for (my $i = 0; $i < @elencoClienti; $i++) {
        my $report = $workbook->add_worksheet($elencoClienti[$i]);

        # impostazioni worksheet
        $report->hide_zero();
        $report->freeze_panes( 1, 0 );

        # larghezza colonne
        $report->set_column( 0, 0, 20 );
        $report->set_column( 1, 1, 20 );
        $report->set_column( 2, 2, 20 );
        $report->set_column( 3, 3, 20 );
        $report->set_column( 4, 4, 25 );
        $report->set_column( 5, 5, 40 );
        $report->set_column( 6, 6, 20 );
        $report->set_column( 7, 7, 15 );
        $report->set_column( 8, 8, 15 );
        $report->set_column( 9, 9, 15 );
        $report->set_column( 10, 10, 10 );
        $report->set_column( 11, 10, 15 );
        $report->set_column( 12, 12, 15 );
        $report->set_column( 13, 13, 20 );
        $report->set_column( 14, 14, 20 );
        $report->set_column( 15, 15, 20 );
        $report->set_column( 16, 16, 20 );
        $report->set_column( 17, 17, 20 );
        $report->set_column( 18, 18, 20 );
        $report->set_column( 19, 19, 20 );
        $report->set_column( 20, 20, 20 );

        #$report->set_column( 19, 19, 0, undef, 1 );

        $riga = 0;

        $report->write( $riga, 0, 'Cat', $formatTitoli);
        $report->write( $riga, 1, 'scat', $formatTitoli);
        $report->write( $riga, 2, 'idprod', $formatTitoli);
        $report->write( $riga, 3, 'codven', $formatTitoli);
        $report->write( $riga, 4, 'Titolo', $formatTitoli);
        $report->write( $riga, 5, 'Descrizione', $formatTitoli);
        $report->write( $riga, 6, 'Peso in decagrammi', $formatTitoli);
        $report->write( $riga, 7, 'Prezzo', $formatTitoli);
        $report->write( $riga, 8, 'Prezzo Listino', $formatTitoli);
        $report->write( $riga, 9, 'IVA', $formatTitoli);
        $report->write( $riga, 10, 'Marca/Brand.', $formatTitoli);
        $report->write( $riga, 11, 'Disponibilitˆ', $formatTitoli);
        $report->write( $riga, 12, 'Disponibilitˆ Futura', $formatTitoli);
        $report->write( $riga, 13, 'Data Disponibilitˆ futura', $formatTitoli);
        $report->write( $riga, 14, 'Prezzo Promozione', $formatTitoli);
        $report->write( $riga, 15, 'Data Inizio Promo', $formatTitoli);
        $report->write( $riga, 16, 'Data Fine Promo', $formatTitoli);
        $report->write( $riga, 17, 'codice ean', $formatTitoli);
        $report->write( $riga, 18, 'SIAE', $formatTitoli);
        $report->write( $riga, 19, 'RAEE', $formatTitoli);
        $report->write( $riga, 20, 'LINK IMMAGINE', $formatTitoli);

        $riga++;
         if ($sth->execute($elencoClienti[$i], $clienti{$elencoClienti[$i]}{'categoria'}, $elencoClienti[$i])) {
            while (my @record = $sth->fetchrow_array()) {

                my $codice = $record[0];
                my $barcode = $record[1];
                my $modello = $record[2];
                my $descrizione = $record[3];
                my $ediel01 = $record[4];
                my $ediel02 = $record[5];
                my $ediel03 = $record[6];
                my $ediel04 = $record[7];
                my $marchio = $record[8];
                my $canale = $record[9];
                my $giacenza = $record[10];
                my $inOrdine = $record[11];
                my $prezzoCliente = $record[12];
                my $prezzoNettoCliente = $record[13];
                my $prezzoVendita = $record[14];
                my $pndAC = $record[15]/100;
                my $pndAP = $record[16]/100;
                my $doppioNetto = $record[17];
                my $ricarico01 = $record[18]/100;
                my $ricarico02 = $record[19]/100;
                my $ricarico03 = $record[20]/100;
                my $ricarico04 = $record[21]/100;
                my $aliquotaIva = $record[22];
                my $inPromoDa = $record[23];
                my $inPromoA = $record[24];

                my $prezzoVenditaNoIva = $prezzoVendita*100/(100 + $aliquotaIva);

                $report->write_string( $riga, 0, $ediel01, $formatEmptyLeft);
                $report->write_string( $riga, 1, $ediel02, $formatEmptyLeft);
                $report->write_string( $riga, 2, $codice, $formatEmpty);
                $report->write_string( $riga, 3, $modello, $formatEmptyLeft);
                $report->write_string( $riga, 4, $descrizione, $formatEmptyLeft);
                $report->write_string( $riga, 5, $descrizione, $formatEmptyLeft);
                $report->write( $riga, 7, $prezzoCliente, $formatNum2DecimalDigit);
                $report->write( $riga, 8, $prezzoVenditaNoIva, $formatNum2DecimalDigit);
                $report->write( $riga, 9, $aliquotaIva, $formatNum2DecimalDigit);
                $report->write_string( $riga, 10, $marchio, $formatEmptyLeft);
                $report->write( $riga, 11, $giacenza, $formatNum0DecimalDigit);
                $report->write( $riga, 12, $inOrdine, $formatNum0DecimalDigit);
                $report->write( $riga, 14, $prezzoNettoCliente, $formatNum2DecimalDigit);
                $report->write( $riga, 15, $inPromoDa, $formatEmptyLeft);
                $report->write( $riga, 16, $inPromoA, $formatEmptyLeft);
                $report->write_string( $riga, 17, $barcode, $formatEmptyLeft);

                $riga++;
            }

            $report->autofilter( 0, 0, $riga, 24);
        }

    }
}

exit;

sub arrotonda {
    my ($importo) = @_;

    my $parteIntera = sprintf('%d', $importo)*1;
    my $parteDecimale = sprintf('%.2f', $importo - $parteIntera)*1;

    my $importoArrotondato = 0;
    if ($importo <10 && $importo > 0.03) {
        $importoArrotondato = $parteIntera + ceil($parteDecimale*10)/10;
    } elsif ($importo >= 10 && $importo < 100) {
        if ($parteDecimale < 0.20) {
            $importoArrotondato = $parteIntera;
        } elsif ($parteDecimale >= 0.20 && $parteDecimale < 0.70) {
            $importoArrotondato = $parteIntera + 0.5;
        } else {
             $importoArrotondato = $parteIntera + 1;
        }

    } else {
        if ($parteDecimale < 0.30) {
            $importoArrotondato = $parteIntera;
        } else {
            $importoArrotondato = $parteIntera + 1;
        }
    }

    return $importoArrotondato;
;
}

sub impostaFormati {
    my ($workbook) = @_;

    #my $redTitle = $workbook->add_format();
    #    $redTitle->copy($formatTitoli);
    #    $redTitle->set_color('red');

    $formatTitoli = $$workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        color => 'Black',
        size => 12
    );

    $formatEmpty = $$workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 0,
        color => 'Black',
        size => 12
    );

    $formatEmptyLeft = $$workbook->add_format(
        valign => 'vcenter',
        align  => 'left',
        bold => 0,
        color => 'Black',
        size => 12
    );

    $formatPerc2DecimalDigit = $$workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 0,
        color => 'Black',
        size => 12,
        num_format =>  "[Black]###,##0.00%; [Red]-###,##0.00%; [Black]###,##0.00%"
    );

    $formatPerc2DecimalDigitBold = $$workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 1,
        color => 'Black',
        size => 12,
        num_format =>  "[Black]###,##0.00%; [Red]-###,##0.00%; [Black]###,##0.00%"
    );

    $formatNum0DecimalDigit = $$workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 0,
        color => 'Black',
        size => 12,
        num_format =>  "[Black]###,##0; [Red]-###,##0; [Black]###,##0"
    );

    $formatNum0DecimalDigitBold = $$workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 1,
        color => 'Black',
        size => 12,
        num_format =>  "[Black]###,##0; [Red]-###,##0; [Black]###,##0"
    );

    $formatNum1DecimalDigit = $$workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 0,
        color => 'Black',
        size => 12,
        num_format =>  "[Black]###,##0.0; [Red]-###,##0.0; [Black]###,##0.0"
    );

    $formatNum1DecimalDigitBold = $$workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 1,
        color => 'Black',
        size => 12,
        num_format =>  "[Black]###,##0.0; [Red]-###,##0.0; [Black]###,##0.0"
    );

    $formatNum2DecimalDigit = $$workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 0,
        color => 'Black',
        size => 12,
        num_format =>  "[Black]###,##0.00; [Red]-###,##0.00; [Black]###,##0.00"
    );

    $formatNum2DecimalDigitBold = $$workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 1,
        color => 'Black',
        size => 12,
        num_format =>  "[Black]###,##0.00; [Red]-###,##0.00; [Black]###,##0.00"
    );
}


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
    $sth = $dbh->prepare(qq{select codice, categoria from clienti order by 1});
    if ($sth->execute()) {
        while (my @record = $sth->fetchrow_array()) {
            $clienti{$record[0]} = { 'categoria' => $record[1] };
        }
    }

    $sth = $dbh->prepare(qq{select
                                t.`codice`,
                                t.`barcode`,
                                upper(t.`modello`),
                                upper(t.`descrizione`),
                                e01.`descrizione` `ediel01`,
                                e02.`descrizione` `ediel02`,
                                ifnull(e03.`descrizione`,'INDEFINITO') `ediel03`,
                                ifnull(e04.`descrizione`,'INDEFINITO') `ediel04`,
                                upper(ifnull(m.`descrizione`,t.`marchioCopre`)),
                                t.`canale`,
                                t.`giacenza`,
                                t.`inOrdine`,
                                c.`prezzoCliente`,
                                c.`prezzoNettoCliente`,
                                t.`prezzoVendita`,
                                t.`pndAC`,
                                t.`pndAP`,
                                t.`doppioNetto`,
                                c.`ricarico01`,
                                c.`ricarico02`,
                                c.`ricarico03`,
                                c.`ricarico04`,
                                t.`aliquotaIva`,
                                c.`inPromoDa`,
                                c.`inPromoA`
								from tabulatoCopre as t join tabulatoCliente as c on t.`codice`=c.`codiceArticolo` join ediel01 as e01 on t.`ediel01`= e01.`codice` join ediel02 as e02 on concat(t.`ediel01`,t.`ediel02`)= e02.`codice` left join ediel03 as e03 on concat(t.`ediel01`,t.`ediel02`,t.`ediel03`)= e03.`codice` left join ediel04 as e04 on concat(t.`ediel01`,t.`ediel02`,t.`ediel03`,t.`ediel04`)= e04.`codice` left join marcheGCC as m on t.`marchio`=m.`codice`
								where c.`codiceCliente`= ? and
								(
									(((t.`giacenza`> 1 or t.`inOrdine`> 0) and t.`canale` = 1 and t.`ordinabile` = 1) or (t.`codice` in (select distinct p.`codiceArticolo` from politicaVendita as p where p.`categoria`= ? and p.`codiceArticolo`<>''))) or
									(t.`codice` in (select codice from articoliObbligatori))
								)
								and t.`doppioNetto`<>0 and t.`marchio` not in ('CLL','EXT','LIE','LOE','MIE','NRD','NTM','SBS','EAS','MEP','CAO','BLC','VIT','FAB','ACT','ADI','APO','AQL','ASF','ATT','BKB','BLC','BLR','BLJ','BPO','CEL','WEB','WAR','WAM','FOX','NTA') and t.`marchioCopre` not in ('MIELE') and t.`doppioNetto`>= 5.00 and c.`data` = (select max(data) from tabulatoCliente where codiceCliente = ?)  and
								t.`codice` <> '0702725087' and t.`codice` <> '0205764016' and t.`codice` <> '0212764005' and t.`codice` <> '0910762009' and t.`codice` <> '0208725002' and t.`codice` <> '0702725075' and t.`codice` <> '0702725088' and t.`codice` <> '0205725004' and t.`codice` <> '0205725008' and t.`codice` <> '4277251195' and t.`codice` <> '2212102014' and t.`codice` <> '2210102021' and t.`codice` <> '1305147003' and t.`codice` <> '0205253127' 
								order by 1;
							});

    return 1;
}
