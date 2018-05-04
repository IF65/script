#!/usr/bin/perl -w
use strict;
use File::HomeDir;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
use DBI;

# parametri di collegamento al database ITM
#------------------------------------------------------------------------------------------------------------
my $hostname			= "10.11.14.76";
my $username			= "root";
my $password			= "mela";

# parametri dei database
#------------------------------------------------------------------------------------------------------------
my $database_archivi	= 'archivi';
my $table_negozi		= 'negozi';
my $table_articoli		= 'articox2';
my $table_barcode		= 'barartx2';
my $table_riepilogo		= 'riepvegi';

my $database_catalogo	= 'catalogo';
my $table_premi			= 'premi';
my $table_report		= 'report';

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sth_riga;

my $desktop = File::HomeDir->my_desktop;
my $excel_file_name = 'report_premiatissimi.xlsx';

my @ar_codici = ();

&DBConnection;

for(my $i=0;$i<@ar_codici;$i++) {
	
	my @ar_codsoc 	= ();
	my @ar_codneg 	= ();
	my @ar_data		= ();
	my @ar_quantita = ();
	$sth = $dbh->prepare(qq{select `RVG-CODSOC`, `RVG-CODNEG`,date_format(`RVG-DATA`,'%Y%m'), sum(`RVG-QTA-USC`) 
							from `$database_archivi`.`$table_riepilogo` 
							where `RVG-CODICE` = '$ar_codici[$i]' and `RVG-DATA` >= '2017-01-01'
							group by 1,2,3 
							order by 1,2,3});
	if ($sth->execute()) {
		while(my @row = $sth->fetchrow_array()) {
			push(@ar_codsoc, $row[0]);
			push(@ar_codneg, $row[1]);
			push(@ar_data, $row[2]);
			push(@ar_quantita, $row[3]);
		}
		$sth->finish();
	}
	
	for(my $j=0;$j<@ar_codsoc;$j++) {
		$sth_riga->execute($ar_codici[$i], $ar_codsoc[$j].$ar_codneg[$j], $ar_data[$j], $ar_quantita[$j], 0);
	}
};
$sth_riga->finish();

$sth = $dbh->prepare(qq{select concat(n.societa,' - ',n.societa_descrizione), concat( n.negozio,' - ',n.negozio_descrizione), p.anno_mese, p.codice, r.descrizione, sum(p.venduto_quantita), round(sum(p.venduto_quantita*r.contributo),2),sum(p.venduto_quantita*r.punti) 
						from catalogo.report as p join (select distinct a.`COD-ART2` `codice`, a.`DES-ART2` `descrizione`, p.`parametro_02`/100 `contributo`, p.`parametro_01` `punti` from archivi.articox2 as a join cm.promozioni as p on a.`COD-ART2`=p.`codice_articolo`
						where (a.`COD-ART2` like '926%' or a.`COD-ART2` like '938%'or a.`COD-ART2` like '943%') and p.data_fine >= '2017-01-01') as r on r.codice = p.codice join
						archivi.negozi as n on p.negozio = n.codice 
						group by 1,2,3,4 
						order by 1,2,3;});
if ($sth->execute()) {
	#creo il workbook
	my $workbook = Excel::Writer::XLSX->new("/$excel_file_name");
		
	#creo il worksheet
	my $report = $workbook->add_worksheet( 'report' );
		
	#aggiungo un formato
    my $format = $workbook->add_format();
    $format->set_bold();
    my $date_format = $workbook->add_format();
    $date_format->set_num_format('dd/mm/yy');
    
    #titoli colonne
	$format->set_color( 'Black' );
	$report->write( 0, 0, "societa", $format );
	$report->write( 0, 1, "negozio", $format );
	$report->write( 0, 2, "data", $format );
	$report->write( 0, 3, "cod. art.", $format );
	$report->write( 0, 4, "descrizione", $format );
	$report->write( 0, 5, "contr. s/n", $format );
	$report->write( 0, 6, "n. premi", $format );
	$report->write( 0, 7, "importo", $format );
	$report->write( 0, 8, "punti", $format );

	my $row_counter = 0;
	while(my @row = $sth->fetchrow_array()) {
		$row_counter++;
			 
		$report->write_string( $row_counter, 0, "$row[0]");
		$report->write_string( $row_counter, 1, "$row[1]");
		$report->write_string( $row_counter, 2, "$row[2]");
		$report->write_string( $row_counter, 3, "$row[3]");
		$report->write_string( $row_counter, 4, "$row[4]");
		$report->write_string( $row_counter, 5, 'S“');
		$report->write( $row_counter, 6, "$row[5]");
		$report->write( $row_counter, 7, "$row[6]");
		$report->write( $row_counter, 8, "$row[7]");
	}
}
$sth->finish();

$dbh->disconnect();
	
sub DBConnection{
	# connessione al database di default
	$dbh = DBI->connect("DBI:mysql:mysql:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database di default!\n";
		return 0;
	}
	# creazione del database
	$sth = $dbh->prepare(qq{CREATE DATABASE IF NOT EXISTS `$database_catalogo` DEFAULT CHARACTER SET = latin1 DEFAULT COLLATE = latin1_swedish_ci});
	if (!$sth->execute()) {
		print "Errore durante la creazione del database `$database_catalogo`! " .$dbh->errstr."\n";
		return 0;
	}
	$sth->finish();
	
	# creazione della tabella premi
	$sth = $dbh->prepare(qq{
		CREATE TABLE IF NOT EXISTS `$database_catalogo`.`$table_premi` (
		`codice` varchar(7) NOT NULL default '',
		`descrizione` varchar(30) NOT NULL default '',
		`contributo` decimal(7,2) NOT NULL default '0.00',
		`punti` int(11) NOT NULL default '0',
		`contributo_flag` varchar(2) NOT NULL default 'Si'
		) ENGINE=InnoDB DEFAULT CHARSET=latin1;
	});
	if (!$sth->execute()) {
		print "Errore durante la creazione della tabella `$table_premi`! " .$dbh->errstr."\n";
		return 0;
	}
	$sth->finish();
	
	# eliminazione della tabella report
	$sth = $dbh->prepare(qq{drop table if exists `$database_catalogo`.`$table_report`});
	if (!$sth->execute()) {
		print "Errore durante l'eliminazione della tabella `$table_report`! " .$dbh->errstr."\n";
		return 0;
	}
	$sth->finish();
	
	# creazione della tabella report
	$sth = $dbh->prepare(qq{
		CREATE TABLE IF NOT EXISTS `$database_catalogo`.`$table_report` (
		`codice` varchar(7) NOT NULL default '',
		`negozio` varchar(4) NOT NULL default '',
		`anno_mese` varchar(8) NOT NULL default '',
		`venduto_quantita` float NOT NULL default '0',
		`venduto_importo` float NOT NULL default '0'
	) ENGINE=InnoDB DEFAULT CHARSET=latin1;});
	if (!$sth->execute()) {
		print "Errore durante la creazione della tabella `$table_report`! " .$dbh->errstr."\n";
		return 0;
	}
	$sth->finish();
	
	# ricerca dei codici degli articoli premio
	$sth = $dbh->prepare(qq{select distinct a.`COD-ART2` from `$database_archivi`.`$table_articoli` as a where (a.`COD-ART2` like '926%' or a.`COD-ART2` like '938%'or a.`COD-ART2` like '943%') and a.`COD-ART2` <> '9431509' order by 1});
	#$sth = $dbh->prepare(qq{select `codice` from `$database_catalogo`.`$table_premi` where `codice` <> '9431509'});
	if ($sth->execute()) {
		while(my @row = $sth->fetchrow_array()) {
			push(@ar_codici, $row[0]);
		}
	}
	$sth->finish();
	
	$sth_riga = $dbh->prepare(qq{INSERT IGNORE INTO `$database_catalogo`.`$table_report` (`codice`, `negozio`, `anno_mese`, `venduto_quantita`, `venduto_importo`) VALUES (?,?,?,?,?)});
}
