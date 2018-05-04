#!/usr/bin/perl -w
use strict;
use File::HomeDir;
use Getopt::Long;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
use DBI;
use DateTime;

# parametri di collegamento al database ITM
#------------------------------------------------------------------------------------------------------------
my $hostname			= "10.11.14.78";
my $username			= "root";
my $password			= "mela";

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $desktop = '/'; #File::HomeDir->my_desktop;
my %negozi;
my $data_corrente;
	
# definizione dei parametri sulla linea di comando
#------------------------------------------------------------------------------------------------------------
my @ar_data = ();

GetOptions(
	'd=s{0,1}'		=> \@ar_data,
) or die "Uso errato dei parametri!\n";

for (my $i=0;$i<@ar_data;$i++) {
	$ar_data[$i] =~ s/[^\d\-]/\-/ig;
	if ($ar_data[$i] =~ /^(\d{4})(\d{2})(\d{2})$/) {
		$ar_data[$i] = $1.'-'.$2.'-'.$3;
	} elsif ($ar_data[$i] =~ /^(\d+)\-(\d+)\-(\d+)$/) {
		$ar_data[$i] = sprintf('%04d-%02d-%02d',$1,$2,$3);
	} else {die "Formato data errato: $ar_data[$i]\n"};
	
	$ar_data[$i] =~ s/\-//ig;
}
if (@ar_data > 0) {
	if ($ar_data[0] =~ /^(20\d{2})(\d{2})(\d{2})/) {
		$data_corrente = string2date($1.'-'.$2.'-'.$3); 
	}
} else {
	$data_corrente = DateTime->today(time_zone=>'local');
}

my $data_fine = $data_corrente->clone->truncate(to=>'week')->subtract(days => 1);
my $data_inizio = $data_fine->clone->truncate(to=>'week');

# connessione al database
$dbh = DBI->connect("DBI:mysql:db_sm:$hostname", $username, $password);
if (! $dbh) {
	print "Errore durante la connessione al database di default!\n";
	return 0;
}

$sth = $dbh->prepare(qq{select n.`codice_interno`,n.`codice_mt`,n.`negozio_descrizione` from archivi.negozi as n where n.`societa`='08' and n.`codice_mt`<>''});
if ($sth->execute()) {
	while(my @row = $sth->fetchrow_array()) {
		$negozi{$row[0]} = {'codice_mt' => $row[1], 'descrizione' => $row[2]};
	}
}
$sth->finish;

$sth = $dbh->prepare(qq{	select rv.data, rv.negozio, rv.codice, m.descrizione, (select e.ean from ean as e where e.codice = rv.`codice` limit 1), sum(rv.quantita)
							from db_sm.righe_vendita as rv join magazzino as m on rv.codice = m.codice
							where rv.data >= ? and rv.data <= ? and
							rv.codice in	(
												select distinct r.codice_articolo
												from db_sm.arrivi as a join db_sm.righe_arrivi as r on a.id=r.id_arrivi
												where a.codice_fornitore='FMT'
											)
							group by 1,2,3
							order by 3,1,2
						}
					);

if ($sth->execute($data_inizio->ymd('-'),$data_fine->ymd('-'))) {
	my $output_file_name = 'report_vendite_mt.xlsx';
	my $workbook = Excel::Writer::XLSX->new("$desktop/$output_file_name");
	
	#creo il foglio di lavoro x l'anno
	my $rv_settimana = $workbook->add_worksheet( 'Foglio1' );
	
	#aggiungo un formato
	my $format = $workbook->add_format();
	$format->set_bold();
	$format->set_color('Black');
	
	my $date_format = $workbook->add_format( num_format => 'dd/mm/yyyy' );
	
	#titoli colonne
	$rv_settimana->write_string( 0, 0, "CodicePuntoVendita", $format );
	$rv_settimana->write_string( 0, 1, "NomePuntoVendita", $format );
	$rv_settimana->write_string( 0, 2, "EAN", $format );
	$rv_settimana->write_string( 0, 3, "DescrizioneArticolo", $format );
	$rv_settimana->write_string( 0, 4, "Qta", $format );
	$rv_settimana->write_string( 0, 5, "Data", $format );
		
	my $row_counter = 0;
	while(my @row = $sth->fetchrow_array()) {
		if ($row[5] != 0) {
			$row_counter++;
		
			$rv_settimana->write_number( $row_counter, 0, $negozi{$row[1]}{'codice_mt'});
			$rv_settimana->write_string( $row_counter, 1, $negozi{$row[1]}{'descrizione'});
			$rv_settimana->write_string( $row_counter, 2, $row[4]);
			$rv_settimana->write_string( $row_counter, 3, $row[3]);
			$rv_settimana->write_number( $row_counter, 4, $row[5]);
			$rv_settimana->write_date_time( $row_counter, 5, string2date($row[0])->iso8601(), $date_format);
		}
	}
		
	#attivo il foglio di lavoro
	$rv_settimana->activate();
	
	$sth->finish();
}


$sth = $dbh->prepare(qq{	select current_date(), g.negozio, g.codice, m.descrizione, (select e.ean from ean as e where e.codice = g.`codice` limit 1), g.giacenza
							from db_sm.giacenze_correnti as g join magazzino as m on g.codice = m.codice
							where g.codice in	(
													select distinct r.codice_articolo
													from db_sm.arrivi as a join db_sm.righe_arrivi as r on a.id=r.id_arrivi
													where a.codice_fornitore='FMT'
												) and
									g.negozio in (select codice_interno from archivi.negozi where `societa`='08' and `codice_mt`<>'')
							order by 3,1,2
						}
					);

if ($sth->execute()) {
	my $output_file_name = 'report_giacenze_mt.xlsx';
	my $workbook = Excel::Writer::XLSX->new("$desktop/$output_file_name");
	
	#creo il foglio di lavoro x l'anno
	my $rv_settimana = $workbook->add_worksheet( 'Foglio1' );
	
	#aggiungo un formato
	my $format = $workbook->add_format();
	$format->set_bold();
	$format->set_color('Black');
	
	my $date_format = $workbook->add_format( num_format => 'dd/mm/yyyy' );
	
	#titoli colonne
	$rv_settimana->write_string( 0, 0, "CodicePuntoVendita", $format );
	$rv_settimana->write_string( 0, 1, "NomePuntoVendita", $format );
	$rv_settimana->write_string( 0, 2, "EAN", $format );
	$rv_settimana->write_string( 0, 3, "DescrizioneArticolo", $format );
	$rv_settimana->write_string( 0, 4, "Qta", $format );
	$rv_settimana->write_string( 0, 5, "Data", $format );
		
	my $row_counter = 0;
	while(my @row = $sth->fetchrow_array()) {
		if ($row[5] != 0) {
			$row_counter++;
		
			$rv_settimana->write_number( $row_counter, 0, $negozi{$row[1]}{'codice_mt'});
			$rv_settimana->write_string( $row_counter, 1, $negozi{$row[1]}{'descrizione'});
			$rv_settimana->write_string( $row_counter, 2, $row[4]);
			$rv_settimana->write_string( $row_counter, 3, $row[3]);
			$rv_settimana->write_number( $row_counter, 4, $row[5]);
			$rv_settimana->write_date_time( $row_counter, 5, string2date($row[0])->iso8601(), $date_format);
		}
	}
		
	#attivo il foglio di lavoro
	$rv_settimana->activate();
	
	$sth->finish();
}


$dbh->disconnect();


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
