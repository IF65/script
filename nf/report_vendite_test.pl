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
my $database			= "controllo";

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sth_riga;
	
# definizione dei parametri sulla linea di comando
#------------------------------------------------------------------------------------------------------------
my $societa = 'SM';
my $tipo_report = 2; 	#2=report settimana, 3=report mese, #4=report anno, 
						#5=progress mese, #6=progress anno
my $data_ac;
my $data_ap;
my $data_inizio_ac;
my $data_fine_ac;
my $data_inizio_ap;
my $data_fine_ap;

my $anno;
my $mese;
my $settimana;

my @ar_societa = ();
my @ar_tipo = ();
my @ar_data = ();

my $txt = 0;
GetOptions(
	's=s{1,1}'		=> \@ar_societa,
	't=s{1,1}'		=> \@ar_tipo,
	'd=s{0,1}'		=> \@ar_data,
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
		$data_ac = string2date($1.'-'.$2.'-'.$3); 
	}
} else {
	$data_ac = DateTime->today(time_zone=>'local');
}

my $desktop = '/';#File::HomeDir->my_desktop;
my $output_file_handler;
my $output_file_name = '';

# connessione al database di default
$dbh = DBI->connect("DBI:mysql:mysql:$hostname", $username, $password);
if (! $dbh) {
	print "Errore durante la connessione al database di default!\n";
	return 0;
}

my $mysql_data_inizio_ac;
my $mysql_data_fine_ac; 
my $mysql_data_inizio_ap;
my $mysql_data_fine_ap;

$output_file_name = 'report_vendite';
$mysql_data_inizio_ap = '2015-01-01';
$mysql_data_fine_ap = '2015-04-26';
$mysql_data_inizio_ac = '2016-01-01';
$mysql_data_fine_ac = '2016-04-26';

$sth = $dbh->prepare(qq{call controllo.report_vendite_sm_test('$mysql_data_inizio_ap', '$mysql_data_fine_ap', '$mysql_data_inizio_ac', '$mysql_data_fine_ac');});
if ($sth->execute()) {
	if ($txt) {#esportazione in formato txt
		$output_file_name .= '.txt';
		open $output_file_handler, "+>", "$desktop/$output_file_name" or die "Non è stato possibile creare il file `$output_file_name`: $!\n";

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
		$rv_anno->write( 0, 3, "Periodo corrente: dal $mysql_data_inizio_ac al $mysql_data_fine_ac", $format );
		$rv_anno->write( 1, 3, "Periodo storico: dal $mysql_data_inizio_ap al $mysql_data_fine_ap", $format );
		
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

sub settimana_limiti {
	my ($anno, $settimana, $tipo) = @_;
	
	my $chiave = sprintf('%04d%02d',$anno, $settimana);

	my $data_inizio;
	my $data_fine;
	if ($tipo eq 'GFK') {    
		$data_inizio = $settimane_gfk{$chiave}{inizio};
		$data_fine = $settimane_gfk{$chiave}{fine};
	} elsif ($tipo eq 'IF65') {
		$data_inizio = $settimane_if65{$chiave}{inizio};
		$data_fine = $settimane_if65{$chiave}{fine};
	}
	return $data_inizio, $data_fine;
}

sub mese_limiti {
	my ($anno, $mese, $tipo) =@_;
	
	my $data_inizio = '2099-12-31';
	my $data_fine = '1900-01-01';
	
	if ($tipo eq 'GFK') {    
		foreach my $chiave (keys %settimane_gfk) {
			if ($settimane_gfk{$chiave}{anno} == $anno && $settimane_gfk{$chiave}{mese} == $mese && $settimane_gfk{$chiave}{inizio} lt $data_inizio ) {
				$data_inizio = $settimane_gfk{$chiave}{inizio};
			}
			
			if ($settimane_gfk{$chiave}{anno} == $anno && $settimane_gfk{$chiave}{mese} == $mese && $settimane_gfk{$chiave}{fine} gt $data_fine ) {
				$data_fine = $settimane_gfk{$chiave}{fine};
			}
		}
	} elsif ($tipo eq 'IF65') {
		foreach my $chiave (keys %settimane_if65) {
			if ($settimane_if65{$chiave}{anno} == $anno && $settimane_if65{$chiave}{mese} == $mese && $settimane_if65{$chiave}{inizio} lt $data_inizio ) {
				$data_inizio = $settimane_if65{$chiave}{inizio};
			}
			
			if ($settimane_if65{$chiave}{anno} == $anno && $settimane_if65{$chiave}{mese} == $mese && $settimane_if65{$chiave}{fine} gt $data_fine ) {
				$data_fine = $settimane_if65{$chiave}{fine};
			}
		}
        
        $data_inizio = string2date($data_fine)->truncate(to => "month")->ymd('-');
	}
    
	return $data_inizio, $data_fine;
}

sub anno_limiti {
	my ($anno, $tipo) =@_;
	
	my $data_inizio = '2099-12-31';
	my $data_fine = '1900-01-01';
	
	if ($tipo eq 'GFK') {
		foreach my $chiave (keys %settimane_gfk) {
			if ($settimane_gfk{$chiave}{anno} == $anno && $settimane_gfk{$chiave}{inizio} lt $data_inizio ) {
				$data_inizio = $settimane_gfk{$chiave}{inizio};
			}
			
			if ($settimane_gfk{$chiave}{anno} == $anno && $settimane_gfk{$chiave}{fine} gt $data_fine ) {
				$data_fine = $settimane_gfk{$chiave}{fine};
			}
		}
	} elsif ($tipo eq 'IF65') {
		foreach my $chiave (keys %settimane_if65) {
			if ($settimane_if65{$chiave}{anno} == $anno && $settimane_if65{$chiave}{inizio} lt $data_inizio ) {
				$data_inizio = $settimane_if65{$chiave}{inizio};
			}
			
			if ($settimane_if65{$chiave}{anno} == $anno && $settimane_if65{$chiave}{fine} gt $data_fine ) {
				$data_fine = $settimane_if65{$chiave}{fine};
			}
		}
        
         $data_inizio = string2date($data_inizio)->truncate(to => "year")->ymd('-');
	}
	return $data_inizio, $data_fine;
}





##creo la giacenza corrente
#     drop table if exists `db_sm`.`date_aggiornamento_sm`;
#     drop table if exists `db_sm`.`giacenza_corrente_sm`;
#     
#     #creo una tabella che contenga la data di aggiornamento più vicina a quella richiesta
#     create table db_sm.date_aggiornamento_sm as select negozio, max(data) `data` from db_sm.giacenze where data <= data_fine_ac group by 1 order by 1;
#     #creo la tabella giacenza corrente in base alle date appena calcolate
#     create table db_sm.giacenza_corrente_sm as select m.codice_famiglia, m.codice_sottofamiglia, g.negozio,round(sum(g.giacenza*m.costo_medio),2) `giacenza` 
# 	from db_sm.giacenze as g join db_sm.date_aggiornamento_sm as d on g.data = d.data and g.negozio = d.negozio
# 	join db_sm.magazzino as m on g.codice = m.codice
#     group by 1, 2, 3;
#     
#     alter table `db_sm`.`giacenza_corrente_sm` add PRIMARY KEY(codice_famiglia,codice_sottofamiglia,negozio);
# 
# 	select 
# 		concat(mo.codice,' - ',mo.descrizione) `mondo`,
# 		concat(se.codice,' - ',se.descrizione) `settore`,
# 		concat(re.codice,' - ',re.descrizione) `reparto`,
# 		concat(fa.codice,' - ',fa.descrizione) `famiglia`,
# 		concat(sf.codice,' - ',sf.descrizione) `sottofamiglia`,
# 		concat(rv.`negozio`,' - ',n.negozio_descrizione) `negozio`,
# 		round(sum(case when (rv.`data` >= data_inizio_ap and rv.`data` <= data_fine_ap) then ifnull(rv.`quantita`,0) else 0 end),2) `q.tà ap`,
#         round(sum(case when (rv.`data` >= data_inizio_ac and rv.`data` <= data_fine_ac) then ifnull(rv.`quantita`,0) else 0 end),2) `q.tà ac`,
#         round(sum(case when (rv.`data` >= data_inizio_ap and rv.`data` <= data_fine_ap) then ifnull(rv.`importo_totale`,0) else 0 end),2) `importo ap`,
#         round(sum(case when (rv.`data` >= data_inizio_ac and rv.`data` <= data_fine_ac) then ifnull(rv.`importo_totale`,0) else 0 end),2) `importo ac`,
#         round(sum(case when (rv.`data` >= data_inizio_ap and rv.`data` <= data_fine_ap) then ifnull(rv.`margine`,0) else 0 end),2) `margine ap`,
#         round(sum(case when (rv.`data` >= data_inizio_ac and rv.`data` <= data_fine_ac) then ifnull(rv.`margine`,0) else 0 end),2) `margine ac`,
#         round(sum(case when (rv.`data` >= data_inizio_ap and rv.`data` <= data_fine_ap) then ifnull(rv.`importo_totale`*100/(100+rv.`aliquota_iva`),0) else 0 end),2) `venduto no iva ap`,
#         round(sum(case when (rv.`data` >= data_inizio_ac and rv.`data` <= data_fine_ac) then ifnull(rv.`importo_totale`*100/(100+rv.`aliquota_iva`),0) else 0 end),2) `venduto no iva ac`,
#         round(ifnull(gc.`giacenza`,0),2) `giacenza`
# 	from 
# 		`db_sm`.`mondi` as mo
# 		left join `db_sm`.`settori` as se on se.`codice_mondo` = mo.`codice`
# 		left join `db_sm`.`reparti` as re on re.`codice_settore` = se.`codice`
# 		left join `db_sm`.`famiglie` as fa on fa.`codice_reparto`=re.`codice`
# 		left join `db_sm`.`sottofamiglie` as sf on sf.`codice_famiglia`=fa.`codice`
#         left join `db_sm`.`magazzino` as ma on ma.`codice_famiglia` = fa.`codice` and ma.`codice_sottofamiglia` = sf.`codice`
#         left join `db_sm`.`righe_vendita` as rv on rv.`codice` = ma.`codice`
#         left join `archivi`.`negozi` as n on n.`codice_interno`=rv.`negozio`
#         left join `db_sm`.`giacenza_corrente_sm` as gc on ma.`codice_famiglia`=gc.`codice_famiglia` and ma.`codice_sottofamiglia`=gc.`codice_sottofamiglia` and rv.`negozio`=gc.`negozio`
# 		where ((rv.`data` >= data_inizio_ap and rv.`data` <= data_fine_ap) or (rv.`data` >= data_inizio_ac and rv.`data` <= data_fine_ac)) and
# 				rv.`riga_non_fiscale` = 0 and  rv.`riparazione` = 0
# 	group by 1,2 ,3,4,5,6;
#     
#     drop table if exists `db_sm`.`date_aggiornamento_sm`;
#     drop table if exists `db_sm`.`giacenza_corrente_sm`;
