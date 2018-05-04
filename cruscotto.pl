#!/usr/bin/perl -w
use strict;

use lib '/script/moduli';
use lib '/root/perl5/lib/perl5';

use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
use DBI;
use Log::Log4perl;
use ITM_cruscotto;

# definizione file cruscotto
#------------------------------------------------------------------------------------------------------------
my $path = '/';
my $output_file_name = "$path/cruscotto.xlsx";

# configurazione log
#------------------------------------------------------------------------------------------------------------
my $configurazione = q(
    log4perl.category.if65_cruscotto    = INFO, Logfile

    log4perl.appender.Logfile           = Log::Log4perl::Appender::File
    log4perl.appender.Logfile.filename  = sub{log_file_name();};
    log4perl.appender.Logfile.mode      = append
    log4perl.appender.Logfile.layout    = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Logfile.layout.ConversionPattern = [%d] [%p{3}] %m %n

    log4perl.appender.Screen            = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr     = 0
    log4perl.appender.Screen.layout     = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Screen.layout.ConversionPattern = [%d] [%p{3}] %m %n
);

Log::Log4perl::init( \$configurazione ) or die "configurazione log non riuscita: $!\n";
my $logger = Log::Log4perl::get_logger("if65_cruscotto");

$logger->info("-" x 76);
$logger->info("creazione cruscotto");
$logger->info("-" x 76);
$logger->info("inizio");
$logger->info("");

if (my $db = new ITM_cruscotto()) {
    
    #creazione file excel+formati
    #--------------------------------------------
    my $workbook = Excel::Writer::XLSX->new("$output_file_name");
	
    my $intestazione = $workbook->add_format(color => 'red', bold => 1, align => 'center');
    my $righe = $workbook->add_format( bold => 0);
    my $righe_date = $workbook->add_format( bold => 0, num_format => 'dd/mm/yy', align => 'center');
    my $righe_currency = $workbook->add_format( bold => 0, num_format => '#,##0.00;[Red]-#,##0.00');
    my $righe_integer = $workbook->add_format( bold => 0, num_format => '#,##0;[Red]-#,##0', align => 'center');
    

    #cruscotto riepilogativo
    #--------------------------------------------
    
    #supermedia
    my $intestazione_sm = $workbook->add_format(color => 'White', bold => 1, align => 'center', pattern => 1, bg_color => 'pink');
    my $testo_sm = $workbook->add_format(color => 'Black', bold => 1, align => 'left');
    
    my ($_dc_08_mancanti_numero, $_dc_08_mancanti_valore) = $db->dc_mancanti_totale('08');
    my ($_dc_08_differenze_numero, $_dc_08_differenze_valore) = $db->dc_differenze_totale('08');
    
	my $wb_cr = $workbook->add_worksheet('Cruscotto');
    
    $wb_cr->set_column( 0, 0, 2);
    
    $wb_cr->set_column( 1, 1, 15);
    $wb_cr->set_column( 2, 2, 12);
    $wb_cr->set_column( 3, 3, 12);
    
    $wb_cr->write_string( 1, 1, 'Supermedia', $intestazione_sm);
    $wb_cr->write_string( 1, 2, 'Numero', $intestazione_sm);
    $wb_cr->write_string( 1, 3, 'Valore', $intestazione_sm);
    $wb_cr->write_string( 2, 1, 'DC Mancanti', $testo_sm);
    $wb_cr->write_number( 2, 2, $$_dc_08_mancanti_numero, $righe_integer);
    $wb_cr->write_number( 2, 3, $$_dc_08_mancanti_valore, $righe_integer);
    $wb_cr->write_string( 3, 1, 'DC con Differenze', $testo_sm);
    $wb_cr->write_number( 3, 2, $$_dc_08_differenze_numero, $righe_integer);
    $wb_cr->write_number( 3, 3, $$_dc_08_differenze_valore, $righe_integer);
    $wb_cr->write_string( 4, 1, 'Totale', $testo_sm);
    
    my $range=xl_rowcol_to_cell( 2, 2 ).':'.xl_rowcol_to_cell( 3, 2 );
    $wb_cr->write_formula( 4, 2, '=SUM('.$range.')', $righe_integer);
    $range=xl_rowcol_to_cell( 2, 3 ).':'.xl_rowcol_to_cell( 3, 3 );
    $wb_cr->write_formula( 4, 3, '=SUM('.$range.')', $righe_integer);
    
    #sportland
    my $intestazione_sp = $workbook->add_format(color => 'White', bold => 1, align => 'center', pattern => 1, bg_color => 'orange');
    my $testo_sp = $workbook->add_format(color => 'Black', bold => 1, align => 'left');
    
    my ($_dc_07_mancanti_numero, $_dc_07_mancanti_valore) = $db->dc_mancanti_totale('07');
    my ($_dc_07_differenze_numero, $_dc_07_differenze_valore) = $db->dc_differenze_totale('07');
    
	$wb_cr->set_column( 5, 5, 15);
    $wb_cr->set_column( 6, 6, 12);
    $wb_cr->set_column( 7, 7, 12);
    
    $wb_cr->write_string( 1, 5, 'Sportland', $intestazione_sp);
    $wb_cr->write_string( 1, 6, 'Numero', $intestazione_sp);
    $wb_cr->write_string( 1, 7, 'Valore', $intestazione_sp);
    $wb_cr->write_string( 2, 5, 'DC Mancanti', $testo_sp);
    $wb_cr->write_number( 2, 6, $$_dc_07_mancanti_numero, $righe_integer);
    $wb_cr->write_number( 2, 7, $$_dc_07_mancanti_valore, $righe_integer);
    $wb_cr->write_string( 3, 5, 'DC con Differenze', $testo_sp);
    $wb_cr->write_number( 3, 6, $$_dc_07_differenze_numero, $righe_integer);
    $wb_cr->write_number( 3, 7, $$_dc_07_differenze_valore, $righe_integer);
    $wb_cr->write_string( 4, 5, 'Totale', $testo_sp);
    
    $range=xl_rowcol_to_cell( 2, 6 ).':'.xl_rowcol_to_cell( 3, 6 );
    $wb_cr->write_formula( 4, 6, '=SUM('.$range.')', $righe_integer);
    $range=xl_rowcol_to_cell( 2, 7 ).':'.xl_rowcol_to_cell( 3, 7 );
    $wb_cr->write_formula( 4, 7, '=SUM('.$range.')', $righe_integer);
    
    #ecobrico
    my $intestazione_eb = $workbook->add_format(color => 'White', bold => 1, align => 'center', pattern => 1, bg_color => 'green');
    my $testo_eb = $workbook->add_format(color => 'Black', bold => 1, align => 'left');
    
    my ($_dc_10_mancanti_numero, $_dc_10_mancanti_valore) = $db->dc_mancanti_totale('10');
    my ($_dc_10_differenze_numero, $_dc_10_differenze_valore) = $db->dc_differenze_totale('10');
    
	$wb_cr->set_column( 9, 9, 15);
    $wb_cr->set_column( 10, 10, 12);
    $wb_cr->set_column( 11, 11, 12);
    
    $wb_cr->write_string( 1, 9, 'Ecobrico', $intestazione_eb);
    $wb_cr->write_string( 1, 10, 'Numero', $intestazione_eb);
    $wb_cr->write_string( 1, 11, 'Valore', $intestazione_eb);
    $wb_cr->write_string( 2, 9, 'DC Mancanti', $testo_eb);
    $wb_cr->write_number( 2, 10, $$_dc_10_mancanti_numero, $righe_integer);
    $wb_cr->write_number( 2, 11, $$_dc_10_mancanti_valore, $righe_integer);
    $wb_cr->write_string( 3, 9, 'DC con Differenze', $testo_eb);
    $wb_cr->write_number( 3, 10, $$_dc_10_differenze_numero, $righe_integer);
    $wb_cr->write_number( 3, 11, $$_dc_10_differenze_valore, $righe_integer);
    $wb_cr->write_string( 4, 9, 'Totale', $testo_eb);
    
    $range=xl_rowcol_to_cell( 2, 10 ).':'.xl_rowcol_to_cell( 3, 10 );
    $wb_cr->write_formula( 4, 10, '=SUM('.$range.')', $righe_integer);
    $range=xl_rowcol_to_cell( 2, 11 ).':'.xl_rowcol_to_cell( 3, 11 );
    $wb_cr->write_formula( 4, 11, '=SUM('.$range.')', $righe_integer);
    
    #r&s
    my $intestazione_rs = $workbook->add_format(color => 'White', bold => 1, align => 'center', pattern => 1, bg_color => 'blue');
    my $testo_rs = $workbook->add_format(color => 'Black', bold => 1, align => 'left');
    
    my ($_dc_53_mancanti_numero, $_dc_53_mancanti_valore) = $db->dc_mancanti_totale('53');
    my ($_dc_53_differenze_numero, $_dc_53_differenze_valore) = $db->dc_differenze_totale('53');
    
	$wb_cr->set_column( 13, 13, 15);
    $wb_cr->set_column( 14, 14, 12);
    $wb_cr->set_column( 15, 15, 12);
    
    $wb_cr->write_string( 1,13, 'R. & S.', $intestazione_rs);
    $wb_cr->write_string( 1, 14, 'Numero', $intestazione_rs);
    $wb_cr->write_string( 1, 15, 'Valore', $intestazione_rs);
    $wb_cr->write_string( 2, 13, 'DC Mancanti', $testo_rs);
    $wb_cr->write_number( 2, 14, $$_dc_53_mancanti_numero, $righe_integer);
    $wb_cr->write_number( 2, 15, $$_dc_53_mancanti_valore, $righe_integer);
    $wb_cr->write_string( 3, 13, 'DC con Differenze', $testo_rs);
    $wb_cr->write_number( 3, 14, $$_dc_53_differenze_numero, $righe_integer);
    $wb_cr->write_number( 3, 15, $$_dc_53_differenze_valore, $righe_integer);
    $wb_cr->write_string( 4, 13, 'Totale', $testo_rs);
    
    $range=xl_rowcol_to_cell( 2, 14 ).':'.xl_rowcol_to_cell( 3, 14 );
    $wb_cr->write_formula( 4, 14, '=SUM('.$range.')', $righe_integer);
    $range=xl_rowcol_to_cell( 2, 15 ).':'.xl_rowcol_to_cell( 3, 15 );
    $wb_cr->write_formula( 4, 15, '=SUM('.$range.')', $righe_integer);
    
    
     #italmark
    my $intestazione_it = $workbook->add_format(color => 'White', bold => 1, align => 'center', pattern => 1, bg_color => 'red');
    my $testo_it = $workbook->add_format(color => 'Black', bold => 1, align => 'left');
    
    my ($_dc_01_mancanti_numero, $_dc_01_mancanti_valore) = $db->dc_mancanti_totale('01');
    my ($_dc_01_differenze_numero, $_dc_01_differenze_valore) = $db->dc_differenze_totale('01');
    
	$wb_cr->write_string( 6, 1, 'Italmark', $intestazione_it);
    $wb_cr->write_string( 6, 2, 'Numero', $intestazione_it);
    $wb_cr->write_string( 6, 3, 'Valore', $intestazione_it);
    $wb_cr->write_string( 7, 1, 'DC Mancanti', $testo_it);
    $wb_cr->write_number( 7, 2, $$_dc_01_mancanti_numero, $righe_integer);
    $wb_cr->write_number( 7, 3, $$_dc_01_mancanti_valore, $righe_integer);
    $wb_cr->write_string( 8, 1, 'DC con Differenze', $testo_it);
    $wb_cr->write_number( 8, 2, $$_dc_01_differenze_numero, $righe_integer);
    $wb_cr->write_number( 8, 3, $$_dc_01_differenze_valore, $righe_integer);
    $wb_cr->write_string( 9, 1, 'Totale', $testo_it);
    
    $range=xl_rowcol_to_cell( 7, 2 ).':'.xl_rowcol_to_cell( 8, 2 );
    $wb_cr->write_formula( 9, 2, '=SUM('.$range.')', $righe_integer);
    $range=xl_rowcol_to_cell( 7, 3 ).':'.xl_rowcol_to_cell( 8, 3 );
    $wb_cr->write_formula( 9, 3, '=SUM('.$range.')', $righe_integer);
    
    #brescia store
    my $intestazione_bs = $workbook->add_format(color => 'White', bold => 1, align => 'center', pattern => 1, bg_color => 'brown');
    my $testo_bs = $workbook->add_format(color => 'Black', bold => 1, align => 'left');
    
    my ($_dc_31_mancanti_numero, $_dc_31_mancanti_valore) = $db->dc_mancanti_totale('31');
    my ($_dc_31_differenze_numero, $_dc_31_differenze_valore) = $db->dc_differenze_totale('31');
    
	$wb_cr->write_string( 6, 5, 'Brescia Store', $intestazione_bs);
    $wb_cr->write_string( 6, 6, 'Numero', $intestazione_bs);
    $wb_cr->write_string( 6, 7, 'Valore', $intestazione_bs);
    $wb_cr->write_string( 7, 5, 'DC Mancanti', $testo_bs);
    $wb_cr->write_number( 7, 6, $$_dc_31_mancanti_numero, $righe_integer);
    $wb_cr->write_number( 7, 7, $$_dc_31_mancanti_valore, $righe_integer);
    $wb_cr->write_string( 8, 5, 'DC con Differenze', $testo_bs);
    $wb_cr->write_number( 8, 6, $$_dc_31_differenze_numero, $righe_integer);
    $wb_cr->write_number( 8, 7, $$_dc_31_differenze_valore, $righe_integer);
    $wb_cr->write_string( 9, 5, 'Totale', $testo_bs);
    
    $range=xl_rowcol_to_cell( 7, 6 ).':'.xl_rowcol_to_cell( 8, 6 );
    $wb_cr->write_formula( 9, 6, '=SUM('.$range.')', $righe_integer);
    $range=xl_rowcol_to_cell( 7, 7 ).':'.xl_rowcol_to_cell( 8, 7 );
    $wb_cr->write_formula( 9, 7, '=SUM('.$range.')', $righe_integer);
    
    #family
    my $intestazione_fm = $workbook->add_format(color => 'White', bold => 1, align => 'center', pattern => 1, bg_color => 'purple');
    my $testo_fm = $workbook->add_format(color => 'Black', bold => 1, align => 'left');
    
    my ($_dc_36_mancanti_numero, $_dc_36_mancanti_valore) = $db->dc_mancanti_totale('36');
    my ($_dc_36_differenze_numero, $_dc_36_differenze_valore) = $db->dc_differenze_totale('36');
    
	$wb_cr->write_string( 6, 9, 'Family', $intestazione_fm);
    $wb_cr->write_string( 6, 10, 'Numero', $intestazione_fm);
    $wb_cr->write_string( 6, 11, 'Valore', $intestazione_fm);
    $wb_cr->write_string( 7, 9, 'DC Mancanti', $testo_fm);
    $wb_cr->write_number( 7, 10, $$_dc_36_mancanti_numero, $righe_integer);
    $wb_cr->write_number( 7, 11, $$_dc_36_mancanti_valore, $righe_integer);
    $wb_cr->write_string( 8, 9, 'DC con Differenze', $testo_fm);
    $wb_cr->write_number( 8, 10, $$_dc_36_differenze_numero, $righe_integer);
    $wb_cr->write_number( 8, 11, $$_dc_36_differenze_valore, $righe_integer);
    $wb_cr->write_string( 9, 9, 'Totale', $testo_fm);
    
    $range=xl_rowcol_to_cell( 7, 10 ).':'.xl_rowcol_to_cell( 8, 10 );
    $wb_cr->write_formula( 9, 10, '=SUM('.$range.')', $righe_integer);
    $range=xl_rowcol_to_cell( 7, 11 ).':'.xl_rowcol_to_cell( 8, 11 );
    $wb_cr->write_formula( 9, 11, '=SUM('.$range.')', $righe_integer);
    
	#italmark ic
    my $intestazione_ic = $workbook->add_format(color => 'White', bold => 1, align => 'center', pattern => 1, bg_color => 'yellow');
    my $testo_ic = $workbook->add_format(color => 'Black', bold => 1, align => 'left');
    
    my ($_dc_04_mancanti_numero, $_dc_04_mancanti_valore) = $db->dc_mancanti_totale('04');
    my ($_dc_04_differenze_numero, $_dc_04_differenze_valore) = $db->dc_differenze_totale('04');
    
	$wb_cr->write_string( 6, 13, 'Italmark IC', $intestazione_ic);
    $wb_cr->write_string( 6, 14, 'Numero', $intestazione_ic);
    $wb_cr->write_string( 6, 15, 'Valore', $intestazione_ic);
    $wb_cr->write_string( 7, 13, 'DC Mancanti', $testo_ic);
    $wb_cr->write_number( 7, 14, $$_dc_04_mancanti_numero, $righe_integer);
    $wb_cr->write_number( 7, 15, $$_dc_04_mancanti_valore, $righe_integer);
    $wb_cr->write_string( 8, 13, 'DC con Differenze', $testo_fm);
    $wb_cr->write_number( 8, 14, $$_dc_04_differenze_numero, $righe_integer);
    $wb_cr->write_number( 8, 15, $$_dc_04_differenze_valore, $righe_integer);
    $wb_cr->write_string( 9, 13, 'Totale', $testo_fm);
    
    $range=xl_rowcol_to_cell( 7, 14 ).':'.xl_rowcol_to_cell( 8, 14 );
    $wb_cr->write_formula( 9, 14, '=SUM('.$range.')', $righe_integer);
    $range=xl_rowcol_to_cell( 7, 15 ).':'.xl_rowcol_to_cell( 8, 15 );
    $wb_cr->write_formula( 9, 15, '=SUM('.$range.')', $righe_integer);
    
    #verifica Supermedia
    #--------------------------------------------
    $logger->info("creazione report supermedia (08)");
    my ($_data, $_negozio, $_negozio_descrizione, $_buoni, $_totale, $_delta, $_dc_presente) = $db->esito_caricamento_dettagliato('08');
    
	my $wb_sm = $workbook->add_worksheet('Supermedia');
    
    $wb_sm->set_column( 0, 0, 10);
    $wb_sm->set_column( 1, 1, 20);
    $wb_sm->set_column( 2, 2, 10);
    $wb_sm->set_column( 3, 3, 10);
    $wb_sm->set_column( 4, 4, 10);
    $wb_sm->set_column( 5, 5, 8);

	$wb_sm->write( 0, 0, "Data", $intestazione );
	$wb_sm->write( 0, 1, "Negozio", $intestazione );
	$wb_sm->write( 0, 2, "Buoni", $intestazione );
    $wb_sm->write( 0, 3, "Totale", $intestazione );
    $wb_sm->write( 0, 4, "Delta", $intestazione );
    $wb_sm->write( 0, 5, "DC", $intestazione );
    
    $wb_sm->freeze_panes( 1, 0 );
    
    my $row_counter = 0;
	for (my $i=0;$i<@$_data;$i++) {
		$row_counter++;
        
        $wb_sm->write_date_time( $row_counter, 0, $$_data[$i], $righe_date);
        $wb_sm->write( $row_counter, 1, $$_negozio[$i].' - '.$$_negozio_descrizione[$i], $righe);
        $wb_sm->write_number( $row_counter, 2, $$_buoni[$i], $righe_currency);
        $wb_sm->write_number( $row_counter, 3, $$_totale[$i], $righe_currency);
        $wb_sm->write_number( $row_counter, 4, $$_delta[$i], $righe_currency);
        $wb_sm->write_number( $row_counter, 5, $$_dc_presente[$i], $righe_integer);
    }
    
    $wb_sm->autofilter( 0, 0, $row_counter, 5 );
    
    
    #verifica Sportland
    #--------------------------------------------
    $logger->info("creazione report sportland (07)");
    ($_data, $_negozio, $_negozio_descrizione, $_buoni, $_totale, $_delta, $_dc_presente) = $db->esito_caricamento_dettagliato('07');
    
	my $wb_sp = $workbook->add_worksheet('Sportland');
    
    $wb_sp->set_column( 0, 0, 10);
    $wb_sp->set_column( 1, 1, 20);
    $wb_sp->set_column( 2, 2, 10);
    $wb_sp->set_column( 3, 3, 10);
    $wb_sp->set_column( 4, 4, 10);
    $wb_sp->set_column( 5, 5, 8);

	$wb_sp->write( 0, 0, "Data", $intestazione );
	$wb_sp->write( 0, 1, "Negozio", $intestazione );
	$wb_sp->write( 0, 2, "Buoni", $intestazione );
    $wb_sp->write( 0, 3, "Totale", $intestazione );
    $wb_sp->write( 0, 4, "Delta", $intestazione );
    $wb_sp->write( 0, 5, "DC", $intestazione );
    
    $wb_sp->freeze_panes( 1, 0 );
    
    $row_counter = 0;
	for (my $i=0;$i<@$_data;$i++) {
		$row_counter++;
        
        $wb_sp->write_date_time( $row_counter, 0, $$_data[$i], $righe_date);
        $wb_sp->write( $row_counter, 1, $$_negozio[$i].' - '.$$_negozio_descrizione[$i], $righe);
        $wb_sp->write_number( $row_counter, 2, $$_buoni[$i], $righe_currency);
        $wb_sp->write_number( $row_counter, 3, $$_totale[$i], $righe_currency);
        $wb_sp->write_number( $row_counter, 4, $$_delta[$i], $righe_currency);
        $wb_sp->write_number( $row_counter, 5, $$_dc_presente[$i], $righe_integer);
    }
    
    $wb_sp->autofilter( 0, 0, $row_counter, 5 );
    
     #verifica Ecobrico
    #--------------------------------------------
    $logger->info("creazione report supermedia (10)");
    ($_data, $_negozio, $_negozio_descrizione, $_buoni, $_totale, $_delta, $_dc_presente) = $db->esito_caricamento_dettagliato('10');
    
	my $wb_eb = $workbook->add_worksheet('Ecobrico');
    
    $wb_eb->set_column( 0, 0, 10);
    $wb_eb->set_column( 1, 1, 20);
    $wb_eb->set_column( 2, 2, 10);
    $wb_eb->set_column( 3, 3, 10);
    $wb_eb->set_column( 4, 4, 10);
    $wb_eb->set_column( 5, 5, 8);

	$wb_eb->write( 0, 0, "Data", $intestazione );
	$wb_eb->write( 0, 1, "Negozio", $intestazione );
	$wb_eb->write( 0, 2, "Buoni", $intestazione );
    $wb_eb->write( 0, 3, "Totale", $intestazione );
    $wb_eb->write( 0, 4, "Delta", $intestazione );
    $wb_eb->write( 0, 5, "DC", $intestazione );
    
    $wb_eb->freeze_panes( 1, 0 );
    
    $row_counter = 0;
	for (my $i=0;$i<@$_data;$i++) {
		$row_counter++;
        
        $wb_eb->write_date_time( $row_counter, 0, $$_data[$i], $righe_date);
        $wb_eb->write( $row_counter, 1, $$_negozio[$i].' - '.$$_negozio_descrizione[$i], $righe);
        $wb_eb->write_number( $row_counter, 2, $$_buoni[$i], $righe_currency);
        $wb_eb->write_number( $row_counter, 3, $$_totale[$i], $righe_currency);
        $wb_eb->write_number( $row_counter, 4, $$_delta[$i], $righe_currency);
        $wb_eb->write_number( $row_counter, 5, $$_dc_presente[$i], $righe_integer);
    }
    
    $wb_eb->autofilter( 0, 0, $row_counter, 5 );
    
    #verifica R&S
    #--------------------------------------------
    ($_data, $_negozio, $_negozio_descrizione, $_buoni, $_totale, $_delta, $_dc_presente) = $db->esito_caricamento_dettagliato('53');
    
	my $wb_rs = $workbook->add_worksheet('R&S');
    
    $wb_rs->set_column( 0, 0, 10);
    $wb_rs->set_column( 1, 1, 20);
    $wb_rs->set_column( 2, 2, 10);
    $wb_rs->set_column( 3, 3, 10);
    $wb_rs->set_column( 4, 4, 10);
    $wb_rs->set_column( 5, 5, 8);

	$wb_rs->write( 0, 0, "Data", $intestazione );
	$wb_rs->write( 0, 1, "Negozio", $intestazione );
	$wb_rs->write( 0, 2, "Buoni", $intestazione );
    $wb_rs->write( 0, 3, "Totale", $intestazione );
    $wb_rs->write( 0, 4, "Delta", $intestazione );
    $wb_rs->write( 0, 5, "DC", $intestazione );
    
    $wb_rs->freeze_panes( 1, 0 );
    
    $row_counter = 0;
	for (my $i=0;$i<@$_data;$i++) {
		$row_counter++;
        
        $wb_rs->write_date_time( $row_counter, 0, $$_data[$i], $righe_date);
        $wb_rs->write( $row_counter, 1, $$_negozio[$i].' - '.$$_negozio_descrizione[$i], $righe);
        $wb_rs->write_number( $row_counter, 2, $$_buoni[$i], $righe_currency);
        $wb_rs->write_number( $row_counter, 3, $$_totale[$i], $righe_currency);
        $wb_rs->write_number( $row_counter, 4, $$_delta[$i], $righe_currency);
        $wb_rs->write_number( $row_counter, 5, $$_dc_presente[$i], $righe_integer);
    }
    
    $wb_rs->autofilter( 0, 0, $row_counter, 5 );
    
    #verifica Italmark
    #--------------------------------------------
    ($_data, $_negozio, $_negozio_descrizione, $_buoni, $_totale, $_delta, $_dc_presente) = $db->esito_caricamento_dettagliato('01');
    
	my $wb_it = $workbook->add_worksheet('Italmark');
    
    $wb_it->set_column( 0, 0, 10);
    $wb_it->set_column( 1, 1, 20);
    $wb_it->set_column( 2, 2, 10);
    $wb_it->set_column( 3, 3, 10);
    $wb_it->set_column( 4, 4, 8);

	$wb_it->write( 0, 0, "Data", $intestazione );
	$wb_it->write( 0, 1, "Negozio", $intestazione );
    $wb_it->write( 0, 2, "Totale", $intestazione );
    $wb_it->write( 0, 3, "Delta", $intestazione );
    $wb_it->write( 0, 4, "DC", $intestazione );
    
    $wb_it->freeze_panes( 1, 0 );
    
    $row_counter = 0;
	for (my $i=0;$i<@$_data;$i++) {
		$row_counter++;
        
        $wb_it->write_date_time( $row_counter, 0, $$_data[$i], $righe_date);
        $wb_it->write( $row_counter, 1, $$_negozio[$i].' - '.$$_negozio_descrizione[$i], $righe);
        $wb_it->write_number( $row_counter, 2, $$_totale[$i], $righe_currency);
        $wb_it->write_number( $row_counter, 3, $$_delta[$i], $righe_currency);
        $wb_it->write_number( $row_counter, 4, $$_dc_presente[$i], $righe_integer);
    }
    
    $wb_it->autofilter( 0, 0, $row_counter, 4 );
    
    #verifica BS Store
    #--------------------------------------------
    ($_data, $_negozio, $_negozio_descrizione, $_buoni, $_totale, $_delta, $_dc_presente) = $db->esito_caricamento_dettagliato('31');
    
	my $wb_bs = $workbook->add_worksheet('BS_Store');
    
    $wb_bs->set_column( 0, 0, 10);
    $wb_bs->set_column( 1, 1, 20);
    $wb_bs->set_column( 2, 2, 10);
    $wb_bs->set_column( 3, 3, 10);
    $wb_bs->set_column( 4, 4, 8);

	$wb_bs->write( 0, 0, "Data", $intestazione );
	$wb_bs->write( 0, 1, "Negozio", $intestazione );
    $wb_bs->write( 0, 2, "Totale", $intestazione );
    $wb_bs->write( 0, 3, "Delta", $intestazione );
    $wb_bs->write( 0, 4, "DC", $intestazione );
    
    $wb_bs->freeze_panes( 1, 0 );
    
    $row_counter = 0;
	for (my $i=0;$i<@$_data;$i++) {
		$row_counter++;
        
        $wb_bs->write_date_time( $row_counter, 0, $$_data[$i], $righe_date);
        $wb_bs->write( $row_counter, 1, $$_negozio[$i].' - '.$$_negozio_descrizione[$i], $righe);
        $wb_bs->write_number( $row_counter, 2, $$_totale[$i], $righe_currency);
        $wb_bs->write_number( $row_counter, 3, $$_delta[$i], $righe_currency);
        $wb_bs->write_number( $row_counter, 4, $$_dc_presente[$i], $righe_integer);
    }
    
    $wb_bs->autofilter( 0, 0, $row_counter, 4 );
    
    #verifica Family
    #--------------------------------------------
    ($_data, $_negozio, $_negozio_descrizione, $_buoni, $_totale, $_delta, $_dc_presente) = $db->esito_caricamento_dettagliato('36');
    
	my $wb_fm = $workbook->add_worksheet('Family');
    
    $wb_fm->set_column( 0, 0, 10);
    $wb_fm->set_column( 1, 1, 20);
    $wb_fm->set_column( 2, 2, 10);
    $wb_fm->set_column( 3, 3, 10);
    $wb_fm->set_column( 4, 4, 8);

	$wb_fm->write( 0, 0, "Data", $intestazione );
	$wb_fm->write( 0, 1, "Negozio", $intestazione );
    $wb_fm->write( 0, 2, "Totale", $intestazione );
    $wb_fm->write( 0, 3, "Delta", $intestazione );
    $wb_fm->write( 0, 4, "DC", $intestazione );
    
    $wb_fm->freeze_panes( 1, 0 );
    
    $row_counter = 0;
	for (my $i=0;$i<@$_data;$i++) {
		$row_counter++;
        
        $wb_fm->write_date_time( $row_counter, 0, $$_data[$i], $righe_date);
        $wb_fm->write( $row_counter, 1, $$_negozio[$i].' - '.$$_negozio_descrizione[$i], $righe);
        $wb_fm->write_number( $row_counter, 2, $$_totale[$i], $righe_currency);
        $wb_fm->write_number( $row_counter, 3, $$_delta[$i], $righe_currency);
        $wb_fm->write_number( $row_counter, 4, $$_dc_presente[$i], $righe_integer);
    }
    
    $wb_fm->autofilter( 0, 0, $row_counter, 4 );
    
    #verifica Italmark IC
    #--------------------------------------------
    ($_data, $_negozio, $_negozio_descrizione, $_buoni, $_totale, $_delta, $_dc_presente) = $db->esito_caricamento_dettagliato('04');
    
	my $wb_ic = $workbook->add_worksheet('Italmark_IC');
    
    $wb_ic->set_column( 0, 0, 10);
    $wb_ic->set_column( 1, 1, 20);
    $wb_ic->set_column( 2, 2, 10);
    $wb_ic->set_column( 3, 3, 10);
    $wb_ic->set_column( 4, 4, 8);

	$wb_ic->write( 0, 0, "Data", $intestazione );
	$wb_ic->write( 0, 1, "Negozio", $intestazione );
    $wb_ic->write( 0, 2, "Totale", $intestazione );
    $wb_ic->write( 0, 3, "Delta", $intestazione );
    $wb_ic->write( 0, 4, "DC", $intestazione );
    
    $wb_ic->freeze_panes( 1, 0 );
    
    $row_counter = 0;
	for (my $i=0;$i<@$_data;$i++) {
		$row_counter++;
        
        $wb_ic->write_date_time( $row_counter, 0, $$_data[$i], $righe_date);
        $wb_ic->write( $row_counter, 1, $$_negozio[$i].' - '.$$_negozio_descrizione[$i], $righe);
        $wb_ic->write_number( $row_counter, 2, $$_totale[$i], $righe_currency);
        $wb_ic->write_number( $row_counter, 3, $$_delta[$i], $righe_currency);
        $wb_ic->write_number( $row_counter, 4, $$_dc_presente[$i], $righe_integer);
    }
    
    $wb_ic->autofilter( 0, 0, $row_counter, 4 );

};

sub log_file_name{
    return  "/cruscotto.log";
}
