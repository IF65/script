#!/usr/bin/perl -w
use strict;
use File::HomeDir;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
use DBI;
use DateTime;

# parametri di collegamento al database ITM
#------------------------------------------------------------------------------------------------------------
my $hostname			= "10.11.14.78";
my $username			= "root";
my $password			= "mela";
my $database			= "db_sm";

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sth_riga;


my $desktop = '/';File::HomeDir->my_desktop;
my $output_file_handler;
my $output_file_name = 'report_vendite_vodafone_maggio_2016';

# connessione al database di default
$dbh = DBI->connect("DBI:mysql:mysql:$hostname", $username, $password);
if (! $dbh) {
	print "Errore durante la connessione al database di default!\n";
	return 0;
}

$sth = $dbh->prepare(qq{select rv.`data`, concat(rv.`negozio`, ' - ',n.`negozio_descrizione`), rv.`codice`, rv.`descrizione`, rv.`codice_venditore`,ifnull(concat(ve.`cognome`, ', ',ve.`nome`),''), sum(rv.`quantita`)
                        from db_sm.righe_vendita as rv left join db_sm.venditori as ve on rv.`codice_venditore`=ve.`codice` join archivi.negozi as n on n.`codice_interno` = rv.`negozio`
                        where rv.`data`>='2016-05-01' and rv.`data`<='2016-05-31' and rv.`codice` in ('0402219','0318622','0318953')
                        group by rv.`data`, rv.`negozio`, rv.`codice`,rv.`codice_venditore`
						order by rv.`data`, rv.`negozio`,rv.`codice_venditore`});

if ($sth->execute()) {
	{#formato excel
		$output_file_name .= '.xlsx';
		my $workbook = Excel::Writer::XLSX->new("$desktop/$output_file_name");
		
		#creo il foglio di lavoro x l'anno
		my $rv_vendite = $workbook->add_worksheet( 'Vodafone' );
		
		#aggiungo un formato
    	my $format = $workbook->add_format();
    	$format->set_bold();
        
        $rv_vendite->set_column( 0, 0, 10 );
		$rv_vendite->set_column( 1, 1, 20 );
        $rv_vendite->set_column( 2, 2, 10 );
        $rv_vendite->set_column( 3, 3, 40 );
        $rv_vendite->set_column( 4, 4, 10 );
        $rv_vendite->set_column( 5, 5, 30 );
        $rv_vendite->set_column( 6, 6, 10 );

		#titoli colonne
		$format->set_color( 'blue' );
		$rv_vendite->write( 0, 0, "Data", $format );
		$rv_vendite->write( 0, 1, "Negozio", $format );
		$rv_vendite->write( 0, 2, "Articolo", $format );
		$rv_vendite->write( 0, 3, "Descrizione", $format );
		$rv_vendite->write( 0, 4, "Cod. vend.", $format );
		$rv_vendite->write( 0, 5, "Venditore", $format );
		$rv_vendite->write( 0, 6, "Quantita\'", $format );
		
        my $date_format = $workbook->add_format( num_format => 'dd/mm/yyyy' );
        
		my $row_counter = 0;
		while(my @row = $sth->fetchrow_array()) {
			$row_counter++;
			
            $rv_vendite->write_date_time( $row_counter, 0, string2date($row[0])->iso8601(), $date_format);
			$rv_vendite->write_string( $row_counter, 1, $row[1]);
			$rv_vendite->write_string( $row_counter, 2, $row[2]);
			$rv_vendite->write_string( $row_counter, 3, $row[3]);
			$rv_vendite->write_string( $row_counter, 4, $row[4]);
			$rv_vendite->write_string( $row_counter, 5, $row[5]);
			$rv_vendite->write( $row_counter, 6, "$row[6]");
		}
		
		#attivo il foglio di lavoro
    	$rv_vendite->activate();
	}
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