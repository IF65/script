#!/usr/bin/perl -w
use strict;
use warnings;

use DBI;
use DateTime;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
use List::MoreUtils qw(firstidx);

# date
#------------------------------------------------------------------------------------------------------------
my $data_corrente = DateTime->today(time_zone=>'local');
my $anno = $data_corrente->year();

my $data_partenza	= DateTime->new(year=>$anno, month=>1,day=> 1);

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "10.11.14.78";
my $username = "root";
my $password = "mela";

# parametri del file Excle di output
#------------------------------------------------------------------------------------------------------------
my $excel_file_name = "report_estendo.xlsx";

# parametri di configurazione dei database
#------------------------------------------------------------------------------------------------------------
my $database_archivi = 'archivi';
my $database_report = 'report';
my $table_pago_nimis = 'report_estendo';

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

my @negozio_codice = ();
my @negozio_descrizione = ();

my %aree = ('SM2' => 'AREA 2', 'SM4' => 'AREA 2', 'SM6' => 'AREA 2', 'SM43' => 'AREA 3', 'SM15' => 'AREA 3',
            'SM21' => 'AREA 2', 'SM22' => 'AREA 3', 'SM25' => 'AREA 3', 'SM26' => 'AREA 3', 'SM1' => 'AREA 2',
            'SM3' => 'AREA 1', 'SM5' => 'AREA 1', 'SM7' => 'AREA 1', 'SM10' => 'AREA 1', 'SM9' => 'AREA 1',
            'SM13' => 'AREA 1', 'SM17' => 'AREA 1', 'SM14' => 'AREA 2', 'SM16' => 'AREA 2', 'SM18' => 'AREA 2',
            'SM33' => 'AREA 2', 'SM34' => 'AREA 2', 'SM36' => 'AREA 2', 'SM38' => 'AREA 2', 'SM27' => 'AREA 3',
            'SM19' => 'AREA 1', 'SM32' => 'AREA 1', 'SM37' => 'AREA 1', 'SM39' => 'AREA 1', 'SM41' => 'AREA 1',
            'SM28' => 'AREA 3', 'SM35' => 'AREA 3', 'SM42' => 'AREA 2', 'SM44' => 'AREA 3', 'SM45' => 'AREA 2',
            'SM99' => 'AREA 1', 'SM46' => 'AREA 3');

my %giorni = (1 => 'LUNEDI', 2 => 'MARTEDI', 3 => 'MERCOLEDI', 4 => 'GIOVEDI', 5 => 'VENERDI', 6 => 'SABATO',
              7 => 'DOMENICA');

my %mesi = (1 => 'GENNAIO', 2 => 'FEBBRAIO', 3 => 'MARZO', 4 => 'APRILE', 5 => 'MAGGIO', 6 => 'GIUGNO',
            7 => 'LUGLIO', 8 => 'AGOSTO', 9 => 'SETTEMBRE', 10 => 'OTTOBRE', 11 => 'NOVEMBRE', 12 => 'DICEMBRE');

if (&ConnessioneDB) {
    
    #creo il workbook
    my $workbook = Excel::Writer::XLSX->new("/$excel_file_name");
    
    #formati
    #-------------------------------------------------------------------------------------------------
    my $format = $workbook->add_format();
    $format->set_bold();
    my $date_format = $workbook->add_format();
    $date_format->set_num_format('dd/mm/yy');
    my $format_titoli_riga_1 = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        color => 'Blue',
        size => 14
    );
    my $format_titoli_riga_2 = $workbook->add_format(
        valign => 'vcenter',
        align  => 'center',
        bold => 1,
        color => 'Black',
        size => 12
    );
    my $format_negozi = $workbook->add_format(
        valign => 'vcenter',
        align  => 'left',
        bold => 1,
        color => 'Black',
        size => 12
    );
    my $format_dati_currency = $workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 0,
        color => 'Black',
        size => 12,
        num_format => 40
    );
    my $format_dati_percentual = $workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 0,
        color => 'Black',
        size => 12,
        num_format => 10
    );
    my $format_totali_currency = $workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 1,
        color => 'Black',
        size => 12,
        num_format => 40
    );
    my $format_totali_percentual = $workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 1,
        color => 'Black',
        size => 12,
        num_format => 10
    );
    my $format_dati_percentual_red = $workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 0,
        color => 'Black',
        bg_color => 'Red',
        size => 12,
        num_format => 10
    );
    my $format_dati_percentual_green = $workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 0,
        color => 'Black',
        bg_color => '#32ED32',
        size => 12,
        num_format => 10
    );
    my $format_dati_percentual_yellow = $workbook->add_format(
        valign => 'vcenter',
        align  => 'right',
        bold => 0,
        color => 'Black',
        bg_color => 'Yellow',
        size => 12,
        num_format => 10
    );
    
    my $totali = $workbook->add_worksheet( 'TOTALI' );
    
    for (my $mese=1;$mese<=12;$mese++) {
        my $primo_giorno_del_mese = DateTime->new(year=>$anno, month=>$mese,day=>1);
        my $ultimo_giorno_del_mese = DateTime->last_day_of_month(year=>$anno, month=>$mese);
        
        #creo il worksheet
        my $report = $workbook->add_worksheet( substr($mesi{$mese},0,3) );
        
        #larghezza predefinita colonne fisse (le prime 5)
        $report->set_column( 0, 0, $larghezza_colonna_area );
        $report->set_column( 1, 1, $larghezza_colonna_negozio );
        $report->set_column( 2, 2, $larghezza_colonna_importo );
        $report->set_column( 3, 3, $larghezza_colonna_estendo );
        $report->set_column( 4, 4, $larghezza_colonna_peso );
        
        #titoli riga 1
        $report->merge_range( 0, 0, 0, 1, 'NEGOZIO', $format_titoli_riga_1 );
        $report->merge_range( 0, 2, 0, 4, 'PROGRESS '.$mesi{$mese}, $format_titoli_riga_1 );
        
        #titoli riga 2
        $report->write_string( 1, 0, 'AREA' , $format_titoli_riga_2);
        $report->write_string( 1, 1, 'FILIALE' , $format_titoli_riga_2);
        $report->write_string( 1, 2, 'INCASSO' , $format_titoli_riga_2);
        $report->write_string( 1, 3, 'ESTENDO' , $format_titoli_riga_2);
        $report->write_string( 1, 4, 'PESO' , $format_titoli_riga_2);
        
        my $data_selezionata = $primo_giorno_del_mese->clone();
        while( DateTime->compare( $data_selezionata, $ultimo_giorno_del_mese ) != 1) {
            my $day_number = $data_selezionata->day();
            
            #riga titoli 1
            $report->merge_range( 0, 2+($day_number*3), 0, 4+($day_number*3),
                                 "$day_number".' - '.$giorni{$data_selezionata->day_of_week()},
                                 $format_titoli_riga_1 );
            
            #riga titoli 2
            $report->write_string( 1, 2+($day_number*3), 'INCASSO' , $format_titoli_riga_2);
            $report->write_string( 1, 3+($day_number*3), 'ESTENDO' , $format_titoli_riga_2);
            $report->write_string( 1, 4+($day_number*3), 'PESO' , $format_titoli_riga_2);
            
            #larghezza colonne
            $report->set_column( 2+($day_number*3), 2+($day_number*3), $larghezza_colonna_importo );
            $report->set_column( 3+($day_number*3), 3+($day_number*3), $larghezza_colonna_estendo );
            $report->set_column( 4+($day_number*3), 4+($day_number*3), $larghezza_colonna_peso );
        
            $data_selezionata->add(days => 1);
        } 
        
        #righe dati        
        my $riga = 0;
        for(my $i=0;$i<@negozio_codice;$i++) {
            $riga = 2 + $i;
            
            my $formula_totale_incasso_orizzontale = '=';
            my $formula_totale_estendo_orizzontale = '=';
            
            $report->write_string( $riga, 0, $aree{$negozio_codice[$i]}, $format_negozi );
            $report->write_string( $riga, 1, $negozio_codice[$i].' - '.$negozio_descrizione[$i], $format_negozi );
            
            my $data_selezionata = $primo_giorno_del_mese->clone();
            while( DateTime->compare( $data_selezionata, $ultimo_giorno_del_mese ) != 1) {
                my $day_number = $data_selezionata->day();
                
                my $incasso = 0;
                my $estendo = 0;
                my $peso = 0;
                if ($sth->execute($data_selezionata->ymd('-'), $negozio_codice[$i])) {
                    while (my @field = $sth->fetchrow_array()) {
                        $incasso = $field[0];
                        $estendo = $field[1];
                        $peso = $field[2];
                    }
                }
                $report->write( $riga, 2+($day_number*3), $incasso, $format_dati_currency);
                $report->write( $riga, 3+($day_number*3), $estendo, $format_dati_currency);
                
                my $c_incasso = xl_rowcol_to_cell( $riga, 4+($day_number*3)-2 );
                my $c_estendo = xl_rowcol_to_cell( $riga, 4+($day_number*3)-1 );
                my $formula = "=IF($c_incasso<>0,$c_estendo/$c_incasso,0)";
                $report->write_formula( $riga, 4+($day_number*3), $formula, $format_dati_percentual);
                
                #costruzione totale orizzontale
                $formula_totale_incasso_orizzontale .= '+'.$c_incasso;
                $formula_totale_estendo_orizzontale .= '+'.$c_estendo;
                
                $data_selezionata->add(days => 1);
            }
            
            #impostazioni worksheet
            #$report->hide_zero();
            $report->autofilter('A2:A'.$riga);
            $report->freeze_panes( $righe_bloccate,$colonne_bloccate);
        
            #totali orizzontali
            $report->write_formula( $riga, 2, substr($formula_totale_incasso_orizzontale,1), $format_dati_currency);
            $report->write_formula( $riga, 3, substr($formula_totale_estendo_orizzontale,1), $format_dati_currency);
            my $c_incasso = xl_rowcol_to_cell( $riga, 2);
            my $c_estendo = xl_rowcol_to_cell( $riga, 3);
            my $formula = "=IF($c_incasso<>0,$c_estendo/$c_incasso,0)";
            $report->write_formula( $riga, 4, $formula, $format_dati_percentual);
        }
        
        #formattazione condizionale
        my $c_first_cell = xl_rowcol_to_cell( 2, 4);
        my $c_last_cell = xl_rowcol_to_cell( $riga, 4);
        $report->conditional_formatting("$c_first_cell:$c_last_cell",
                                        {
                                            type => 'cell',
                                            criteria => '>',
                                            value => 0.04,
                                            format => $format_dati_percentual_green
                                        }
        );
        $report->conditional_formatting("$c_first_cell:$c_last_cell",
                                        {
                                            type => 'cell',
                                            criteria => 'between',
                                            minimum => 0.03,
                                            maximum => 0.04,
                                            format => $format_dati_percentual_yellow
                                        }
        );
        $report->conditional_formatting("$c_first_cell:$c_last_cell",
                                        {
                                            type => 'cell',
                                            criteria => '<',
                                            value => 0.03,
                                            format => $format_dati_percentual_red
                                        }
        );
        
        #totali verticali
        for (my $i = 0; $i <= $ultimo_giorno_del_mese->day(); $i++) {
            $c_first_cell = xl_rowcol_to_cell( 2, 2+($i*3));
            $c_last_cell = xl_rowcol_to_cell( $riga, 2+($i*3));
            my $formula = "=SUBTOTAL(9, $c_first_cell:$c_last_cell)";
            $report->write_formula( $riga+1, 2+($i*3), $formula, $format_totali_currency);
            $c_first_cell = xl_rowcol_to_cell( 2, 3+($i*3));
            $c_last_cell = xl_rowcol_to_cell( $riga, 3+($i*3));
            $formula = "=SUBTOTAL(9, $c_first_cell:$c_last_cell)";
            $report->write_formula( $riga+1, 3+($i*3), $formula, $format_totali_currency);
            my $c_incasso = xl_rowcol_to_cell( $riga+1, 2+($i*3));
            my $c_estendo = xl_rowcol_to_cell( $riga+1, 3+($i*3));
            $formula = "=IF($c_incasso<>0,$c_estendo/$c_incasso,0)";
            $report->write_formula( $riga+1, 4+($i*3), $formula, $format_totali_percentual);
        }
    }
        
    #larghezza predefinita colonne fisse (le prime 4)
    $totali->set_column( 0, 0, $larghezza_colonna_area );
    $totali->set_column( 1, 1, $larghezza_colonna_negozio );
    $totali->set_column( 2, 2, $larghezza_colonna_importo+2 );
    $totali->set_column( 3, 3, $larghezza_colonna_estendo );
    $totali->set_column( 4, 4, $larghezza_colonna_peso );
    
    #titoli riga 1
    $totali->merge_range( 0, 0, 0, 1, 'NEGOZIO', $format_titoli_riga_1 );
    $totali->merge_range( 0, 2, 0, 4, 'PROGRESS ANNO', $format_titoli_riga_1 );
    
    #titoli riga 2
    $totali->write_string( 1, 0, 'AREA' , $format_titoli_riga_2);
    $totali->write_string( 1, 1, 'FILIALE' , $format_titoli_riga_2);
    $totali->write_string( 1, 2, 'INCASSO' , $format_titoli_riga_2);
    $totali->write_string( 1, 3, 'ESTENDO' , $format_titoli_riga_2);
    $totali->write_string( 1, 4, 'PESO' , $format_titoli_riga_2);
    
    for (my $i=0;$i<=3;$i++) {
        #larghezza predefinita colonne
        $totali->set_column( 5+(3*$i), 5+(3*$i), $larghezza_colonna_importo+2 );
        $totali->set_column( 6+(3*$i), 6+(3*$i), $larghezza_colonna_estendo+2 );
        $totali->set_column( 7+(3*$i), 7+(3*$i), $larghezza_colonna_peso );
        
        #titoli riga 1
        $totali->merge_range( 0, 5+(3*$i), 0, 7+(3*$i), 'TRIMESTRE '.sprintf('%s',$i+1), $format_titoli_riga_1 );
        
        #titoli riga 2
        $totali->write_string( 1, 5+(3*$i), 'INCASSO' , $format_titoli_riga_2);
        $totali->write_string( 1, 6+(3*$i), 'ESTENDO' , $format_titoli_riga_2);
        $totali->write_string( 1, 7+(3*$i), 'PESO' , $format_titoli_riga_2);
    }
    
    my $formula;
    my $riga = 0;
    for(my $i=0;$i<@negozio_codice;$i++) {
        $riga = 2 + $i;
        
        #colonna negozi
        $totali->write_string( $riga, 0, $aree{$negozio_codice[$i]}, $format_negozi );
        $totali->write_string( $riga, 1, $negozio_codice[$i].' - '.$negozio_descrizione[$i], $format_negozi );
        
        #ANNO
        $formula = "=F".sprintf('%s',$riga+1).'+'."I".sprintf('%s',$riga+1).'+'."L".sprintf('%s',$riga+1).'+'."O".sprintf('%s',$riga+1);
        $totali->write_formula( $riga, 2, $formula, $format_dati_currency);
        $formula = "=G".sprintf('%s',$riga+1).'+'."J".sprintf('%s',$riga+1).'+'."M".sprintf('%s',$riga+1).'+'."P".sprintf('%s',$riga+1);
        $totali->write_formula( $riga, 3, $formula, $format_dati_currency);
        $formula = "=IF(C".sprintf('%s',$riga+1)."<>0,D".sprintf('%s',$riga+1)."/C".sprintf('%s',$riga+1).",0)";
        $totali->write_formula( $riga, 4, $formula, $format_totali_percentual);
        
        #T1
        $formula = "=GEN!C".sprintf('%s',$riga+1).'+'."FEB!C".sprintf('%s',$riga+1).'+'."MAR!C".sprintf('%s',$riga+1);
        $totali->write_formula( $riga, 5, $formula, $format_dati_currency);
        $formula = "=GEN!D".sprintf('%s',$riga+1).'+'."FEB!D".sprintf('%s',$riga+1).'+'."MAR!D".sprintf('%s',$riga+1);
        $totali->write_formula( $riga, 6, $formula, $format_dati_currency);
        $formula = "=IF(F".sprintf('%s',$riga+1)."<>0,G".sprintf('%s',$riga+1)."/F".sprintf('%s',$riga+1).",0)";
        $totali->write_formula( $riga, 7, $formula, $format_totali_percentual);
        
        #T2
        $formula = "=APR!C".sprintf('%s',$riga+1).'+'."MAG!C".sprintf('%s',$riga+1).'+'."GIU!C".sprintf('%s',$riga+1);
        $totali->write_formula( $riga, 8, $formula, $format_dati_currency);
        $formula = "=APR!D".sprintf('%s',$riga+1).'+'."MAG!D".sprintf('%s',$riga+1).'+'."GIU!D".sprintf('%s',$riga+1);
        $totali->write_formula( $riga, 9, $formula, $format_dati_currency);
        $formula = "=IF(I".sprintf('%s',$riga+1)."<>0,J".sprintf('%s',$riga+1)."/I".sprintf('%s',$riga+1).",0)";
        $totali->write_formula( $riga, 10, $formula, $format_totali_percentual);
        
        #T3
        $formula = "=LUG!C".sprintf('%s',$riga+1).'+'."AGO!C".sprintf('%s',$riga+1).'+'."SET!C".sprintf('%s',$riga+1);
        $totali->write_formula( $riga, 11, $formula, $format_dati_currency);
        $formula = "=LUG!D".sprintf('%s',$riga+1).'+'."AGO!D".sprintf('%s',$riga+1).'+'."SET!D".sprintf('%s',$riga+1);
        $totali->write_formula( $riga, 12, $formula, $format_dati_currency);
        $formula = "=IF(L".sprintf('%s',$riga+1)."<>0,M".sprintf('%s',$riga+1)."/L".sprintf('%s',$riga+1).",0)";
        $totali->write_formula( $riga, 13, $formula, $format_totali_percentual);
        
        #T4
        $formula = "=OTT!C".sprintf('%s',$riga+1).'+'."NOV!C".sprintf('%s',$riga+1).'+'."DIC!C".sprintf('%s',$riga+1);
        $totali->write_formula( $riga, 14, $formula, $format_dati_currency);
        $formula = "=OTT!D".sprintf('%s',$riga+1).'+'."NOV!D".sprintf('%s',$riga+1).'+'."DIC!D".sprintf('%s',$riga+1);
        $totali->write_formula( $riga, 15, $formula, $format_dati_currency);
        $formula = "=IF(O".sprintf('%s',$riga+1)."<>0,P".sprintf('%s',$riga+1)."/O".sprintf('%s',$riga+1).",0)";
        $totali->write_formula( $riga, 16, $formula, $format_totali_percentual);
    }
    
    #impostazioni worksheet
    #$totali->hide_zero();
    $totali->autofilter('A2:A'.$riga);
    $totali->freeze_panes( $righe_bloccate, $colonne_bloccate);
    
    #ANNO
    $formula = "=SUBTOTAL(9,C3:C".sprintf('%s',$riga+1).")";
    $totali->write_formula( $riga+1, 2, $formula, $format_totali_currency);
    $formula = "=SUBTOTAL(9,D3:D".sprintf('%s',$riga+1).")";
    $totali->write_formula( $riga+1, 3, $formula, $format_totali_currency);
    $formula = "=IF(C".sprintf('%s',$riga+2)."<>0,D".sprintf('%s',$riga+2)."/C".sprintf('%s',$riga+2).",0)";
    $totali->write_formula( $riga+1, 4, $formula, $format_totali_percentual);

    #T1
    $formula = "=SUBTOTAL(9,F3:F".sprintf('%s',$riga+1).")";
    $totali->write_formula( $riga+1, 5, $formula, $format_totali_currency);
    $formula = "=SUBTOTAL(9,G3:G".sprintf('%s',$riga+1).")";
    $totali->write_formula( $riga+1, 6, $formula, $format_totali_currency);
    $formula = "=IF(F".sprintf('%s',$riga+2)."<>0,G".sprintf('%s',$riga+2)."/F".sprintf('%s',$riga+2).",0)";
    $totali->write_formula( $riga+1, 7, $formula, $format_totali_percentual);
    
    #T2
    $formula = "=SUBTOTAL(9,I3:I".sprintf('%s',$riga+1).")";
    $totali->write_formula( $riga+1, 8, $formula, $format_totali_currency);
    $formula = "=SUBTOTAL(9,J3:J".sprintf('%s',$riga+1).")";
    $totali->write_formula( $riga+1, 9, $formula, $format_totali_currency);
    $formula = "=IF(I".sprintf('%s',$riga+2)."<>0,J".sprintf('%s',$riga+2)."/I".sprintf('%s',$riga+2).",0)";
    $totali->write_formula( $riga+1, 10, $formula, $format_totali_percentual);
    
    #T3
    $formula = "=SUBTOTAL(9,L3:L".sprintf('%s',$riga+1).")";
    $totali->write_formula( $riga+1, 11, $formula, $format_totali_currency);
    $formula = "=SUBTOTAL(9,M3:M".sprintf('%s',$riga+1).")";
    $totali->write_formula( $riga+1, 12, $formula, $format_totali_currency);
    $formula = "=IF(L".sprintf('%s',$riga+2)."<>0,M".sprintf('%s',$riga+2)."/L".sprintf('%s',$riga+2).",0)";
    $totali->write_formula( $riga+1, 13, $formula, $format_totali_percentual);
    
     #T4
    $formula = "=SUBTOTAL(9,O3:O".sprintf('%s',$riga+1).")";
    $totali->write_formula( $riga+1, 14, $formula, $format_totali_currency);
    $formula = "=SUBTOTAL(9,P3:P".sprintf('%s',$riga+1).")";
    $totali->write_formula( $riga+1, 15, $formula, $format_totali_currency);
    $formula = "=IF(O".sprintf('%s',$riga+2)."<>0,P".sprintf('%s',$riga+2)."/O".sprintf('%s',$riga+2).",0)";
    $totali->write_formula( $riga+1, 16, $formula, $format_totali_percentual);
    
    #formattazione condizionale
    my $range = "E3:E".sprintf('%s',$riga+1).",H3:H".sprintf('%s',$riga+1).",K3:K".sprintf('%s',$riga+1).",N3:N".sprintf('%s',$riga+1).",Q3:Q".sprintf('%s',$riga+1);
    $totali->conditional_formatting($range,
                                    {
                                        type => 'cell',
                                        criteria => '>',
                                        value => 0.04,
                                        format => $format_dati_percentual_green
                                    }
    );
    $totali->conditional_formatting($range,
                                    {
                                        type => 'cell',
                                        criteria => 'between',
                                        minimum => 0.03,
                                        maximum => 0.04,
                                        format => $format_dati_percentual_yellow
                                    }
    );
    $totali->conditional_formatting($range,
                                    {
                                        type => 'cell',
                                        criteria => '<',
                                        value => 0.03,
                                        format => $format_dati_percentual_red
                                    }
    );
    
    $totali->activate();
    $totali->set_selection( 0, 0 ); 
}

sub ConnessioneDB {
	# connessione al database negozi
	$dbh = DBI->connect("DBI:mysql:$database_archivi:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database `$database_report`!\n";
		return 0;
	}

	$sth = $dbh->prepare(qq{select n.`codice_interno`, n.`negozio_descrizione` from `archivi`.`negozi` as n
                            where n.`societa` = '08' and (n.`data_fine` is null or n.`data_fine`>'2017-01-01')
                            and n.`tipo`=3 order by lpad(substr(n.`codice_interno`,3),3,'0')}
                        );
    
    if (!$sth->execute()) {
        print "Errore durante l'esecuzione di una query su db! " .$dbh->errstr."\n";
        return 0;
    }
    
    while (my @record = $sth->fetchrow_array()) {
        push(@negozio_codice, $record[0]);
        push(@negozio_descrizione, $record[1]);
    }
	
    
	$sth->finish();
    
    $sth = $dbh->prepare(qq{select r.`incasso`, r.`estendo`,
                         case when r.`incasso` <> 0 then round(r.`estendo`/r.`incasso`*100,2) else 0 end `peso`
                         from `report`.`report_estendo` as r
                         where r.`data` = ? and r.`negozio` = ?}
                        );
    
    return 1;
}
