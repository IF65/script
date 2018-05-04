#!/usr/bin/perl -w
use strict;
use File::HomeDir;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
use DBI;
use DateTime;
use Getopt::Long;

# ftp3.samsung.it
# user: copre
# password: Htr&ju65

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

my $weekFirstDay = DateTime->today(time_zone=>'local')->truncate(to => "week")->subtract(days => 1)->truncate(to => "week")->ymd('-');
my $weekLastDay = DateTime->today(time_zone=>'local')->truncate(to => "week")->subtract(days => 1)->ymd('-');
my $monthFirstDay = DateTime->today(time_zone=>'local')->truncate(to => "month")->ymd('-');
my $previousMonthFirstDay = DateTime->today(time_zone=>'local')->truncate(to => "month")->subtract(days => 1)->truncate(to => "month")->ymd('-');
my $previousMonthLastDay = DateTime->today(time_zone=>'local')->truncate(to => "month")->subtract(days => 1)->ymd('-');
my ($weekYear, $weekNumber) = DateTime->today(time_zone=>'local')->truncate(to => "week")->subtract(days => 1)->week();

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sth_riga;

# recupero parametri dalla linea di comando
#----------------------------------------------------------------------------------------------------------------------
if (@ARGV == 0) {
   die "Nessun parametro definito!\n";
}

my $selettore_report = '';

GetOptions(
's=s{1,1}'	=> \$selettore_report,
) or die "parametri non corretti!\n";

my $desktop = File::HomeDir->my_desktop;
my $output_file_name = sprintf('SUPERMEDIA-%02d%04d',$week,$year);

# connessione al database di default
$dbh = DBI->connect("DBI:mysql:mysql:$hostname", $username, $password);
if (! $dbh) {
	die "Errore durante la connessione al database di default!\n";
}

my %giacenze = ();
my %vendite = ();
my %articoli = ();
my %negozi = ();

if ($selettore_report eq 'SAMSUNG') {
	$sth = $dbh->prepare(qq{    select m.`codice`, g.`negozio`, sum(g.`giacenza`) `giacenza`
                                from db_sm.magazzino as m join db_sm.giacenze as g on m.`codice`=g.`codice`
                                where m.`linea` like 'SAMSUNG%' and g.`data`= ? and g.`negozio` not in ('SMMD') and
								m.`codice` not in ('0560440','0560459','0560468','0619218','0560477','0560486','0560495','0575504','0575513')
                                group by 1,2
                                order by 1,2}
                            );
	
    # giacenze alla fine della settimana precedente
    if ($sth->execute($weekLastDay)) {
        while(my @row = $sth->fetchrow_array()) {
            $giacenze{$row[0]}{'settimana'}{$row[1]} = $row[2]*1;
        }
    }
	
	# giacenze alla fine del mese precedente
    if ($sth->execute($previousMonthLastDay)) {
        while(my @row = $sth->fetchrow_array()) {
            $giacenze{$row[0]}{'mese'}{$row[1]} = $row[2]*1;
        }
    }
    
    $sth = $dbh->prepare(qq{    select m.`codice`, r.`negozio`, sum(r.`quantita`) `quantita`
                                from db_sm.magazzino as m left join db_sm.righe_vendita as r on r.`codice`=m.`codice` 
                                where m.`linea` like 'SAMSUNG%' and r.`data`>= ? and r.`data`<= ? and
								r.`codice` not in ('0560440','0560459','0560468','0619218','0560477','0560486','0560495','0575504','0575513')
                                group by 1,2
                                order by 1,2}
                            );
    
    # vendite da inizio mese all'ultimo giorno della settimana precedente
    #if ($sth->execute($monthFirstDay, $weekLastDay)) {
    if ($sth->execute($monthFirstDay, $weekLastDay)) {
        while(my @row = $sth->fetchrow_array()) {
           $vendite{$row[0]}{'mese'}{$row[1]} = $row[2];
        }
    }
    
    # vendite della settimana precedente
    if ($sth->execute($weekFirstDay, $weekLastDay)) {
        while(my @row = $sth->fetchrow_array()) {
           $vendite{$row[0]}{'settimana'}{$row[1]} = $row[2];
        }
    }
    
    # descrizione articoli
    $sth = $dbh->prepare(qq{select m.`codice`, m.`descrizione`,ifnull(e.`ean`,'') from db_sm.magazzino as m left join db_sm.ean as e on m.`codice`=e.`codice` where m.`linea` like 'SAMSUNG%' group by 1});
    if ($sth->execute()) {
        while(my @row = $sth->fetchrow_array()) {
            $articoli{$row[0]}{'descrizione'} = $row[1];
			$articoli{$row[0]}{'barcode'} = $row[2];
        }
    }
	
	$sth = $dbh->prepare(qq{select n.`codice_interno`, n.`negozio_descrizione` from archivi.negozi as n where n.`societa`='08' order by 1});
	if ($sth->execute()) {
        while(my @row = $sth->fetchrow_array()) {
            $negozi{$row[0]} = $row[1];
        }
    }
	
	if (open my $output_file_handler, "+>:crlf", "$desktop/$output_file_name") {					
		my @codici = sort { $a cmp $b } keys %articoli;
		for(my $i=0;$i<@codici;$i++) {
			my $codice = $codici[$i];
			
			if (exists $vendite{$codice} or exists $giacenze{$codice}) {
				my %negoziUsati = ();
				if (exists $giacenze{$codice}{'settimana'}) {
					foreach (keys $giacenze{$codice}{'settimana'}) {
						$negoziUsati{$_} = '';
					}
				}
				if (exists $giacenze{$codice}{'mese'}) {
					foreach (keys $giacenze{$codice}{'mese'}) {
						$negoziUsati{$_} = '';
					}
				}
				if (exists $vendite{$codice}{'settimana'}) {
					foreach (keys $vendite{$codice}{'settimana'}) {
						$negoziUsati{$_} = '';
					}
				}
				if (exists $vendite{$codice}{'mese'}) {
					foreach (keys $vendite{$codice}{'mese'}) {
						$negoziUsati{$_} = '';
					}
				}
				my @negozi = grep { $_ =~ /^SM/ }  keys %negoziUsati;
				
				my $descrizione = $articoli{$codice}{'descrizione'};
				my $barcode = $articoli{$codice}{'barcode'};
	
				foreach (@negozi) {
					my $negozio = $_;
					
					my $giacenzaSettimana = 0;
					if (exists $giacenze{$codice}{'settimana'}{$negozio}) {
						$giacenzaSettimana = $giacenze{$codice}{'settimana'}{$negozio};
						if ($giacenzaSettimana<0) {$giacenzaSettimana=0}
					}
					my $giacenzaMese = 0;
					if (exists $giacenze{$codice}{'mese'}{$negozio}) {
						$giacenzaMese = $giacenze{$codice}{'mese'}{$negozio};
						if ($giacenzaMese<0) {$giacenzaMese=0}
					}
					my $vendutoSettimana = 0;
					if (exists $vendite{$codice}{'settimana'}{$negozio}) {
						$vendutoSettimana = $vendite{$codice}{'settimana'}{$negozio};
						if ($vendutoSettimana<0) {$vendutoSettimana=0}
					}
					my $vendutoMese = 0;
					if (exists $vendite{$codice}{'mese'}{$negozio}) {
						$vendutoMese = $vendite{$codice}{'mese'}{$negozio};
					}
					
					my $negozioDescrizione = 'SCONOSCIUTO';
					if (exists $negozi{$negozio}) {
						$negozioDescrizione = $negozi{$negozio};
					}
					
					my $riga =sprintf("%-20s%-30.30s%-18s%18s%-18s%-30.30s%.4d%.2d%.10d%.10d%.10d%.10dP%s",$negozio,$negozioDescrizione,$codice,'',$barcode,$descrizione,$weekYear, $weekNumber,$giacenzaSettimana,$vendutoSettimana,$giacenzaMese,$vendutoMese,$current_date->ymd(''));
					print $output_file_handler "$riga\n";
				}
			}
		}
		close $output_file_handler;
	}
} else {
	die "Report $selettore_report non definito\n";
}
$dbh->disconnect();

print "$desktop/$output_file_name\n";

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
