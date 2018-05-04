#!/usr/bin/perl -w
use strict;
use DBI;
use File::HomeDir;
use DateTime;
use Spreadsheet::WriteExcel;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
use Log::Log4perl;

# parametri database
#----------------------------------------------------------------------------------------------------------------------
my $hostname = '10.11.14.78';
my $username = 'root';
my $password = 'mela';
my $database = 'promozioni';
my $table = 'offerte';

# date
#----------------------------------------------------------------------------------------------------------------------
my $current_date 	= DateTime->now(time_zone=>'local');

# definizione cartelle
#----------------------------------------------------------------------------------------------------------------------
my $desktop = File::HomeDir->my_desktop;
my $export_folder = "$desktop/promozioni_".$current_date->ymd('').'_'.$current_date->hms('');
my $local_log_folder = "/log";
my $log_folder = "$local_log_folder/".substr($current_date->ymd(''),0,6);

# Creazione cartelle locali (se non esistono)
#----------------------------------------------------------------------------------------------------------------------
unless (-e $export_folder or mkdir $export_folder) {die "Impossibile creare la cartella $export_folder: $!\n";};
unless (-e $local_log_folder or mkdir $local_log_folder) {die "Impossibile creare la cartella $local_log_folder: $!\n";};
unless (-e $log_folder or mkdir $log_folder) {die "Impossibile creare la cartella $log_folder: $!\n";};

# File di export
#----------------------------------------------------------------------------------------------------------------------
#my $elenco_promozioni = 'elenco_promozioni.xlsx';
my $elenco_promozioni = 'elenco_promozioni.xls';
#my $caricamento_promozione = '_cm.xlsx';
my $caricamento_promozione = '_cm.xls';

# configurazione log
#----------------------------------------------------------------------------------------------------------------------
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
$logger->info("invio rvg a Italbrix");
$logger->info("-" x 76);
$logger->info("inizio elaborazione");
$logger->info("");

# handler
#----------------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sth_elenco_promozioni;
my $sth_cm_promozione;

# esecuzione ****
#----------------------------------------------------------------------------------------------------------------------
if (&ConnessioneDB) {   
    $logger->info("connessione avvenuta con successo.");
    
    my @elenco_id = ();
    my @elenco_tipo = ();
    my @elenco_societa = ();
    
    if ($sth_elenco_promozioni->execute()) {
        
        $logger->info("creazione elenco promozioni");
        
        #my $workbook = Excel::Writer::XLSX->new("$export_folder/$elenco_promozioni");
        my $workbook = Spreadsheet::WriteExcel->new("$export_folder/$elenco_promozioni");
        
        #creo il foglio di lavoro x l'elenco delle promozioni
        my $rv_elenco = $workbook->add_worksheet( 'Elenco' );
        
        #aggiungo un formato
        my $format = $workbook->add_format();
        $format->set_bold();
        
        #titolo colonne
        $format->set_color( 'blue' );
        $rv_elenco->write( 0, 0, "Id", $format );
        $rv_elenco->write( 0, 1, "Tipo", $format );
        $rv_elenco->write( 0, 2, "Societa", $format );
        $rv_elenco->write( 0, 3, "Descrizione", $format );
        $rv_elenco->write( 0, 4, "Inizio", $format );
        $rv_elenco->write( 0, 5, "Fine", $format );
        $rv_elenco->write( 0, 6, "Gruppo", $format );
        
        #larghezza colonne
        $rv_elenco->set_column( 0, 0, 8 );
        $rv_elenco->set_column( 1, 1, 5 );
        $rv_elenco->set_column( 2, 2, 20 );
        $rv_elenco->set_column( 3, 3, 50 );
        $rv_elenco->set_column( 4, 4, 10 );
        $rv_elenco->set_column( 5, 5, 10 );
        $rv_elenco->set_column( 6, 6, 5 );
        
        my $row_counter = 1;
        while(my @row = $sth_elenco_promozioni->fetchrow_array()) {
            
            #aggiungo l'elemento agli array elenco...
            push(@elenco_id, $row[0]);
            push(@elenco_tipo, $row[1]);
            push(@elenco_societa, substr($row[2],0,2));
                    
            $rv_elenco->write_string( $row_counter, 0, "$row[0]");
            $rv_elenco->write( $row_counter, 1, "$row[1]");
            $rv_elenco->write( $row_counter, 2, "$row[2]");
            $rv_elenco->write( $row_counter, 3, "$row[3]");
            $rv_elenco->write( $row_counter, 4, "$row[4]");
            $rv_elenco->write( $row_counter, 5, "$row[5]");
            $rv_elenco->write( $row_counter, 6, "$row[6]");
            
            $row_counter++;
        }        
    }
    
    for (my $i=0;$i<@elenco_id;$i++) {
    
    	my $descrizione_tipo = $elenco_tipo[$i];
    	if ($elenco_tipo[$i] eq 'LPC') {
    		$descrizione_tipo = 'PF';
    	}
    	
        #my $workbook = Excel::Writer::XLSX->new("$export_folder/$elenco_id[$i]_$elenco_societa[$i]_$descrizione_tipo$caricamento_promozione");
        my $workbook = Spreadsheet::WriteExcel->new("$export_folder/$elenco_id[$i]_$elenco_societa[$i]_$descrizione_tipo$caricamento_promozione");
        #creo il foglio di lavoro x il dettaglio della promozione
        my $rv_cm = $workbook->add_worksheet( 'CM' );
        
        if ($sth_cm_promozione->execute($elenco_id[$i], $elenco_tipo[$i], $elenco_societa[$i])) {
            my $row_counter = 0;
            while(my @row = $sth_cm_promozione->fetchrow_array()) {
                
                $rv_cm->write_string( $row_counter, 0, "000000");
                $rv_cm->write_string( $row_counter, 1, "$row[0]");
                #$rv_cm->write_string( $row_counter, 1, "$row[1]");
                #$rv_cm->write( $row_counter, 2, "$row[2]");
                if ($elenco_tipo[$i] eq 'P+C') {
                    $rv_cm->write( $row_counter, 2, "$row[2]");
                    $rv_cm->write( $row_counter, 3, "$row[3]");
                } elsif ($elenco_tipo[$i] eq 'LPC') {
                    $rv_cm->write( $row_counter, 2, "1");
                    $rv_cm->write( $row_counter, 3, "$row[2]");
                    $rv_cm->write( $row_counter, 4, "10");
                } else {
                    $rv_cm->write( $row_counter, 2, "$row[2]");
                }

                $row_counter++;
            } 
        }
    }
}

&chiusura_log();

sub ConnessioneDB {
    # connessione al database negozi
    $dbh = DBI->connect("DBI:mysql:$database:$hostname", $username, $password);
    if (! $dbh) {
        print "Errore durante la connessione al database `$database`!\n";
        return 0;
    }
    $sth_elenco_promozioni = $dbh->prepare(qq{
                                                select distinct
                                                    o.promo_id,
                                                    o.promo_tipo,
                                                    concat(o.societa_codice,' - ',ifnull(s.descrizione,'SCONOSCIUTA')),
                                                    o.promo_descrizione,
                                                    o.data_inizio,
                                                    o.data_fine,
                                                    o.gruppo_codice
                                                from promozioni.offerte as o left join archivi.societa as s on o.societa_codice = s.codice
                                                where nimis ='S' order by promo_id, promo_tipo, societa_codice
                                            }
    );
    
    
    $sth_cm_promozione = $dbh->prepare(qq{
                                            select distinct o.articolo_codice, a.`DES-ART2`,o.punti_sconto, o.prezzo
                                            from promozioni.offerte as o join archivi.articox2 as a on o.articolo_codice = a.`COD-ART2` 
                                            where o.promo_id = ? and o.promo_tipo = ? and o.societa_codice = ? and o.nimis ='S'
                                        });
    
    return 1;
}

sub log_file_name {
    return "$log_folder/".$current_date->ymd('')."_creazione_promozioni_cm.log";
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

                    
