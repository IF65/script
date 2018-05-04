#!/usr/bin/perl -w
use strict;
use warnings;

use DBI;
use DateTime;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
use List::MoreUtils qw(firstidx);

# tipo report
#------------------------------------------------------------------------------------------------------------
my $tipo_report = 1; #1=annuale, 2=mese corrente, 3=mese precedente

# date
#------------------------------------------------------------------------------------------------------------
my $data = DateTime->today(time_zone=>'local')->truncate(to=>'week')->subtract(days => 1); #ultimo giorno della settimana prec
my $anno_corrente = $data->year();
my $data_inizio_mese = $data->clone()->truncate(to => 'month');
my $data_inizio_anno = $data->clone()->truncate(to => 'year');
my $data_inizio_mese_precedente = $data_inizio_mese->clone()->subtract(months => 1);
my $data_fine_mese_precedente = $data_inizio_mese->clone()->subtract(days => 1);

my $data_ap = DateTime->new(year => ($data->year() - 1), month => $data->month(), day => $data->day());
my $anno_precedente = $anno_corrente - 1;
my $data_inizio_mese_ap = $data_ap->clone()->truncate(to => 'month');
my $data_inizio_anno_ap = $data_ap->clone()->truncate(to => 'year');
my $data_inizio_mese_precedente_ap = $data_inizio_mese_ap->clone()->subtract(months => 1);
my $data_fine_mese_precedente_ap = $data_inizio_mese_ap->clone()->subtract(days => 1);

#default report annuale
my $dalla_data = $data_inizio_anno->ymd('-');
my $alla_data = $data->ymd('-');
my $dalla_data_ap = $data_inizio_anno_ap->ymd('-');
my $alla_data_ap = $data_ap->ymd('-');
if ($tipo_report == 2) {
	$dalla_data = $data_inizio_mese->ymd('-');
	$alla_data = $data->ymd('-');
	$dalla_data_ap = $data_inizio_mese_ap->ymd('-');
	$alla_data_ap = $data_ap->ymd('-');
} elsif ($tipo_report == 3) {
	$dalla_data = $data_inizio_mese_precedente->ymd('-');
	$alla_data = $data_fine_mese_precedente->ymd('-');
	$dalla_data_ap = $data_inizio_mese_precedente_ap->ymd('-');
	$alla_data_ap = $data_fine_mese_precedente_ap->ymd('-');
}

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "10.11.14.78";
my $username = "root";
my $password = "mela";

# parametri del file Excel di output
#------------------------------------------------------------------------------------------------------------
my $excel_file_name = "report_marche.xlsx";

# parametri di configurazione dei database
#------------------------------------------------------------------------------------------------------------
my $database_archivi = 'archivi';
my $database_report = 'report';
my $database_sm = 'db_sm';
my $table_pago_nimis = 'report_marche';

# parametri di configurazione foglio excel
#------------------------------------------------------------------------------------------------------------

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh; #database handler
my $sth; #statement handler

&ConnessioneDB();

$sth = $dbh->prepare(qq{select * from `$database_report`.`report_marche` order by 1,2,3});

if ($sth->execute()) {
	my $workbook = Excel::Writer::XLSX->new("/$excel_file_name");

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
		size => 12,
		text_wrap => 1
	);
	my $format_righe = $workbook->add_format(
		valign => 'vcenter',
		align  => 'left',
		bold => 0,
		color => 'Black',
		size => 12
	);
	my $format_dati_currency = $workbook->add_format(
		valign => 'vcenter',
		align  => 'right',
		bold => 0,
		color => 'Black',
		size => 12,
		num_format => 38
	);
	my $format_dati_percentual = $workbook->add_format(
		valign => 'vcenter',
		align  => 'right',
		bold => 0,
		color => 'Black',
		size => 12,
		num_format => '[Black]#,##0.00%;[Red]-#,##0.00%;0'
	);
		
	#creo il foglio di lavoro x l'anno
	my $progress = $workbook->add_worksheet( 'Progress Marche' );
	
	 #larghezza predefinita colonne fisse (le prime 5)
    $progress->set_column( 0, 0, 20 );
    $progress->set_column( 1, 1, 40 );
	$progress->set_column( 2, 2, 40 );
	$progress->set_column( 3, 4, 15 );
	$progress->set_column( 5, 5, 10 );
	$progress->set_column( 6, 9, 15 );
	$progress->set_column( 10, 10, 10 );
	$progress->set_column( 11, 53, 15 );
        
	#titoli colonne
	$progress->merge_range( 1, 0, 3, 0, 'Category', $format_titoli_riga_2 );
	$progress->merge_range( 1, 1, 3, 1, 'Marca', $format_titoli_riga_2 );
	$progress->merge_range( 1, 2, 3, 2, 'Linea', $format_titoli_riga_2 );
	$progress->merge_range( 1, 3, 3, 3, 'Acquistato 2015', $format_titoli_riga_2 );
	$progress->merge_range( 1, 4, 3, 4, 'Acquistato 2016', $format_titoli_riga_2 );
	$progress->merge_range( 1, 5, 3, 5, 'Var. Acq.%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 6, 3, 6, 'Incasso 2015', $format_titoli_riga_2 );
	$progress->merge_range( 1, 7, 3, 7, 'Incasso 2016', $format_titoli_riga_2 );
	$progress->merge_range( 1, 8, 3, 8, 'Incasso No Iva 2015', $format_titoli_riga_2 );
	$progress->merge_range( 1, 9, 3, 9, 'Incasso No Iva 2016', $format_titoli_riga_2 );
	$progress->merge_range( 1, 10, 3, 10, 'Var. Inc. No Iva%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 11, 3, 11, 'Pezzi 2015', $format_titoli_riga_2 );
	$progress->merge_range( 1, 12, 3, 12, 'Pezzi 2016', $format_titoli_riga_2 );
	$progress->merge_range( 1, 13, 3, 13, 'Var. Pezzi%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 14, 3, 14, 'M0 2015', $format_titoli_riga_2 );
	$progress->merge_range( 1, 15, 3, 15, 'M0 2015%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 16, 3, 16, 'M0 2016', $format_titoli_riga_2 );
	$progress->merge_range( 1, 17, 3, 17, 'M0 2016%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 18, 3, 18, 'M(0+1) 2016%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 19, 3, 19, 'M(0+1+2) 2016%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 20, 3, 20, 'M(0+1+2+4) 2016%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 21, 3, 21, 'Var.M0%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 22, 3, 22, 'Var.M(0+1)%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 23, 3, 23, 'Var.M(0+1+2)%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 24, 3, 24, 'Var.M(0+1+2+4)%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 25, 3, 25, 'Giacenza Finale', $format_titoli_riga_2 );
	$progress->merge_range( 1, 26, 3, 26, 'Indice permanenza in gg (proiez. 12 mesi)', $format_titoli_riga_2 );
	$progress->merge_range( 1, 27, 3, 27, 'M1 2015', $format_titoli_riga_2 );
	$progress->merge_range( 1, 28, 3, 28, 'M1 2016', $format_titoli_riga_2 );
	$progress->merge_range( 1, 29, 3, 29, 'Var. M1%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 30, 3, 30, 'M2 2015', $format_titoli_riga_2 );
	$progress->merge_range( 1, 31, 3, 31, 'M2 2016', $format_titoli_riga_2 );
	$progress->merge_range( 1, 32, 3, 32, 'Var. M2%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 33, 3, 33, 'M3 SM 2015', $format_titoli_riga_2 );
	$progress->merge_range( 1, 34, 3, 34, 'M3 SM 2016', $format_titoli_riga_2 );
	$progress->merge_range( 1, 35, 3, 35, 'Var. M3 SM%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 36, 3, 36, 'M3 Copre 2015', $format_titoli_riga_2 );
	$progress->merge_range( 1, 37, 3, 37, 'M3 Copre 2016', $format_titoli_riga_2 );
	$progress->merge_range( 1, 38, 3, 38, 'Var. M3 Copre%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 39, 3, 39, 'M4 2015', $format_titoli_riga_2 );
	$progress->merge_range( 1, 40, 3, 40, 'M4 2016', $format_titoli_riga_2 );
	$progress->merge_range( 1, 41, 3, 41, 'Var. M4%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 42, 3, 42, 'M5 SM 2015', $format_titoli_riga_2 );
	$progress->merge_range( 1, 43, 3, 43, 'M5 SM 2016', $format_titoli_riga_2 );
	$progress->merge_range( 1, 44, 3, 44, 'Var. M5 SM%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 45, 3, 45, 'M5 Copre 2015', $format_titoli_riga_2 );
	$progress->merge_range( 1, 46, 3, 46, 'M5 Copre 2016', $format_titoli_riga_2 );
	$progress->merge_range( 1, 47, 3, 47, 'Var. M5 Copre%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 48, 3, 48, 'No lbl 2015', $format_titoli_riga_2 );
	$progress->merge_range( 1, 49, 3, 49, 'No lbl 2016', $format_titoli_riga_2 );
	$progress->merge_range( 1, 50, 3, 50, 'Var. No lbl%', $format_titoli_riga_2 );
	$progress->merge_range( 1, 51, 3, 51, 'Val.In.Ord.', $format_titoli_riga_2 );
	$progress->merge_range( 1, 52, 3, 52, 'Val.Giac.In.', $format_titoli_riga_2 );
	$progress->merge_range( 1, 53, 3, 53, 'Val.Div.', $format_titoli_riga_2 );
	
	my $row_counter = 3;
	while(my @row = $sth->fetchrow_array()) {
		$row_counter++;
		
		my $r = sprintf('%s',$row_counter+1);
		
		$progress->write( $row_counter, 0, "$row[0]", $format_righe);
		$progress->write( $row_counter, 1, "$row[1]", $format_righe);
		$progress->write( $row_counter, 2, "$row[2]", $format_righe);
		
		$progress->write_number( $row_counter, 3, "$row[3]", $format_dati_currency);
		$progress->write_number( $row_counter, 4, "$row[4]", $format_dati_currency);
		$progress->write_formula( $row_counter, 5, "=IF(D$r<>0,(E$r-D$r)/D$r,0)", $format_dati_percentual);
		
		$progress->write_number( $row_counter, 6, "$row[5]", $format_dati_currency);
		$progress->write_number( $row_counter, 7, "$row[6]", $format_dati_currency);
		$progress->write_number( $row_counter, 8, "$row[7]", $format_dati_currency);
		$progress->write_number( $row_counter, 9, "$row[8]", $format_dati_currency);
		$progress->write_formula( $row_counter, 10, "=IF(I$r<>0,(J$r-I$r)/I$r,0)", $format_dati_percentual);
		
		$progress->write( $row_counter, 11, "$row[9]", $format_righe);
		$progress->write_formula( $row_counter, 12, "=IF(L$r<>0,(M$r-L$r)/L$r,0)", $format_dati_percentual);
		
		$progress->write( $row_counter, 13, "$row[10]", $format_righe);
		$progress->write_formula( $row_counter, 14, "=IF(J$r<>0,Q$r/J$r,0)", $format_dati_percentual);

		#$progress->write( $row_counter, 10, "$row[10]", $format_righe);
		#$progress->write( $row_counter, 11, "$row[11]", $format_righe);
		#$progress->write( $row_counter, 12, "$row[12]", $format_righe);
		#$progress->write( $row_counter, 13, "$row[13]", $format_righe);
		#$progress->write( $row_counter, 14, "$row[14]", $format_righe);
		#$progress->write( $row_counter, 15, "$row[15]", $format_righe);
		#$progress->write( $row_counter, 16, "$row[16]", $format_righe);
		#$progress->write( $row_counter, 17, "$row[17]", $format_righe);
		#$progress->write( $row_counter, 18, "$row[18]", $format_righe);
		#$progress->write( $row_counter, 19, "$row[19]", $format_righe);
		#$progress->write( $row_counter, 20, "$row[20]", $format_righe);
		#$progress->write( $row_counter, 21, "$row[21]", $format_righe);
		#$progress->write( $row_counter, 22, "$row[22]", $format_righe);
		#$progress->write( $row_counter, 23, "$row[23]", $format_righe);
		#$progress->write( $row_counter, 24, "$row[24]", $format_righe);
		#$progress->write( $row_counter, 25, "$row[25]", $format_righe);
		#$progress->write( $row_counter, 26, "$row[26]", $format_righe);
		#$progress->write( $row_counter, 27, "$row[27]", $format_righe);
		#$progress->write( $row_counter, 28, "$row[28]", $format_righe);
		#$progress->write( $row_counter, 29, "$row[29]", $format_righe);
		#$progress->write( $row_counter, 30, "$row[30]", $format_righe);
		#$progress->write( $row_counter, 31, "$row[31]", $format_righe);
		#$progress->write( $row_counter, 32, "$row[32]", $format_righe);
		#$progress->write( $row_counter, 33, "$row[33]", $format_righe);
		#$progress->write( $row_counter, 34, "$row[34]", $format_righe);
#		$progress->write( $row_counter, 35, "$row[35]", $format_righe);
#		$progress->write( $row_counter, 36, "$row[36]", $format_righe);
#		$progress->write( $row_counter, 37, "$row[37]", $format_righe);
# 		$progress->write( $row_counter, 38, "$row[38]", $format_righe);
# 		$progress->write( $row_counter, 39, "$row[39]", $format_righe);
# 		$progress->write( $row_counter, 40, "$row[40]", $format_righe);
# 		$progress->write( $row_counter, 41, "$row[41]", $format_righe);
# 		$progress->write( $row_counter, 42, "$row[42]", $format_righe);
# 		$progress->write( $row_counter, 43, "$row[43]", $format_righe);
# 		$progress->write( $row_counter, 44, "$row[44]", $format_righe);
# 		$progress->write( $row_counter, 45, "$row[45]", $format_righe);
# 		$progress->write( $row_counter, 46, "$row[46]", $format_righe);
# 		$progress->write( $row_counter, 47, "$row[47]", $format_righe);
# 		$progress->write( $row_counter, 48, "$row[48]", $format_righe);
# 		$progress->write( $row_counter, 49, "$row[49]", $format_righe);
# 		$progress->write( $row_counter, 50, "$row[50]", $format_righe);
# 		$progress->write( $row_counter, 51, "$row[51]", $format_righe);
# 		$progress->write( $row_counter, 52, "$row[52]", $format_righe);
# 		$progress->write( $row_counter, 53, "$row[53]", $format_righe);
	}
}

$sth->finish();
$dbh->disconnect();

#------------------------------------------------------------------------------------------------------------
# subs & functions
#------------------------------------------------------------------------------------------------------------
sub ConnessioneDB {
	# connessione al database negozi
	$dbh = DBI->connect("DBI:mysql:$database_archivi:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database `$database_report`!\n";
		return 0;
	}
if(0) {
	$sth = $dbh->do(qq{drop table if exists `$database_report`.`report_marche`}) or 
					die"Errore durante l'eliminazione della tabella `$database_report`.`report_marche`! " .$dbh->errstr."\n";
    
	$sth = $dbh->do(qq{CREATE TABLE IF NOT EXISTS `$database_report`.`report_marche` (
							`category` varchar(40) NOT NULL DEFAULT '',
							`marca` varchar(40) NOT NULL DEFAULT '',
							`linea` varchar(40) NOT NULL DEFAULT '',
							`acquistato_ap` float NOT NULL DEFAULT '0',
							`acquistato` float NOT NULL DEFAULT '0',
							`pezzi_a_ap` float NOT NULL DEFAULT '0',
							`pezzi_a` float NOT NULL DEFAULT '0',
							`incasso_ap` float NOT NULL DEFAULT '0',
							`incasso` float NOT NULL DEFAULT '0',
							`incasso_no_iva_ap` float NOT NULL DEFAULT '0',
							`incasso_no_iva` float NOT NULL DEFAULT '0',
							`margine_ap` float NOT NULL DEFAULT '0',
							`margine` float NOT NULL DEFAULT '0',
							`pezzi_v_ap` float NOT NULL DEFAULT '0',
							`pezzi_v` float NOT NULL DEFAULT '0',
							`m1_sm_ap` float NOT NULL DEFAULT '0',
							`m1_ca_ap` float NOT NULL DEFAULT '0',
							`m1_sm` float NOT NULL DEFAULT '0',
							`m1_ca` float NOT NULL DEFAULT '0',
							`m2_sm_ap` float NOT NULL DEFAULT '0',
							`m2_ca_ap` float NOT NULL DEFAULT '0',
							`m2_sm` float NOT NULL DEFAULT '0',
							`m2_ca` float NOT NULL DEFAULT '0',
							`m3_sm_ap` float NOT NULL DEFAULT '0',
							`m3_ca_ap` float NOT NULL DEFAULT '0',
							`m3_sm` float NOT NULL DEFAULT '0',
							`m3_ca` float NOT NULL DEFAULT '0',
							`m4_sm_ap` float NOT NULL DEFAULT '0',
							`m4_ca_ap` float NOT NULL DEFAULT '0',
							`m4_sm` float NOT NULL DEFAULT '0',
							`m4_ca` float NOT NULL DEFAULT '0',
							`m5_sm_ap` float NOT NULL DEFAULT '0',
							`m5_ca_ap` float NOT NULL DEFAULT '0',
							`m5_sm` float NOT NULL DEFAULT '0',
							`m5_ca` float NOT NULL DEFAULT '0',
							primary key (`linea`)
						  ) ENGINE=InnoDB DEFAULT CHARSET=latin1}) or 
					die "Errore durante la creazione della tabella `$database_report`.`report_marche`! " .$dbh->errstr."\n";
      
	#creazione record linee
    $sth = $dbh->do(qq{	insert into `$database_report`.`report_marche` (`category`,`marca`,`linea`)
                        select concat(v.`cognome`,' ',v.`nome`) `category`, m.`marca`, m.`linea` 
                        from `$database_sm`.`venditori` as v join `$database_sm`.`marche` as m on m.`codice_compratore`=v.`codice_buyer` 
                        where v.`codice_buyer`<>'' and v.`data_dimissioni` is null}) or 
    				die "Errore durante l'inserimento dati nella tabella`$database_report`.`report_marche`! " .$dbh->errstr."\n";

	#update con dati arrivi anno in corso
	$sth = $dbh->do(qq{ update `$database_report`.`report_marche` as rm join (select m.`linea` as `linea`,round(sum(r.`quantita`),2) as `quantita`, round(sum(r.`quantita`*r.`costo`),2) as `costo` 
						from `$database_report`.`report_marche` as m join `$database_sm`.`magazzino` as mag on m.`linea`=mag.`linea` join `$database_sm`.`righe_arrivi` as r on r.`codice_articolo`=mag.`codice` join `$database_sm`.`arrivi` as a on r.`id_arrivi`=a.`id` 
						where a.`data_ddt`>='$dalla_data' and a.`data_ddt`<='$alla_data'  group by m.`linea`) as t on rm.`linea` = t.`linea`
						set rm.`acquistato`= t.costo, rm.`pezzi_a`=t.quantita}) or
					die "Errore durante l'aggiornamento arrivi anno in corso nella tabella`$database_report`.`report_marche`! " .$dbh->errstr."\n";
    
    #update con dati arrivi anno precedente
	$sth = $dbh->do(qq{	update `$database_report`.`report_marche` as rm join (select m.`linea` as `linea`,round(sum(r.`quantita`),2) as `quantita`, round(sum(r.`quantita`*r.`costo`),2) as `costo` 
						from `$database_report`.`report_marche` as m join `$database_sm`.`magazzino` as mag on m.`linea`=mag.`linea` join `$database_sm`.`righe_arrivi` as r on r.`codice_articolo`=mag.`codice` join `$database_sm`.`arrivi` as a on r.`id_arrivi`=a.`id` 
						where a.`data_ddt`>='$dalla_data_ap' and a.`data_ddt`<='$alla_data_ap'  group by m.`linea`) as t on rm.`linea` = t.`linea`
						set rm.`acquistato_ap`= t.costo, rm.`pezzi_a_ap`=t.quantita}) or
    				die "Errore durante l'aggiornamento arrivi anno precedente nella tabella`$database_report`.`report_marche`! " .$dbh->errstr."\n";
	
	#update con dati vendita anno in corso
	$sth = $dbh->do(qq{	update `$database_report`.`report_marche` as rm join (select m.`linea` as `linea`,round(sum(r.`quantita`),2) as `quantita`, round(sum(r.`importo_totale`),2) as `prezzo`, round(sum(r.`importo_totale`*100/(100+r.`aliquota_iva`)),2) as `prezzo_no_iva`, round(sum(ifnull(mrg.`margine`,r.`margine`)),2) as `margine`
						from `$database_report`.`report_marche` as m join `$database_sm`.`magazzino` as mag on m.`linea`=mag.`linea` join `$database_sm`.`righe_vendita` as r on r.`codice`=mag.`codice` left join `$database_sm`.`margini` as mrg on r.`progressivo`=mrg.`progressivo`
						where r.`data`>='$dalla_data' and r.`data`<='$alla_data'  group by m.`linea`) as t on rm.`linea` = t.`linea`
						set rm.`incasso`= t.prezzo, rm.`incasso_no_iva`= t.prezzo_no_iva, rm.`pezzi_v`=t.quantita, rm.`margine`=t.`margine`}) or
   					die "Errore durante l'aggiornamento vendite anno in corso nella tabella `$database_report`.`report_marche`! " .$dbh->errstr."\n";
	
	#update con dati vendita anno precdente
	$sth = $dbh->do(qq{	update `$database_report`.`report_marche` as rm join (select m.`linea` as `linea`,round(sum(r.`quantita`),2) as `quantita`, round(sum(r.`importo_totale`),2) as `prezzo`, round(sum(r.`importo_totale`*100/(100+r.`aliquota_iva`)),2) as `prezzo_no_iva`, round(sum(ifnull(mrg.`margine`,r.`margine`)),2) as `margine`
						from `$database_report`.`report_marche` as m join `$database_sm`.`magazzino` as mag on m.`linea`=mag.`linea` join `$database_sm`.`righe_vendita` as r on r.`codice`=mag.`codice` left join `$database_sm`.`margini` as mrg on r.`progressivo`=mrg.`progressivo`
						where r.`data`>='$dalla_data_ap' and r.`data`<='$alla_data_ap'  group by m.`linea`) as t on rm.`linea` = t.`linea`
						set rm.`incasso_ap`= t.prezzo, rm.`incasso_no_iva_ap`= t.prezzo_no_iva, rm.`pezzi_v_ap`=t.quantita, rm.`margine_ap`=t.`margine`}) or
					die "Errore durante l'aggiornamento vendite anno precedente nella tabella `$database_report`.`report_marche`! " .$dbh->errstr."\n";
 
	#update con dati contributi anno in corso
	$sth = $dbh->do(qq{	update `$database_report`.`report_marche` as rm join (
						select	c.`marca` as `linea`,
								round(sum(case when descrizione_contabile like '%SM%' and c.`livello_margine` = 'M1' then importo else 0 end),2) as `M1_SM`,
								round(sum(case when descrizione_contabile not like '%SM%' and c.`livello_margine` = 'M1' then importo else 0 end),2) as `M1_CA`,
								round(sum(case when descrizione_contabile like '%SM%' and c.`livello_margine` = 'M2' then importo else 0 end),2) as `M2_SM`,
								round(sum(case when descrizione_contabile not like '%SM%' and c.`livello_margine` = 'M2' then importo else 0 end),2) as `M2_CA`,
								round(sum(case when descrizione_contabile like '%SM%' and c.`livello_margine` = 'M3' then importo else 0 end),2) as `M3_SM`,
								round(sum(case when descrizione_contabile not like '%SM%' and c.`livello_margine` = 'M3' then importo else 0 end),2) as `M3_CA`,
								round(sum(case when descrizione_contabile like '%SM%' and c.`livello_margine` = 'M4' then importo else 0 end),2) as `M4_SM`,
								round(sum(case when descrizione_contabile not like '%SM%' and c.`livello_margine` = 'M4' then importo else 0 end),2) as `M4_CA`,
								round(sum(case when descrizione_contabile like '%SM%' and c.`livello_margine` = 'M5' then importo else 0 end),2) as `M5_SM`,
								round(sum(case when descrizione_contabile not like '%SM%' and c.`livello_margine` = 'M5' then importo else 0 end),2) as `M5_CA`,
								round(sum(case when descrizione_contabile like '%SM%' then importo else 0 end),2) as `SM`,
								round(sum(case when descrizione_contabile not like '%SM%' then importo else 0 end),2) as `CA`
						from `$database_sm`.`contributi` as c where c.`competenza` = $anno_corrente group by 1) as t on rm.`linea` = t.`linea`
						set rm.`m1_sm` = t.`M1_SM`, rm.`m1_ca` = t.`M1_CA`,
							rm.`m2_sm` = t.`M2_SM`, rm.`m2_ca` = t.`M2_CA`,
							rm.`m3_sm` = t.`M3_SM`, rm.`m3_ca` = t.`M3_CA`,
							rm.`m4_sm` = t.`M4_SM`, rm.`m4_ca` = t.`M4_CA`,
							rm.`m5_sm` = t.`M5_SM`, rm.`m5_ca` = t.`M5_CA`}) or
					die "Errore durante l'aggiornamento contributi anno in corso nella tabella `$database_report`.`report_marche`! " .$dbh->errstr."\n";
	
	#update con dati contributi anno precedente
	$sth = $dbh->do(qq{	update `$database_report`.`report_marche` as rm join (
						select	c.`marca` as `linea`,
								round(sum(case when descrizione_contabile like '%SM%' and c.`livello_margine` = 'M1' then importo else 0 end),2) as `M1_SM`,
								round(sum(case when descrizione_contabile not like '%SM%' and c.`livello_margine` = 'M1' then importo else 0 end),2) as `M1_CA`,
								round(sum(case when descrizione_contabile like '%SM%' and c.`livello_margine` = 'M2' then importo else 0 end),2) as `M2_SM`,
								round(sum(case when descrizione_contabile not like '%SM%' and c.`livello_margine` = 'M2' then importo else 0 end),2) as `M2_CA`,
								round(sum(case when descrizione_contabile like '%SM%' and c.`livello_margine` = 'M3' then importo else 0 end),2) as `M3_SM`,
								round(sum(case when descrizione_contabile not like '%SM%' and c.`livello_margine` = 'M3' then importo else 0 end),2) as `M3_CA`,
								round(sum(case when descrizione_contabile like '%SM%' and c.`livello_margine` = 'M4' then importo else 0 end),2) as `M4_SM`,
								round(sum(case when descrizione_contabile not like '%SM%' and c.`livello_margine` = 'M4' then importo else 0 end),2) as `M4_CA`,
								round(sum(case when descrizione_contabile like '%SM%' and c.`livello_margine` = 'M5' then importo else 0 end),2) as `M5_SM`,
								round(sum(case when descrizione_contabile not like '%SM%' and c.`livello_margine` = 'M5' then importo else 0 end),2) as `M5_CA`,
								round(sum(case when descrizione_contabile like '%SM%' then importo else 0 end),2) as `SM`,
								round(sum(case when descrizione_contabile not like '%SM%' then importo else 0 end),2) as `CA`
						from `$database_sm`.`contributi` as c where c.`competenza` = $anno_precedente group by 1) as t on rm.`linea` = t.`linea`
						set rm.`m1_sm_ap` = t.`M1_SM`, rm.`m1_ca_ap` = t.`M1_CA`,
							rm.`m2_sm_ap` = t.`M2_SM`, rm.`m2_ca_ap` = t.`M2_CA`,
							rm.`m3_sm_ap` = t.`M3_SM`, rm.`m3_ca_ap` = t.`M3_CA`,
							rm.`m4_sm_ap` = t.`M4_SM`, rm.`m4_ca_ap` = t.`M4_CA`,
							rm.`m5_sm_ap` = t.`M5_SM`, rm.`m5_ca_ap` = t.`M5_CA`}) or 
					die "Errore durante l'aggiornamento contributi anno in corso nella tabella `$database_report`.`report_marche`! " .$dbh->errstr."\n";
    
    $sth->finish();
}    
    return 1;
}
