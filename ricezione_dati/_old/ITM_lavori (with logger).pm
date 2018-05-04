package ITM_lavori;

use Moose;
use DBI; 
use DateTime;

with 'MooseX::Log::Log4perl'; 

has 'default_starting_date' => (
	is  => 'ro',
	isa => 'DateTime',
	default => sub {DateTime->new(year=>2016, month=>1, day=>1)},
);

#viene eseguita subito dopo che l'oggetto  stato creato
sub BUILD {
    my $self = shift;
	
		$self->_creazione_db();
};

#viene eseguita subito prima che l'oggetto sia distrutto
sub DEMOLISH {
		my $self = shift;
		
		$self->_distruzione_db();
}

# date
#------------------------------------------------------------------------------------------------------------
my $current_date 	= DateTime->now(time_zone=>'local');
my $current_time 	= DateTime->now(time_zone=>'local');

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "localhost";
my $username = "root";
my $password = "mela";

# database/tabelle in uso
#------------------------------------------------------------------------------------------------------------
my $db_archivi = 'archivi';
my $tb_negozi = 'negozi';

my $db_lavori = 'lavori';
my $tb_lavori = 'lavori';
my $tb_lavori_negozi = 'lavori_negozi';
my $tb_incarichi = 'incarichi';

# definizione cartelle
#------------------------------------------------------------------------------------------------------------
my $local_log_folder = "/log";
my $log_folder = "$local_log_folder/".substr($current_date->ymd(''),0,6);

# Creazione cartelle locali (se non esistono)
#------------------------------------------------------------------------------------------------------------
unless(-e $local_log_folder or mkdir $local_log_folder) {die "Impossibile creare la cartella $local_log_folder: $!\n";};
unless(-e $log_folder or mkdir $log_folder) {die "Impossibile creare la cartella $log_folder: $!\n";};

# handler/variabili globali
#------------------------------------------------------------------------------------------------------------
my $sth;
my $dbh;

# configurazione log
#------------------------------------------------------------------------------------------------------------
my $configurazione = q(
	log4perl.category.if65log           = INFO, Logfile

	log4perl.appender.Logfile           = Log::Log4perl::Appender::File
	log4perl.appender.Logfile.filename  = sub{ITM_lavori::_log_file_name();};
	log4perl.appender.Logfile.mode      = append
	log4perl.appender.Logfile.layout    = Log::Log4perl::Layout::PatternLayout
	log4perl.appender.Logfile.layout.ConversionPattern = [%d] [%p{3}] %m %n

	log4perl.appender.Screen            = Log::Log4perl::Appender::Screen
	log4perl.appender.Screen.stderr     = 0
	log4perl.appender.Screen.layout    	= Log::Log4perl::Layout::PatternLayout
	log4perl.appender.Screen.layout.ConversionPattern = [%d] [%p{3}] %m %n
);

Log::Log4perl::init( \$configurazione ) or die "configurazione log non riuscita: $!\n";
my $logger = Log::Log4perl::get_logger("if65log");

$logger->info("-" x 76);
$logger->info("lavori");
$logger->info("-" x 76);
$logger->info("inizio");

sub datacollect_ncr_ok {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 10, 1);
};

sub datacollect_ncr_ko {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 10, 0);
};

sub journal_ok {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 20, 1);
};

sub journal_ko {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 20, 0);
};

sub anagdafi_ok {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 30, 1);
};

sub anagdafi_ko {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 30, 0);
};

sub datacollect_epipoli_ok {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 100, 1);
};

sub datacollect_epipoli_ko {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 100, 0);
};

sub datacollect_catalina_ok {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 110, 1);
};

sub datacollect_catalina_ko {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 110, 0);
};

sub invio_riepvegi_ok {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 120, 1);
};

sub invio_riepvegi_ko {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 120, 0);
};

sub distribuzione_riepvegi_ok {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 130, 1);
};

sub distribuzione_riepvegi_ko {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 130, 0);
};

sub elenco_datacollect_ncr_da_caricare { # lavoro_codice = 10
	my $self = shift;
	
	return _elenco_file_da_caricare(10);
}

sub _elenco_file_da_caricare { 
	my ($lavoro_codice) = @_;
	
	my @codice = ();
	my @ip = ();
	my @utente = ();
	my @password = ();
	my @percorso = ();
	$sth = $dbh->prepare(qq{
							select distinct i.`negozio_codice`,n.`ip`,n.`utente`,n.`password`,n.`percorso`
							from lavori.incarichi as i join archivi.negozi as n on i.`negozio_codice`=n.`codice`
							where i.`lavoro_codice`= ? and i.`eseguito`=0 and i.`annullato`=0
							order by i.`negozio_codice`;
						});
	
	if ($sth->execute($lavoro_codice)) {
		while (my @row = $sth->fetchrow_array()) {
			push @codice, $row[0];
			push @ip, $row[1];
			push @utente, $row[2];
			push @password, $row[3];
			push @percorso, $row[4];
		}
	};
	
	my @log_codice = ();
	my @log_data = ();
	$sth = $dbh->prepare(qq{
							select `negozio_codice`,`data`
							from lavori.incarichi
							where `lavoro_codice`= ? and `eseguito`=0 and `annullato`=0
							order by `negozio_codice`,`data`;
						});
	
	if ($sth->execute($lavoro_codice)) {
		while (my @row = $sth->fetchrow_array()) {
			push @log_codice, $row[0];
			push @log_data, $row[1];
		}
	};
	
	$sth->finish();
	
	return (\@log_codice, \@log_data, \@codice, \@ip, \@utente, \@password, \@percorso);
}

sub _creazione_db {
		my $self = shift;
		
		my %attributes = (
							PrintWarn => 0,
							PrintError => 0,
							RaiseError => 1,
							HandleError => \&_dbi_error_handler,
							ShowErrorStatement => 1,
					);
		
		# creazione dell'ambiente di lavoro
		#--------------------------------------------------------------------------------------------------------
		# connessione al database di default
		$logger->info("connessione a MySql");
		$dbh = DBI->connect("DBI:mysql:mysql:$hostname", $username, $password, \%attributes);
		if (! $dbh) {
				return 0;
		}

		# creazione/verifica del database `$db_archivi`
		$logger->info("creazione/verifica del database `$db_archivi`");
		$dbh->do(qq{create database if not exists `$db_archivi` default character set = latin1	default collate = latin1_swedish_ci})
		or return 0;

		#creo la tabella di `$db_archivi`.`$tb_negozi` se non esiste
		$logger->info("creazione/verifica tabella `$db_archivi`.`.$tb_negozi`");
		$dbh->do(qq{
					create table if not exists `$db_archivi`.`$tb_negozi` (
						`codice` varchar(4) not null default '',
						`codice_interno` varchar(4) not null,
						`societa` varchar(2) not null,
						`societa_descrizione` varchar(100) not null default '',
						`negozio` varchar(2) not null,
						`negozio_descrizione` varchar(100) not null default '',
						`tipo` tinyint(1) not null default '3' comment '1=sede, 2=magazzino, 3=vendita',
						`ip` varchar(15) not null,
						`ip_mtx` varchar(15) not null,
						`utente` varchar(50) not null,
						`password` varchar(50) not null,
						`percorso` varchar(255) not null,
						`data_inizio` date default null,
						`data_fine` date default null,
						`abilita` tinyint(1) not null default '1',
						`recupero_anagdafi` tinyint(1) not null default '0',
						`invio_dati_gre` tinyint(1) not null default '0',
						`invio_dati_copre` tinyint(1) not null default '0',
						`codice_ca` varchar(10) not null default '',
					primary key (`codice`)) engine=innodb default charset=latin1;
					})
		or return 0;

		# creazione/verifica del database `$db_lavori`
		$logger->info("creazione/verifica del database `$db_lavori`");
		$dbh->do(qq{
					create database if not exists `$db_lavori`
					default character set = latin1
					default collate       = latin1_swedish_ci
					})
		or return 0;

		#creo la tabella di `$db_lavori`.`$tb_lavori` se non esiste
		$logger->info("creazione/verifica tabella `$db_lavori`.`$tb_lavori`");
		$dbh->do(qq{
					create table if not exists `$db_lavori`.`$tb_lavori` (
						`lavoro_codice` smallint(11) unsigned not null auto_increment,
						`lavoro_descrizione` varchar(100) not null default '',
						`data_inizio` date not null default '2015-01-01',
						`data_fine` date default null,
						`attivo` tinyint(3) unsigned not null default '1',
					primary key (`lavoro_codice`)) engine=innodb auto_increment=1 default charset=latin1;
					})
		or return 0;
		
		#creo la tabella di `$db_lavori`.`$tb_lavori_negozi` se non esiste
		$logger->info("creazione/verifica tabella `$db_lavori`.`$tb_lavori_negozi`");
		$dbh->do(qq{
					create table if not exists `$db_lavori`.`$tb_lavori_negozi` (
						`negozio_codice` varchar(4) not null default '',
						`negozio_descrizione` varchar(100) not null default '',
						`lavoro_codice` smallint(11) not null,
						`lavoro_descrizione` varchar(100) not null default '',
						`data_inizio` date not null default '2015-01-01',
						`data_fine` date default null,
						`attivo` tinyint(3) unsigned not null default '0',
					primary key (`negozio_codice`,`lavoro_codice`)) engine=innodb default charset=latin1;
					})
		or return 0;
		
		#creo la tabella di `$db_lavori`.`$tb_incarichi` se non esiste
		$logger->info("creazione/verifica tabella `$db_lavori`.`$tb_incarichi`");
		$dbh->do(qq{
					create table if not exists `$db_lavori`.`$tb_incarichi` (
							`lavoro_codice` smallint(11) unsigned not null,
							`lavoro_descrizione` varchar(100) not null default '',
							`negozio_codice` varchar(4) not null default '',
							`negozio_descrizione` varchar(100) not null default '',
							`data` date not null,
							`giorno` tinyint(1) unsigned not null default '1',
							`eseguito` tinyint(1) unsigned not null default '0',
							`annullato` tinyint(1) unsigned not null default '0',
					primary key (`lavoro_codice`,`negozio_codice`,`data`),
					key `esecuzione` (`eseguito`,`annullato`)) engine=innodb default charset=latin1;
					})
		or return 0;

		$logger->info("creazione dei record della tabella `$db_lavori`.`$tb_lavori_negozi`");
		$dbh->do(qq{
					insert ignore 
					into `$db_lavori`.`$tb_lavori_negozi`
					select 
						n.`codice`,
						n.`negozio_descrizione`,
						l.`lavoro_codice`,
						l.`lavoro_descrizione`,
						case when n.`data_inizio`<l.`data_inizio` then l.`data_inizio` else n.`data_inizio` end `data_inizo`,
						case when ifnull(n.`data_fine`,'2099-12-31') <= ifnull(l.`data_fine`,'2099-12-31') then n.`data_fine` else l.`data_fine` end `data_fine`,
						1
					from `$db_archivi`.`$tb_negozi` as n join `$db_lavori`.`$tb_lavori` as l 
					where (n.`data_fine` is null or (n.`data_fine` is not null and n.`data_fine` >= l.`data_inizio`)) and n.`societa` in ('01','31','36')
					order by 1,3;
					})
		or return 0;
		
		$logger->info("creazione dei record della tabella `$db_lavori`.`$tb_incarichi`");
		$sth = $dbh->prepare(qq{
								insert ignore 
								into `$db_lavori`.`$tb_incarichi`
								select lneg.`lavoro_codice`,lneg.`lavoro_descrizione`,lneg.`negozio_codice`,lneg.`negozio_descrizione`,?,weekday(?)+1,0,0
								from `$db_lavori`.`$tb_lavori_negozi` as lneg
								where lneg.`data_inizio`<=? and ifnull(lneg.`data_fine`,'2099-12-31')>=?;
								});
		if ($sth->execute()) {
				my $data = $self->default_starting_date->clone();
				while (DateTime->compare($data, $current_date)<0) {
						if (! $sth->execute($data->ymd('-'), $data->ymd('-'), $data->ymd('-'), $data->ymd('-'))) {
								return 0;
						}
						$data->add(days => 1);
				}
		}
		$sth->finish();

		return 1;
}
sub _dbi_error_handler { 
	my($message, $handle, $first_value) = @_;

	foreach	($message =~ m/(.{1,255})/g) {$logger->error($_)}

	return 1;
}

sub _imposta_incarico {
	my ($data, $negozio, $incarico, $valore) = @_;
	$sth = $dbh->prepare(qq{
							update`$db_lavori`.`$tb_incarichi`
							set `eseguito` = ? 
							where `data`<= ? and `negozio_codice`= ? and `lavoro_codice`= ?;
							});
	if (! $sth->execute($valore, $data, $negozio, $incarico)) {
			return 0;
	}
	return 1;
}
sub _log_file_name{
	my $self = shift;

	return "$log_folder/".$current_date->ymd('').'_'.$current_time->hms('')."_creazione_lavori.log";
}

sub _distruzione_db {
	my $self = shift;
	
	$dbh->disconnect;
	
	$logger->info("disconnessione da MySql");
	$logger->info("fine");
	$logger->info("-" x 76);
}

no Moose;

1;