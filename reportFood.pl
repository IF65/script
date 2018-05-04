#!/usr/bin/perl
use strict;
use warnings;

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
my $hostname = "10.11.14.76";
my $username = "root";
my $password = "mela";

# parametri del file Excel di output
#------------------------------------------------------------------------------------------------------------
my $excelFileName = "reportFood.xlsx";

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
my $dbh; #database handler
my $sth; #statement handler

my @acRepartoCodice = ();
my @acRepartoDescrizione = ();
my @acImporto = ();
my @acOre = ();
my @acClienti = ();
my @apImporto = ();
my @apOre = ();
my @apClienti = ();

my @righeInizioSettimana = ();

my $societa = '01';
my $negozio = '71';

my %negozi = ();

my @descrizioneReparti = ();

my %descrizioneGiorni = (1 => 'Lun', 2 => 'Mar', 3 => 'Mer', 4 => 'Gio', 5 => 'Ven', 6 => 'Sab', 7 => 'Dom');

my %descrizioneMesi = ( 1 => 'GENNAIO', 2 => 'FEBBRAIO', 3 => 'MARZO', 4 => 'APRILE', 5 => 'MAGGIO', 6 => 'GIUGNO',
                        7 => 'LUGLIO', 8 => 'AGOSTO', 9 => 'SETTEMBRE', 10 => 'OTTOBRE', 11 => 'NOVEMBRE', 12 => 'DICEMBRE');

my %settimane = ();
my %mesi = ();

my @refInizioSettimana = ();

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
    
    my $totali = $workbook->add_worksheet( 'TOTALI' );
    my $settimane = $workbook->add_worksheet( 'SETTIMANE' );

    for (my $mese=1;$mese <= 12; $mese++) {
        my $report = $workbook->add_worksheet(substr($descrizioneMesi{$mese},0,3));
        
        # impostazioni worksheet
        $report->hide_zero();
        
        # larghezza colonne
        $report->set_column( 0, 0, 20 );
        $report->set_column( 1, 1, 12 );
        $report->set_column( 2, 2, 9 );
        $report->set_column( 3, 6, 8 );
        
        $report->set_column( 7, 7, 12 );
        $report->set_column( 8, 8, 9 );
        $report->set_column( 9, 12, 8 );
        
        $report->set_column( 13, 13, 12 );
        $report->set_column( 14, 14, 9 );
        $report->set_column( 15, 18, 8 );
        $report->set_column( 19, 19, 0, undef, 1 );
        
        my $riga = 0;
        
        
        my $meseId = sprintf('%04d%02d', $annoCorrente, $mese);
        
        my $settimanaIniziale = $mesi{$meseId}{'inizio'};
        my $settimanaFinale = $mesi{$meseId}{'fine'};
        
        $riga = 17;
        $report->freeze_panes( $riga, 0 );
        
        @righeInizioSettimana = ();
        
        for (my $settimana = $settimanaIniziale; $settimana <= $settimanaFinale; $settimana++) {
        
            my $settimanaId = sprintf('%04d%02d', $annoCorrente, $settimana);
            
            my $dataInizio = string2Date($settimane{$settimanaId}{'inizio'});
            my $dataFine = string2Date($settimane{$settimanaId}{'fine'});
            
            my $data = $dataInizio->clone();
            
            &scriviSettimana($report, \$riga);
            
            while (DateTime->compare($data, $dataFine) <= 0) {
            
                # anno corrente
                @acRepartoCodice = ();
                @acRepartoDescrizione = ();
                @acImporto = ();
                @acOre = ();
                @acClienti = ();
                if ($sth->execute($societa, $negozio, $data->ymd('-'), $data->ymd('-'))) {
                    while (my @record = $sth->fetchrow_array()) {
                        push @acRepartoCodice, $record[0];
                        push @acRepartoDescrizione, $record[1];
                        push @acImporto, $record[2];
                        push @acOre, $record[3];
                        push @acClienti, $record[4];
                    }
                }
                
                #anno precedente
                @apImporto = ();
                @apOre = ();
                @apClienti = ();
                if ($sth->execute($societa, $negozio, &giornoCorrispondente($data)->ymd('-'), &giornoCorrispondente($data)->ymd('-'))) {
                    while (my @record = $sth->fetchrow_array()) {
                        push @apImporto, $record[2];
                        push @apOre, $record[3];
                        push @apClienti, $record[4];
                    }
                }
            
                &scriviGiornata($report, \$riga, $data);
                
                $data->add(days => 1);
            
            } # fine ciclo sui giorni
            $riga++;
        } # fine ciclo sulle settimane
        
        &scriviMese($report, \$riga);
        
    } # fine ciclo sui mesi

    &scriviAnno($workbook, $totali);
}

exit;

sub impostaFormati {
    my ($workbook) = @_;
    
    $formatTitoli = $$workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        color => 'Black',
        size => 12
    );
    
    $formatTitoliBorderDay = $$workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => '#F4C875' #'#D6FFFF'
    );
    
    $formatTitoliBorderMonth = $$workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => '#8CFACA' #'#D6FFFF'
    );
    
    $formatTitoliBorderYear = $$workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => '#EE82EE' # violet
    );
    
    $formatEmpty = $$workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
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

sub scriviGiornata {
    my ($report, $riga, $data) = @_;
    
    my $formula = '';
    
    # titoli
    $report->merge_range( $$riga, 1, $$riga, 6, $descrizioneGiorni{$data->day_of_week()}.', '.$data->dmy('/'), $formatTitoliBorderDay);
    $report->merge_range( $$riga, 7, $$riga, 12, $descrizioneGiorni{&giornoCorrispondente($data)->day_of_week()}.', '.&giornoCorrispondente($data)->dmy('/'), $formatTitoliBorderDay);
    $report->merge_range( $$riga, 13, $$riga, 18, "Differenze", $formatTitoliBorderDay);
    $$riga++;
    $report->merge_range( $$riga, 0, $$riga-1, 0, $descrizioneGiorni{$data->day_of_week()}.", Settimana nr.".$data->week_number(), $formatTitoliBorderDay);
    $report->write( $$riga, 1, "Venduto", $formatTitoliBorderDay);
    $report->write( $$riga, 2, "%", $formatTitoliBorderDay);
    $report->write( $$riga, 3, "Ore", $formatTitoliBorderDay); 
    $report->write( $$riga, 4, "Proc.", $formatTitoliBorderDay);
    $report->write( $$riga, 5, "Clienti", $formatTitoliBorderDay);
    $report->write( $$riga, 6, "Sc. Med.", $formatTitoliBorderDay);
    
    $report->write( $$riga, 7, "Venduto", $formatTitoliBorderDay);
    $report->write( $$riga, 8, "%", $formatTitoliBorderDay);
    $report->write( $$riga, 9, "Ore", $formatTitoliBorderDay);
    $report->write( $$riga, 10, "Proc.", $formatTitoliBorderDay);
    $report->write( $$riga, 11, "Clienti", $formatTitoliBorderDay);
    $report->write( $$riga, 12, "Sc. Med.", $formatTitoliBorderDay);
    
    $report->write( $$riga, 13, "Venduto", $formatTitoliBorderDay);
    $report->write( $$riga, 14, "%", $formatTitoliBorderDay);
    $report->write( $$riga, 15, "Ore", $formatTitoliBorderDay);
    $report->write( $$riga, 16, "Proc.", $formatTitoliBorderDay);
    $report->write( $$riga, 17, "Clienti", $formatTitoliBorderDay);
    $report->write( $$riga, 18, "Sc. Med.", $formatTitoliBorderDay);
    $$riga++;
    
    # sull'ultima colonna all'altezza del reparto 1 scrivo se la giornata partecipa alla somma o no
    if (DateTime->compare($data, $dataCorrente) <= 0) {
        $report->write( $$riga, 19, 1, $formatNum0DecimalDigit);
    } else {
        $report->write( $$riga, 19, 0, $formatNum0DecimalDigit);
    }
    
    for(my $i=0; $i<@acRepartoCodice; $i++) {
        
        $report->write( $$riga, 0, $acRepartoDescrizione[$i]);
        
        # Anno Corrente
        $report->write( $$riga, 1, $acImporto[$i], $formatNum2DecimalDigit);
        
        my $cellaACTotale = xl_rowcol_to_cell( $$riga+13-$i, 1, 1, 1 );    #riferimenti assoluti
        my $cellaACImporto = xl_rowcol_to_cell($$riga, 1);
        $formula = "=IF(".$cellaACTotale."<>0,".$cellaACImporto."/".$cellaACTotale.",0)";
        $report->write_formula( $$riga, 2, $formula, $formatPerc2DecimalDigit);
        
        my $cellaACOre = xl_rowcol_to_cell($$riga, 3);
        $report->write( $$riga, 3, $acOre[$i], $formatNum1DecimalDigit);
        
        $formula = "=IF(".$cellaACOre."<>0,".$cellaACImporto."/".$cellaACOre.",0)";
        $report->write_formula( $$riga, 4, $formula, $formatNum2DecimalDigit);
        
        my $cellaACClienti = xl_rowcol_to_cell($$riga, 5);
        $report->write( $$riga, 5, $acClienti[$i], $formatNum0DecimalDigit);
        
        #$formula = "=IF(".$cellaACClienti."<>0,".$cellaACImporto."/".$cellaACClienti.",0)";
        #$report->write_formula( $$riga, 6, $formula, $formatNum2DecimalDigit);
        
        # Anno Precedente
        $report->write( $$riga, 7, $apImporto[$i], $formatNum2DecimalDigit);
        
        my $cellaAPTotale = xl_rowcol_to_cell( $$riga+13-$i, 7, 1, 1 );    #riferimenti assoluti
        my $cellaAPImporto = xl_rowcol_to_cell($$riga, 7);
        $formula = "=IF(".$cellaAPTotale."<>0,".$cellaAPImporto."/".$cellaAPTotale.",0)";
        $report->write_formula( $$riga, 8, $formula, $formatPerc2DecimalDigit);
        
        my $cellaAPOre = xl_rowcol_to_cell($$riga, 9);
        $report->write( $$riga, 9, $apOre[$i], $formatNum1DecimalDigit);
        
        $formula = "=IF(".$cellaAPOre."<>0,".$cellaAPImporto."/".$cellaAPOre.",0)";
        $report->write_formula( $$riga, 10, $formula, $formatNum2DecimalDigit);
        
        my $cellaAPClienti = xl_rowcol_to_cell($$riga, 11);
        $report->write( $$riga, 11, $apClienti[$i], $formatNum0DecimalDigit);
        
        
        # Differenze
        $formula = "=".$cellaACImporto."-".$cellaAPImporto;
        $report->write_formula( $$riga, 13, $formula, $formatNum2DecimalDigit);
     
        $formula = "=IF($cellaACImporto<>0,($cellaACImporto-$cellaAPImporto)/$cellaACImporto,0)";
        $report->write_formula( $$riga, 14, $formula, $formatPerc2DecimalDigit);
        
        $formula = "=".$cellaACOre."-".$cellaAPOre;
        $report->write_formula( $$riga, 15, $formula, $formatNum1DecimalDigit);
        
        $formula = "=".xl_rowcol_to_cell($$riga, 4)."-".xl_rowcol_to_cell($$riga, 10);
        $report->write_formula( $$riga, 16, $formula, $formatNum2DecimalDigit);
        
        $formula = "=".$cellaACClienti."-".$cellaAPClienti;
        $report->write_formula( $$riga, 17, $formula, $formatNum0DecimalDigit);
        
        $$riga++;
    } # fine ciclo sui reparti
    
    $report->write( $riga, 0, "Totali Giorno", $formatTitoli);
    
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 1).":".xl_rowcol_to_cell($$riga-1, 1).")";
    $report->write_formula( $$riga, 1, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 3).":".xl_rowcol_to_cell($$riga-1, 3).")";
    $report->write_formula( $$riga, 3, $formula, $formatNum1DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($$riga, 3)."<>0,".xl_rowcol_to_cell($$riga, 1)."/".xl_rowcol_to_cell($$riga, 3).",0)";
    $report->write_formula( $$riga, 4, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 5).":".xl_rowcol_to_cell($$riga-1, 5).")";
    $report->write_formula( $$riga, 5, $formula, $formatNum0DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($$riga, 5)."<>0,".xl_rowcol_to_cell($$riga, 1)."/".xl_rowcol_to_cell($$riga, 5).",0)";
    $report->write_formula( $$riga, 6, $formula, $formatNum2DecimalDigitBold);
    $report->merge_range( $$riga-13, 6, $$riga-1, 6, '', $formatEmpty);
    
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 7).":".xl_rowcol_to_cell($$riga-1, 7).")";
    $report->write_formula( $$riga, 7, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 9).":".xl_rowcol_to_cell($$riga-1, 9).")";
    $report->write_formula( $$riga, 9, $formula, $formatNum1DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($$riga, 9)."<>0,".xl_rowcol_to_cell($$riga, 7)."/".xl_rowcol_to_cell($$riga, 9).",0)";
    $report->write_formula( $$riga, 10, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 11).":".xl_rowcol_to_cell($$riga-1, 11).")";
    $report->write_formula( $$riga, 11, $formula, $formatNum0DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($$riga, 11)."<>0,".xl_rowcol_to_cell($$riga, 7)."/".xl_rowcol_to_cell($$riga, 11).",0)";
    $report->write_formula( $$riga, 12, $formula, $formatNum2DecimalDigitBold);
    $report->merge_range( $$riga-13, 12, $$riga-1, 12, '', $formatEmpty);

    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 13).":".xl_rowcol_to_cell($$riga-1, 13).")";
    $report->write_formula( $$riga, 13, $formula, $formatNum2DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($$riga, 1)."<>0,(".xl_rowcol_to_cell($$riga, 1)."-".xl_rowcol_to_cell($$riga, 7).")/".xl_rowcol_to_cell($$riga, 1).",0)";
    $report->write_formula( $$riga, 14, $formula, $formatPerc2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 15).":".xl_rowcol_to_cell($$riga-1, 15).")";
    $report->write_formula( $$riga, 15, $formula, $formatNum1DecimalDigitBold);
    $formula = "=".xl_rowcol_to_cell($$riga, 4)."-".xl_rowcol_to_cell($$riga, 10);
    $report->write_formula( $$riga, 16, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 17).":".xl_rowcol_to_cell($$riga-1, 17).")";
    $report->write_formula( $$riga, 17, $formula, $formatNum0DecimalDigitBold);
    $formula = "=".xl_rowcol_to_cell($$riga, 6)."-".xl_rowcol_to_cell($$riga, 12);
    $report->write_formula( $$riga, 18, $formula, $formatNum2DecimalDigitBold);
    $report->merge_range( $$riga-13, 18, $$riga-1, 18, '', $formatEmpty);
    
    $$riga++;
    $$riga++;  
}


sub scriviSettimana {
    my ($report, $riga) = @_;
    
    my $formula = '';
    
    push @righeInizioSettimana, $$riga;
    
    push @refInizioSettimana, $report->get_name().'!'.xl_rowcol_to_cell( $$riga, 1);
            
    # titoli
    $report->merge_range( $$riga, 1, $$riga, 6, '', $formatTitoliBorderDay);
    $report->merge_range( $$riga, 7, $$riga, 12, '', $formatTitoliBorderDay);
    $report->merge_range( $$riga, 13, $$riga, 18, "Differenze", $formatTitoliBorderDay);
    $$riga++;
    $report->merge_range( $$riga, 0, $$riga-1, 0, '', $formatTitoliBorderDay);
    $report->write( $$riga, 1, "Venduto", $formatTitoliBorderDay);
    $report->write( $$riga, 2, "%", $formatTitoliBorderDay);
    $report->write( $$riga, 3, "Ore", $formatTitoliBorderDay); 
    $report->write( $$riga, 4, "Proc.", $formatTitoliBorderDay);
    $report->write( $$riga, 5, "Clienti", $formatTitoliBorderDay);
    $report->write( $$riga, 6, "Sc. Med.", $formatTitoliBorderDay);
    
    $report->write( $$riga, 7, "Venduto", $formatTitoliBorderDay);
    $report->write( $$riga, 8, "%", $formatTitoliBorderDay);
    $report->write( $$riga, 9, "Ore", $formatTitoliBorderDay);
    $report->write( $$riga, 10, "Proc.", $formatTitoliBorderDay);
    $report->write( $$riga, 11, "Clienti", $formatTitoliBorderDay);
    $report->write( $$riga, 12, "Sc. Med.", $formatTitoliBorderDay);
    
    $report->write( $$riga, 13, "Venduto", $formatTitoliBorderDay);
    $report->write( $$riga, 14, "%", $formatTitoliBorderDay);
    $report->write( $$riga, 15, "Ore", $formatTitoliBorderDay);
    $report->write( $$riga, 16, "Proc.", $formatTitoliBorderDay);
    $report->write( $$riga, 17, "Clienti", $formatTitoliBorderDay);
    $report->write( $$riga, 18, "Sc. Med.", $formatTitoliBorderDay);
    $$riga++;
    
    for(my $i=0; $i<@descrizioneReparti; $i++) {
        $report->write( $$riga, 0, $descrizioneReparti[$i]);
        
        # venduto anno corrente
        $formula = '';
        for my $offset (1..7) {
            $formula .= xl_rowcol_to_cell($$riga + $offset * 17 , 1).'+';
        }
        $formula =~ s/\+$//;
        $report->write_formula( $$riga, 1, $formula, $formatNum2DecimalDigit);

        # venduto percentuale anno corrente 
        my $cellaACTotale = xl_rowcol_to_cell( $$riga - $i + @descrizioneReparti, 1, 1, 1 );    #riferimenti assolutila cella è costante
        my $cellaACImporto = xl_rowcol_to_cell($$riga , 1);
        $formula = "=IF(".$cellaACTotale."<>0,".$cellaACImporto."/".$cellaACTotale.",0)";
        $report->write_formula( $$riga, 2, $formula, $formatPerc2DecimalDigit);
        
        # ore anno corrente
        my $cellaACOre = xl_rowcol_to_cell($$riga, 3);
        $formula = '';
        for my $offset (1..7) {
            $formula .= xl_rowcol_to_cell($$riga + $offset * 17 , 3).'+';
        }
        $formula =~ s/\+$//;
        $report->write_formula( $$riga, 3, $formula, $formatNum1DecimalDigit);
        
        # procapite anno corrente
        $formula = "=IF(".$cellaACOre."<>0,".$cellaACImporto."/".$cellaACOre.",0)";
        $report->write_formula( $$riga, 4, $formula, $formatNum2DecimalDigit);
        
        # clienti anno corrente
        my $cellaACClienti = xl_rowcol_to_cell($$riga , 5);
        $formula = '';
        for my $offset (1..7) {
           $formula .= xl_rowcol_to_cell($$riga + $offset * 17, 5).'+';
        }
        $formula =~ s/\+$//;
        $report->write_formula( $$riga, 5, $formula, $formatNum0DecimalDigit);
        
        # venduto anno precedente
        $formula = '=';
        for my $offset (1..7) {
            my $okSomma = xl_rowcol_to_cell( $$riga + $offset * 17 -$i, 19 );
            $formula .= xl_rowcol_to_cell($$riga + $offset * 17, 7).'*OR('.$okSomma.',TOTALI!T3)'.'+';
        }
        $formula =~ s/\+$//;
        $report->write_formula( $$riga, 7, $formula, $formatNum2DecimalDigit);

        # venduto percentuale anno precedente 
        my $cellaAPTotale = xl_rowcol_to_cell( $$riga - $i + @descrizioneReparti, 7, 1, 1 );    #riferimenti assolutila cella è costante
        my $cellaAPImporto = xl_rowcol_to_cell( $$riga, 7);
        $formula = "=IF(".$cellaAPTotale."<>0,".$cellaAPImporto."/".$cellaAPTotale.",0)";
        $report->write_formula( $$riga, 8, $formula, $formatPerc2DecimalDigit);
        
        # ore anno precedente
        my $cellaAPOre = xl_rowcol_to_cell( $$riga, 9);
        $formula = '';
        for my $offset (1..7) {
            my $okSomma = xl_rowcol_to_cell( $$riga + $offset * 17 -$i, 19 );
            $formula .= xl_rowcol_to_cell($$riga + $offset * 17, 9).'*'.$okSomma.'+';
        }
        $formula =~ s/\+$//;
        $report->write_formula( $$riga, 9, $formula, $formatNum1DecimalDigit);
        
        # procapite anno precedente
        $formula = "=IF(".$cellaAPOre."<>0,".$cellaAPImporto."/".$cellaAPOre.",0)";
        $report->write_formula( $$riga, 10, $formula, $formatNum2DecimalDigit);
        
        # clienti anno precedente
        my $cellaAPClienti = xl_rowcol_to_cell( $$riga, 11);
        $formula = '';
        for my $offset (1..7) {
            my $okSomma = xl_rowcol_to_cell( $$riga + $offset * 17 -$i, 19 );
            $formula .= xl_rowcol_to_cell($$riga + $offset * 17, 11).'*'.$okSomma.'+';
        }
        $formula =~ s/\+$//;
        $report->write_formula( $$riga, 11, $formula, $formatNum0DecimalDigit);
        
        # Differenze
        $formula = "=".$cellaACImporto."-".$cellaAPImporto;
        $report->write_formula( $$riga, 13, $formula, $formatNum2DecimalDigit);
        
        $formula = "=IF($cellaACImporto<>0,($cellaACImporto-$cellaAPImporto)/$cellaACImporto,0)";
        $report->write_formula( $$riga, 14, $formula, $formatPerc2DecimalDigit);
        
        $formula = "=".$cellaACOre."-".$cellaAPOre;
        $report->write_formula( $$riga, 15, $formula, $formatNum1DecimalDigit);
        
        $formula = "=".xl_rowcol_to_cell( $$riga, 4)."-".xl_rowcol_to_cell( $$riga, 10);
        $report->write_formula( $$riga, 16, $formula, $formatNum2DecimalDigit);
            
        $formula = "=".$cellaACClienti."-".$cellaAPClienti;
        $report->write_formula( $$riga, 17, $formula, $formatNum0DecimalDigit);
        
        $$riga++;
    }
    
    $report->write( $$riga, 0, "Totali Giorno", $formatTitoli);
            
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 1).":".xl_rowcol_to_cell($$riga-1, 1).")";
    $report->write_formula( $$riga, 1, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 3).":".xl_rowcol_to_cell($$riga-1, 3).")";
    $report->write_formula( $$riga, 3, $formula, $formatNum1DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($$riga, 3)."<>0,".xl_rowcol_to_cell($$riga, 1)."/".xl_rowcol_to_cell($$riga, 3).",0)";
    $report->write_formula( $$riga, 4, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 5).":".xl_rowcol_to_cell($$riga-1, 5).")";
    $report->write_formula( $$riga, 5, $formula, $formatNum0DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($$riga, 5)."<>0,".xl_rowcol_to_cell($$riga, 1)."/".xl_rowcol_to_cell($$riga, 5).",0)";
    $report->write_formula( $$riga, 6, $formula, $formatNum2DecimalDigitBold);
    $report->merge_range( $$riga-13, 6, $$riga-1, 6, '', $formatEmpty);
    
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 7).":".xl_rowcol_to_cell($$riga-1, 7).")";
    $report->write_formula( $$riga, 7, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 9).":".xl_rowcol_to_cell($$riga-1, 9).")";
    $report->write_formula( $$riga, 9, $formula, $formatNum1DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($$riga, 9)."<>0,".xl_rowcol_to_cell($$riga, 7)."/".xl_rowcol_to_cell($$riga, 9).",0)";
    $report->write_formula( $$riga, 10, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 11).":".xl_rowcol_to_cell($$riga-1, 11).")";
    $report->write_formula( $$riga, 11, $formula, $formatNum0DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($$riga, 11)."<>0,".xl_rowcol_to_cell($$riga, 7)."/".xl_rowcol_to_cell($$riga, 11).",0)";
    $report->write_formula( $$riga, 12, $formula, $formatNum2DecimalDigitBold);
    $report->merge_range( $$riga-13, 12, $$riga-1, 12, '', $formatEmpty);

    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 13).":".xl_rowcol_to_cell($$riga-1, 13).")";
    $report->write_formula( $$riga, 13, $formula, $formatNum2DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($$riga, 1)."<>0,(".xl_rowcol_to_cell($$riga, 1)."-".xl_rowcol_to_cell($$riga, 7).")/".xl_rowcol_to_cell($$riga, 1).",0)";
    $report->write_formula( $$riga, 14, $formula, $formatPerc2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 15).":".xl_rowcol_to_cell($$riga-1, 15).")";
    $report->write_formula( $$riga, 15, $formula, $formatNum1DecimalDigitBold);
    $formula = "=".xl_rowcol_to_cell($$riga, 4)."-".xl_rowcol_to_cell($$riga, 10);
    $report->write_formula( $$riga, 16, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($$riga-13, 17).":".xl_rowcol_to_cell($$riga-1, 17).")";
    $report->write_formula( $$riga, 17, $formula, $formatNum0DecimalDigitBold);
    $formula = "=".xl_rowcol_to_cell($$riga, 6)."-".xl_rowcol_to_cell($$riga, 12);
    $report->write_formula( $$riga, 18, $formula, $formatNum2DecimalDigitBold);
    $report->merge_range( $$riga-13, 18, $$riga-1, 18, '', $formatEmpty);
     
    $$riga++;
    $$riga++;
}

sub scriviMese {
    my ($report) = @_;
    
    $report->merge_range( 0, 1, 0, 6, $annoCorrente, $formatTitoliBorderMonth);
    $report->merge_range( 0, 7, 0, 12, $annoPrecedente, $formatTitoliBorderMonth);
    $report->merge_range( 0, 13, 0, 18, "Differenze", $formatTitoliBorderMonth);
    
    $report->merge_range( 1, 0, 0, 0, '', $formatTitoliBorderMonth);
    $report->write( 1, 1, "Venduto", $formatTitoliBorderMonth);
    $report->write( 1, 2, "%", $formatTitoliBorderMonth);
    $report->write( 1, 3, "Ore", $formatTitoliBorderMonth);
    $report->write( 1, 4, "Proc.", $formatTitoliBorderMonth);
    $report->write( 1, 5, "Clienti", $formatTitoliBorderMonth);
    $report->write( 1, 6, "Sc. Med.", $formatTitoliBorderMonth);
    $report->write( 1, 7, "Venduto", $formatTitoliBorderMonth);
    $report->write( 1, 8, "%", $formatTitoliBorderMonth);
    $report->write( 1, 9, "Ore", $formatTitoliBorderMonth);
    $report->write( 1, 10, "Proc.", $formatTitoliBorderMonth);
    $report->write( 1, 11, "Clienti", $formatTitoliBorderMonth);
    $report->write( 1, 12, "Sc. Med.", $formatTitoliBorderMonth);
    $report->write( 1, 13, "Venduto", $formatTitoliBorderMonth);
    $report->write( 1, 14, "%", $formatTitoliBorderMonth);
    $report->write( 1, 15, "Ore", $formatTitoliBorderMonth);
    $report->write( 1, 16, "Proc.", $formatTitoliBorderMonth);
    $report->write( 1, 17, "Clienti", $formatTitoliBorderMonth);
    $report->write( 1, 18, "Sc. Med.", $formatTitoliBorderMonth);
    
    for(my $i=0; $i<@descrizioneReparti; $i++) {
        $report->write( $i+2, 0, $descrizioneReparti[$i]);
        
        # venduto anno corrente
        my $formula = '';
        foreach my $riga (@righeInizioSettimana) {
            $formula .= xl_rowcol_to_cell($riga + $i + 2, 1).'+';
        }
        $formula =~ s/\+$//;
        $report->write_formula( $i + 2, 1, $formula, $formatNum2DecimalDigit);
        
        # venduto percentuale anno corrente 
        my $cellaACTotale = xl_rowcol_to_cell( 15, 1, 1, 1 );    #riferimenti assoluti
        my $cellaACImporto = xl_rowcol_to_cell($i + 2, 1);
        $formula = "=IF(".$cellaACTotale."<>0,".$cellaACImporto."/".$cellaACTotale.",0)";
        $report->write_formula( $i + 2, 2, $formula, $formatPerc2DecimalDigit);
        
        # ore anno corrente
        my $cellaACOre = xl_rowcol_to_cell($i + 2, 3);
        $formula = '';
        foreach  my $riga (@righeInizioSettimana) {
            $formula .= xl_rowcol_to_cell($riga + $i + 2, 3).'+';
        }
        $formula =~ s/\+$//;
        $report->write_formula( $i + 2, 3, $formula, $formatNum1DecimalDigit);
        
        # procapite anno corrente
        $formula = "=IF(".$cellaACOre."<>0,".$cellaACImporto."/".$cellaACOre.",0)";
        $report->write_formula( $i + 2, 4, $formula, $formatNum2DecimalDigit);
        
        # clienti anno corrente
        my $cellaACClienti = xl_rowcol_to_cell($i + 2, 5);
        $formula = '';
        foreach my $riga (@righeInizioSettimana) {
            $formula .= xl_rowcol_to_cell($riga + $i + 2, 5).'+';
        }
        $formula =~ s/\+$//;
        $report->write_formula( $i + 2, 5, $formula, $formatNum0DecimalDigit);
        
         # venduto anno precedente
        $formula = '';
        foreach my $riga (@righeInizioSettimana) {
            $formula .= xl_rowcol_to_cell($riga + $i + 2, 7).'+';
        }
        $formula =~ s/\+$//;
        $report->write_formula( $i + 2, 7, $formula, $formatNum2DecimalDigit);
        
        # venduto percentuale anno precedente 
        my $cellaAPTotale = xl_rowcol_to_cell( 15, 7, 1, 1 );    #riferimenti assoluti
        my $cellaAPImporto = xl_rowcol_to_cell($i + 2, 7);
        $formula = "=IF(".$cellaAPTotale."<>0,".$cellaAPImporto."/".$cellaAPTotale.",0)";
        $report->write_formula( $i + 2, 8, $formula, $formatPerc2DecimalDigit);
        
        # ore anno precedente
        my $cellaAPOre = xl_rowcol_to_cell($i + 2, 9);
        $formula = '';
        foreach my $riga (@righeInizioSettimana) {
            $formula .= xl_rowcol_to_cell($riga + $i + 2, 9).'+';
        }
        $formula =~ s/\+$//;
        $report->write_formula( $i + 2, 9, $formula, $formatNum1DecimalDigit);
        
        # procapite anno precedente
        $formula = "=IF(".$cellaAPOre."<>0,".$cellaAPImporto."/".$cellaAPOre.",0)";
        $report->write_formula( $i + 2, 10, $formula, $formatNum2DecimalDigit);
        
        # clienti anno precedente
        my $cellaAPClienti = xl_rowcol_to_cell($i + 2, 11);
        $formula = '';
        foreach my $riga (@righeInizioSettimana) {
            $formula .= xl_rowcol_to_cell($riga + $i + 2, 11).'+';
        }
        $formula =~ s/\+$//;
        $report->write_formula( $i + 2, 11, $formula, $formatNum0DecimalDigit);
        
        # Differenze
        $formula = "=".$cellaACImporto."-".$cellaAPImporto;
        $report->write_formula( $i + 2, 13, $formula, $formatNum2DecimalDigit);
     
        $formula = "=IF($cellaACImporto<>0,($cellaACImporto-$cellaAPImporto)/$cellaACImporto,0)";
        $report->write_formula( $i + 2, 14, $formula, $formatPerc2DecimalDigit);
        
        $formula = "=".$cellaACOre."-".$cellaAPOre;
        $report->write_formula( $i + 2, 15, $formula, $formatNum1DecimalDigit);
        
        $formula = "=".xl_rowcol_to_cell($i + 2, 4)."-".xl_rowcol_to_cell($i + 2, 10);
        $report->write_formula( $i + 2, 16, $formula, $formatNum2DecimalDigit);
            
        $formula = "=".$cellaACClienti."-".$cellaAPClienti;
        $report->write_formula( $i + 2, 17, $formula, $formatNum0DecimalDigit);
        
    }
    
    my $riga = 15;
    $report->write( $riga, 0, "Totali Mese", $formatTitoli);
        
    my $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($riga-13, 1).":".xl_rowcol_to_cell($riga-1, 1).")";
    $report->write_formula( $riga, 1, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($riga-13, 3).":".xl_rowcol_to_cell($riga-1, 3).")";
    $report->write_formula( $riga, 3, $formula, $formatNum1DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($riga, 3)."<>0,".xl_rowcol_to_cell($riga, 1)."/".xl_rowcol_to_cell($riga, 3).",0)";
    $report->write_formula( $riga, 4, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($riga-13, 5).":".xl_rowcol_to_cell($riga-1, 5).")";
    $report->write_formula( $riga, 5, $formula, $formatNum0DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($riga, 1)."<>0,".xl_rowcol_to_cell($riga, 1)."/".xl_rowcol_to_cell($riga, 5).",0)";
    $report->write_formula( $riga, 6, $formula, $formatNum2DecimalDigitBold);
    $report->merge_range( $riga-13, 6, $riga-1, 6, '', $formatEmpty);
    
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($riga-13, 7).":".xl_rowcol_to_cell($riga-1, 7).")";
    $report->write_formula( $riga, 7, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($riga-13, 9).":".xl_rowcol_to_cell($riga-1, 9).")";
    $report->write_formula( $riga, 9, $formula, $formatNum1DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($riga, 9)."<>0,".xl_rowcol_to_cell($riga, 7)."/".xl_rowcol_to_cell($riga, 9).",0)";
    $report->write_formula( $riga, 10, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($riga-13, 11).":".xl_rowcol_to_cell($riga-1, 11).")";
    $report->write_formula( $riga, 11, $formula, $formatNum0DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($riga, 11)."<>0,".xl_rowcol_to_cell($riga, 7)."/".xl_rowcol_to_cell($riga, 11).",0)";
    $report->write_formula( $riga, 12, $formula, $formatNum2DecimalDigitBold);
    $report->merge_range( $riga-13, 12, $riga-1, 12, '', $formatEmpty);
    
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($riga-13, 13).":".xl_rowcol_to_cell($riga-1, 13).")";
    $report->write_formula( $riga, 13, $formula, $formatNum2DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($riga, 1)."<>0,(".xl_rowcol_to_cell($riga, 1)."-".xl_rowcol_to_cell($riga, 7).")/".xl_rowcol_to_cell($riga, 1).",0)";
    $report->write_formula( $riga, 14, $formula, $formatPerc2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($riga-13, 15).":".xl_rowcol_to_cell($riga-1, 15).")";
    $report->write_formula( $riga, 15, $formula, $formatNum1DecimalDigitBold);
    $formula = "=".xl_rowcol_to_cell($riga, 4)."-".xl_rowcol_to_cell($riga, 10);
    $report->write_formula( $riga, 16, $formula, $formatNum1DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($riga-13, 17).":".xl_rowcol_to_cell($riga-1, 17).")";
    $report->write_formula( $riga, 17, $formula, $formatNum0DecimalDigitBold);
    $formula = "=".xl_rowcol_to_cell($riga, 6)."-".xl_rowcol_to_cell($riga, 12);
    $report->write_formula( $riga, 18, $formula, $formatNum2DecimalDigitBold);
    $report->merge_range( $riga-13, 18, $riga-1, 18, '', $formatEmpty);
}

sub scriviElencoSettimane {
    
    for (my $i = 0; $i < @refInizioSettimana; $i++) {
        
    }
}

sub scriviAnno {
    my ($workbook, $totali) = @_;
    
    my $offset = 2;
    $totali->merge_range( $offset, 0, $offset+1, 0, "$societa$negozio - $negozi{$societa.$negozio}" , $formatTitoliBorderYear);
    $totali->merge_range( $offset, 1, $offset, 6, $annoCorrente, $formatTitoliBorderYear);
    $totali->merge_range( $offset, 7, $offset, 12, $annoPrecedente, $formatTitoliBorderYear);
    $totali->merge_range( $offset, 13, $offset, 18, 'Differenze', $formatTitoliBorderYear);
    
    $totali->write( $offset + 1, 1, "Venduto", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 2, "%", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 3, "Ore", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 4, "Proc.", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 5, "Clienti", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 6, "Sc. Med.", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 7, "Venduto", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 8, "%", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 9, "Ore", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 10, "Proc.", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 11, "Clienti", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 12, "Sc. Med.", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 13, "Venduto", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 14, "%", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 15, "Ore", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 16, "Proc.", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 17, "Clienti", $formatTitoliBorderYear);
    $totali->write( $offset + 1, 18, "Sc. Med.", $formatTitoliBorderYear);
    
    # larghezza colonne
    $totali->set_column( 0, 0, 20 );
    $totali->set_column( 1, 1, 12 );
    $totali->set_column( 2, 2, 9 );
    $totali->set_column( 3, 6, 8 );
    
    $totali->set_column( 7, 7, 12 );
    $totali->set_column( 8, 8, 9 );
    $totali->set_column( 9, 12, 8 );
    
    $totali->set_column( 13, 13, 12 );
    $totali->set_column( 14, 14, 9 );
    $totali->set_column( 15, 18, 8 );
            
    my @sheetList = $workbook->sheets();
    
    for(my $i=0; $i<@descrizioneReparti; $i++) {
            $totali->write( $offset + 2 + $i, 0, $descrizioneReparti[$i]);
            
            # venduto anno corrente
            my $formula = '';
            for (my $j = 1; $j < @sheetList; $j++) {
                $formula .= $sheetList[$j]->get_name().'!'.xl_rowcol_to_cell( 2 + $i, 1).'+';
            }
            $formula =~ s/\+$//;
            $totali->write_formula( $offset + 2 + $i, 1, $formula, $formatNum2DecimalDigit);
            
            # venduto percentuale anno corrente 
            my $cellaACTotale = xl_rowcol_to_cell( $offset + 15, 1, 1, 1 );    #riferimenti assoluti
            my $cellaACImporto = xl_rowcol_to_cell($offset + 2 + $i, 1);
            $formula = "=IF(".$cellaACTotale."<>0,".$cellaACImporto."/".$cellaACTotale.",0)";
            $totali->write_formula( $offset + 2 + $i, 2, $formula, $formatPerc2DecimalDigit);
            
            # ore anno corrente
            my $cellaACOre = xl_rowcol_to_cell($offset + 2 + $i, 3);
            $formula = '';
            for (my $j = 1; $j < @sheetList; $j++) {
                $formula .= $sheetList[$j]->get_name().'!'.xl_rowcol_to_cell( 2 + $i, 3).'+';
            }
            $formula =~ s/\+$//;
            $totali->write_formula( $offset + 2 + $i, 3, $formula, $formatNum1DecimalDigit);
            
            ## procapite anno corrente
            $formula = "=IF(".$cellaACOre."<>0,".$cellaACImporto."/".$cellaACOre.",0)";
            $totali->write_formula( $offset + 2 + $i, 4, $formula, $formatNum2DecimalDigit);
            
            ## clienti anno corrente
            my $cellaACClienti = xl_rowcol_to_cell($offset + 2 + $i, 5);
            $formula = '';
            for (my $j = 1; $j < @sheetList; $j++) {
                $formula .= $sheetList[$j]->get_name().'!'.xl_rowcol_to_cell( 2 + $i, 5).'+';
            }
            $formula =~ s/\+$//;
            $totali->write_formula( $offset + 2 + $i, 5, $formula, $formatNum0DecimalDigit);
            
            # venduto anno precedente
            $formula = '';
            for (my $j = 1; $j < @sheetList; $j++) {
                $formula .= $sheetList[$j]->get_name().'!'.xl_rowcol_to_cell( 2 + $i, 7).'+';
            }
            $formula =~ s/\+$//;
            $totali->write_formula( $offset + 2 + $i, 7, $formula, $formatNum2DecimalDigit);
            
            # venduto percentuale anno precedente 
            my $cellaAPTotale = xl_rowcol_to_cell( $offset + 15, 7, 1, 1 );    #riferimenti assoluti
            my $cellaAPImporto = xl_rowcol_to_cell($offset + 2 + $i, 7);
            $formula = "=IF(".$cellaAPTotale."<>0,".$cellaAPImporto."/".$cellaAPTotale.",0)";
            $totali->write_formula( $offset + 2 + $i, 8, $formula, $formatPerc2DecimalDigit);
            
            # ore anno precedente
            my $cellaAPOre = xl_rowcol_to_cell($offset + 2 + $i, 9);
            $formula = '';
            for (my $j = 1; $j < @sheetList; $j++) {
                $formula .= $sheetList[$j]->get_name().'!'.xl_rowcol_to_cell( 2 + $i, 9).'+';
            }
            $formula =~ s/\+$//;
            $totali->write_formula( $offset + 2 + $i, 9, $formula, $formatNum1DecimalDigit);
            
            # procapite anno precedente
            $formula = "=IF(".$cellaAPOre."<>0,".$cellaAPImporto."/".$cellaAPOre.",0)";
            $totali->write_formula( $offset + 2 + $i, 10, $formula, $formatNum2DecimalDigit);
            
            # clienti anno precedente
            my $cellaAPClienti = xl_rowcol_to_cell($offset + 2 + $i, 11);
            $formula = '';
            for (my $j = 1; $j < @sheetList; $j++) {
                $formula .= $sheetList[$j]->get_name().'!'.xl_rowcol_to_cell( 2 + $i, 11).'+';
            }
            $formula =~ s/\+$//;
            $totali->write_formula( $offset + 2 + $i, 11, $formula, $formatNum0DecimalDigit);
            
            # Differenze
            $formula = "=".$cellaACImporto."-".$cellaAPImporto;
            $totali->write_formula( $offset + 2 + $i, 13, $formula, $formatNum2DecimalDigit);
            
            $formula = "=IF($cellaACImporto<>0,($cellaACImporto-$cellaAPImporto)/$cellaACImporto,0)";
            $totali->write_formula( $offset + 2 + $i, 14, $formula, $formatPerc2DecimalDigit);
            
            $formula = "=".$cellaACOre."-".$cellaAPOre;
            $totali->write_formula( $offset + 2 + $i, 15, $formula, $formatNum1DecimalDigit);
            
            $formula = "=".xl_rowcol_to_cell($offset + 2 + $i, 4)."-".xl_rowcol_to_cell($offset + 2 + $i, 10);
            $totali->write_formula( $offset + 2 + $i, 16, $formula, $formatNum2DecimalDigit);
                
            $formula = "=".$cellaACClienti."-".$cellaAPClienti;
            $totali->write_formula( $offset + 2 + $i, 17, $formula, $formatNum0DecimalDigit);
            
        }
    
    $totali->write( $offset + 15, 0, "Totali Anno", $formatTitoli);
            
    my $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($offset + 15-13, 1).":".xl_rowcol_to_cell($offset + 15-1, 1).")";
    $totali->write_formula( $offset + 15, 1, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($offset + 15-13, 3).":".xl_rowcol_to_cell($offset + 15-1, 3).")";
    $totali->write_formula( $offset + 15, 3, $formula, $formatNum1DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($offset + 15, 1)."<>0,".xl_rowcol_to_cell($offset + 15, 1)."/".xl_rowcol_to_cell($offset + 15, 3).",0)";
    $totali->write_formula( $offset + 15, 4, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($offset + 15-13, 5).":".xl_rowcol_to_cell($offset + 15-1, 5).")";
    $totali->write_formula( $offset + 15, 5, $formula, $formatNum0DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($offset + 15, 1)."<>0,".xl_rowcol_to_cell($offset + 15, 1)."/".xl_rowcol_to_cell($offset + 15, 5).",0)";
    $totali->write_formula( $offset + 15, 6, $formula, $formatNum2DecimalDigitBold);
    $totali->merge_range( $offset + 15-13, 6, $offset + 15-1, 6, '', $formatEmpty);
    
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($offset + 15-13, 7).":".xl_rowcol_to_cell($offset + 15-1, 7).")";
    $totali->write_formula( $offset + 15, 7, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($offset + 15-13, 9).":".xl_rowcol_to_cell($offset + 15-1, 9).")";
    $totali->write_formula( $offset + 15, 9, $formula, $formatNum1DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($offset + 15, 7)."<>0,".xl_rowcol_to_cell($offset + 15, 7)."/".xl_rowcol_to_cell($offset + 15, 9).",0)";
    $totali->write_formula( $offset + 15, 10, $formula, $formatNum2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($offset + 15-13, 11).":".xl_rowcol_to_cell($offset + 15-1, 11).")";
    $totali->write_formula( $offset + 15, 11, $formula, $formatNum0DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($offset + 15, 7)."<>0,".xl_rowcol_to_cell($offset + 15, 7)."/".xl_rowcol_to_cell($offset + 15, 11).",0)";
    $totali->write_formula( $offset + 15, 12, $formula, $formatNum2DecimalDigitBold);
    $totali->merge_range( $offset + 15-13, 12, $offset + 15-1, 12, '', $formatEmpty);
    
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($offset + 15-13, 13).":".xl_rowcol_to_cell($offset + 15-1, 13).")";
    $totali->write_formula( $offset + 15, 13, $formula, $formatNum2DecimalDigitBold);
    $formula = "=IF(".xl_rowcol_to_cell($offset + 15, 1)."<>0,(".xl_rowcol_to_cell($offset + 15, 1)."-".xl_rowcol_to_cell($offset + 15, 7).")/".xl_rowcol_to_cell($offset + 15, 1).",0)";
    $totali->write_formula( $offset + 15, 14, $formula, $formatPerc2DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($offset + 15-13, 15).":".xl_rowcol_to_cell($offset + 15-1, 15).")";
    $totali->write_formula( $offset + 15, 15, $formula, $formatNum1DecimalDigitBold);
    $formula = "=".xl_rowcol_to_cell($offset + 15, 4)."-".xl_rowcol_to_cell($offset + 15, 10);
    $totali->write_formula( $offset + 15, 16, $formula, $formatNum1DecimalDigitBold);
    $formula = "=SUBTOTAL(9, ".xl_rowcol_to_cell($offset + 15-13, 17).":".xl_rowcol_to_cell($offset + 15-1, 17).")";
    $totali->write_formula( $offset + 15, 17, $formula, $formatNum0DecimalDigitBold);
    $formula = "=".xl_rowcol_to_cell($offset + 15, 6)."-".xl_rowcol_to_cell($offset + 15, 12);
    $totali->write_formula( $offset + 15, 18, $formula, $formatNum2DecimalDigitBold);
    $totali->merge_range( $offset + 15-13, 18, $offset + 15-1, 18, '', $formatEmpty);
    
    
    # Add the VBA project binary.
    #$totali->add_vba_project( '/script/vbaProject.bin' );
      
    # Add a button tied to a macro in the VBA project.
    $totali->insert_button(
        'A1',
        {
            macro   => 'crea_pivot',
            caption => 'Obbiettivo',
            width   => 120,
            height  => 40
        }
    );
}

sub giornoCorrispondente {
    my ($data) = @_;
    
    my ($weekYear, $weekNumber) = $data->week;

    my $dayOfWeek = $data->day_of_week();
    return DateTime->new( year => ($weekYear-1), month => 1, day => 4 )->add( weeks => ($weekNumber-1) )->truncate( to => 'week' )->add(days => ($dayOfWeek-1));
}

sub limitiMese {
    my ($anno, $mese) = @_;
    
    my $idMese = sprintf('%04d%02d',$anno, $mese);
    
    my $idSettimanaIniziale = sprintf('%04d%02d',$anno, $mesi{$idMese}{'inizio'});
    my $idSettimanaFinale = sprintf('%04d%02d',$anno, $mesi{$idMese}{'fine'});
        
    return string2Date($settimane{$idSettimanaIniziale}{'inizio'}), string2Date($settimane{$idSettimanaFinale}{'fine'});
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
	$dbh = DBI->connect("DBI:mysql:archivi:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database!\n";
		return 0;
	}

    # limiti settimane
	$sth = $dbh->prepare(qq{select concat(cast(anno as char), lpad(cast(settimana as char),2,'0')) `id`, data_inizio, data_fine
                            from archivi.calendario
                            where anno in (?,?)
                            order by 1}
                        );
    if ($sth->execute($annoCorrente, $annoPrecedente)) {
        while (my @record = $sth->fetchrow_array()) {
            $settimane{$record[0]} = {'inizio' => $record[1], 'fine' => $record[2]};
        }
    }
    $sth->finish();
    
    # composizione mesi
    $sth = $dbh->prepare(qq{select concat(cast(anno as char), lpad(cast(mese as char),2,'0')) `id`, min(settimana), max(settimana)
                            from archivi.calendario
                            where anno in (?,?)
                            group by 1
                            order by 1}
                        );
    if ($sth->execute($annoCorrente, $annoPrecedente)) {
        while (my @record = $sth->fetchrow_array()) {
            $mesi{$record[0]} = {'inizio' => $record[1], 'fine' => $record[2]};
        }
    }
    $sth->finish();
    
    # descrizione reparti
    $sth = $dbh->prepare(qq{select descrizione from archivi.reparti order by codice});
    if ($sth->execute()) {
        while (my @record = $sth->fetchrow_array()) {
            push @descrizioneReparti, $record[0];
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
    
    $sth = $dbh->prepare(qq{select r.`codice`, r.`descrizione`, ifnull(c.importo,0), ifnull(c.ore,0), ifnull(c.clienti,0)
                            from archivi.reparti as r left join 
                                (select c.`reparto`, round(sum(c.importo),2) `importo`, round(sum(c.ore),2) `ore`, round(ifnull(sum(c.clienti),0),2) `clienti`
                                from archivi.consolidatiReparto as c
                                where c.codiceSocieta=? and c.codiceNegozio=? and c.data>=? and c.data<=? 
                                group by 1) as c on r.`codice`=c.`reparto`
                            order by 1}
                        );
        
    return 1;
}
