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



my $desktop     = File::HomeDir->my_desktop;

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
my $excelFileName = "tabulatoCopre.xlsx";

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

my @elencoClienti;

if (&ConnessioneDB) {
    
    #creo il workbook
    my $workbook = Excel::Writer::XLSX->new("$desktop/$excelFileName");
    
    #formati
    #-------------------------------------------------------------------------------------------------
    my $format = $workbook->add_format();
    $format->set_bold();
    my $date_format = $workbook->add_format();
    $date_format->set_num_format('dd/mm/yy');
    
    &impostaFormati(\$workbook);
    
    
    # Creazione tabulato grezzo
    #-------------------------------------------------------------------------------------------------
    
    my $report = $workbook->add_worksheet('TABULATO');
    
    # impostazioni worksheet
    $report->hide_zero();
    $report->freeze_panes( 1, 0 );
    
    # larghezza colonne
    $report->set_column( 0, 0, 10 );
    $report->set_column( 1, 1, 15 );
    $report->set_column( 2, 2, 15 );
    $report->set_column( 3, 3, 40 );
    $report->set_column( 4, 4, 30 );
    $report->set_column( 5, 5, 30 );
    $report->set_column( 6, 6, 30 );
    $report->set_column( 7, 7, 30 );
    $report->set_column( 8, 8, 10 );
    $report->set_column( 9, 9, 20 );
    $report->set_column( 10, 10, 12 );
    $report->set_column( 11, 10, 12 );
    $report->set_column( 12, 12, 12 );
    $report->set_column( 13, 13, 12 );
    $report->set_column( 14, 14, 12 );
    $report->set_column( 15, 15, 12 );
    $report->set_column( 16, 16, 12 );
    $report->set_column( 17, 17, 12 );
    $report->set_column( 18, 18, 12 );
    $report->set_column( 19, 19, 12 );
    $report->set_column( 20, 20, 12 );
        
    $riga = 0;
    $report->write( $riga, 0, 'Codice', $formatTitoli);
    $report->write( $riga, 1, 'Barcode', $formatTitoli);
    $report->write( $riga, 2, 'Modello', $formatTitoli);
    $report->write( $riga, 3, 'Descrizione', $formatTitoli);
    $report->write( $riga, 4, 'Ediel Liv.1', $formatTitoli);
    $report->write( $riga, 5, 'Ediel Liv.2', $formatTitoli);
    $report->write( $riga, 6, 'Ediel Liv.3', $formatTitoli);
    $report->write( $riga, 7, 'Ediel Liv.4', $formatTitoli);
    $report->write( $riga, 8, 'Marchio', $formatTitoli);
    $report->write( $riga, 9, 'Canale', $formatTitoli);
    $report->write( $riga, 10, 'Giac.', $formatTitoli); 
    $report->write( $riga, 11, 'In Ord.', $formatTitoli);
    $report->write( $riga, 12, 'Prz. Acq.', $formatTitoli); 
    $report->write( $riga, 13, '% Copre', $formatTitoli);
    $report->write( $riga, 14, 'Val. Copre', $formatTitoli);
    $report->write( $riga, 15, 'Prz. Vend.', $formatTitoli);
    $report->write( $riga, 16, 'Pnd Loc.', $formatTitoli); 
    $report->write( $riga, 17, 'Pnd Gre', $formatTitoli); 
    $report->write( $riga, 18, 'D. Netto', $formatTitoli);
    $report->write( $riga, 19, 'Net. Net.', $formatTitoli);
    $report->write( $riga, 20, 'Ordinabile', $formatTitoli);
        
    $riga++;
    if ($sth_tabulato->execute()) {
        while (my @record = $sth_tabulato->fetchrow_array()) {
            $report->write_string( $riga, 0, $record[0], $formatEmpty);
            $report->write_string( $riga, 1, $record[1], $formatEmpty);
            $report->write( $riga, 2, $record[2]);
            $report->write( $riga, 3, $record[3]);
            $report->write( $riga, 4, $record[4]);
            $report->write( $riga, 5, $record[5]);
            $report->write( $riga, 6, $record[6]);
            $report->write( $riga, 7, $record[7]);
            $report->write( $riga, 8, $record[8]);
            
            if ($record[9] eq '1' ) {
                $report->write( $riga, 9, 'Tutti');
            } elsif ($record[9] eq '2' ) {
                $report->write( $riga, 9, 'Escluso ingrosso');
            } elsif ($record[9] eq '3' ) {
                $report->write( $riga, 9, 'Escluso web se non a prezzo negozio');
            } elsif ($record[9] eq '4' ) {
                $report->write( $riga, 9, 'Escluso web e ingrosso');
            } elsif ($record[9] eq '5' ) {
                $report->write( $riga, 9, 'Non pubblicabile su web');
            }
            
            $report->write( $riga, 10, $record[10], $formatNum0DecimalDigit);
            $report->write( $riga, 11, $record[11], $formatNum0DecimalDigit);
            $report->write( $riga, 12, $record[12], $formatNum2DecimalDigit);
            $report->write( $riga, 13, $record[13]/100, $formatPerc2DecimalDigit);
            
            my $cellaPrezzoAcquisto = xl_rowcol_to_cell($riga, 12);
            my $cellaPercCopre = xl_rowcol_to_cell($riga, 13);
            my $formula = "=$cellaPrezzoAcquisto/(1+$cellaPercCopre)*$cellaPercCopre";
            $report->write_formula( $riga, 14, $formula, $formatNum2DecimalDigit);
            
            $report->write( $riga, 15, $record[14], $formatNum2DecimalDigit);
            $report->write( $riga, 16, $record[15]/100, $formatPerc2DecimalDigit);
            $report->write( $riga, 17, $record[16]/100, $formatPerc2DecimalDigit);
            $report->write( $riga, 18, $record[17], $formatNum2DecimalDigit);
            
            my $cellaValoreCopre = xl_rowcol_to_cell($riga, 14);
            my $cellaDoppioNetto = xl_rowcol_to_cell($riga, 18);
            my $cellaPndLocale = xl_rowcol_to_cell($riga, 16);
            my $cellaPndGre = xl_rowcol_to_cell($riga, 17);
            $formula = "=$cellaDoppioNetto-$cellaDoppioNetto*($cellaPndLocale+$cellaPndGre)+$cellaValoreCopre";
            $report->write_formula( $riga, 19, $formula, $formatNum2DecimalDigitBold);
            
            $report->write( $riga, 20, $record[18]);
            
            $riga++;
        }
    }
    $report->autofilter( 0, 0, $riga, 19);
    
    #tabulato con politica vendita filtrato
    #-------------------------------------------------------------------------------------------------
    for (my $i = 0; $i < @elencoClienti; $i++) {
        my $report = $workbook->add_worksheet($elencoClienti[$i]);
    
        # impostazioni worksheet
        $report->hide_zero();
        $report->freeze_panes( 1, 0 );
        
        # larghezza colonne
        $report->set_column( 0, 0, 10 );
        $report->set_column( 1, 1, 15 );
        $report->set_column( 2, 2, 15 );
        $report->set_column( 3, 3, 40 );
        $report->set_column( 4, 4, 30 );
        $report->set_column( 5, 5, 30 );
        $report->set_column( 6, 6, 30 );
        $report->set_column( 7, 7, 30 );
        $report->set_column( 8, 8, 10 );
        $report->set_column( 9, 9, 20 );
        $report->set_column( 10, 10, 12 );
        $report->set_column( 11, 10, 12 );
        $report->set_column( 12, 12, 12 );
        $report->set_column( 13, 13, 12 );
        $report->set_column( 14, 14, 12 );
        $report->set_column( 15, 15, 12 );
        $report->set_column( 16, 16, 12 );
        $report->set_column( 17, 17, 12 );
        $report->set_column( 18, 18, 12 );
        $report->set_column( 19, 19, 12 );
        $report->set_column( 20, 20, 12 );
        $report->set_column( 21, 21, 12 );
        $report->set_column( 22, 22, 12 );
        $report->set_column( 23, 23, 12 );
        $report->set_column( 24, 23, 12 );

        #$report->set_column( 19, 19, 0, undef, 1 );
        
        $riga = 0;
        
        $report->write( $riga, 0, 'Codice', $formatTitoli);
        $report->write( $riga, 1, 'Barcode', $formatTitoli);
        $report->write( $riga, 2, 'Modello', $formatTitoli);
        $report->write( $riga, 3, 'Descrizione', $formatTitoli);
        $report->write( $riga, 4, 'Ediel Liv.1', $formatTitoli);
        $report->write( $riga, 5, 'Ediel Liv.2', $formatTitoli);
        $report->write( $riga, 6, 'Ediel Liv.3', $formatTitoli);
        $report->write( $riga, 7, 'Ediel Liv.4', $formatTitoli);
        $report->write( $riga, 8, 'Marchio', $formatTitoli);
        $report->write( $riga, 9, 'Canale', $formatTitoli);
        $report->write( $riga, 10, 'Giac.', $formatTitoli); 
        $report->write( $riga, 11, 'In Ord.', $formatTitoli);
        $report->write( $riga, 12, 'Prz. Acq.', $formatTitoli); 
        $report->write( $riga, 13, '% Copre', $formatTitoli);
        $report->write( $riga, 14, 'Val. Copre', $formatTitoli);
        $report->write( $riga, 15, 'Prz. Vend.', $formatTitoli);
        $report->write( $riga, 16, 'Pnd Loc.', $formatTitoli); 
        $report->write( $riga, 17, 'Pnd Gre', $formatTitoli); 
        $report->write( $riga, 18, 'D. Netto', $formatTitoli);
        $report->write( $riga, 19, 'Net. Net.', $formatTitoli);
        $report->write( $riga, 20, '% Cl. 01', $formatTitoli);
        $report->write( $riga, 21, '% Cl. 02', $formatTitoli);
        $report->write( $riga, 22, '% Cl. 03', $formatTitoli);
        $report->write( $riga, 23, '% Cl. 04', $formatTitoli);
        $report->write( $riga, 24, 'Prz. Cliente', $formatTitoli);
        
        $riga++;
        if ($sth->execute($elencoClienti[$i], $elencoClienti[$i])) {
            while (my @record = $sth->fetchrow_array()) {
                $report->write_string( $riga, 0, $record[0], $formatEmpty);
                $report->write_string( $riga, 1, $record[1], $formatEmpty);
                $report->write( $riga, 2, $record[2]);
                $report->write( $riga, 3, $record[3]);
                $report->write( $riga, 4, $record[4]);
                $report->write( $riga, 5, $record[5]);
                $report->write( $riga, 6, $record[6]);
                $report->write( $riga, 7, $record[7]);
                $report->write( $riga, 8, $record[8]);
                
                if ($record[9] eq '1' ) {
                    $report->write( $riga, 9, 'Tutti');
                } elsif ($record[9] eq '2' ) {
                    $report->write( $riga, 9, 'Escluso ingrosso');
                } elsif ($record[9] eq '3' ) {
                    $report->write( $riga, 9, 'Escluso web se non a prezzo negozio');
                } elsif ($record[9] eq '4' ) {
                    $report->write( $riga, 9, 'Escluso web e ingrosso');
                } elsif ($record[9] eq '5' ) {
                    $report->write( $riga, 9, 'Non pubblicabile su web');
                }
                
                $report->write( $riga, 10, $record[10], $formatNum0DecimalDigit);
                $report->write( $riga, 11, $record[11], $formatNum0DecimalDigit);
                $report->write( $riga, 12, $record[12], $formatNum2DecimalDigit);
                $report->write( $riga, 13, $record[13]/100, $formatPerc2DecimalDigit);
                
                my $cellaPrezzoAcquisto = xl_rowcol_to_cell($riga, 12);
                my $cellaPercCopre = xl_rowcol_to_cell($riga, 13);
                my $formula = "=$cellaPrezzoAcquisto/(1+$cellaPercCopre)*$cellaPercCopre";
                $report->write_formula( $riga, 14, $formula, $formatNum2DecimalDigit);
                
                $report->write( $riga, 15, $record[14], $formatNum2DecimalDigit);
                $report->write( $riga, 16, $record[15]/100, $formatPerc2DecimalDigit);
                $report->write( $riga, 17, $record[16]/100, $formatPerc2DecimalDigit);
                $report->write( $riga, 18, $record[17], $formatNum2DecimalDigit);
                
                my $cellaValoreCopre = xl_rowcol_to_cell($riga, 14);
                my $cellaDoppioNetto = xl_rowcol_to_cell($riga, 18);
                my $cellaPndLocale = xl_rowcol_to_cell($riga, 16);
                my $cellaPndGre = xl_rowcol_to_cell($riga, 17);
                $formula = "=$cellaDoppioNetto-$cellaDoppioNetto*($cellaPndLocale+$cellaPndGre)+$cellaValoreCopre";
                $report->write_formula( $riga, 19, $formula, $formatNum2DecimalDigitBold);
                
                $report->write( $riga, 20, $record[18]/100, $formatPerc2DecimalDigit);
                $report->write( $riga, 21, $record[19]/100, $formatPerc2DecimalDigit);
                $report->write( $riga, 22, $record[20]/100, $formatPerc2DecimalDigit);
                $report->write( $riga, 23, $record[21]/100, $formatPerc2DecimalDigit);
                
                my $cellaNetNet = xl_rowcol_to_cell($riga, 19);
                my $cellaRicarico01 = xl_rowcol_to_cell($riga, 20);
                my $cellaRicarico02 = xl_rowcol_to_cell($riga, 21);
                my $cellaRicarico03 = xl_rowcol_to_cell($riga, 22);
                my $cellaRicarico04 = xl_rowcol_to_cell($riga, 23);
                $formula = "=$cellaNetNet+$cellaNetNet*($cellaRicarico01+$cellaRicarico02+$cellaRicarico03+$cellaRicarico04)";
                $report->write_formula( $riga, 24, $formula, $formatNum2DecimalDigitBold);
                
                $riga++;
            }
            
            $report->autofilter( 0, 0, $riga, 24);
        }
        
    }
}

exit;

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
    $sth = $dbh->prepare(qq{select distinct codiceCliente from politicaVendita order by 1});
    if ($sth->execute()) {
        while (my @record = $sth->fetchrow_array()) {
            push @elencoClienti,  $record[0];
        }
    }
    
    $sth_tabulato = $dbh->prepare(qq{select 
                                t.`codice`, 
                                t.`barcode`, 
                                t.`modello`,
                                t.`descrizione`, 
                                concat(t.`ediel01`, ' - ',e01.`descrizione`) `ediel01`,
                                concat(t.`ediel02`, ' - ',e02.`descrizione`) `ediel02`, 
                                concat(t.`ediel03`, ' - ',ifnull(e03.`descrizione`,'INNDEFINITO')) `ediel03`, 
                                concat(t.`ediel04`, ' - ',ifnull(e04.`descrizione`,'INNDEFINITO')) `ediel04`,
                                t.`marchio`, 
                                t.`canale`, 
                                t.`giacenza`, 
                                t.`inOrdine`, 
                                t.`prezzoAcquisto`, 
                                t.`ricaricoPercentuale`,
                                t.`prezzoVendita`,
                                t.`pndAC`, 
                                t.`pndAP`, 
                                t.`doppioNetto`,
                                t.`ordinabile`
                            from tabulatoCopre as t join ediel01 as e01 on t.`ediel01`= e01.`codice` join ediel02 as e02 on concat(t.`ediel01`,t.`ediel02`)= e02.`codice`
                            left join ediel03 as e03 on concat(t.`ediel01`,t.`ediel02`,t.`ediel03`)= e03.`codice` left join ediel04 as e04 on concat(t.`ediel01`,t.`ediel02`,t.`ediel03`,t.`ediel04`)= e04.`codice`
                            order by 1
                });
    
    $sth = $dbh->prepare(qq{select 
                                t.`codice`, 
                                t.`barcode`, 
                                t.`modello`,
                                t.`descrizione`, 
                                concat(t.`ediel01`, ' - ',e01.`descrizione`) `ediel01`,
                                concat(t.`ediel02`, ' - ',e02.`descrizione`) `ediel02`, 
                                concat(t.`ediel03`, ' - ',ifnull(e03.`descrizione`,'INNDEFINITO')) `ediel03`, 
                                concat(t.`ediel04`, ' - ',ifnull(e04.`descrizione`,'INNDEFINITO')) `ediel04`,
                                t.`marchio`, 
                                t.`canale`, 
                                t.`giacenza`, 
                                t.`inOrdine`, 
                                t.`prezzoAcquisto`, 
                                t.`ricaricoPercentuale`,
                                t.`prezzoVendita`,
                                t.`pndAC`, 
                                t.`pndAP`, 
                                t.`doppioNetto`,
                                c.`ricarico01`,
                                c.`ricarico02`,
                                c.`ricarico03`,
                                c.`ricarico04`
                            from tabulatoCopre as t join tabulatoCliente as c on t.`idTime`=c.`idTime` and t.`codice`=c.`codiceArticolo` join ediel01 as e01 on t.`ediel01`= e01.`codice` join ediel02 as e02 on concat(t.`ediel01`,t.`ediel02`)= e02.`codice` left join ediel03 as e03 on concat(t.`ediel01`,t.`ediel02`,t.`ediel03`)= e03.`codice` left join ediel04 as e04 on concat(t.`ediel01`,t.`ediel02`,t.`ediel03`,t.`ediel04`)= e04.`codice`
                            where c.`codiceCliente`= ? and (((t.`inOrdine`<>0 or t.`giacenza`<>0) and t.`canale` = 1 and t.`ordinabile` = 1) or (t.`codice` in (select distinct p.`codiceArticolo` from politicaVendita as p where p.`codiceCliente`=? and p.`codiceArticolo`<>''))) and t.`doppioNetto`<>0;
                });
        
    return 1;
}
