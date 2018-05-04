#!/usr/bin/perl -w
use strict;
use File::HomeDir;
use Getopt::Long;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
use DBI;
use DateTime;

# date
#------------------------------------------------------------------------------------------------------------
my $current_date 	= DateTime->today(time_zone=>'local');

# parametri di collegamento al database ITM
#------------------------------------------------------------------------------------------------------------
my $hostname			= "10.11.14.78";
my $username			= "root";
my $password			= "mela";
my $database			= "controllo";

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sth_riga;
	
# definizione dei parametri sulla linea di comando
#------------------------------------------------------------------------------------------------------------
my $societa = 'SM';
my $tipo_report = 2; 	#1=libero (obbligatori date inizio e fine), 
						#2=report settimana corrente, 3=report mese corrente, #4=report anno corrente, 
						#5=progress settimana corrente, 6=progress mese corrente, #7=progress anno corrente,
						#8=mese specifico (obbligatori a ed m)
my $data_ac;
my $data_ap;
my $data_inizio_ac;
my $data_fine_ac;
my $data_inizio_ap;
my $data_fine_ap;
my $anno;
my $mese;

my @ar_societa = ();
my @ar_tipo = ();
my @ar_date_ac = ();
my @ar_date_ap = ();
my @ar_data = ();
my @ar_anno = ();
my @ar_mese = ();

my $txt = 0;
GetOptions(
	's=s{1,1}'		=> \@ar_societa,
	't=s{1,1}'		=> \@ar_tipo,
	'dac=s{0,2}'	=> \@ar_date_ac,
	'dap=s{0,2}'	=> \@ar_date_ap,
	'd=s{0,1}'		=> \@ar_data,
	'a=s{0,1}'		=> \@ar_anno,
	'm=s{0,1}'		=> \@ar_mese,
	'txt!'			=> \$txt,
) or die "Uso errato dei parametri!\n";


if (@ar_societa > 0) {
	if ($ar_societa[0] !~ /^(SM|EB|SP|GA|RU)$/) {
		die "Tipo report Errato: $ar_tipo[0]\n";
	}
	$societa = $ar_societa[0];
}

if (@ar_tipo > 0) {
	if ($ar_tipo[0] !~ /^(1|2|3|4|5|6|7|8)$/) {
		die "Tipo report Errato: $ar_tipo[0]\n";
	}
	$tipo_report = $ar_tipo[0];
}

for (my $i=0;$i<@ar_date_ac;$i++) {
	$ar_date_ac[$i] =~ s/[^\d\-]/\-/ig;
	if ($ar_date_ac[$i] =~ /^(\d{4})(\d{2})(\d{2})$/) {
		$ar_date_ac[$i] = $1.'-'.$2.'-'.$3;
	} elsif ($ar_date_ac[$i] =~ /^(\d+)\-(\d+)\-(\d+)$/) {
		$ar_date_ac[$i] = sprintf('%04d-%02d-%02d',$1,$2,$3);
	} else {die "Formato data errato: $ar_date_ac[$i]\n"};
	
	$ar_date_ac[$i] =~ s/\-//ig;
}
if (@ar_date_ac > 0) {
	if ($ar_date_ac[0] =~ /^(20\d{2})(\d{2})(\d{2})/) {
		$data_inizio_ac =$1.'-'.$2.'-'.$3; 
	}
	$data_fine_ac = $data_inizio_ac;
	if (@ar_date_ac > 1) {
		if ($ar_date_ac[1] =~ /^(20\d{2})(\d{2})(\d{2})/) {
			$data_fine_ac =$1.'-'.$2.'-'.$3; 
		}
	}
	if ($data_inizio_ac gt $data_fine_ac) {
		my $temp_var = $data_fine_ac;
		$data_fine_ac = $data_inizio_ac;
		$data_inizio_ac = $temp_var;
	}
}

for (my $i=0;$i<@ar_date_ac;$i++) {
	$ar_date_ap[$i] =~ s/[^\d\-]/\-/ig;
	if ($ar_date_ap[$i] =~ /^(\d{4})(\d{2})(\d{2})$/) {
		$ar_date_ap[$i] = $1.'-'.$2.'-'.$3;
	} elsif ($ar_date_ap[$i] =~ /^(\d+)\-(\d+)\-(\d+)$/) {
		$ar_date_ap[$i] = sprintf('%04d-%02d-%02d',$1,$2,$3);
	} else {die "Formato data errato: $ar_date_ap[$i]\n"};
	
	$ar_date_ap[$i] =~ s/\-//ig;
}
if (@ar_date_ap > 0) {
	if ($ar_date_ap[0] =~ /^(20\d{2})(\d{2})(\d{2})/) {
		$data_inizio_ap = $1.'-'.$2.'-'.$3; 
	}
	$data_fine_ap = $data_inizio_ap;
	if (@ar_date_ap > 1) {
		if ($ar_date_ap[1] =~ /^(20\d{2})(\d{2})(\d{2})/) {
			$data_fine_ap = $1.'-'.$2.'-'.$3; 
		}
	}
	if ($data_inizio_ap gt $data_fine_ap) {
		my $temp_var = $data_fine_ap;
		$data_fine_ap = $data_inizio_ap;
		$data_inizio_ap = $temp_var;
	}
}

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
		$data_ac = $1.'-'.$2.'-'.$3; 
	}
}

if (@ar_anno > 0) {
	$anno = $ar_anno[0];
}

if (@ar_mese > 0) {
	if ($ar_mese[0] !~ /^(1|2|3|4|5|6|7|8|9|10|11|12)$/) {
		die "Mese Errato: $ar_mese[0]\n";
	}
	$mese = $ar_mese[0];
}

my $desktop = '/';#File::HomeDir->my_desktop;
my $output_file_handler;

# connessione al database di default
$dbh = DBI->connect("DBI:mysql:controllo:$hostname", $username, $password);
if (! $dbh) {
	print "Errore durante la connessione al database di default!\n";
	return 0;
}

my $output_file_name = '';

if ($tipo_report >= 2 and $tipo_report <= 7) {
	$dbh->do(qq{call cerca_data_corrispondente($tipo_report,'$data_ac', \@data_ap, \@data_inizio_ac, \@data_fine_ac, \@data_inizio_ap, \@data_fine_ap);} );
	$data_ap = $dbh->selectrow_array("SELECT \@data_ap");
	$data_inizio_ac = $dbh->selectrow_array("SELECT \@data_inizio_ac"); 
	$data_fine_ac = $dbh->selectrow_array("SELECT \@data_fine_ac");
	$data_inizio_ap = $dbh->selectrow_array("SELECT \@data_inizio_ap"); 
	$data_fine_ap = $dbh->selectrow_array("SELECT \@data_fine_ap");

	if ($tipo_report == 2) {
		$output_file_name = 'report_vendite_settimanali';
	} elsif ($tipo_report == 3) {
		$output_file_name = 'report_vendite_mensili';
	} elsif ($tipo_report == 4) {
		$output_file_name = 'report_vendite_annuali';
	} elsif ($tipo_report == 5) {
		$output_file_name = 'progress_vendite_settimanali';
	} elsif ($tipo_report == 6) {
		$output_file_name = 'progress_vendite_mensili';
	} elsif ($tipo_report == 7) {
		$output_file_name = 'progress_vendite_annuali';
	} 
} elsif ($tipo_report == 8) { # mese specifico
	$sth = $dbh->prepare(qq{select min(data_inizio), max(data_fine) from archivi.calendario where anno = $anno and mese = $mese;});
	if ($sth->execute()) {
		my @record = $sth->fetchrow_array();
		$data_inizio_ac		= $record[0];
		$data_fine_ac		= $record[1];
		
		$sth = $dbh->prepare(qq{select min(data_inizio), max(data_fine) from archivi.calendario where anno = $anno-1 and mese = $mese;});
		if ($sth->execute()) {
			@record = $sth->fetchrow_array();
			$data_inizio_ap		= $record[0];
			$data_fine_ap		= $record[1];
		}
	}
	$output_file_name = "report_vendite_".sprintf('%02d',$mese)."_".$anno;
}

if ($societa eq 'SM') {
	$sth = $dbh->prepare(qq{call controllo.report_vendite_sm('$data_inizio_ap', '$data_fine_ap', '$data_inizio_ac', '$data_fine_ac');});
} else {
	$sth = $dbh->prepare(qq{call controllo.report_vendite_eb('$data_inizio_ap', '$data_fine_ap', '$data_inizio_ac', '$data_fine_ac');});
}
#$sth = $dbh->prepare(qq{call controllo.report_vendite_nf('2013-12-29', '2014-07-28', '2014-12-30', '2015-07-29');});
if ($sth->execute()) {
	if ($txt) {#esportazione in formato txt
		$output_file_name .= '.txt';
		open $output_file_handler, "+>", "$desktop/$output_file_name" or die "Non  stato possibile creare il file `$output_file_name`: $!\n";

		#titoli colonne
		print $output_file_handler "Mondo_\t";
		print $output_file_handler "Settore_\t";
		print $output_file_handler "Reparto_\t";
		print $output_file_handler "Famiglia_\t";
		print $output_file_handler "Sottofamiglia_\t";
		print $output_file_handler "Sede_\t";
		print $output_file_handler "Venduto_AP_\t";
		print $output_file_handler "Venduto_AC_\t";
		print $output_file_handler "Delta_V_\t";
		print $output_file_handler "Delta_VP_\t";
		print $output_file_handler "Pezzi_AP_\t";
		print $output_file_handler "Pezzi_AC_\t";
		print $output_file_handler "Delta_P_\t";
		print $output_file_handler "Delta_PP_\t";
		print $output_file_handler "Margine_AP_\t";
		print $output_file_handler "Margine_AC_\t";
		print $output_file_handler "Delta_M_\t";
		print $output_file_handler "Delta_MP_\t";
		print $output_file_handler "Vend_No_Iva_AP_\t";
		print $output_file_handler "Vend_No_Iva_AC_\n";
		
	
		while(my @row = $sth->fetchrow_array()) {
			print $output_file_handler "$row[0]\t";
			print $output_file_handler "$row[1]\t";
			print $output_file_handler "$row[2]\t";
			print $output_file_handler "$row[3]\t";
			print $output_file_handler "$row[4]\t";
			print $output_file_handler "$row[5]\t";
			print $output_file_handler "$row[8]\t";
			print $output_file_handler "$row[9]\t";
			print $output_file_handler "0\t";
			print $output_file_handler "0\t";
			print $output_file_handler "$row[6]\t";
			print $output_file_handler "$row[7]\t";
			print $output_file_handler "0\t";
			print $output_file_handler "0\t";
			print $output_file_handler "$row[10]\t";
			print $output_file_handler "$row[11]\t";
			print $output_file_handler "0\t";
			print $output_file_handler "0\t";
			print $output_file_handler "$row[12]\t";
			print $output_file_handler "$row[13]\t";
			print $output_file_handler "$row[14]\n";
		}
		close($output_file_handler);
	} else {#formato excel
		$output_file_name .= '.xlsm';
		my $workbook = Excel::Writer::XLSX->new("$desktop/$output_file_name");
		
		#creo il foglio di lavoro x l'anno
		my $rv_anno = $workbook->add_worksheet( 'RV_Anno' );
		
		#aggiungo un formato
    	my $format = $workbook->add_format();
    	$format->set_bold();
		
    	$format->set_color( 'Red' );
		$rv_anno->write( 0, 3, "Periodo corrente: dal $data_inizio_ac al $data_fine_ac", $format );
		$rv_anno->write( 1, 3, "Periodo storico: dal $data_inizio_ap al $data_fine_ap", $format );
		
		#titoli colonne
		$format->set_color( 'blue' );
		$rv_anno->write( 3, 0, "Mondo_", $format );
		$rv_anno->write( 3, 1, "Settore_", $format );
		$rv_anno->write( 3, 2, "Reparto_", $format );
		$rv_anno->write( 3, 3, "Famiglia_", $format );
		$rv_anno->write( 3, 4, "Sottofamiglia_", $format );
		$rv_anno->write( 3, 5, "Sede_", $format );
		$rv_anno->write( 3, 6, "Venduto_AP_", $format );
		$rv_anno->write( 3, 7, "Venduto_AC_", $format );
		$rv_anno->write( 3, 8, "Delta_V_", $format );
		$rv_anno->write( 3, 9, "Delta_VP_", $format );
		$rv_anno->write( 3,10, "Pezzi_AP_", $format );
		$rv_anno->write( 3,11, "Pezzi_AC_", $format );
		$rv_anno->write( 3,12, "Delta_P_", $format );
		$rv_anno->write( 3,13, "Delta_PP_", $format );
		$rv_anno->write( 3,14, "Margine_AP_", $format );
		$rv_anno->write( 3,15, "Margine_AC_", $format );
		$rv_anno->write( 3,16, "Delta_M_", $format );
		$rv_anno->write( 3,17, "Delta_MP_", $format );
		$rv_anno->write( 3,18, "Vend_No_Iva_AP_", $format );
		$rv_anno->write( 3,19, "Vend_No_Iva_AC_", $format );
		$rv_anno->write( 3,20, "Giacenza_", $format );
		
		my $row_counter = 3;
		while(my @row = $sth->fetchrow_array()) {
			$row_counter++;
			
			my $delta_venduto = "=".xl_rowcol_to_cell( $row_counter, 7)."-".xl_rowcol_to_cell( $row_counter, 6);
			my $delta_venduto_p = "=IF(".xl_rowcol_to_cell( $row_counter, 6)."<>0,(".xl_rowcol_to_cell( $row_counter, 7)."-".xl_rowcol_to_cell( $row_counter, 6).")/".xl_rowcol_to_cell( $row_counter, 6).",0)";
			my $delta_pezzi = "=".xl_rowcol_to_cell( $row_counter, 11)."-".xl_rowcol_to_cell( $row_counter, 10);
			my $delta_pezzi_p = "=IF(".xl_rowcol_to_cell( $row_counter, 10)."<>0,(".xl_rowcol_to_cell( $row_counter, 11)."-".xl_rowcol_to_cell( $row_counter, 10).")/".xl_rowcol_to_cell( $row_counter, 10).",0)";
			my $delta_margine = "=".xl_rowcol_to_cell( $row_counter, 15)."-".xl_rowcol_to_cell( $row_counter, 14);
			my $delta_margine_p = "=IF(".xl_rowcol_to_cell( $row_counter, 14)."<>0,(".xl_rowcol_to_cell( $row_counter, 15)."-".xl_rowcol_to_cell( $row_counter, 14).")/".xl_rowcol_to_cell( $row_counter, 14).",0)";
			
			$rv_anno->write( $row_counter, 0, "$row[0]");
			$rv_anno->write( $row_counter, 1, "$row[1]");
			$rv_anno->write( $row_counter, 2, "$row[2]");
			$rv_anno->write( $row_counter, 3, "$row[3]");
			$rv_anno->write( $row_counter, 4, "$row[4]");
			$rv_anno->write( $row_counter, 5, "$row[5]");
			$rv_anno->write( $row_counter, 6, "$row[8]");
			$rv_anno->write( $row_counter, 7, "$row[9]");
			$rv_anno->write( $row_counter, 8, $delta_venduto);
			$rv_anno->write( $row_counter, 9, $delta_venduto_p);
			$rv_anno->write( $row_counter,10, "$row[6]");
			$rv_anno->write( $row_counter,11, "$row[7]");
			$rv_anno->write( $row_counter,12, $delta_pezzi);
			$rv_anno->write( $row_counter,13, $delta_pezzi_p);
			$rv_anno->write( $row_counter,14, "$row[10]");
			$rv_anno->write( $row_counter,15, "$row[11]");
			$rv_anno->write( $row_counter,16, $delta_margine);
			$rv_anno->write( $row_counter,17, $delta_margine_p);
			$rv_anno->write( $row_counter,18, "$row[12]");
			$rv_anno->write( $row_counter,19, "$row[13]");
			$rv_anno->write( $row_counter,20, "$row[14]");
		}
		
		# Add the VBA project binary.
    $workbook->add_vba_project( '/script/vbaProject.bin' );
      
    # Add a button tied to a macro in the VBA project.
    $rv_anno->insert_button(
        'A1',
        {
            macro   => 'crea_pivot',
            caption => 'Crea Tabella Pivot',
            width   => 120,
            height  => 40
        }
    );
		#attivo il foglio di lavoro
    	$rv_anno->activate();
	}
	$sth->finish();
}

$dbh->disconnect();
