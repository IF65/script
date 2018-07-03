package ITM_lavori;

# by Marco Gnecchi

use Moose;
use DBI; 
use DateTime;
use Log::Log4perl; 

has 'default_starting_date' => (
	is  => 'ro',
	isa => 'DateTime',
	default => sub {DateTime->new(year=>2016, month=>1, day=>1)},
);

#viene eseguita subito dopo che l'oggetto  stato creato
sub BUILD {
    my $self = shift;
	
		if (! $self->_creazione_db()) {
			die "inizializzazione db fallita!\n"
		};
};

# date
#------------------------------------------------------------------------------------------------------------
my $current_date = DateTime->now(time_zone=>'local');
my $current_time = DateTime->now(time_zone=>'local');

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "localhost";
my $username = "root";
my $password = "mela";

# database/tabelle in uso
#------------------------------------------------------------------------------------------------------------
my $db_archivi = 'archivi';
my $tb_negozi = 'negozi';

my $db_controllo = 'controllo';
my $tb_quadrature = 'quadrature';

my $db_lavori = 'lavori';
my $tb_lavori = 'lavori';
my $tb_lavori_societa = 'lavori_societa';
my $tb_lavori_negozi = 'lavori_negozi';
my $tb_incarichi = 'incarichi';

# handler/variabili globali
#------------------------------------------------------------------------------------------------------------
my $sth;
my $dbh;

# ricerca log aperto
my $logger = Log::Log4perl::get_logger("if65log");

sub datacollect_ncr_mtx_ok {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 10, 2);
};

sub datacollect_ncr_mtx_ko {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 10, 0);
};

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

sub distribuzione_riepvegi_brix_ok {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 140, 1);
};

sub distribuzione_riepvegi_brix_ko {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 140, 0);
};

sub distribuzione_extrascanner_ok {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 150, 1);
};

sub distribuzione_extrascanner_ko {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 150, 0);
};

sub calcolo_forme_pagamento_ok {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 160, 1);
};

sub calcolo_forme_pagamento_ko {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 160, 0);
};

sub calcolo_resi_ok {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 170, 1);
};

sub calcolo_resi_ko {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 170, 0);
};

sub cash_ok {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 180, 1);
};

sub cash_ko {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 180, 0);
};

sub caricamento_anagdafi_ok {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 190, 1);
};

sub caricamento_anagdafi_ko {
	my ($self, $data, $negozio) = @_;
	
	return _imposta_incarico($data, $negozio, 190, 0);
};

sub elenco_datacollect_ncr_da_caricare { # lavoro_codice = 10
	my $self = shift;
	
	return $self->_elenco_file_da_caricare(10);
}

sub elenco_journal_da_caricare { # lavoro_codice = 20
	my $self = shift;
	
	return $self->_elenco_file_da_caricare(20);
}

sub elenco_anagdafi_da_caricare { # lavoro_codice = 30
	my $self = shift;
	
	return $self->_elenco_file_da_caricare(30);
}

sub elenco_datacollect_epipoli_da_inviare { # lavoro_codice = 100
	my $self = shift;
	
	return $self->_elenco_file_da_caricare(100);
}

sub elenco_datacollect_catalina_da_inviare { # lavoro_codice = 110
	my $self = shift;
	
	return $self->_elenco_file_da_caricare(110);
}

sub elenco_riepvegi_da_inviare { # lavoro_codice = 120
	my $self = shift;
	
	return $self->_elenco_file_da_caricare(120);
}

sub elenco_riepvegi_da_inviare_ai_negozi { # lavoro_codice = 130
	my $self = shift;
	
	return $self->_elenco_file_da_caricare(130);
}

sub elenco_riepvegi_da_inviare_a_brix { # lavoro_codice = 140
	my $self = shift;
	
	return $self->_elenco_file_da_caricare(140);
}

sub elenco_extrascanner_da_inviare { # lavoro_codice = 150
	my $self = shift;
	
	return $self->_elenco_file_da_caricare(150);
}

sub elenco_forme_pagamento_da_calcolare { # lavoro_codice = 160
	my $self = shift;
	
	return $self->_elenco_file_da_caricare(160);
}

sub elenco_resi_da_calcolare { # lavoro_codice = 170
	my $self = shift;
	
	return $self->_elenco_file_da_caricare(170);
}

sub elenco_cash_da_caricare { # lavoro_codice = 180
	my $self = shift;
	
	return $self->_elenco_file_da_caricare(180);
}

sub elenco_caricamento_anagdafi_da_caricare { # lavoro_codice = 190 <--anagdafi che vanno in tabella
	my $self = shift;
	
	return $self->_elenco_file_da_caricare(190);
}


sub elenco_datacollect_ncr_da_caricare_mtx { 
	my ($self) = @_;
	
	my $starting_date = $self->default_starting_date->ymd('-');
	
	my @codice = ();
	my @data = ();
	my @ip_mtx = ();
	$sth = $dbh->prepare(qq{
							select i.`negozio_codice`, i.`data`,concat(n.`ip_mtx`,':1433')
							from lavori.incarichi as i join archivi.negozi as n on i.`negozio_codice`=n.`codice`
							where i.`lavoro_codice`= 10 and i.`eseguito`=0 and i.`annullato`=0 and i.`data` >= '$starting_date'
							order by i.`negozio_codice`;
						});
	
	if ($sth->execute()) {
		while (my @row = $sth->fetchrow_array()) {
			push @codice, $row[0];
			push @data, $row[1];
			push @ip_mtx, $row[2];
		}
	};
	
	$sth->finish();
	
	return (\@codice, \@data, \@ip_mtx);
}

sub _elenco_file_da_caricare { 
	my ($self, $lavoro_codice) = @_;
	
	my $starting_date = $self->default_starting_date->ymd('-');
	
	my @codice = ();
	my @ip = ();
	my @utente = ();
	my @password = ();
	my @percorso = ();
	$sth = $dbh->prepare(qq{
							select distinct i.`negozio_codice`,n.`ip`,n.`utente`,n.`password`,n.`percorso`
							from lavori.incarichi as i join archivi.negozi as n on i.`negozio_codice`=n.`codice`
							where i.`lavoro_codice`= ? and i.`eseguito`=0 and i.`annullato`=0 and i.`data` >= '$starting_date'
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
							where `lavoro_codice`= ? and `eseguito`=0 and `annullato`=0 and `data` >= '$starting_date'
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
						`data_inizio` date not null default '$starting_date',
						`data_fine` date default null,
						`attivo` tinyint(3) unsigned not null default '1',
					primary key (`lavoro_codice`)) engine=innodb auto_increment=1 default charset=latin1;
					})
		or return 0;
		
		#creo la tabella di `$db_lavori`.`$tb_lavori_societa` se non esiste
		$logger->info("creazione/verifica tabella `$db_lavori`.`$tb_lavori_negozi`");
		$dbh->do(qq{
					create table if not exists `$db_lavori`.`$tb_lavori_societa` (
						  `societa_codice` varchar(2) NOT NULL DEFAULT '',
						  `societa_descrizione` varchar(100) NOT NULL DEFAULT '',
						  `lavoro_codice` smallint(6) NOT NULL,
						  `lavoro_descrizione` varchar(100) NOT NULL DEFAULT ''
						) ENGINE=InnoDB DEFAULT CHARSET=latin1;
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
						`data_inizio` date not null default '$starting_date',
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
					key `esecuzione` (`data`,`eseguito`,`annullato`)) engine=innodb default charset=latin1;
					})
		or return 0;

		$logger->info("creazione dei record della tabella `$db_lavori`.`$tb_lavori_negozi`");
		$dbh->do(qq{
					select	n.codice `negozio_codice`, 
						n.negozio_descrizione, 
						s.`lavoro_codice`, 
						l.`lavoro_descrizione`, 
						case when l.`data_inizio`<=n.data_inizio then n.data_inizio else l.`data_inizio` end as `data_inizio`,
						case when l.`data_fine` is null and n.data_fine is null then null else 
							case when ifnull(l.`data_fine`,'2099-12-31')<=ifnull(n.data_fine,'2099-12-31') then 
								ifnull(l.`data_fine`,'2099-12-31')
							else 
								ifnull(n.data_fine,'2099-12-31') 
							end
						end as `data_fine`,
						n.abilita `attivo`
					from `lavori`.`lavori_societa` as s join (select n.societa, n.codice, n.negozio_descrizione, n.data_inizio, data_fine, n.abilita, n.invio_dati_gre, n.invio_dati_copre, n.invio_giacenze_copre, n.invio_giacenze_gre from `archivi`.`negozi` as n) as n on n.societa=s.societa_codice join `lavori`.`lavori` as l on l.`lavoro_codice`=s.`lavoro_codice`
					where (n.societa = '08' and s.`lavoro_codice` = 200 and  n.invio_dati_copre=1) or (n.societa = '08' and s.`lavoro_codice` = 210 and  n.invio_dati_gre=1) or (n.societa = '08' and s.`lavoro_codice` = 220 and  n.invio_giacenze_copre=1) or (n.societa = '08' and s.`lavoro_codice` = 230 and  n.invio_giacenze_gre=1) or (s.`lavoro_codice` not in (200,210,220,230))
					having (`data_fine` is null or `data_fine`>=`data_inizio`) and `data_inizio`<=current_date()
					order by 1,3;})
		or return 0;
		
		$logger->info("update dei record `$db_lavori`.`$tb_lavori_negozi`");
		$dbh->do(qq{
					update `$db_lavori`.`$tb_lavori_negozi` as l join `$db_archivi`.`$tb_negozi` as n on l.`negozio_codice`=n.codice 
					set l.`attivo`=case when ifnull(n.`data_fine`,'2099-12-31') < current_date() then 0 else n.`abilita` end, l.`data_fine`=n.`data_fine`
					})
		or return 0;
		
		$logger->info("creazione dei record della tabella `$db_lavori`.`$tb_incarichi`");
		$sth = $dbh->prepare(qq{
								insert ignore 
								into `$db_lavori`.`$tb_incarichi`
								select lneg.`lavoro_codice`,lneg.`lavoro_descrizione`,lneg.`negozio_codice`,lneg.`negozio_descrizione`,?,weekday(?)+1,0,case when lneg.attivo = 1 then 0 else 1 end
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
		
		#confronto la tabella incarichi con la tabella quadrature per eliminare le giornate in cui i negozi erano chiusi
		$logger->info("incrocio della tabella `$db_lavori`.`$tb_incarichi` con la tabella `$db_controllo`.`$tb_quadrature`.");
		$dbh->do(qq{
					update `$db_lavori`.`$tb_incarichi` as i left join `$db_controllo`.`$tb_quadrature` as q on i.`negozio_codice`=q.`negozio` and i.`data`=q.`data`
					set i.`eseguito`=2
					where i.`data` <= (select max(data) from controllo.quadrature where negozio like '01%' or negozio like '04%' or negozio like '31%' or negozio like '36%')  and 
						i.`data` >= '$starting_date' and i.`eseguito`=0 and i.`annullato`=0 and
						(q.`data` is null or q.`totale` = 0);
					})
		or return 0;
		
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

no Moose;

1;
