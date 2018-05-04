#!/usr/bin/perl -w
use strict;
use DBI;
use File::HomeDir;
use Getopt::Long;
use Net::FTP;
use DateTime;
use Log::Log4perl;

# parametri database
#----------------------------------------------------------------------------------------------------------------------
my $hostname = '10.11.14.76';
my $username = 'root';
my $password = 'mela';
my $database = 'archivi';
my $table = 'riepvegi';

my $lavori_hostname = '10.11.14.78';
my $lavori_username = 'root';
my $lavori_password = 'mela';
my $lavori_database = 'lavori';
my $lavori_table = 'incarichi';

my $ftp_url = '10.0.4.81:9037';
my $ftp_user = '/g7/gcos7';
my $ftp_password = 'g7';

# date
#------------------------------------------------------------------------------------------------------------
my $current_date 	= DateTime->now(time_zone=>'local');

# definizione cartelle
#----------------------------------------------------------------------------------------------------------------------
my $desktop = File::HomeDir->my_desktop;
my $local_log_folder = "/log";
my $log_folder = "$local_log_folder/".substr($current_date->ymd(''),0,6);

# Creazione cartelle locali (se non esistono)
#----------------------------------------------------------------------------------------------------------------------
unless (-e $local_log_folder or mkdir $local_log_folder) {die "Impossibile creare la cartella $local_log_folder: $!\n";};
unless (-e $log_folder or mkdir $log_folder) {die "Impossibile creare la cartella $log_folder: $!\n";};

# configurazione log
#----------------------------------------------------------------------------------------------------------------------
my $configurazione = q(
    log4perl.category.if65log            = DEBUG, Logfile ,Screen

    log4perl.appender.Logfile           = Log::Log4perl::Appender::File
    log4perl.appender.Logfile.filename  = sub{log_file_name();};
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
$logger->info("invio scarmene a Bull");
$logger->info("-" x 76);
$logger->info("inizio elaborazione");
$logger->info("");

# handler
#----------------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sth_elenco_societa;
my $sth_elenco_negozi;
my $sth_elenco_filiali;
my $dbh_lavori;
my $sth_lavori;
my $ftph;

# gestione società e filiali trattabili
#----------------------------------------------------------------------------------------------------------------------
my @elenco_societa_food;
my $senza_negozi_in_input=1;

# parametri da linea di comando
#----------------------------------------------------------------------------------------------------------------------
my $sede;
my $data_inizio;
my $data_fine;


my %elenco_filiali;


my @elenco_negozi;
my @ar_data;
my $export_folder = "$desktop/SCM_EXPORT_".DateTime->now(time_zone=>'local')->ymd('').'_'.DateTime->now(time_zone=>'local')->hms('');
my $ftp;
my $delete;
my $flag;
my $help;
if (@ARGV == 0) {
    $help = 1
}

GetOptions(
	's=s{,}'	=> \@elenco_negozi,
	'd=s{1,2}'	=> \@ar_data,
    'f=s{,1}'	=> \$export_folder,
	'ftp'       => \$ftp,
    'delete'    => \$delete,
    'flag'      => \$flag,
    'help'      => \$help,
) or die "parametri non corretti!\n";

if ($help) {
    print "Utilizzo: perl [path]scm2bull.pl -d yyyy-mm-dd [yyyy-mm-dd] [-s ssnn [ssnn [ssnn....[....]]]] [--ftp] [--flag] [--delete] [--help]\n\n";
    print "significato:     -d           data_iniziale [data_finale] se le date sono diverse viene considerato tutto il periodo, date comprese,\n";
    print "                              altrimenti, se la data e\' una sola o le due date coincidono, solo il giorno indicato dalla data iniziale.\n";
    print "                 -s           sedi nella forma ssnn (Es.0171); puo\' essere fornito un qualsiasi elenco di sedi ma le societa\' ammesse\n";
    print "                              sono solo 01, 30, 31 e 36 se nessuna sede e\' indicata e/o l'opzione e\' mancante si considerano tutte le\n";
    print "                              sedi presenti nella giornata.\n";
    print "                --ftp         invia in FTP i file trattati.\n";
    print "                --delete      elimina i file inviati dopo l'invio in FTP; non ha senso se non c'e\' invio FTP.\n";
    print "                --flag        imposta i flag nel db lavori dopo l'invio in FTP; non ha senso se non c'e\' invio FTP.\n";
    print "                --help        mostra queste istruzioni.\n";
    print "	\n";
    print "Esempio di lancio: perl scm2bull.pl -d 2016-05-08 2016-05-09 -s 0101 0102 --ftp --delete\n";
    die "\n";
}

# se non c'è ftp le 2 opzioni non hanno senso
if (! $ftp) {
   $flag = 0;
   $delete = 0;
}

# Verifica date in input
if (@ar_data) {
    #se la data di fine periodo non è definita verrà considerata identica alla data di inizio
    for (my $i=0;$i<@ar_data;$i++) { 
        $ar_data[$i] =~ s/[^\d\-]/\-/ig;
        if ($ar_data[$i] =~ /^(\d{4})(\d{2})(\d{2})$/) {
                $ar_data[$i] = $1.'-'.$2.'-'.$3;
        } elsif ($ar_data[$i] =~ /^(\d{1,4})(?:\-|\/)(\d{1,2})(?:\-|\/)(\d{1,2})$/) {
                $ar_data[$i] = sprintf('%04d-%02d-%02d',$1,$2,$3);
        } else {
            $logger->fatal("Formato data errato: $ar_data[$i]") && chiusura_log() && die "\n";
        }
        $data_inizio = string2date($ar_data[0]);
        $data_fine = $data_inizio;
        if (@ar_data > 1) {
            $data_fine = string2date($ar_data[1]);
        }
    }
} else {$logger->fatal("almeno una data è obbligatoria!") && chiusura_log() && die "\n"}


#cerco in anagrafica le società i cui negozi sono trattabili
if (&ConnessioneDB_lavori) {   
    $logger->info("connessione db $lavori_database avvenuta con successo.");
     if ($sth_elenco_societa->execute()) {
        while(my @row = $sth_elenco_societa->fetchrow_array()) {
            push @elenco_societa_food, $row[0];
        }
    }
    else {$logger->fatal("Societa Food non rilevate") && chiusura_log() && die "\n"};

# Creo un Hash in cui la chiave e' il codice filiale e l'elemento contiene un hash di tante chiavi quanti sono i campi che voglio memorizzare 
# (in questo caso 3): apertura, chiusura e ragsoc. Praticamente è come se il primo hash fosse il primo livello di una file description
# e l'hash in esso contenuto il secondo livello in cui la chiave è il nome campo ed il valore rappresenta il contenuto del campo. 
	if ($sth_elenco_filiali->execute()) {
        while(my @row = $sth_elenco_filiali->fetchrow_array()) {
        	$elenco_filiali{$row[0]} = {'apertura' => $row[1], 'chiusura' => $row[2], 'descrizione' => $row[3]}
        }
    }
    else {$logger->fatal("Non rilevo in anagrafica filiali appartenenti a societa' Food.") && chiusura_log() && die "\n"};
    $dbh_lavori->disconnect();
}
 

# Qualora siano state richieste filiali specifiche verifico che appartengano alle societa' previste
if (@elenco_negozi) {	
	$senza_negozi_in_input=0;
	my $lista_soc = join ('|',@elenco_societa_food);
	$logger->debug("Societa' trattabili: @elenco_societa_food , filiali in input: @elenco_negozi");
	my @elenco_negozi_errati = grep { $_ !~ /^($lista_soc)\d\d/ } @elenco_negozi;
    if (@elenco_negozi_errati) {
#        if (@elenco_negozi_errati == 1) {
#         	print("Il negozio $elenco_negozi_errati[0] e' errato!\n");
#         	$logger->info("Negozio $elenco_negozi_errati[0] non appartenente alle societa ".join('|', @elenco_societa_food));
#       } else {
#        	print("Proseguo nonostante alcuni negozi in input errati: @elenco_negozi_errati\n");
        	$logger->info("Proseguo nonostante alcuni negozi in input ".join(', ', @elenco_negozi_errati)." non appartenenti alle societa' ".join('-', @elenco_societa_food));
#           $logger->fatal("I negozi ".join(', ', @elenco_negozi_errati)." sono errati. Chiusura anomala !") && chiusura_log() && die "\n";
#       }
    }
}
	
# Qualora siano state richieste filiali specifiche verifico che siano valide nel periodo richiesto


if (@elenco_negozi) {
#	my $lista_neg = join ('|',@elenco_negozi);
	foreach my $chiave (keys %elenco_filiali) {
		if (grep {($_ eq $chiave) } @elenco_negozi) {
			if 	(($elenco_filiali{$chiave}{chiusura} lt $data_inizio)
			||	($elenco_filiali{$chiave}{apertura} gt $data_fine)) {
				$logger->info("Filiale ".$chiave." con data validita' (dal ".$elenco_filiali{$chiave}{apertura}." al ".$elenco_filiali{$chiave}{chiusura}.") esterna all'intervallo ".($data_inizio->ymd('-'))." ".($data_fine->ymd('-')));
			}
		}
	}
}	


if (&ConnessioneDB) {   
    $logger->info("connessione db $database $hostname avvenuta con successo.");
    
    unless(mkdir $export_folder) {
        $logger->fatal("Impossibile creare la cartella: $export_folder") && chiusura_log() && die "\n";
    }            
    my $data = $data_inizio->clone();
    while ( DateTime->compare($data, $data_fine) <= 0) {
        if ($sth_elenco_negozi->execute($data->ymd('-'))) {
            my @elenco_negozi_della_giornata = ();
            while(my @row = $sth_elenco_negozi->fetchrow_array()) {
                push @elenco_negozi_della_giornata, $row[0];
            }
            # intersezione dei due array
            my %elenco_negozi_della_giornata = map{$_ =>1} @elenco_negozi_della_giornata;
            my %elenco_negozi = map{$_=>1} @elenco_negozi;
            my @elenco_negozi = grep( $elenco_negozi{$_}, @elenco_negozi_della_giornata );
            
            if (!@elenco_negozi and !$senza_negozi_in_input
            	) {
                	 $logger->fatal("In input solo negozi errati o senza venduti. Chiusura anomala !") && chiusura_log() && die "\n";
             }
             
            if ( ! @elenco_negozi and $senza_negozi_in_input
            ) {
                @elenco_negozi = @elenco_negozi_della_giornata;
            }
            
#           print "senza_neg_in_inp=".$senza_negozi_in_input." ele_neg=@elenco_negozi num_neg_gio=".@elenco_negozi_della_giornata ."\n";
            for(my $i=0;$i<@elenco_negozi;$i++) {
                $logger->info("Inizio creazione scarmene del giorno: ".$data->ymd('-').', del negozio: '.$elenco_negozi[$i]);
                if ($sth->execute($elenco_negozi[$i], $data->ymd('-'))) {
                	my $ctr_righe = 0;
                    my $nome_file = 'SCARMENE_'.$elenco_negozi[$i].'_'.$data->ymd('').'_'.DateTime->now(time_zone=>'local')->ymd('').DateTime->now(time_zone=>'local')->hms('');
                    if (open my $file_handler, "+>:crlf", "$export_folder/$nome_file\.txt") {
                        while(my @row = $sth->fetchrow_array()) {                                                    
                            print $file_handler "$row[0]\n";
							$ctr_righe++;
                        }
                        close $file_handler;
                        $logger->info("Fine creazione scarmene del giorno: ".$data->ymd('-').', del negozio: '.$elenco_negozi[$i].' per righe='.$ctr_righe);
                        if ($ftp) {
                            $ftph = Net::FTP->new($ftp_url) or $logger->fatal("Mancata connessione al sito $ftp_url: $!") && chiusura_log() && die "\n";
                            if ( $ftph->login("$ftp_user","$ftp_password")) {
                                $ftph->ascii();
                                
                                $logger->debug("invio del file: $export_folder/$nome_file\.txt");
                                if ($ftph->append("$export_folder/$nome_file\.txt", 'SCARMGIFT')) {
                                    if ($flag) {
                                        $sth_lavori->execute($elenco_negozi[$i], $data->ymd('-'));
                                    }
                                }
                            } else {$logger->fatal("Login sito $ftp_url fallito.") && chiusura_log() && die "\n"}
                            $ftph->quit;
                        }
                        
                        if ( $delete ) {
                            unlink("$export_folder/$nome_file\.txt") or $logger->warn("rimozione del file $export_folder/$nome_file\.txt non riuscita.");
                        }
                    }
                
                }
            }
        }
        $data->add(days => 1);
    }
    
    if ( $delete ) {
        rmdir "$export_folder" or $logger->warn("rimozione della cartella $export_folder non riuscita.");
    }
    $dbh->disconnect();
    if ($flag) {$dbh_lavori->disconnect()};
}

&chiusura_log();

sub ConnessioneDB {
    # connessione al database negozi
    $dbh = DBI->connect("DBI:mysql:$database:$hostname", $username, $password);
    if (! $dbh) {
        print "Errore durante la connessione al database `$database`!\n";
        return 0;
    }

    $sth_elenco_negozi = $dbh->prepare(qq{  select distinct concat(r.`RVG-CODSOC`,r.`RVG-CODNEG`)
                                            from archivi.riepvegi as r
                                            where r.`RVG-DATA` = ?
                                            order by 1}
    );

     $sth = $dbh->prepare(qq{select
                                concat('0',
                                concat(r.`RVG-CODSOC`,r.`RVG-CODNEG`),
                                'REGM',								-- smn-tmov
                                '399994',							-- smn-codfor
                                date_format(r.`RVG-DATA`,'%Y%m%d'),	-- smn-data
                                '9999999999',						-- smn-nbolla
                                lpad(t.codice,7,0),					-- smn-codcin
                                case
                                	when not (r.`RVG-VAL-VEN-CASSE-E` < 0 and r.`RVG-QTA-USC` <= 0) 
                                		then 	lpad(abs(round((r.`RVG-QTA-USC` * 100),0)),10,0) 
                                	else 		'0000000000' 
                                end,													-- smn-qtabopz
                                lpad(abs(round((a.`COSTOCES-ART2` * 100),0)),6,0),		-- smn-pcf
                                lpad(abs(round((a.`prvecash-art2-e` * 100),0)),6,0),	-- smn-pvcas
                                lpad(abs(round((a.`prveif-art2-e` * 100),0)),6,0),		-- smn-pvif
                                '0000',													-- smn-destinazione
                                lpad(abs(round((a.`iva-art2` * 100),0)),4,0),			-- smn-iva
                                ' ',													-- smn-seg-doc
                                '0000',													-- smn-prep-note
                                '0000',													-- smn-pz
                                lpad(a.`um-art2`,2,0),									-- smn-um
								'001',													-- smn-pz
								case
                                	when (r.`RVG-VAL-VEN-CASSE-E` < 0 and r.`RVG-QTA-USC` <= 0) 
                                		then 	lpad(abs(round((r.`RVG-QTA-USC` * 100),0)),10,0) 
                                	else 		'0000000000' 
                                end,													-- smn-qtacar
								'00000',												-- smn-ncolli
								'00',													-- filler
								'0',													-- smn-seg-prezresi
								'00000000',												-- smn-cart-giac
								'0',													-- smn-corrgiac
								' ',													-- smn-seg-sta
								' ',													-- smn-seg-agg
                                date_format(r.`RVG-DATA`,'%Y%m%d'),						-- smn-data-trasm
								'T'														-- smn-seg-trasm
							) as SCARMENE_RECORD
                            from		archivi.riepvegi as r
                            inner join	archivi.trascodifica_articoli t
                            on 	'GIFT_FOOD'			= t.tipo
                            and	r.`RVG-CODBARRE`	= t.ean
                            AND "1"					= t.valido
                            inner join	archivi.articox2 a
                            on 	t.codice			= a.`cod-art2`
                            where concat(r.`RVG-CODSOC`,r.`RVG-CODNEG`) = ? and r.`RVG-DATA` = ?
                            order by r.`RVG-DATA`, concat(r.`RVG-CODSOC`,r.`RVG-CODNEG`), lpad(r.`RVG-CODICE`,7,0), lpad(r.`RVG-CODBARRE`,13,0)}
    );
    if ($flag) {
        # connessione al database lavori
        $dbh_lavori = DBI->connect("DBI:mysql:$lavori_database:$lavori_hostname", $lavori_username, $lavori_password);
        if (! $dbh_lavori) {
            print "Errore durante la connessione al database `$lavori_database`!\n";
            return 0;
        }
        $sth_lavori = $dbh_lavori->prepare(qq{update incarichi as i set i.eseguito = 1 where i.lavoro_codice = 150 and i.negozio_codice = ? and i.data = ?});
    }
    
    return 1;
}


sub ConnessioneDB_lavori {
    # connessione al database lavori
    $dbh_lavori = DBI->connect("DBI:mysql:$lavori_database:$lavori_hostname", $lavori_username, $lavori_password);
    if (! $dbh_lavori) {
        print "Errore durante la connessione al database `$lavori_database`!\n";
        return 0;
    }

	$sth_elenco_societa = $dbh_lavori->prepare(qq{  select codice
	                                        		from archivi.societa as s
	                                        		where s.food = '1'
	                                        		order by 1}
	);
	$sth_elenco_filiali = $dbh_lavori->prepare(qq{  select n.codice	,
													n.data_inizio,
													ifnull(n.data_fine,'2099-12-31'),
													negozio_descrizione							
													from archivi.negozi			as n
	                                        		inner join archivi.societa	as s
                                                    on n.societa = s.codice
	                                        		where s.food = '1'
	                                        		order by 1}
	);
    return 1;
}


sub log_file_name {
    return "$log_folder/".$current_date->ymd('')."_invio_scm_2_bull.log";
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

sub chiusura_log {
    $logger->info("");
    $logger->info("fine elaborazione");
    $logger->info("-" x 76);
    $logger->info("");
    
    return 1;
};

                    
