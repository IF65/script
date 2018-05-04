#!/usr/bin/perl -w
use strict;
use File::HomeDir;
use DBI;

# parametri di collegamento al database ITM
#------------------------------------------------------------------------------------------------------------
my $hostname			= "127.0.0.1";
my $username			= "root";
my $password			= "mela";

# parametri di collegamento al database Produzione Italmark
#------------------------------------------------------------------------------------------------------------
my $hostname_carichi	= "10.11.14.154";
my $username_carichi	= "cedadmin";
my $password_carichi	= "ced";

# parametri dei database
#------------------------------------------------------------------------------------------------------------
my $database_archivi	= 'archivi';
my $table_negozi		= 'negozi';
my $table_articoli		= 'articox2';
my $table_riepilogo		= 'riepvegi';

my $database_catalogo	= 'catalogo';
my $table_premi			= 'premi';
my $table_report		= 'report';

my $database_carichi	= 'temp';
my $table_carichi		= 'carnimis';

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sth_riga;
	
my @ar_codici_padre 			= ();
my @ar_articoli_codice_padre	= ();
my @ar_articoli_codice			= ();
my @ar_articoli_descrizione		= ();

my $desktop = File::HomeDir->my_desktop;
my $output_file_handler;
my $output_file_name = 'report.txt';

&DBConnection;

for(my $i=0;$i<@ar_codici_padre;$i++) {
	my $elenco_codici = '(';
	for(my $j=0;$j<@ar_articoli_codice_padre;$j++) {
		if ($ar_codici_padre[$i] eq $ar_articoli_codice_padre[$j]) {
			$elenco_codici .= qq('$ar_articoli_codice[$j]',);
		}
	}
	$elenco_codici = substr($elenco_codici,0,length($elenco_codici)-1).")";
	
	my @ar_codsoc 	= ();
	my @ar_codneg 	= ();
	my @ar_data		= ();
	my @ar_quantita = ();
	$sth = $dbh->prepare(qq{select `RVG-CODSOC`, `RVG-CODNEG`, `RVG-DATA`, sum(`RVG-QTA-USC`) from `$database_archivi`.`$table_riepilogo` where `RVG-CODICE` in $elenco_codici group by 1,2,3 order by 1,2,3});
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
		$sth_riga->execute($ar_codici_padre[$i], $ar_codsoc[$j].$ar_codneg[$j],substr($ar_data[$j],0,4).substr($ar_data[$j],5,2),0,0,$ar_quantita[$j],0);
	}
};
$sth_riga->finish();

open $output_file_handler, "+>", "$desktop/$output_file_name" or die "Non  stato possibile creare il file `$output_file_name`: $!\n";

$sth = $dbh->prepare(qq{select concat(n.societa,' - ',n.societa_descrizione), concat( n.negozio,' - ',n.negozio_descrizione), p.anno_mese, p.codice, r.descrizione, sum(p.carico_quantita), sum(p.venduto_quantita), round(sum(p.venduto_quantita*r.contributo),2),sum(p.venduto_quantita*r.punti) from `$database_catalogo`.`$table_report` as p, `$database_archivi`.`$table_negozi` as n, `$database_catalogo`.`$table_premi` as r where r.codice = p.codice and p.negozio = n.codice group by 1,2,3,4 order by 1,2,3;});
if ($sth->execute()) {
	print $output_file_handler "SOCIETA'\tNEGOZIO\tMESE\tARTICOLO\tENTRATI\tUSCITI\n";
	while(my @row = $sth->fetchrow_array()) {
		my $descrizione = "$row[3] \- $row[4]";
		
		print $output_file_handler "$row[0]\t";
		print $output_file_handler "$row[1]\t";
		print $output_file_handler "$row[2]\t";
		print $output_file_handler "$descrizione\t";
		print $output_file_handler "$row[5]\t";
		print $output_file_handler "$row[6]\n";
	}
}
$sth->finish();

close($output_file_handler);

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
		`contributo_flag` varchar(2) NOT NULL default 'S“'
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
		`carico_quantita` float NOT NULL default '0',
		`carico_importo` float NOT NULL default '0',
		`venduto_quantita` float NOT NULL default '0',
		`venduto_importo` float NOT NULL default '0'
	) ENGINE=InnoDB DEFAULT CHARSET=latin1;});
	if (!$sth->execute()) {
		print "Errore durante la creazione della tabella `$table_report`! " .$dbh->errstr."\n";
		return 0;
	}
	$sth->finish();
	
	# ricerca dei codici padre degli articoli premio
	$sth = $dbh->prepare(qq{select `codice` from `$database_catalogo`.`$table_premi`});
	if ($sth->execute()) {
		while(my @row = $sth->fetchrow_array()) {
			push(@ar_codici_padre, $row[0]);
		}
	}
	$sth->finish();
	
	$sth_riga = $dbh->prepare(qq{INSERT IGNORE INTO `$database_catalogo`.`$table_report` (`codice`, `negozio`, `anno_mese`,`carico_quantita`, `carico_importo`, `venduto_quantita`, `venduto_importo`) VALUES (?,?,?,?,?,?,?)});
	
	$sth = $dbh->prepare(qq{select `COD-ART2`, `DES-ART2` from $database_archivi.`$table_articoli` where `CODCIN-PADRE-ART2`=?});
	foreach my $codice (@ar_codici_padre) {
		if ($sth->execute($codice)) {
			while(my @row = $sth->fetchrow_array()) {
				push (@ar_articoli_codice_padre, $codice);
				push (@ar_articoli_codice, $row[0]);
				push (@ar_articoli_descrizione, $row[1]);
			}
		}
	}
	$sth->finish();
	
	my $dbh_carichi = DBI->connect("DBI:mysql:$database_carichi:$hostname_carichi", $username_carichi, $password_carichi);
	if (! $dbh_carichi) {
		print "Errore durante la connessione al database `$dbh_carichi`!\n";
		return 0;
	}
	my $sth_carichi = $dbh_carichi->prepare(qq{select `CodPadre`, `Filiale`, `Carichi_pezzi` from `carnimis`});
	if ($sth_carichi->execute()) {
		while(my @row = $sth_carichi->fetchrow_array()) {
			$sth_riga->execute($row[0], $row[1],'201501',$row[2],0,0,0);
		}
	}
	$sth_carichi->finish();
	$dbh_carichi->disconnect();
}
