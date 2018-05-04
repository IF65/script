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
my $hostname = "localhost";
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

$sth->finish();


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

	$sth = $dbh->prepare(qq{drop table if exists `$database_report`.`report_marche`});
    if (!$sth->execute()) {
        print "Errore durante l'eliminazione della tabella `$database_report`.`report_marche`! " .$dbh->errstr."\n";
        return 0;
    }
    
	$sth = $dbh->prepare(qq{CREATE TABLE IF NOT EXISTS `$database_report`.`report_marche` (
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
							`m5_ca` float NOT NULL DEFAULT '0'
						  ) ENGINE=InnoDB DEFAULT CHARSET=latin1});
    if (!$sth->execute()) {
        print "Errore durante la creazione della tabella `$database_report`.`report_marche`! " .$dbh->errstr."\n";
        return 0;
    }
    
	#creazione record linee
    $sth = $dbh->prepare(qq{insert into `$database_report`.`report_marche` (`category`,`marca`,`linea`)
                            select concat(v.`cognome`,' ',v.`nome`) `category`, m.`marca`, m.`linea` 
                            from `$database_sm`.`venditori` as v join `$database_sm`.`marche` as m on m.`codice_compratore`=v.`codice_buyer` 
                            where v.`codice_buyer`<>'' and v.`data_dimissioni` is null});
    if (!$sth->execute()) {
        print "Errore durante l'inserimento dati nella tabella`$database_report`.`report_marche`! " .$dbh->errstr."\n";
        return 0;
    }
	#update con dati arrivi anno in corso
	$sth = $dbh->prepare(qq{update `$database_report`.`report_marche` as rm join (select m.`linea` as `linea`,round(sum(r.`quantita`),2) as `quantita`, round(sum(r.`quantita`*r.`costo`),2) as `costo` 
							from `$database_report`.`report_marche` as m join `$database_sm`.`magazzino` as mag on m.`linea`=mag.`linea` join `$database_sm`.`righe_arrivi` as r on r.`codice_articolo`=mag.`codice` join `$database_sm`.`arrivi` as a on r.`id_arrivi`=a.`id` 
							where a.`data_ddt`>='$dalla_data' and a.`data_ddt`<='$alla_data'  group by m.`linea`) as t on rm.`linea` = t.`linea`
							set rm.`acquistato`= t.costo, rm.`pezzi_a`=t.quantita});
    if (!$sth->execute()) {
        print "Errore durante l'aggiornamento arrivi anno in corso nella tabella`$database_report`.`report_marche`! " .$dbh->errstr."\n";
        return 0;
    }
	
	#update con dati arrivi anno precedente
	$sth = $dbh->prepare(qq{update `$database_report`.`report_marche` as rm join (select m.`linea` as `linea`,round(sum(r.`quantita`),2) as `quantita`, round(sum(r.`quantita`*r.`costo`),2) as `costo` 
							from `$database_report`.`report_marche` as m join `$database_sm`.`magazzino` as mag on m.`linea`=mag.`linea` join `$database_sm`.`righe_arrivi` as r on r.`codice_articolo`=mag.`codice` join `$database_sm`.`arrivi` as a on r.`id_arrivi`=a.`id` 
							where a.`data_ddt`>='$dalla_data_ap' and a.`data_ddt`<='$alla_data_ap'  group by m.`linea`) as t on rm.`linea` = t.`linea`
							set rm.`acquistato_ap`= t.costo, rm.`pezzi_a_ap`=t.quantita});
    if (!$sth->execute()) {
        print "Errore durante l'aggiornamento arrivi anno precedente nella tabella`$database_report`.`report_marche`! " .$dbh->errstr."\n";
        return 0;
    }
	
	#update con dati vendita anno in corso
	$sth = $dbh->prepare(qq{update `$database_report`.`report_marche` as rm join (select m.`linea` as `linea`,round(sum(r.`quantita`),2) as `quantita`, round(sum(r.`importo_totale`),2) as `prezzo`, round(sum(r.`importo_totale`*100/(100+r.`aliquota_iva`)),2) as `prezzo_no_iva`, round(sum(ifnull(mrg.`margine`,r.`margine`)),2) as `margine`
							from `$database_report`.`report_marche` as m join `$database_sm`.`magazzino` as mag on m.`linea`=mag.`linea` join `$database_sm`.`righe_vendita` as r on r.`codice`=mag.`codice` left join `$database_sm`.`margini` as mrg on r.`progressivo`=mrg.`progressivo`
							where r.`data`>='$dalla_data' and r.`data`<='$alla_data'  group by m.`linea`) as t on rm.`linea` = t.`linea`
							set rm.`incasso`= t.prezzo, rm.`incasso_no_iva`= t.prezzo_no_iva, rm.`pezzi_v`=t.quantita, rm.`margine`=t.`margine`});
    if (!$sth->execute()) {
        print "Errore durante l'aggiornamento vendite anno in corso nella tabella `$database_report`.`report_marche`! " .$dbh->errstr."\n";
        return 0;
    }
	
	#update con dati vendita anno precdente
	$sth = $dbh->prepare(qq{update `$database_report`.`report_marche` as rm join (select m.`linea` as `linea`,round(sum(r.`quantita`),2) as `quantita`, round(sum(r.`importo_totale`),2) as `prezzo`, round(sum(r.`importo_totale`*100/(100+r.`aliquota_iva`)),2) as `prezzo_no_iva`, round(sum(ifnull(mrg.`margine`,r.`margine`)),2) as `margine`
							from `$database_report`.`report_marche` as m join `$database_sm`.`magazzino` as mag on m.`linea`=mag.`linea` join `$database_sm`.`righe_vendita` as r on r.`codice`=mag.`codice` left join `$database_sm`.`margini` as mrg on r.`progressivo`=mrg.`progressivo`
							where r.`data`>='$dalla_data_ap' and r.`data`<='$alla_data_ap'  group by m.`linea`) as t on rm.`linea` = t.`linea`
							set rm.`incasso_ap`= t.prezzo, rm.`incasso_no_iva_ap`= t.prezzo_no_iva, rm.`pezzi_v_ap`=t.quantita, rm.`margine_ap`=t.`margine`});
    if (!$sth->execute()) {
        print "Errore durante l'aggiornamento vendite anno precedente nella tabella `$database_report`.`report_marche`! " .$dbh->errstr."\n";
        return 0;
    }
	
	#update con dati contributi anno in corso
	$sth = $dbh->prepare(qq{update `$database_report`.`report_marche` as rm join (
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
								rm.`m5_sm` = t.`M5_SM`, rm.`m5_ca` = t.`M5_CA`});
    if (!$sth->execute()) {
        print "Errore durante l'aggiornamento contributi anno in corso nella tabella `$database_report`.`report_marche`! " .$dbh->errstr."\n";
        return 0;
    }
	
	#update con dati contributi anno precedente
	$sth = $dbh->prepare(qq{update `$database_report`.`report_marche` as rm join (
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
								rm.`m5_sm_ap` = t.`M5_SM`, rm.`m5_ca_ap` = t.`M5_CA`});
    if (!$sth->execute()) {
        print "Errore durante l'aggiornamento contributi anno in corso nella tabella `$database_report`.`report_marche`! " .$dbh->errstr."\n";
        return 0;
    }
    
    return 1;
}