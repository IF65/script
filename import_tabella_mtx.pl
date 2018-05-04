#!/usr/bin/perl

use DBI;
use Getopt::Long;

my @ar_host;
my @ar_data;
GetOptions(
	'h=s{1,1}'	=> \@ar_host,
	'd=s{1,1}'	=> \@ar_data,
) or die "Uso errato!\n";

my $var_host = '';
if (@ar_host > 0) {
	if ($ar_host[0] !~ /^\d{4}$/) {
		die "Codice host errato: $ar_host[0]\n";
	}
	$var_host = $ar_host[0];
}

my $var_data = '';
for (my $i=0;$i<@ar_data;$i++) {
	$ar_data[$i] =~ s/[^\d\-]/\-/ig;
	if ($ar_data[$i] =~ /^(\d{4})(\d{2})(\d{2})$/) {
		$ar_data[$i] = $1.'-'.$2.'-'.$3;
	} elsif ($ar_data[$i] =~ /^(\d+)\-(\d+)\-(\d+)$/) {
		$ar_data[$i] = sprintf('%04d-%02d-%02d',$1,$2,$3);
	} else {die "Formato data errato: $ar_data[$i]\n"};
	$var_data = $ar_data[0];
}

my $dsn = '';
$dbh = DBI->connect("DBI:mysql:mysql:$hostname", 'root', 'mela');
die "unable to connect to server $DBI::errstr" unless $dbh;
$sth = $dbh->prepare(qq{select ip_mtx from archivi.negozi where codice = $var_host});
if (!$sth->execute()) {
	print "Errore durante la creazione della tabella negozi! " .$dbh->errstr."\n";
	return 0;
}
if ($sth->execute()) {while(my @row = $sth->fetchrow_array()) {$dsn = $row[0].':1433'}};
$sth->finish();

my $dbh = DBI->connect("DBI:Sybase:server=$dsn", "mtxadmin", 'mtxadmin');
die "unable to connect to server $DBI::errstr" unless $dbh;

$dbh->do("use mtx");

$query = "SELECT 
			REG, 
			STORE, 
			replace(substring(convert(VARCHAR, DDATE, 120),3,8),'-',''), 
			TTIME, 
			SEQUENCENUMBER, 
			TRANS, 
			TRANSSTEP, 
			RECORDTYPE, 
			RECORDCODE,
			USERNO,
			MISC,
			DATA
		from IDC_EOD
		where Ddate = '$var_data' 
		order by ddate, reg, sequencenumber";
$sth = $dbh->prepare ($query) or die "prepare failed\n";
$sth->execute( ) or die "unable to execute query $query   error $DBI::errstr";
# usare solo IDC al posto di IDC_EOD se la giornata non è chiusa <=====================================

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
	
	print sprintf('%04s:%03d:%06s:%06s:%04d:%03d:%1s:%03s:',$STORE,$REG,$DDATE,$TTIME,$TRANS,$TRANSSTEP,$RECORDTYPE,$RECORDCODE).$MIXED_FIELD."\r\n";
}
