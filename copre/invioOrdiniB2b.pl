#!/usr/bin/perl
use strict;
use warnings;

use lib '/root/perl5/lib/perl5';

use DBI;
use REST::Client;
use DateTime;
use POSIX;
use JSON;
use Log::Log4perl;

# data e ora di caricamento dei dati
#------------------------------------------------------------------------------------------------------------
my $currentDate = DateTime->now(time_zone=>'local');
my $currentTime 	= DateTime->now(time_zone=>'local');
my $timestamp   = $currentDate->ymd().' '.$currentDate->hms();
my $data        = $currentDate->ymd('-');

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "10.11.14.78";
my $username = "root";
my $password = "mela";

# parametri di chiamata al server REST
#------------------------------------------------------------------------------------------------------------
my $requestUrl =  'http://11.0.1.31:8080/b2b';

# configurazione log
#------------------------------------------------------------------------------------------------------------
my $mainLogFolder = "/log";
my $logFolder = "$mainLogFolder/".substr($currentDate->ymd(''),0,6);

unless(-e $mainLogFolder or mkdir $mainLogFolder) {die "Impossibile creare la cartella $mainLogFolder: $!\n";};
unless(-e $logFolder or mkdir $logFolder) {die "Impossibile creare la cartella $logFolder: $!\n";};

my $configurazione = q(
    log4perl.category.if65log            = DEBUG, Logfile

    log4perl.appender.Logfile           = Log::Log4perl::Appender::File
    log4perl.appender.Logfile.filename  = sub{log_file_name();};
    log4perl.appender.Logfile.mode      = append
    log4perl.appender.Logfile.layout    = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Logfile.layout.ConversionPattern = [%d] [%p{3}] %m %n

    log4perl.appender.Screen            = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr     = 0
    log4perl.appender.Screen.layout    = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Screen.layout.ConversionPattern = [%d] [%p{3}] %m %n
);

Log::Log4perl::init( \$configurazione ) or die "configurazione log non riuscita: $!\n";
my $logger = Log::Log4perl::get_logger("if65log");

$logger->info("-" x 76);
$logger->info("invio Ordini B2B -> 4D");
$logger->info("-" x 76);
$logger->info("inizio");

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $json;
my @ordiniDaInviare = ();

if (&ConnessioneDB) {
	if (@ordiniDaInviare > 0) {
		$logger->info("INVIO ORDINI 4D: ci sono @ordiniDaInviare ordini da inviare.");

		my $client = REST::Client->new();

		# nel caso di collegamento https non verifico il certificato
		$client->getUseragent()->ssl_opts(verify_hostname => 0);

		my $datiRicevuti = $client->POST($requestUrl, $json, {'Content-type' => 'application/json', 'funzione' => 'caricamentoOrdini'})->responseContent;

		if ( $client->responseCode() eq '200' ) {
			$sth = $dbh->prepare(qq{update ordiniTestata set id4D = ? where codiceCliente = ? and riferimento = ?});

			my $jsonObj = new JSON;
			my $response = $jsonObj->decode(qq{$datiRicevuti}); #pretty->
			my $recordCount = $response->{'recordCount'};
			for (my $i=0;$i<$recordCount;$i++) {
				my $codiceCliente = $response->{'records'}[$i]->{'codiceCliente'};
				my $riferimento = $response->{'records'}[$i]->{'riferimento'};
				my $numero = $response->{'records'}[$i]->{'numero'};
				my $stato = $response->{'records'}[$i]->{'stato'};

				if ($stato eq 'ok') {
					$sth->execute($numero, $codiceCliente, $riferimento) or die "Errore di update";
					$logger->info("INVIO ORDINI 4D: l\'ordine $numero, $codiceCliente - $riferimento è stato inviato.");
				} else {
					$logger->warn("INVIO ORDINI 4D: l\'ordine $numero, $codiceCliente - $riferimento non è stato caricato.");
				}
			}
			$sth->finish();
		}
	} else {
		$logger->warn("INVIO ORDINI 4D: non ci sono ordini da inviare.");
	}
}

sub ConnessioneDB {
	# connessione al database
	$dbh = DBI->connect("DBI:mysql:copre:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database!\n";
		return 0;
	}

	# caricamento dettaglio ordine
    my $sthDettaglio = $dbh->prepare(qq{select  r.codiceArticolo, t.`barcode`, t.`descrizione`, t.`marchioCopre`, t.`modello`, t.`nettoNetto`,
                                        t.`prezzoAcquisto`, r.numeroRiga, r.quantita, r.prezzo, t.`inOrdine`, t.`giacenza`
                                        from ordiniRighe as r join tabulatoCopre as t on r.`codiceArticolo`=t.`codice`
                                        where r.codiceCliente = ? and r.riferimento = ?});

    # cerco gli ordini da inviare a SM
    $sth = $dbh->prepare(qq{select codiceCliente, riferimento, tipo, data, codiceVettore, numeroRighe, valoreContrassegno,
                            destinatario, indirizzo, cap, localita, provincia, telefono, note, id4D
                            from ordiniTestata where id4D = 0});
    if ($sth->execute()) {
		while(my @row = $sth->fetchrow_array()) {
			my %ordine = ();
			$ordine{'codiceCliente'}=$row[0];
			$ordine{'riferimento'}=$row[1];
			$ordine{'tipo'}=$row[2];
			$ordine{'data'}=$row[3].'T00:00:00';
			$ordine{'codiceVettore'}=$row[4];
			$ordine{'numeroRighe'}=$row[5]*1;
			$ordine{'valoreContrassegno'}=$row[6];
			$ordine{'destinatario'}=$row[7];
			$ordine{'indirizzo'}=$row[8];
			$ordine{'cap'}=$row[9];
			$ordine{'localita'}=$row[10];
			$ordine{'provincia'}=$row[11];
			$ordine{'telefono'}=$row[12];
			$ordine{'note'}=$row[13];
			$ordine{'id4D'}=$row[14] * 1;

			my @righe = ();
			if ($sthDettaglio->execute($ordine{'codiceCliente'},$ordine{'riferimento'})) {
				while(my @row = $sthDettaglio->fetchrow_array()) {
					my %righeOrdine = ();

                    $righeOrdine{'codiceArticolo'}=$row[0];
                    $righeOrdine{'barcode'}=$row[1];
                    $righeOrdine{'descrizione'}=$row[2];
                    $righeOrdine{'marchio'}=$row[3];
                    $righeOrdine{'modello'}=$row[4];
                    $righeOrdine{'nettoNetto'}=$row[5]*1;
                    $righeOrdine{'prezzoAcquisto'}=$row[6]*1;
                    $righeOrdine{'numeroRiga'}=$row[7]*1;
                    $righeOrdine{'quantita'}=$row[8]*1;
                    $righeOrdine{'prezzo'}=$row[9]*1;
                    $righeOrdine{'inOrdine'}=$row[10]*1;
                    $righeOrdine{'giacenza'}=$row[11]*1;

					push(@righe, \%righeOrdine);
				}
				$sthDettaglio->finish();
			}
			$ordine{'righe'} = \@righe;

			push(@ordiniDaInviare, \%ordine);
		}
		$sth->finish();

		my $jsonObj = new JSON;
		$json = $jsonObj->encode({'recordCount' => scalar @ordiniDaInviare, 'records' => \@ordiniDaInviare}); #pretty->
	}

    return 1;
}

sub ltrim { my $s = shift; $s =~ s/^\s+//; return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//; return $s };
sub trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };

sub log_file_name{
    return "$logFolder/".$currentDate->ymd('').'_'.$currentTime->hms('')."_invio_4d.log";
}
