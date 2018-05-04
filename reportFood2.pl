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
my $excelFileName = "reportFood2.xlsx";

# parametri di configurazione foglio excel
#------------------------------------------------------------------------------------------------------------
my $righe_bloccate = 2;
my $colonne_bloccate = 5;

my $larghezza_colonna_area = 10;
my $larghezza_colonna_negozio = 25;
my $larghezza_colonna_importo = 13;
my $larghezza_colonna_estendo = 12;
my $larghezza_colonna_peso= 7;

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh; #database handler
my $sth; #statement handler

my @acNegozioCodice = ();
my @acNegozioDescrizione = ();
my @acRepartoCodice = ();
my @acRepartoDescrizione = ();
my @acImporto = ();
my @acOre = ();
my @acClienti = ();
my @apNegozioCodice = ();
my @apNegozioDescrizione = ();
my @apRepartoCodice = ();
my @apRepartoDescrizione = ();
my @apImporto = ();
my @apOre = ();
my @apClienti = ();

my @codiceReparti = ();
my @descrizioneReparti = ();

my %descrizioneMesi = ( 1 => 'GENNAIO', 2 => 'FEBBRAIO', 3 => 'MARZO', 4 => 'APRILE', 5 => 'MAGGIO', 6 => 'GIUGNO',
                        7 => 'LUGLIO', 8 => 'AGOSTO', 9 => 'SETTEMBRE', 10 => 'OTTOBRE', 11 => 'NOVEMBRE', 12 => 'DICEMBRE');

my %settimane = ();
my %mesi = ();


if (&ConnessioneDB) {
    
    #creo il workbook
    my $workbook = Excel::Writer::XLSX->new("$desktop/$excelFileName");
    
    #formati
    #-------------------------------------------------------------------------------------------------
    my $format = $workbook->add_format();
    $format->set_bold();
    my $date_format = $workbook->add_format();
    $date_format->set_num_format('dd/mm/yy');
    
    my $formatTitoli = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        color => 'Black',
        size => 12
    );
    
    my $formatTitoliBorderDay = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => '#F4C875' #'#D6FFFF'
    );
    
    my $formatTitoliBorderRep1 = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => '#00bfff'
    );
    
    my $formatTitoliBorderRep2 = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => '#00ff7f'
    );
    
    my $formatTitoliBorderRep3 = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => '#ff0000'
    );
    
    my $formatTitoliBorderRep4 = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => 'e6e6fa'
    );
    
    my $formatTitoliBorderRep5 = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => '#da70d6'
    );
    
    my $formatTitoliBorderRep6 = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => '#ffff00'
    );
    
    my $formatTitoliBorderRep7 = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => '#228b22'
    );
    
    my $formatTitoliBorderRep8 = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => '#1e90ff'
    );
    
    my $formatTitoliBorderRep9 = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => '#778899'
    );
    
    my $formatTitoliBorderRep10 = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => '#fff0f5'
    );
    
    my $formatTitoliBorderRep11 = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => '#f0fff0'
    );
    
    my $formatTitoliBorderRep12 = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => '#cdc8b1'
    );
    
    my $formatTitoliBorderRep13 = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        border => 1,
        color => 'Black',
        size => 12,
        bg_color => '#8b7765'
    );
    
    my $formatEmpty = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        color => 'Black',
        size => 12
    );
    
    my $formatPerc2DecimalDigit = $workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 0,
        color => 'Black',
        size => 12,
        num_format =>  "[Black]###,##0.00%; [Red]-###,##0.00%; [Black]###,##0.00%"
    );
    
    my $formatPerc2DecimalDigitBold = $workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 1,
        color => 'Black',
        size => 12,
        num_format =>  "[Black]###,##0.00%; [Red]-###,##0.00%; [Black]###,##0.00%"
    );
    
    my $formatNum0DecimalDigit = $workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 0,
        color => 'Black',
        size => 12,
        num_format =>  "[Black]###,##0; [Red]-###,##0; [Black]###,##0"
    );
    
    my $formatNum0DecimalDigitBold = $workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 1,
        color => 'Black',
        size => 12,
        num_format =>  "[Black]###,##0; [Red]-###,##0; [Black]###,##0"
    );

    my $formatNum1DecimalDigit = $workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 0,
        color => 'Black',
        size => 12,
        num_format =>  "[Black]###,##0.0; [Red]-###,##0.0; [Black]###,##0.0"
    );
    
    my $formatNum1DecimalDigitBold = $workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 1,
        color => 'Black',
        size => 12,
        num_format =>  "[Black]###,##0.0; [Red]-###,##0.0; [Black]###,##0.0"
    );
    
    my $formatNum2DecimalDigit = $workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 0,
        color => 'Black',
        size => 12,
        num_format =>  "[Black]###,##0.00; [Red]-###,##0.00; [Black]###,##0.00"
    );
    
    my $formatNum2DecimalDigitBold = $workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 1,
        color => 'Black',
        size => 12,
        num_format =>  "[Black]###,##0.00; [Red]-###,##0.00; [Black]###,##0.00"
    );
    
    my $formula = '';
    
    my $anno = $workbook->add_worksheet( 'ANNO' );
     
    # calcolo limiti periodo
    # ------------------------------------------------------------------------------------------------------------------------------------
    my ($dataInizioMese, $dataFineMese) = &limitiMese($annoCorrente, 1);
    my $dataInizioAnno = $dataInizioMese;
    #($dataInizioMese, $dataFineMese) = &limitiMese($annoCorrente, 12);
    #my $dataFineAnno = $dataFineMese;
    
    my $dataFine = $dataCorrente->clone()->subtract(days => 1);

    # caricamento dati
    # -----------------------------------------------------------------------------------------------------------------------------------
    @acNegozioCodice = ();
    @acNegozioDescrizione = ();
    @acRepartoCodice = ();
    @acRepartoDescrizione = ();
    @acImporto = ();
    @acOre = ();
    @acClienti = ();
    if ($sth->execute($dataInizioAnno->ymd('-'), $dataFine->ymd('-'))) {
        while (my @record = $sth->fetchrow_array()) {
            push @acNegozioCodice, $record[0];
            push @acNegozioDescrizione, $record[1];
            push @acRepartoCodice, $record[2];
            push @acRepartoDescrizione, $record[3];
            push @acImporto, $record[4];
            push @acOre, $record[5];
            push @acClienti, $record[6];
        }
    }
    
    @apNegozioCodice = ();
    @apNegozioDescrizione = ();
    @apRepartoCodice = ();
    @apRepartoDescrizione = ();
    @apImporto = ();
    @apOre = ();
    @apClienti = ();
    if ($sth->execute(&giornoCorrispondente($dataInizioAnno)->ymd('-'), &giornoCorrispondente($dataFine)->ymd('-'))) {
        while (my @record = $sth->fetchrow_array()) {
            push @apNegozioCodice, $record[0];
            push @apNegozioDescrizione, $record[1];
            push @apRepartoCodice, $record[2];
            push @apRepartoDescrizione, $record[3];
            push @apImporto, $record[4];
            push @apOre, $record[5];
            push @apClienti, $record[6];
        }
    }
    
    # creazione foglio
    # ------------------------------------------------------------------------------------------------------------------------------------
    my %negozi = ();
    for (my $i = 0; $i < @acNegozioCodice; $i++) {$negozi{$acNegozioCodice[$i]} = $acNegozioDescrizione[$i]};
    for (my $i = 0; $i < @apNegozioCodice; $i++) {$negozi{$apNegozioCodice[$i]} = $apNegozioDescrizione[$i]};
    my @listaNegozi = sort { $a cmp $b } keys %negozi;
    
    my $riga = 0;
    
    $anno->set_column( 0, 0, 20 );
    $anno->merge_range( $riga, 0, $riga + 1, 0, 'Punti Vendita', $formatTitoliBorderDay);
    
    my $colonneReparto = 11;
    my $colonnaInizialeReparti = 16;
    
    $anno->freeze_panes( 2, 1 );
     
    $anno->merge_range( $riga, 1, $riga, 3, "Venduto", $formatTitoliBorderDay);
    $anno->merge_range( $riga, 4, $riga, 6, "Ore", $formatTitoliBorderDay);
    $anno->merge_range( $riga, 7, $riga, 9, "Procapite", $formatTitoliBorderDay);
    $anno->merge_range( $riga, 10, $riga, 12, "Clienti", $formatTitoliBorderDay);
    $anno->merge_range( $riga, 13, $riga, 15, "Scontrino Medio", $formatTitoliBorderDay);
    
    my $colonna = $colonnaInizialeReparti;
    for(my $j=0; $j<@codiceReparti; $j++) {
        
        my $format = $formatTitoliBorderDay;
        if ($j == 0) {
            $format = $formatTitoliBorderRep1;
        } elsif ($j == 1) {
            $format = $formatTitoliBorderRep2;
        } elsif ($j == 2) {
            $format = $formatTitoliBorderRep3;
        } elsif ($j == 3) {
            $format = $formatTitoliBorderRep4;
        } elsif ($j == 4) {
            $format = $formatTitoliBorderRep5;
        } elsif ($j == 5) {
            $format = $formatTitoliBorderRep6;
        } elsif ($j == 6) {
            $format = $formatTitoliBorderRep7;
        } elsif ($j == 7) {
            $format = $formatTitoliBorderRep8;
        } elsif ($j == 8) {
            $format = $formatTitoliBorderRep9;
        } elsif ($j == 9) {
            $format = $formatTitoliBorderRep10;
        } elsif ($j == 10) {
            $format = $formatTitoliBorderRep11;
        } elsif ($j == 11) {
            $format = $formatTitoliBorderRep12;
        } elsif ($j == 12) {
            $format = $formatTitoliBorderRep13;
        }
        $anno->merge_range( $riga, $colonna, $riga , $colonna + $colonneReparto -1 , $descrizioneReparti[$j], $format);
        $colonna += $colonneReparto;
    }
    $riga++;
    
    $anno->set_column( 1, 1, 15 );
    $anno->write( 1, 1,  $annoPrecedente, $formatTitoliBorderDay);
    $anno->set_column( 2, 2, 15 );
    $anno->write( 1, 2,  $annoCorrente, $formatTitoliBorderDay);
    $anno->set_column( 3, 3, 9 );
    $anno->write( 1, 3,  'diff.%', $formatTitoliBorderDay);
    $anno->set_column( 4, 4, 10 );
    $anno->write( 1, 4,  $annoPrecedente, $formatTitoliBorderDay);
    $anno->set_column( 5, 5, 10 );
    $anno->write( 1, 5,  $annoCorrente, $formatTitoliBorderDay);
    $anno->set_column( 6, 6, 9 );
    $anno->write( 1, 6,  'diff.%', $formatTitoliBorderDay);
    $anno->set_column( 7, 7, 10 );
    $anno->write( 1, 7,  $annoPrecedente, $formatTitoliBorderDay);
    $anno->set_column( 8, 8, 10 );
    $anno->write( 1, 8,  $annoCorrente, $formatTitoliBorderDay);
    $anno->set_column( 9, 9, 9 );
    $anno->write( 1, 9,  'diff.%', $formatTitoliBorderDay);
    $anno->set_column( 10, 10, 10 );
    $anno->write( 1, 10,  $annoPrecedente, $formatTitoliBorderDay);
    $anno->set_column( 11, 11, 10 );
    $anno->write( 1, 11,  $annoCorrente, $formatTitoliBorderDay);
    $anno->set_column( 12, 12, 9 );
    $anno->write( 1, 12,  'diff.%', $formatTitoliBorderDay);
    $anno->set_column( 13, 13, 9 );
    $anno->write( 1, 13,  $annoPrecedente, $formatTitoliBorderDay);
    $anno->set_column( 14, 14, 9 );
    $anno->write( 1, 14,  $annoCorrente, $formatTitoliBorderDay);
    $anno->set_column( 15, 15, 9 );
    $anno->write( 1, 15,  'diff.%', $formatTitoliBorderDay);
    
    $colonna = $colonnaInizialeReparti;
    for(my $j=0; $j<@codiceReparti; $j++) {
        
        my $format = $formatTitoliBorderDay;
        if ($j == 0) {
            $format = $formatTitoliBorderRep1;
        } elsif ($j == 1) {
            $format = $formatTitoliBorderRep2;
        } elsif ($j == 2) {
            $format = $formatTitoliBorderRep3;
        } elsif ($j == 3) {
            $format = $formatTitoliBorderRep4;
        } elsif ($j == 4) {
            $format = $formatTitoliBorderRep5;
        } elsif ($j == 5) {
            $format = $formatTitoliBorderRep6;
        } elsif ($j == 6) {
            $format = $formatTitoliBorderRep7;
        } elsif ($j == 7) {
            $format = $formatTitoliBorderRep8;
        } elsif ($j == 8) {
            $format = $formatTitoliBorderRep9;
        } elsif ($j == 9) {
            $format = $formatTitoliBorderRep10;
        } elsif ($j == 10) {
            $format = $formatTitoliBorderRep11;
        } elsif ($j == 11) {
            $format = $formatTitoliBorderRep12;
        } elsif ($j == 12) {
            $format = $formatTitoliBorderRep13;
        }
        
        
        $anno->set_column( $colonna, $colonna, 15 );
        $anno->write( $riga, $colonna,  $annoPrecedente, $format);
        
        $anno->set_column( $colonna + 1, $colonna + 1, 15 );
        $anno->write( $riga, $colonna + 1,  $annoCorrente, $format);
        
        $anno->set_column( $colonna + 2, $colonna + 2, 9 );
        $anno->write( $riga, $colonna + 2,  'diff.%', $format);
        
        $anno->set_column( $colonna + 3, $colonna + 3, 9 );
        $anno->write( $riga, $colonna + 3,  "inc.% $annoPrecedente", $format);
        
        $anno->set_column( $colonna + 4, $colonna + 4, 9 );
        $anno->write( $riga, $colonna + 4,  "inc.% $annoCorrente", $format);
        
        $anno->set_column( $colonna + 5, $colonna + 5, 9 );
        $anno->write( $riga, $colonna + 5,  "Var.%", $format);
        
        $anno->set_column( $colonna + 6, $colonna + 6, 0, 1); # <------NASCOSTA
        $anno->write( $riga, $colonna + 6,  "ore AP", $format);
        
        $anno->set_column( $colonna + 7, $colonna + 7, 9 );
        $anno->write( $riga, $colonna + 7,  "ore", $format);
        
        $anno->set_column( $colonna + 8, $colonna + 8, 0, 1); # <------NASCOSTA
        $anno->write( $riga, $colonna + 8,  "clienti AP", $format);
        
        $anno->set_column( $colonna + 9, $colonna + 9, 0, 1); # <------NASCOSTA
        $anno->write( $riga, $colonna + 9,  "clienti AC", $format);
        
        $anno->set_column( $colonna + 10, $colonna + 10, 8 );
        $anno->write( $riga, $colonna + 10, "Proc.", $format);
        
        $colonna += $colonneReparto;
    }
    $riga++;
    
    $anno->set_column( 0, 0, 30 );
    for (my $i = 0; $i<@listaNegozi; $i++) {
        $anno->write( $riga, 0, $listaNegozi[$i].' - '.$negozi{$listaNegozi[$i]});
        
        my $colonna = $colonnaInizialeReparti;
        
        # totale anno precedente
        my $cellaAPTotale = xl_rowcol_to_cell($riga, 1);
        $formula = '';
        for(my $j=0; $j<@codiceReparti; $j++) {
            $formula .= xl_rowcol_to_cell($riga, $colonna + ($colonneReparto * $j)).'+';
        }
        $formula =~ s/\+$//;
        $anno->write_formula( $riga, 1, $formula, $formatNum2DecimalDigit);
        
        # totale anno corrente
        my $cellaACTotale = xl_rowcol_to_cell($riga, 2);
        $formula = '';
        for(my $j=0; $j<@codiceReparti; $j++) {
            $formula .= xl_rowcol_to_cell($riga, $colonna + ($colonneReparto * $j) + 1).'+';
        }
        $formula =~ s/\+$//;
        $anno->write_formula( $riga, 2, $formula, $formatNum2DecimalDigit);
        
        # differenza totali
        $formula = "=IF($cellaACTotale <> 0,  ($cellaACTotale - $cellaAPTotale)/$cellaACTotale, -1)";
        $anno->write_formula( $riga, 3, $formula, $formatPerc2DecimalDigit);
        
        # totale ore anno precedente
        my $cellaAPOreTotale = xl_rowcol_to_cell($riga, 4);
        $formula = '';
        for(my $j=0; $j<@codiceReparti; $j++) {
            $formula .= xl_rowcol_to_cell($riga, $colonna + ($colonneReparto * $j) + 6).'+';
        }
        $formula =~ s/\+$//;
        $anno->write_formula( $riga, 4, $formula, $formatNum1DecimalDigit);
        
        # totale ore anno corrente
        my $cellaACOreTotale = xl_rowcol_to_cell($riga, 5);
        $formula = '';
        for(my $j=0; $j<@codiceReparti; $j++) {
            $formula .= xl_rowcol_to_cell($riga, $colonna + ($colonneReparto * $j) + 7).'+';
        }
        $formula =~ s/\+$//;
        $anno->write_formula( $riga, 5, $formula, $formatNum1DecimalDigit);
        
        # differenza ore totali %
        $formula = "=IF($cellaACOreTotale <> 0,  ($cellaACOreTotale - $cellaAPOreTotale)/$cellaACOreTotale, -1)";
        $anno->write_formula( $riga, 6, $formula, $formatPerc2DecimalDigit);
        
        # procapite anno precedente
        my $cellaAPProcapite = xl_rowcol_to_cell($riga, 7);
        $formula = "=IF($cellaAPOreTotale <> 0,  $cellaAPTotale/$cellaAPOreTotale, 0)";
        $anno->write_formula( $riga, 7, $formula, $formatNum2DecimalDigit);
        
        # procapite anno corrente
        my $cellaACProcapite = xl_rowcol_to_cell($riga, 8);
        $formula = "=IF($cellaACOreTotale <> 0,  $cellaACTotale/$cellaACOreTotale, 0)";
        $anno->write_formula( $riga, 8, $formula, $formatNum2DecimalDigit);
        
        # differenza procapite %
        $formula = "=IF($cellaACProcapite<>0, ($cellaACProcapite-$cellaAPProcapite)/$cellaACProcapite, 0)";
        $anno->write_formula( $riga, 9, $formula, $formatPerc2DecimalDigit);
        
        # totale clienti anno precedente
        my $cellaAPClientiTotale = xl_rowcol_to_cell($riga, 10);
        $formula = '';
        for(my $j=0; $j<@codiceReparti; $j++) {
            $formula .= xl_rowcol_to_cell($riga, $colonna + ($colonneReparto * $j) + 8).'+';
        }
        $formula =~ s/\+$//;
        $anno->write_formula( $riga, 10, $formula, $formatNum1DecimalDigit);
        
        # totale clienti anno corrente
        my $cellaACClientiTotale = xl_rowcol_to_cell($riga, 11);
        $formula = '';
        for(my $j=0; $j<@codiceReparti; $j++) {
            $formula .= xl_rowcol_to_cell($riga, $colonna + ($colonneReparto * $j) + 9).'+';
        }
        $formula =~ s/\+$//;
        $anno->write_formula( $riga, 11, $formula, $formatNum1DecimalDigit);
        
        # differenza clienti totali
        $formula = "=IF($cellaACClientiTotale <> 0,  ($cellaACClientiTotale - $cellaAPClientiTotale)/$cellaACClientiTotale, -1)";
        $anno->write_formula( $riga, 12, $formula, $formatPerc2DecimalDigit);
        
        # Scontrino Medio anno precedente
        my $cellaAPScontrinoMedio = xl_rowcol_to_cell($riga, 13);
        $formula = "=IF($cellaAPClientiTotale <> 0,  $cellaAPTotale/$cellaAPClientiTotale, 0)";
        $anno->write_formula( $riga, 13, $formula, $formatNum2DecimalDigit);
        
        # Scontrino Medio anno corrente
        my $cellaACScontrinoMedio = xl_rowcol_to_cell($riga, 14);
        $formula = "=IF($cellaACClientiTotale <> 0,  $cellaACTotale/$cellaACClientiTotale, 0)";
        $anno->write_formula( $riga, 14, $formula, $formatNum2DecimalDigit);
        
        # differenza Scontrino Medio clienti %
        $formula = "=IF($cellaACScontrinoMedio<>0, ($cellaACScontrinoMedio-$cellaAPScontrinoMedio)/$cellaACScontrinoMedio, 0)";
        $anno->write_formula( $riga, 15, $formula, $formatPerc2DecimalDigit);
        
        # scrittura importi reparto
        for(my $j=0; $j<@codiceReparti; $j++) {
            my ($vAcImporto, $vAcOre, $vAcClienti, $vApImporto, $vApOre, $vApClienti) = &cercaDatiNegozio($listaNegozi[$i], $codiceReparti[$j]);
            
            # incasso anno precedente
            my $cellaAPImporto = xl_rowcol_to_cell($riga, $colonna + $j);
            $anno->write( $riga, $colonna + $j, $vApImporto, $formatNum2DecimalDigit);
            
            # incasso anno corrente
            my $cellaACImporto = xl_rowcol_to_cell($riga, $colonna + $j + 1);
            $anno->write( $riga, $colonna + $j + 1, $vAcImporto, $formatNum2DecimalDigit);
            
            # differenza incasso %
            $formula = "=IF($cellaACImporto <> 0,  ($cellaACImporto - $cellaAPImporto)/$cellaACImporto, -1)";
            $anno->write_formula( $riga, $colonna + $j + 2, $formula, $formatPerc2DecimalDigit);
            
            # incidenza reparto anno precedente
            my $cellaAPIncidenza = xl_rowcol_to_cell($riga, $colonna + $j + 3);
            $formula = "=IF($cellaAPTotale <> 0 , $cellaAPImporto/$cellaAPTotale, 0)";
            $anno->write_formula( $riga, $colonna + $j + 3, $formula, $formatPerc2DecimalDigit);
            
            # incidenza reparto anno corrente
            my $cellaACIncidenza = xl_rowcol_to_cell($riga, $colonna + $j + 4);
            $formula = "=IF($cellaACTotale <> 0 , $cellaACImporto/$cellaACTotale, 0)";
            $anno->write_formula( $riga, $colonna + $j + 4, $formula, $formatPerc2DecimalDigit);
            
            # differenza incidenza %
            $formula = "=IF($cellaACIncidenza <> 0,  ($cellaACIncidenza - $cellaAPIncidenza)/$cellaACIncidenza, -1)";
            $anno->write_formula( $riga, $colonna + $j + 5, $formula, $formatPerc2DecimalDigit);
            
            # ore anno precedente
            $anno->write( $riga, $colonna + $j + 6, $vApOre, $formatNum1DecimalDigit);
            
            # ore anno corrente
            my $cellaACOre = xl_rowcol_to_cell($riga, $colonna + $j + 7);
            $anno->write( $riga, $colonna + $j + 7, $vAcOre, $formatNum1DecimalDigit);
            
            # clienti anno precedente
            $anno->write( $riga, $colonna + $j + 8, $vApClienti, $formatNum0DecimalDigit);
            
            # clienti anno corrente
            $anno->write( $riga, $colonna + $j + 9, $vAcClienti, $formatNum0DecimalDigit);
            
            # procapite
            $formula = "=IF($cellaACOre <> 0,  $cellaACImporto/$cellaACOre, 0)";
            $anno->write_formula( $riga, $colonna + $j + 10, $formula, $formatNum2DecimalDigit);
            
            $colonna += $colonneReparto - 1;
        }
        $riga++;
    }
}

sub cercaDatiNegozio {
    my ($negozio, $reparto) = @_;
    
    my $vAcImporto = 0;
    my $vAcOre = 0;
    my $vAcClienti = 0;
    my $vApImporto = 0;
    my $vApOre = 0;
    my $vApClienti = 0;
        
    if ($negozio eq '3674') {
        print "\n";
    }
    for(my $i = 0; $i < @acNegozioCodice; $i++)  {
        if ($acNegozioCodice[$i] eq $negozio && $acRepartoCodice[$i] == $reparto) {
            $vAcImporto = $acImporto[$i];
            $vAcOre = $acOre[$i];
            $vAcClienti = $acClienti[$i];
        }
    }
    
    for(my $i = 0; $i < @apNegozioCodice; $i++)  {
        if ($apNegozioCodice[$i] eq $negozio && $apRepartoCodice[$i] == $reparto) {
            $vApImporto = $apImporto[$i];
            $vApOre = $apOre[$i];
            $vApClienti = $apClienti[$i];
        }
    }
    
    return $vAcImporto, $vAcOre, $vAcClienti, $vApImporto, $vApOre, $vApClienti;
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
    
    
    $sth = $dbh->prepare(qq{select codice, descrizione from archivi.reparti order by codice});
    if ($sth->execute()) {
        while (my @record = $sth->fetchrow_array()) {
            push @codiceReparti, $record[0];
            push @descrizioneReparti, $record[1];
        }
    }
    $sth->finish();
    
    $sth = $dbh->prepare(qq{select c.`codice`, n.`negozio_descrizione`, r.`codice`, r.`descrizione`, ifnull(c.importo,0), ifnull(c.ore,0), ifnull(c.clienti,0)
                            from archivi.reparti as r left join 
                            (select c.`codice`, c.`reparto`, round(sum(c.importo),2) `importo`, round(sum(c.ore),2) `ore`, round(ifnull(sum(c.clienti),0),2) `clienti`
                                from archivi.consolidatiReparto as c
                                where c.data>=? and c.data<=? 
                                group by 1, 2) as c on r.`codice`=c.`reparto` join archivi.negozi as n on c.codice=n.`codice`
                            order by 1, 3}
                        );
        
    return 1;
}
