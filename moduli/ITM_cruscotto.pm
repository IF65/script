package ITM_cruscotto;

use Moose;
use DBI; 
use DateTime;
use Log::Log4perl; 

has 'default_starting_date' => (
	is  => 'ro',
	isa => 'DateTime',
	default => sub {DateTime->new(year=>2017, month=>4, day=>1)},
);

#viene eseguita subito dopo che l'oggetto  stato creato
sub BUILD {
    my $self = shift;
	
		if (! $self->_apertura_db()) {
			die "collegamento ai db fallito!\n"
		};
};

# date
#------------------------------------------------------------------------------------------------------------
my $current_date = DateTime->now(time_zone=>'local');
my $current_time = DateTime->now(time_zone=>'local');

# parametri di collegamento a mysql delle macchine da tenere sotto controllo
#------------------------------------------------------------------------------------------------------------
my $src_hostname = "10.11.14.154";
my $src_username = "cedadmin";
my $src_password = "ced";

my $itm_hostname = "10.11.14.78";
my $itm_username = "root";
my $itm_password = "mela";

my $if_hostname = "10.11.14.76";
my $if_username = "root";
my $if_password = "mela";

# database/tabelle in uso
#------------------------------------------------------------------------------------------------------------


# handler/variabili globali
#------------------------------------------------------------------------------------------------------------
my $sth;
my $dbh_src;
my $dbh_itm;
my $dbh_if;

# ricerca log aperto
my $logger = Log::Log4perl::get_logger("if65_cruscotto");

sub _apertura_db {
		my $self = shift;
		
		my $starting_date = $self->default_starting_date->ymd('-'); 
		
		my %attributes = (
							PrintWarn => 0,
							PrintError => 0,
							RaiseError => 1,
							HandleError => \&_dbi_error_handler,
							ShowErrorStatement => 1,
					);
		
		# creazione dell'ambiente di lavoro
		#--------------------------------------------------------------------------------------------------------
		# connessione ai database di default
		$logger->info("tentativo di connessione a MySql($src_hostname)");
		$dbh_src = DBI->connect("DBI:mysql:mysql:$src_hostname", $src_username, $src_password, \%attributes);
		if (! $dbh_src) {
				$logger->error("connessione a MySql $src_hostname");
				return 0;
		}
		$logger->info("connessione a MySql($src_hostname) avvenuta con successo");
		$logger->info("");
		
		$logger->info("tentativo di connessione a MySql($itm_hostname)");
		$dbh_itm = DBI->connect("DBI:mysql:mysql:$itm_hostname", $itm_username, $itm_password, \%attributes);
		if (! $dbh_itm) {
				$logger->error("connessione a MySql $itm_hostname");
				return 0;
		}
		$logger->info("connessione a MySql($if_hostname) avvenuta con successo");
		$logger->info("");
		
		$logger->info("tentativo di connessione a MySql($if_hostname)");
		$dbh_if = DBI->connect("DBI:mysql:mysql:$if_hostname", $if_username, $if_password, \%attributes);
		if (! $dbh_if) {
				$logger->error("connessione a MySql $if_hostname");
				return 0;
		}
		$logger->info("connessione a MySql($if_hostname) avvenuta con successo");
		$logger->info("");
		
		return 1;
}


sub esito_caricamento_dettagliato {
	my($self, $societa) = @_;
	
	my @data = ();
	my @negozio = ();
	my @negozio_descrizione = ();
	my @buoni = ();
	my @totale = ();
	my @delta = ();
	my @dc_presente = ();
	$sth = $dbh_itm->prepare(qq{
								select	q.`data`, q.`negozio`, n.`negozio_descrizione`, q.`buoni`, q.`totale`, round(q.`totale`+q.`buoni`-ifnull(l.`totale`,0),2) as delta,
										case when l.`totale` is null then 0 else 1 end from controllo.quadrature as q left join controllo.totali_lrp as l
										on q.`data`=l.`data` and q.`negozio`=
										case when substr(l.`negozio`,1,2)='51' then	concat('53',substr(l.`negozio`,3)) else	l.`negozio` end
										left join archivi.negozi as n on q.`negozio`=n.`codice`
										where q.`negozio` like concat(?,'%') and q.`data`>= ? 
										having delta <> 0
										order by q.`negozio`, q.`data`;
								});
	if ($sth->execute($societa, $self->default_starting_date->ymd('-'))) {
		while (my @row = $sth->fetchrow_array()) {
			push @data, string2date($row[0])->iso8601();
			push @negozio, $row[1];
			push @negozio_descrizione, $row[2];
			push @buoni, $row[3];
			push @totale, $row[4];
			push @delta, $row[5];
			push @dc_presente, $row[6];
		}
	};
	
	$sth->finish();
	
	return (\@data, \@negozio, \@negozio_descrizione, \@buoni, \@totale, \@delta, \@dc_presente);
}


sub dc_mancanti_totale {
	my($self, $societa) = @_;
	
	my $numero = 0;
	my $totale = 0;
	$sth = $dbh_itm->prepare(qq{
								select ifnull(sum(case when q.`totale`-ifnull(l.`totale`,0)<>0 then 1 else 0 end),0), ifnull(sum(q.`totale`-ifnull(l.`totale`,0)),0)
								from controllo.quadrature as q left join controllo.totali_lrp as l on q.`data`=l.`data` and q.`negozio`=
								case when substr(l.`negozio`,1,2)='51' then	concat('53',substr(l.`negozio`,3)) else	l.`negozio` end
								left join archivi.negozi as n on q.`negozio`=n.`codice`
								where l.`totale` is null and q.`negozio` like concat(?,'%') and q.`data`>= ?
							 });
	
	if ($sth->execute($societa, $self->default_starting_date->ymd('-'))) {
		if (my @row = $sth->fetchrow_array()) {
			$numero = $row[0];
			$totale = $row[1];
		}
	};
	
	$sth->finish();
	
	return \$numero, \$totale;
}

sub dc_differenze_totale {
	my($self, $societa) = @_;
	
	my $numero = 0;
	my $totale = 0;
	$sth = $dbh_itm->prepare(qq{
								select	ifnull(sum(case when round(q.`totale`+q.`buoni`-ifnull(l.`totale`,0),2)<>0 then 1 else 0 end),0), ifnull(sum(round(q.`totale`+q.`buoni`-ifnull(l.`totale`,0),2)),0)
								from controllo.quadrature as q left join controllo.totali_lrp as l on q.`data`=l.`data` and q.`negozio`=
								case when substr(l.`negozio`,1,2)='51' then	concat('53',substr(l.`negozio`,3)) else	l.`negozio` end
								left join archivi.negozi as n on q.`negozio`=n.`codice`
								where l.`totale` is not null and round(q.`totale`+q.`buoni`,2)<> l.`totale` and q.`negozio` like concat(?,'%') and q.`data`>= ?
							 });
	
	if ($sth->execute($societa, $self->default_starting_date->ymd('-'))) {
		if (my @row = $sth->fetchrow_array()) {
			$numero = $row[0];
			$totale = $row[1];
		}
	};
	
	$sth->finish();
	
	return \$numero, \$totale;
}


sub string2date { #trasformo una data in un oggetto DateTime
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

sub _dbi_error_handler { 
	my($message, $handle, $first_value) = @_;

	foreach	($message =~ m/(.{1,255})/g) {$logger->error($_)}

	return 1;
}


no Moose;

1;
