#!/usr/bin/perl -w
use strict;
use DBI;        # permette di comunicare con il database
use File::Find;
use File::Basename;
use File::HomeDir;
use Net::FTP;

# parametri FTP
my $ftp_url = 'itm-lrp01.italmark.com';
my $ftp_utente = "lrp";
my $ftp_password = "lrp";

# posizione locale dati
my $cartella_locale = '/PR';
unless(-e $cartella_locale or mkdir $cartella_locale)
		{die "Impossibile creare la cartella $cartella_locale: $!\n";};

# parametri di collegamento
my $hostname                = "localhost";
my $username                = "root";
my $password                = "mela";

# parametri di configurazione dei database
my $database_cm             = 'cm';
my $table_campagne          = 'campagne';
my $table_promozioni        = 'promozioni';
my $table_negozi            = 'negozi_promozioni';

# variabili globali
my $dbh;
my $sth;
my $sth_inserimento_campagna;
my $sth_inserimento_promozione;
my $sth_aggiornamento_promozione_1;
my $sth_aggiornamento_promozione_2;
my $sth_aggiornamento_promozione_3;
my $sth_inserimento_negozio_promozione;
my $file_handler;
my $line;

if (&ConnessioneDB()) {
		my $ftp = Net::FTP->new($ftp_url) or die "Mancata connessione al sito $ftp_url: $!\n";
		$ftp->login("$ftp_utente","$ftp_password") or die "Login al sito $ftp_url fallito per l'utente $ftp_utente: $!\n";
		$ftp->binary();

		# Carico la lista dei file compattati presenti nelle cartelle di ricezione e li prelevo
		my $cartella_remota = '/PO_fid_files/trasm/00001/OUT';
		my @elenco_files = grep { /\.CTL$/ } grep { !/^\./ } $ftp->ls("$cartella_remota");
		$ftp->cwd("$cartella_remota");
		foreach my $file (@elenco_files) {
				my ($name,$path,$suffix) = fileparse("$file",qr/\.[^.]*/);
				$ftp->get("$path$name\.DAT", "$cartella_locale/$name\.DAT");
				$ftp->delete("$path$name\.DAT");
				$ftp->delete("$path$name\.CTL");
		}
		$cartella_remota = '/PO_fid_files/trasm/00004/OUT';
		@elenco_files = grep { /\.CTL$/ } grep { !/^\./ } $ftp->ls("$cartella_remota");
		$ftp->cwd("$cartella_remota");
		foreach my $file (@elenco_files) {
				my ($name,$path,$suffix) = fileparse("$file",qr/\.[^.]*/);
				$ftp->get("$path$name\.DAT", "$cartella_locale/$name\.DAT");
				$ftp->delete("$path$name\.DAT");
				$ftp->delete("$path$name\.CTL");
		}
		$cartella_remota = '/PO_fid_files/trasm/00031/OUT';
		@elenco_files = grep { /\.CTL$/ } grep { !/^\./ } $ftp->ls("$cartella_remota");
		$ftp->cwd("$cartella_remota");
		foreach my $file (@elenco_files) {
				my ($name,$path,$suffix) = fileparse("$file",qr/\.[^.]*/);
				$ftp->get("$path$name\.DAT", "$cartella_locale/$name\.DAT");
				$ftp->delete("$path$name\.DAT");
				$ftp->delete("$path$name\.CTL");
		}
		$cartella_remota = '/PO_fid_files/trasm/00036/OUT';
		@elenco_files = grep { /\.CTL$/ } grep { !/^\./ } $ftp->ls("$cartella_remota");
		$ftp->cwd("$cartella_remota");
		foreach my $file (@elenco_files) {
				my ($name,$path,$suffix) = fileparse("$file",qr/\.[^.]*/);
				$ftp->get("$path$name\.DAT", "$cartella_locale/$name\.DAT");
				$ftp->delete("$path$name\.DAT");
				$ftp->delete("$path$name\.CTL");
		}
		$ftp->quit(); 
		
    opendir my($DIR), $cartella_locale or die "Non è stato possibile aprire la cartella $cartella_locale: $!\n";
    @elenco_files = grep { /^PR\d{16}\.DAT$/ } readdir $DIR;
    closedir $DIR;
    
    foreach my $file (@elenco_files) {
        if (open $file_handler, "<:crlf", "$cartella_locale/$file") {
            while(! eof ($file_handler))  {
                $line = <$file_handler>;
                $line =~ s/\n$//ig;
                
                if ($line =~ /^C/) {
                    &Campagna($line);
                } else {
                    &Promozione($line);
                }   
            }
            close($file_handler);
        }
    }

};

$dbh->disconnect();




#------------------------------------------------------------------------------
sub Campagna{
    my ($line) = @_;
    
    my $id_trasmissione;
    my $data;
    my $ora;
    my $negozio;
    my $campagna;
    my $descrizione;
    my $tipo;
    my $data_inizio;
    my $data_fine;
    my $tipo_attivita;
    if ($line =~ /^C(\d{6})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})(\d{4})\s(\d{5})\s{4}..{9}(.{50})(.{2})(\d{2})(\d{2})(\d{4})(\d{2})(\d{2})(\d{4})/) {
        $id_trasmissione = $1;
        $data            = '20'.$2.'-'.$3.'-'.$4;
        $ora             = $5.':'.$6.':'.$7.'.'.$8;
        $negozio         = $9;
        $campagna        = $10;
        $descrizione     = $11;
        $tipo            = $12;
        $data_inizio     = $15.'-'.$14.'-'.$13;
        $data_fine       = $18.'-'.$17.'-'.$16;
        $tipo_attivita   = '';
        
        $descrizione =~ s/\s*$//ig;
        
        if (!$sth_inserimento_campagna->execute($id_trasmissione, $data, $ora, $campagna, $descrizione, $tipo, $data_inizio, $data_fine, $tipo_attivita)) {
            print "Errore nell'inserimento della campagna: $campagna $descrizione\n";
        }
    }
}

sub Promozione{
    my ($line) = @_;
    
    my $old_id = 0;
    
    my $id_trasmissione;
    my $data;
    my $ora;
    my $negozio;
    my $campagna;
    my $promozione;
    my $descrizione;
    my $tipo;
    my $data_inizio;
    my $data_fine;
    my $classe;
    my $tipo_attivita;
    my $articolo            = '';
    my $codice_articolo     = '';
    my $codice_ean          = '';
    my $codice_reparto      = '';
    my $slot_reparto        = '';
    my $parametri           = '';
    my $parametro_01        = 0;
    my $parametro_02        = 0;
    my $parametro_03        = 0;
    my $parametro_04        = 0;
    my $parametro_05        = 0;
    my $parametro_06        = 0;
    my $parametro_07        = 0;
    my $parametro_08        = 0;
    my $parametro_09        = 0;
    my $parametro_10        = 0;
    my $parametro_11        = 0;
    my $parametro_12        = 0;       
    if ($line =~ /^P(\d{6})(\d{2})(\d{2})(\d{4})(\d{2})(\d{2})(\d{2})(\d{4})\s(\d{5})\s{5}(\d{9})(.{50})(.{2})(\d{2})(\d{2})(\d{4})(\d{2})(\d{2})(\d{4}).{24}(\d{4})(.)(.{32}).{7}(.{96}).*$/) {
        $id_trasmissione = $1*1;
        $data            = $4.'-'.$3.'-'.$2;
        $ora             = $5.':'.$6.':'.$7;
        $negozio         = $8;
        $campagna        = $9;
        $promozione      = $10;
        $descrizione     = $11;
        $tipo            = $12;
        $data_inizio     = $15.'-'.$14.'-'.$13;
        $data_fine       = $18.'-'.$17.'-'.$16;
        $classe          = $19;
        $tipo_attivita   = $20;
        $articolo        = $21;
        $parametri       = $22;
        
        $descrizione =~ s/\s*$//ig;
        
        $articolo =~ s/\s/0/ig;
        if ($articolo =~ /^(.{7})...(.{13})(.{8})(.)/) {
            $codice_articolo    = $1;
            $codice_ean         = $2;
            $codice_reparto     = $3;
            $slot_reparto       = $4*1;
        }
        
        $parametri =~ s/\s/0/ig;
        if ($parametri =~ /^(.{8})(.{8})(.{8})(.{8})(.{8})(.{8})(.{8})(.{8})(.{8})(.{8})(.{8})(.{8})/) {
            $parametro_01 = $1*1;
            $parametro_02 = $2*1;
            $parametro_03 = $3*1;
            $parametro_04 = $4*1;
            $parametro_05 = $5*1;
            $parametro_06 = $6*1;
            $parametro_07 = $7*1;
            $parametro_08 = $8*1;
            $parametro_09 = $9*1;
            $parametro_10 = $10*1;
            $parametro_11 = $11*1;
            $parametro_12 = $12*1;
        }
        
        if (($tipo eq 'PF')||($tipo eq 'AP')||($tipo eq 'AV')||($tipo eq 'BJ')||($tipo eq 'BP')||($tipo eq 'FV')||($tipo eq 'FP')||($tipo eq 'BM')||($tipo eq 'DM')||($tipo eq 'DJ')) {
            $sth = $dbh->prepare(qq{SELECT ifnull(id_esportazione,0) FROM `$table_promozioni` WHERE codice_campagna = ? AND  codice_promozione = ? AND classe = ? AND codice_articolo = ?});
            $sth->execute($campagna,$promozione,$classe,$codice_articolo);
            $old_id = $sth->fetchrow_array;
            $sth->finish;
        } elsif (($tipo eq 'RP')||($tipo eq 'RV')) {
            $sth = $dbh->prepare(qq{SELECT ifnull(id_esportazione,0) FROM `$table_promozioni` WHERE codice_campagna = ? AND  codice_promozione = ? AND classe = ? AND codice_reparto = ?});
            $sth->execute($campagna,$promozione,$classe,$codice_reparto);
            $old_id = $sth->fetchrow_array;
            $sth->finish;
        } else {
            $sth = $dbh->prepare(qq{SELECT ifnull(id_esportazione,0) FROM `$table_promozioni` WHERE codice_campagna = ? AND  codice_promozione = ? AND classe = ?});
            $sth->execute($campagna,$promozione,$classe);
            $old_id = $sth->fetchrow_array;
            $sth->finish;
        }
        
        if (!$old_id) {
            if( !$sth_inserimento_promozione->execute($id_trasmissione,$data,$ora,$campagna,$promozione,$descrizione,$tipo,$data_inizio,$data_fine,'','','',
                                                      $classe,$tipo_attivita,$codice_articolo,$codice_ean,$codice_reparto,$slot_reparto,$parametro_01,$parametro_02,$parametro_03,
                                                      $parametro_04,$parametro_05,$parametro_06,$parametro_07,$parametro_08,$parametro_09,$parametro_10,$parametro_11,$parametro_12)) {
                print "Errore nell'inserimento della promozione \n";
            };
				} elsif ($old_id < $id_trasmissione) {
						if (($tipo eq 'PF')||($tipo eq 'AP')||($tipo eq 'AV')||($tipo eq 'BJ')||($tipo eq 'BP')||($tipo eq 'FV')||($tipo eq 'FP')||($tipo eq 'BM')) {
								$sth_aggiornamento_promozione_1->execute($id_trasmissione,$data,$ora,$campagna,$promozione,$descrizione,$tipo,$data_inizio,$data_fine,'','','',
                        $classe,$tipo_attivita,$codice_articolo,$codice_ean,$codice_reparto,$slot_reparto,$parametro_01,$parametro_02,$parametro_03,
                        $parametro_04,$parametro_05,$parametro_06,$parametro_07,$parametro_08,$parametro_09,$parametro_10,$parametro_11,$parametro_12,
												$campagna,$promozione,$classe,$codice_articolo);
						} elsif (($tipo eq 'RP')||($tipo eq 'RV')) {
								$sth_aggiornamento_promozione_2->execute($id_trasmissione,$data,$ora,$campagna,$promozione,$descrizione,$tipo,$data_inizio,$data_fine,'','','',
                        $classe,$tipo_attivita,$codice_articolo,$codice_ean,$codice_reparto,$slot_reparto,$parametro_01,$parametro_02,$parametro_03,
                        $parametro_04,$parametro_05,$parametro_06,$parametro_07,$parametro_08,$parametro_09,$parametro_10,$parametro_11,$parametro_12,
												$campagna,$promozione,$classe,$codice_reparto);
						} else {
								$sth_aggiornamento_promozione_3->execute($id_trasmissione,$data,$ora,$campagna,$promozione,$descrizione,$tipo,$data_inizio,$data_fine,'','','',
                        $classe,$tipo_attivita,$codice_articolo,$codice_ean,$codice_reparto,$slot_reparto,$parametro_01,$parametro_02,$parametro_03,
                        $parametro_04,$parametro_05,$parametro_06,$parametro_07,$parametro_08,$parametro_09,$parametro_10,$parametro_11,$parametro_12,
												$campagna,$promozione,$classe);
						}
				}
				
				$sth_inserimento_negozio_promozione->execute($negozio,$campagna,$promozione);
    }
}

sub ConnessioneDB{
    # connessione al database
    $dbh = DBI->connect("DBI:mysql:mysql:$hostname", $username, $password);
    if (! $dbh) {
        print "Errore durante la connessione al database di default!\n";
        return 0;
    }
    
    # creazione del database datacollect
    $sth = $dbh->prepare(qq{
        CREATE DATABASE IF NOT EXISTS `$database_cm`
            DEFAULT CHARACTER SET = latin1
            DEFAULT COLLATE       = latin1_swedish_ci
    });
    if (!$sth->execute()) {
        print "Errore durante la creazione del database `$database_cm`! " .$dbh->errstr."\n";
        return 0;
    }
    $dbh->disconnect();
    
    
    # connessione al database
    $dbh = DBI->connect("DBI:mysql:$database_cm:$hostname", $username, $password);
    if (! $dbh) {
        print "Errore durante la connessione al database `$database_cm`!\n";
        return 0;
    }
    
    # creazione della tabella campagne
    $sth = $dbh->prepare(qq{
        CREATE TABLE IF NOT EXISTS `$table_campagne` (
            `id_esportazione` int(11) NOT NULL DEFAULT '0',
            `data_elaborazione` date NOT NULL,
            `ora_elaborazione` time NOT NULL,
            `codice_campagna` varchar(5) NOT NULL DEFAULT '""',
            `descrizione` varchar(50) NOT NULL DEFAULT '""',
            `tipo` varchar(2) NOT NULL DEFAULT '""',
            `data_inizio` date NOT NULL,
            `data_fine` date NOT NULL,
            `tipo_attivita` varchar(1) NOT NULL DEFAULT '',
            PRIMARY KEY (`codice_campagna`)) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });
    if (!$sth->execute()) {
        print "Errore durante la creazione della tabella `$table_campagne`! " .$dbh->errstr."\n";
        return 0;
    }
    $sth->finish();
    
    # inserimento/aggiornamento tabella campagne
    $sth_inserimento_campagna= $dbh->prepare(qq{
        INSERT INTO `$table_campagne`
                (id_esportazione, data_elaborazione, ora_elaborazione, codice_campagna, descrizione, tipo, data_inizio, data_fine, tipo_attivita)
        VALUES  (?,?,?,?,?,?,?,?,?)
        ON DUPLICATE KEY UPDATE
                id_esportazione=values(id_esportazione),
                data_elaborazione=values(data_elaborazione),
                ora_elaborazione=values(ora_elaborazione),
                descrizione=values(descrizione),
                tipo=values(tipo),
                data_inizio=values(data_inizio),
                data_fine=values(data_fine),
                tipo_attivita=values(tipo_attivita);});
    
    # creazione della tabella negozi
    $sth = $dbh->prepare(qq{
        CREATE TABLE IF NOT EXISTS `$table_negozi` (
            `negozio_codice` varchar(4) NOT NULL DEFAULT '',
            `campagna_codice` varchar(5) NOT NULL DEFAULT '',
            `promozione_codice` varchar(9) NOT NULL DEFAULT '',
			PRIMARY KEY (`negozio_codice`,`promozione_codice`)
			) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });
    if (!$sth->execute()) {
        print "Errore durante la creazione della tabella `$table_negozi`! " .$dbh->errstr."\n";
        return 0;
    }
    $sth->finish();
    
		$sth_inserimento_negozio_promozione = $dbh->prepare(qq{
		INSERT IGNORE INTO `$table_negozi`
						(negozio_codice, campagna_codice, promozione_codice) 
		VALUES  (?,?,?)});
				

    # creazione della tabella promozioni
    $sth = $dbh->prepare(qq{
        CREATE TABLE IF NOT EXISTS `$table_promozioni` (
            `id_esportazione` int(11) NOT NULL DEFAULT '0',
            `data_elaborazione` date NOT NULL,
            `ora_elaborazione` time NOT NULL,
            `codice_campagna` varchar(5) NOT NULL DEFAULT '""',
            `codice_promozione` varchar(9) NOT NULL DEFAULT '""',
            `descrizione` varchar(50) NOT NULL DEFAULT '""',
            `tipo` varchar(2) NOT NULL DEFAULT '""',
            `data_inizio` date NOT NULL,
            `data_fine` date NOT NULL,
            `calendario` varchar(7) NOT NULL DEFAULT '',
            `ora_inizio` time NOT NULL,
            `ora_fine` time NOT NULL,
            `classe` smallint(6) NOT NULL,
            `tipo_attivita` varchar(1) NOT NULL DEFAULT '',
            `codice_articolo` varchar(7) NOT NULL DEFAULT '""',
            `codice_ean` varchar(13) NOT NULL DEFAULT '""',
            `codice_reparto` varchar(20) NOT NULL DEFAULT '""',
            `slot_reparto` smallint(6) NOT NULL DEFAULT '0',
            `parametro_01` int(11) NOT NULL DEFAULT '0',
            `parametro_02` int(11) NOT NULL DEFAULT '0',
            `parametro_03` int(11) NOT NULL DEFAULT '0',
            `parametro_04` int(11) NOT NULL DEFAULT '0',
            `parametro_05` int(11) NOT NULL DEFAULT '0',
            `parametro_06` int(11) NOT NULL DEFAULT '0',
            `parametro_07` int(11) NOT NULL DEFAULT '0',
            `parametro_08` int(11) NOT NULL DEFAULT '0',
            `parametro_09` int(11) NOT NULL DEFAULT '0',
            `parametro_10` int(11) NOT NULL DEFAULT '0',
            `parametro_11` int(11) NOT NULL DEFAULT '0',
            `parametro_12` int(11) NOT NULL DEFAULT '0',
						KEY `codice_campagna` (`codice_campagna`,`codice_promozione`,`classe`,`codice_articolo`,`codice_reparto`)) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });
    if (!$sth->execute()) {
        print "Errore durante la creazione della tabella `$table_promozioni`! " .$dbh->errstr."\n";
        return 0;
    }
    $sth->finish();
    
    
    $sth_inserimento_promozione = $dbh->prepare(qq{
        INSERT INTO `$table_promozioni`
                (id_esportazione, data_elaborazione, ora_elaborazione, codice_campagna, codice_promozione, descrizione, tipo, data_inizio, data_fine,
                calendario,ora_inizio,ora_fine,classe,tipo_attivita,codice_articolo,codice_ean,codice_reparto,slot_reparto,
                parametro_01,parametro_02,parametro_03,parametro_04,parametro_05,parametro_06,parametro_07,parametro_08,
                parametro_09,parametro_10,parametro_11,parametro_12) 
        VALUES  (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)});
		
		$sth_aggiornamento_promozione_1 = $dbh->prepare(qq{
				UPDATE `$table_promozioni` SET
        id_esportazione = ?, data_elaborazione = ?, ora_elaborazione = ?, codice_campagna = ?, codice_promozione = ?, descrizione = ?, tipo = ?, data_inizio = ?, data_fine = ?,
        calendario = ?,ora_inizio = ?,ora_fine = ?,classe = ?,tipo_attivita = ?,codice_articolo = ?,codice_ean = ?,codice_reparto = ?,slot_reparto = ?,
        parametro_01 = ?,parametro_02 = ?,parametro_03 = ?,parametro_04 = ?,parametro_05 = ?,parametro_06 = ?,parametro_07 = ?,parametro_08 = ?,
        parametro_09 = ?,parametro_10 = ?,parametro_11 = ?,parametro_12 = ?
				WHERE codice_campagna = ? AND  codice_promozione = ? AND classe = ? AND codice_articolo = ?});
		
		$sth_aggiornamento_promozione_2 = $dbh->prepare(qq{
				UPDATE `$table_promozioni` SET
        id_esportazione = ?, data_elaborazione = ?, ora_elaborazione = ?, codice_campagna = ?, codice_promozione = ?, descrizione = ?, tipo = ?, data_inizio = ?, data_fine = ?,
        calendario = ?,ora_inizio = ?,ora_fine = ?,classe = ?,tipo_attivita = ?,codice_articolo = ?,codice_ean = ?,codice_reparto = ?,slot_reparto = ?,
        parametro_01 = ?,parametro_02 = ?,parametro_03 = ?,parametro_04 = ?,parametro_05 = ?,parametro_06 = ?,parametro_07 = ?,parametro_08 = ?,
        parametro_09 = ?,parametro_10 = ?,parametro_11 = ?,parametro_12 = ?
				WHERE codice_campagna = ? AND  codice_promozione = ? AND classe = ? AND codice_reparto = ?});
		
		$sth_aggiornamento_promozione_3 = $dbh->prepare(qq{
				UPDATE `$table_promozioni` SET
        id_esportazione = ?, data_elaborazione = ?, ora_elaborazione = ?, codice_campagna = ?, codice_promozione = ?, descrizione = ?, tipo = ?, data_inizio = ?, data_fine = ?,
        calendario = ?,ora_inizio = ?,ora_fine = ?,classe = ?,tipo_attivita = ?,codice_articolo = ?,codice_ean = ?,codice_reparto = ?,slot_reparto = ?,
        parametro_01 = ?,parametro_02 = ?,parametro_03 = ?,parametro_04 = ?,parametro_05 = ?,parametro_06 = ?,parametro_07 = ?,parametro_08 = ?,
        parametro_09 = ?,parametro_10 = ?,parametro_11 = ?,parametro_12 = ?
				WHERE codice_campagna = ? AND  codice_promozione = ? AND classe = ?});
		
    return 1;
}
