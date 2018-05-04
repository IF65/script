#!/usr/bin/perl

use strict;
use warnings;

use DBI;
use Getopt::Long;
use DateTime;
use File::Util;
use List::MoreUtils qw(firstidx);

# parametri database
#----------------------------------------------------------------------------------------------------------------------
my $hostname = '10.11.14.78';
my $user = 'root';
my $password = 'mela';

# variabili globali
#----------------------------------------------------------------------------------------------------------------------
my %host;
my $dbh;
my $sth;
my $fileName;

# parametri
#----------------------------------------------------------------------------------------------------------------------
my @arHost;
my @arData;
GetOptions(
	'h=s{1,1}'	=> \@arHost,
	'd=s{1,1}'	=> \@arData,
) or die "Numero parametri errato!\n";

my $pHost = '';
if (@arHost > 0) {
	if ($arHost[0] !~ /^\d{4}$/) {
		die "Codice host errato: $arHost[0]\n";
	}
	$pHost = $arHost[0];
}

my $pData;
for (my $i=0;$i<@arData;$i++) {
	$arData[$i] =~ s/[^\d\-]/\-/ig;
	if ($arData[$i] =~ /^(\d{4})(\d{2})(\d{2})$/) {
		$arData[$i] = $1.'-'.$2.'-'.$3;
	} elsif ($arData[$i] =~ /^(\d+)\-(\d+)\-(\d+)$/) {
		$arData[$i] = sprintf('%04d-%02d-%02d',$1,$2,$3);
	} else {die "Formato data errato: $arData[$i]\n"};
	$pData = string2date($arData[0]);
}

# definizione cartelle
#----------------------------------------------------------------------------------------------------------------------
my $baseFolder = '/dati/datacollect';
my $dayFolder = $baseFolder."/".$pData->ymd('');

# creazione cartelle locali (se non esistono)
#----------------------------------------------------------------------------------------------------------------------
unless(-e $dayFolder or File::Util->new()->make_dir( $dayFolder)) {
    die "Impossibile creare la cartella $dayFolder: $!\n"
}

$fileName = $pHost.'_'.$pData->ymd('').'_'.substr($pData->ymd(''),2).'_DC.TXT';

if (&connessioneDb) {
	# connessione al database di negozio (ip contenuto nel file configurazione sybase).
	# usare solo IDC al posto di IDC_EOD se la giornata non è chiusa
	$dbh = DBI->connect("DBI:Sybase:server=$host{$pHost}", "mtxadmin", 'mtxadmin');
	die "unable to connect to server $DBI::errstr" unless $dbh;
	
	$dbh->do("use mtx");
	$sth = $dbh->prepare("	select
								REG, STORE, replace(substring(convert(VARCHAR, DDATE, 120),3,8),'-',''), TTIME, SEQUENCENUMBER,
								TRANS, TRANSSTEP, RECORDTYPE, RECORDCODE, USERNO, MISC, DATA
							from IDC_EOD
							where Ddate = ?
							order by ddate, reg, sequencenumber;"); 
	if ($sth->execute($pData->ymd('-'))) {
		my @dc = ();
		while (my @record = $sth->fetchrow_array()) {
			my $REG = $record[0];
			my $STORE = $record[1];
			my $DDATE = $record[2];
			my $TTIME = $record[3];
			my $SEQUENCENUMBER = $record[4];
			my $TRANS = $record[5];
			my $TRANSSTEP = $record[6];
			my $RECORDTYPE = $record[7];
			my $RECORDCODE = $record[8];
			my $USERNO = $record[9];
			my $MISC = $record[10];
			my $DATA = $record[11];
		
			my $MIXED_FIELD = sprintf('%04d',$USERNO).':'.$MISC.$DATA;
		
			if ($RECORDTYPE =~ /z/) {
				if ($MISC =~ /^(..\:)(.*)$/) {
					$MIXED_FIELD = '00'.$1.$2.$DATA.'000';
				}
			}
		
			if ($RECORDTYPE =~ /m/) {
				if ($MISC =~ /^(..\:)(.*)$/) {
					$MIXED_FIELD = '  '.$1.$2.$DATA.'   ';
					if ($MIXED_FIELD =~ /^....:(0492.*)$/) {
						$MIXED_FIELD = '0000:'.$1;
					}
				}
			}
		
			push @dc, sprintf('%04s:%03d:%06s:%06s:%04d:%03d:%1s:%03s:',$STORE,$REG,$DDATE,$TTIME,$TRANS,$TRANSSTEP,$RECORDTYPE,$RECORDCODE).$MIXED_FIELD;
		}
		$sth->finish();
		$dbh->disconnect();
		
		if (@dc) {
			if (open my $fileHandler, "+>:crlf", "$dayFolder/$fileName") {
				for (my $i=0;$i<@dc;$i++) {
					print $fileHandler "$dc[$i]\n";
				}
			 }
		}
	}
} else {
	die "Errore di connessione!\n";
}

exit;

sub connessioneDb {
    # connessione al database archivi
	$dbh = DBI->connect("DBI:mysql:archivi:$hostname", $user, $password);
	if (! $dbh) {
        print "Errore durante la connessione al database `archivi`!\n";
        return 0;
    }
	$sth = $dbh->prepare(qq{select codice, ip_mtx from negozi where societa in ('01','04','31','36')});
	if (!$sth->execute()) {
		print "Errore durante la creazione della tabella negozi! ".$dbh->errstr."\n";
		return 0;
	}
	if ($sth->execute()) {
		while(my @row = $sth->fetchrow_array()) {
			$host{$row[0]} = $row[1].':1433';
		}
	};
	$sth->finish();
	$dbh->disconnect();
	
	return 1;
}

sub string2date { #trasformo una data un oggetto DateTime
	my ($data) = @_;
	
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

