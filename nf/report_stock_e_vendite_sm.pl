#!/usr/bin/perl -w
use strict;
use File::HomeDir;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
use DBI;
use DateTime;
use Getopt::Long;

# parametri di collegamento al database ITM
#------------------------------------------------------------------------------------------------------------
my $hostname			= "10.11.14.78";
my $username			= "root";
my $password			= "mela";
my $database			= "db_sm";

# date
#------------------------------------------------------------------------------------------------------------
my $current_date 	= DateTime->now(time_zone=>'local');
my $week = $current_date->week_number() - 1;
my $year = $current_date->year();
my $dalla_data = $current_date->clone()->truncate(to => "week")->subtract(weeks => 1)->dmy('-');
my $alla_data = $current_date->clone()->truncate(to => "week")->subtract(days => 1)->dmy('-');

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sth_riga;

# recupero parametri dalla linea di comando
#----------------------------------------------------------------------------------------------------------------------
my $selettore_report;

if (@ARGV == 0) {
    die "Nessun parametro definito!\n";
}

GetOptions(
	's=s{1,1}'	=> \$selettore_report,
) or die "parametri non corretti!\n";

my $desktop = File::HomeDir->my_desktop;
my $output_file_handler;
my $output_file_name = $year."_W".$week."_".$selettore_report;

# connessione al database di default
$dbh = DBI->connect("DBI:mysql:mysql:$hostname", $username, $password);
if (! $dbh) {
	die "Errore durante la connessione al database di default!\n";
}

if ($selettore_report eq 'KASPERSKY') {
	$sth = $dbh->prepare(qq{	select concat(s.`negozio`, ' - ', n.negozio_descrizione), m.`codice`, 
								ifnull((select `ean` from db_sm.ean where `codice`=m.`codice` order by `ean` limit 1),''), 
								m.`descrizione`, m.`modello`, m.`linea`, s.`giacenza`, s.`venduto_7` 
								from db_sm.situazioni as s left join db_sm.magazzino as m on m.`codice`=s.`codice_articolo` 
								join archivi.negozi as n on n.codice_interno = s.`negozio` 
								where m.`linea`='KASPERSKY' and (s.`venduto_7`>0 or s.`giacenza`>0) and (s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD')});
} elsif ($selettore_report eq 'CANON_COMPUTER') {
	$sth = $dbh->prepare(qq{	select concat(s.`negozio`, ' - ', n.negozio_descrizione), m.`codice`, 
								ifnull((select `ean` from db_sm.ean where `codice`=m.`codice` order by `ean` limit 1),''), 
								m.`descrizione`, m.`modello`, m.`linea`, s.`giacenza`, s.`venduto_7` 
								from db_sm.situazioni as s left join db_sm.magazzino as m on m.`codice`=s.`codice_articolo` 
								join archivi.negozi as n on n.codice_interno = s.`negozio` 
								where m.`linea` like 'CANON%' and (m.codice_famiglia='14' or m.codice_famiglia='15') and (s.`venduto_7`>0 or s.`giacenza`>0) 
								and (s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD')});
} elsif ($selettore_report eq 'DATAMATIC') {
	$sth = $dbh->prepare(qq{	select concat(s.`negozio`, ' - ', n.negozio_descrizione), m.`codice`, 
								ifnull((select `ean` from db_sm.ean where `codice`=m.`codice` order by `ean` limit 1),''), 
								m.`descrizione`, m.`modello`, m.`linea`, s.`giacenza`, s.`venduto_7` 
								from db_sm.fornitore_articolo as f join db_sm.situazioni as s on f.`codice_articolo`=s.`codice_articolo` left join db_sm.magazzino as m on m.`codice`=s.`codice_articolo` 
								join archivi.negozi as n on n.codice_interno = s.`negozio` 
								where f.`codice_fornitore`='FDATAMATIC' and ((m.codice_famiglia='14' and m.codice_sottofamiglia='5') or (m.codice_famiglia='14' and m.codice_sottofamiglia='6')) and (s.`venduto_7`>0 or s.`giacenza`>0)
								and (s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD')});
} elsif ($selettore_report eq 'EPSON') {
	$sth = $dbh->prepare(qq{	select concat(s.`negozio`, ' - ', n.negozio_descrizione), m.`codice`, 
								ifnull((select `ean` from db_sm.ean where `codice`=m.`codice` order by `ean` limit 1),''), 
								m.`descrizione`, m.`modello`, m.`linea`, s.`giacenza`, s.`venduto_7` 
								from db_sm.situazioni as s left join db_sm.magazzino as m on m.`codice`=s.`codice_articolo` 
								join archivi.negozi as n on n.codice_interno = s.`negozio` 
								where m.`linea` like 'EPSON%' and (m.codice_famiglia='14' or m.codice_famiglia='15') and (s.`venduto_7`>0 or s.`giacenza`>0) 
								and (s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD')});
} elsif ($selettore_report eq 'CELLY') {
	$sth = $dbh->prepare(qq{	select concat(s.`negozio`, ' - ', n.negozio_descrizione), m.`codice`, 
								ifnull((select `ean` from db_sm.ean where `codice`=m.`codice` order by `ean` limit 1),''), 
								m.`descrizione`, m.`modello`, m.`linea`, s.`giacenza`, s.`venduto_7` 
								from db_sm.situazioni as s left join db_sm.magazzino as m on m.`codice`=s.`codice_articolo` 
								join archivi.negozi as n on n.codice_interno = s.`negozio` 
								where m.`linea`='CELLY TEL ACC' and (s.`venduto_7`>0 or s.`giacenza`>0) and (s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD')});
} elsif ($selettore_report eq 'HUAWEI') {
	$sth = $dbh->prepare(qq{	select concat(s.`negozio`, ' - ', n.negozio_descrizione), m.`codice`, 
								ifnull((select `ean` from db_sm.ean where `codice`=m.`codice` order by `ean` limit 1),''), 
								m.`descrizione`, m.`modello`, m.`linea`, s.`giacenza`, s.`venduto_7` 
								from db_sm.situazioni as s left join db_sm.magazzino as m on m.`codice`=s.`codice_articolo` 
								join archivi.negozi as n on n.codice_interno = s.`negozio` 
								where m.`linea`='HUAWEI TEL' and (s.`venduto_7`>0 or s.`giacenza`>0) and (s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD') and 
								m.`codice` not in ('0501754','0501763','0538797','0538804','0538831','0538840','0546332','0556151','0556160')});
} elsif ($selettore_report eq 'SBS') {
	$sth = $dbh->prepare(qq{	select concat(s.`negozio`, ' - ', n.negozio_descrizione), m.`codice`, 
								ifnull((select `ean` from db_sm.ean where `codice`=m.`codice` order by `ean` limit 1),''), 
								m.`descrizione`, m.`modello`, m.`linea`, s.`giacenza`, s.`venduto_7` 
								from db_sm.situazioni as s left join db_sm.magazzino as m on m.`codice`=s.`codice_articolo` 
								join archivi.negozi as n on n.codice_interno = s.`negozio` 
								where ((m.`linea` like 'EKON%') or (m.`linea` like 'SBS%')) and (substr(m.griglia,1,1) <> 'N') and (s.`venduto_7`>0 or s.`giacenza`>0)
								and (s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD')});
} elsif ($selettore_report eq 'SONY_GAME') {
	$sth = $dbh->prepare(qq{	select concat(s.`negozio`, ' - ', n.negozio_descrizione), m.`codice`, 
								ifnull((select `ean` from db_sm.ean where `codice`=m.`codice` order by `ean` limit 1),''), 
								m.`descrizione`, m.`modello`, m.`linea`, s.`giacenza`, s.`venduto_7` 
								from db_sm.situazioni as s left join db_sm.magazzino as m on m.`codice`=s.`codice_articolo` 
								join archivi.negozi as n on n.codice_interno = s.`negozio` 
								where (m.`linea` = 'SONY CONSOLLE' or m.`linea` = 'SONY GAME' or m.`linea` = 'SONY GAME ACC') and (s.`venduto_7`>0 or s.`giacenza`>0)
								and (s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD')});
} elsif ($selettore_report eq 'WIKO') {
	$sth = $dbh->prepare(qq{	select concat(s.`negozio`, ' - ', n.negozio_descrizione), m.`codice`, 
								ifnull((select `ean` from db_sm.ean where `codice`=m.`codice` order by `ean` limit 1),''), 
								m.`descrizione`, m.`modello`, m.`linea`, s.`giacenza`, s.`venduto_7` 
								from db_sm.situazioni as s left join db_sm.magazzino as m on m.`codice`=s.`codice_articolo` 
								join archivi.negozi as n on n.codice_interno = s.`negozio` 
								where m.`linea` = 'WIKO TEL' and (s.`venduto_7`>0 or s.`giacenza`>0) and (s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD')});
} else {
	die "Report $selettore_report non definito\n";
}

&esecuzione_report_tipo_dettagliato_excel();

$dbh->disconnect();

sub esecuzione_report_tipo_dettagliato_excel {
	if ($sth->execute()) {
        #formato excel
        $output_file_name .= '.xlsx';
        my $workbook = Excel::Writer::XLSX->new("$desktop/$output_file_name");
        
        #creo il foglio di lavoro x l'anno
        my $rv_report = $workbook->add_worksheet( $selettore_report );
        
        #aggiungo un formato
        
        
        $rv_report->set_column( 0, 0, 25 );
        $rv_report->set_column( 1, 1, 10 );
        $rv_report->set_column( 2, 2, 15 );
        $rv_report->set_column( 3, 3, 70 );
        $rv_report->set_column( 4, 4, 25 );
        $rv_report->set_column( 5, 5, 25 );
        $rv_report->set_column( 6, 6, 15 );
        $rv_report->set_column( 7, 7, 15 );

        #indicazione periodo
        my $format_indicazione = $workbook->add_format();
        $format_indicazione->set_bold();
        $format_indicazione->set_color( 'black' );
        $format_indicazione->set_align( 'left' );
        $rv_report->write_string( 0, 0, "Periodo Considerato Dal $dalla_data Al $alla_data", $format_indicazione );
        
        #titoli colonne
        my $format = $workbook->add_format();
        $format->set_bold();
        $format->set_color( 'blue' );
        $format->set_align( 'center' );
        $rv_report->write_string( 1, 0, "Sede", $format );
        $rv_report->write_string( 1, 1, "Codice Art.", $format );
        $rv_report->write_string( 1, 2, "EAN", $format );
        $rv_report->write_string( 1, 3, "Descrizione", $format );
        $rv_report->write_string( 1, 4, "Modello", $format );
        $rv_report->write_string( 1, 5, "Marca", $format );
        $rv_report->write_string( 1, 6, "Giac.Fine Per.", $format );
        $rv_report->write_string( 1, 7, "Venduto Nel Per.", $format );
        
        
        my $date_format = $workbook->add_format( num_format => 'dd/mm/yyyy' );
        my $integer_format = $workbook->add_format( num_format => '#,##0' );
        $integer_format->set_align( 'center' );
        my $currency_format = $workbook->add_format( num_format => '#,##0.00' );
        my $string_left = $workbook->add_format();
        $string_left->set_align( 'left' );
        my $string_centered = $workbook->add_format();
        $string_centered->set_align( 'center' );
        my $row_counter = 1;
        while(my @row = $sth->fetchrow_array()) {
            $row_counter++;
            
            $rv_report->write_string( $row_counter, 0, $row[0], $string_left);
            $rv_report->write_string( $row_counter, 1, $row[1], $string_centered);
            $rv_report->write_string( $row_counter, 2, $row[2], $string_centered);
            $rv_report->write_string( $row_counter, 3, $row[3], $string_left);
            $rv_report->write_string( $row_counter, 4, $row[4], $string_left);
            $rv_report->write_string( $row_counter, 5, $row[5], $string_left);
            $rv_report->write( $row_counter, 6, $row[6], $integer_format);
            $rv_report->write( $row_counter, 7, $row[7], $integer_format);
            
        }
        
        #attivo il foglio di lavoro
        $rv_report->activate();
        
		$sth->finish();
        
        print "$desktop/$output_file_name\n";
	}
}

sub string2date { #trasformo una data un oggetto DateTime
	my ($data) =@_;
	
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
