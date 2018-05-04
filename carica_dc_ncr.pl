#!/usr/bin/perl -w
use strict;
use DBI;
use Getopt::Long;
use DateTime;
use File::HomeDir;

# parametri di configurazione del database
#---------------------------------------------------------------------------------------
my $hostname    = "localhost";
my $database    = "controllo";
my $username    = "root";
my $password    = "mela";

# variabili globali
#---------------------------------------------------------------------------------------
my $dbh;
my $sth_update;
my $sth_insert;
my $sth_drop;
my $sth_totali;
my $sth_indici;
my %scontrino;
my $linea;

my $scontrino_aperto = 0;

my $file_negozio;
my $file_data;
my $file_data_confronto;

my $data;

# opzioni sulla linea di comando
#---------------------------------------------------------------------------------------
my $param_data = '';
my $param_sede = '';
my $param_path = '';
my $help;
if (@ARGV == 0) {
    $help = 1
}

GetOptions(
    'p=s{,1}'   => \$param_path,
    'd=s{1,1}'  => \$param_data,
    's=s{1,1}'  => \$param_sede,
    'help'      => \$help,
) or die "parametri non corretti!\n";

if ($param_sede !~ /^\d{4}$/) {
    $help = 1
}

if ($param_sede !~ /^\d{4}$/) {
    $help = 1
}

if ($param_data ne '') {
    $param_data =~ s/[^\d\-]/\-/ig;
    if ($param_data =~ /^(\d{4})(\d{2})(\d{2})$/) {
        $param_data = $1.'-'.$2.'-'.$3;
    } elsif ($param_data =~ /^(\d{1,4})(?:\-|\/)(\d{1,2})(?:\-|\/)(\d{1,2})$/) {
        $param_data = sprintf('%04d-%02d-%02d',$1,$2,$3);
    } else {
        $help = 1
    }
    if (! $help) {
        $data = string2date($param_data)
    }
} else {
    $help = 1
}

if ($help) {
    print "Utilizzo: perl [path]carica_dc_ncr.pl [-d path] -d data -s sede\n\n";
    print "significato:     -p           path dei file del/dei file da caricare;\n";
    print "                              se manca questo parametro il path e\' la directory corrente\n";
    print "                 -d           data del file da caricare\n";
    print "                 -s           sede da caricare\n";    
    print "                --help        mostra queste istruzioni.\n";
     
    die "\n";
}

if ($param_path ne '') {
    $param_path .= '/'
}

if (&ConnessioneDB()) {
    my $file = $param_sede.'_'.$data->ymd('').'_'.substr($data->ymd(''),2).'_DC.TXT';
    if (open my $file_handler, "<:crlf", $param_path.$file) {
        if ($file =~ /^(\d{4})_(\d{2})(\d{2})(\d\d)(\d\d)/) {
            $file_negozio = $1;
            $file_data = $2.$3.'-'.$4.'-'.$5;
            $file_data_confronto =$3.$4.$5;
        }
        
        while(! eof ($file_handler))  {
            $linea = <$file_handler>;
            $linea =~ s/\n$//ig;
            if ($linea =~ /^\d{4}:\d{3}:(\d{6})/) {
                if ($file_data_confronto eq $1) {  #$file_negozio eq $1 and 
                    &analizza_contenuto_linea($linea); 
                }
            }      
        }
        close($file_handler)
    } else {die $param_path.$file.": $!\n"}
} else {die;}

$sth_update->finish();
$sth_insert->finish();
$sth_drop->finish();
$sth_totali->finish();
$sth_indici->finish();

sub analizza_contenuto_linea{
    my($linea) = @_;
    
    if ($linea =~ /^(\d{4}):(\d{3}):(\d{2})(\d{2})(\d{2}):(\d{2})(\d{2})(\d{2}):(\d{4}):.{3}:H:/) {
        &crea_nuovo_scontrino;
         
        $scontrino{'negozio'}       = $file_negozio;
        $scontrino{'cassa'}         = $2;
        $scontrino{'data'}          = $file_data;
        $scontrino{'ora'}           = $6.':'.$7.':'.$8;
        $scontrino{'transazione'}   = $9;
        
        $scontrino_aperto = 1;
    }
    
    if ($linea =~ /^.{31}:S:1(\d).{23}(.{5})(.)(\d{3})(.)(\d{9})$/) {
        my $reso                = $1;
        my $parte_intera        = $2;
        my $punto               = $3;
        my $parte_decimale      = $4;
        my $segno               = $5;
        my $importo             = $6;
        
        my $quantita = 0;
        if ($punto ne '.') {
            $quantita = $parte_intera
        } else {
            $quantita = $parte_intera.$punto.$parte_decimale;
        }
        
        if ($segno eq '*') {
            if ($punto ne '.') {
                $importo *= $quantita;
            } else {
                if ($quantita < 0) {
                    $importo *= -1;
                }
            }
        } else {
            $importo = $segno.$importo;
            $importo *= 1;
        }
        
        $scontrino{'totale_calcolato'} += $importo/100;
    }
        
    if ($linea =~ /^.{31}:k:.{12}(.{13})/) {
        $scontrino{'carta'} = $1;
    }
    
    if ($linea =~ /^.{31}:C:1.{24}(.{5}).{4}(.)(\d{9})/) {
        my $quantita    = $1;
        my $segno       = $2;
        my $importo     = $3;
        
        if ($segno eq '<' or $segno eq '>') {
            $importo = '-'.$importo;
            $importo *= $quantita;
        } else {
            $importo = $segno.$importo;
        }
           
        $scontrino{'sconto_totale'} += $importo/100*-1;
        $scontrino{'totale_calcolato'} += $importo/100;
    }
    
    if ($linea =~ /^.{31}:D:1.{27}(.{6})(.{10})/) {
        my $quantita    = $1;
        my $importo     = $2;
        
        $scontrino{'sconto_totale'} += $importo/100*-1;
        $scontrino{'totale_calcolato'} += $importo/100;
    }
    
    if ($linea =~ /^.{31}:G:1(\d).{26}(.{6})/) {
        my $tipo    = $1;
        my $punti   = $2;
        
        if ($tipo eq '2') {
            $scontrino{'punti_transazione'} += $punti;
        } elsif ($tipo eq '3') {
            $scontrino{'punti_utilizzati'} -= $punti;
        } elsif ($tipo eq '1') {
            $scontrino{'punti_articolo'} += $punti;
        } else {
        	$scontrino{'punti_utilizzati'} -= $punti; #reso
        }
    }
    
    if ($linea =~ /^.{31}:F:1.{27}(.{6})(.{10})/ and $scontrino_aperto) {
        $scontrino{'pezzi'} = $1*1;
        $scontrino{'totale'} = $2/100;
        
        #if ($scontrino{'totale'} != 0) {
            &salva_scontrino;
        #}
        $scontrino_aperto = 0;
    }
    
}

sub crea_nuovo_scontrino{
    %scontrino = ();
    
    $scontrino{'data'}              = '';
    $scontrino{'ora'}               = '';
    $scontrino{'negozio'}           = '';
    $scontrino{'cassa'}             = '';
    $scontrino{'transazione'}       = '';
    $scontrino{'pezzi'}             = 0;
    $scontrino{'totale'}            = 0;
    $scontrino{'totale_calcolato'}  = 0;
    $scontrino{'punti_articolo'}    = 0;
    $scontrino{'punti_transazione'} = 0;
    $scontrino{'punti_target'}      = 0;
    $scontrino{'punti_utilizzati'}  = 0;
    $scontrino{'sconto_totale'}     = 0;
    $scontrino{'carta'}           = '';
}

sub salva_scontrino{
    $scontrino{'pezzi'}             = sprintf('%2f',$scontrino{'pezzi'});
    $scontrino{'totale'}            = sprintf('%2f',$scontrino{'totale'});
    $scontrino{'totale_calcolato'}  = sprintf('%2f',$scontrino{'totale_calcolato'});
    $scontrino{'punti_articolo'}    = sprintf('%2f',$scontrino{'punti_articolo'});
    $scontrino{'punti_transazione'} = sprintf('%2f',$scontrino{'punti_transazione'});
    $scontrino{'punti_target'}      = sprintf('%2f',$scontrino{'punti_target'});
    $scontrino{'punti_utilizzati'}  = sprintf('%2f',$scontrino{'punti_utilizzati'});
    $scontrino{'sconto_totale'}     = sprintf('%2f',$scontrino{'sconto_totale'});
    
    if ($scontrino{'carta'} !~ /^046/) {
        $scontrino{'punti_articolo'}    = 0;
        $scontrino{'punti_transazione'} = 0;
        $scontrino{'punti_target'}      = 0;
        $scontrino{'punti_utilizzati'}  = 0;
    }
    
    
    my $sth = $dbh->prepare(qq{ select count(*) from $database.testate_ncr where data = ? and negozio = ? and cassa = ? and transazione = ?});
    $sth->execute($scontrino{'data'}, $scontrino{'negozio'}, $scontrino{'cassa'}, $scontrino{'transazione'});
    my $rows = $sth->fetchrow_arrayref->[0];
    $sth->finish;  
    
    if ($rows) {
        if (!$sth_update->execute(  $scontrino{'pezzi'}, $scontrino{'totale'}, $scontrino{'totale_calcolato'}, $scontrino{'punti_articolo'},
                                    $scontrino{'punti_transazione'}, $scontrino{'punti_target'}, $scontrino{'punti_utilizzati'}, $scontrino{'sconto_totale'},
                                    $scontrino{'carta'}, $scontrino{'data'}, $scontrino{'negozio'}, $scontrino{'cassa'}, $scontrino{'transazione'}))
        {print "Errore update\n";}
    } else {    
        if (!$sth_insert->execute(  $scontrino{'data'}, $scontrino{'ora'}, $scontrino{'negozio'}, $scontrino{'cassa'}, $scontrino{'transazione'},
                                    $scontrino{'pezzi'}, $scontrino{'totale'}, $scontrino{'totale_calcolato'}, $scontrino{'punti_articolo'},
                                    $scontrino{'punti_transazione'}, $scontrino{'punti_target'}, $scontrino{'punti_utilizzati'},$scontrino{'sconto_totale'},
                                    $scontrino{'carta'})) {
            print "Errore inserimento\n";
        }
    }
}

sub ConnessioneDB{
     $dbh = DBI->connect("DBI:mysql:$database:$hostname", $username, $password);
    if (! $dbh) {
        print "Errore durante la connessione al database: $database\n";
        return 0;
    } 
    my $sth;
    
    # creazione della tabella scontrini
    $sth = $dbh->prepare(qq{
        CREATE TABLE IF NOT EXISTS `testate_ncr` (
            `data` date NOT NULL,
            `ora` time NOT NULL,
            `negozio` varchar(4) NOT NULL DEFAULT '',
            `cassa` varchar(3) NOT NULL DEFAULT '',
            `transazione` varchar(4) NOT NULL DEFAULT '',
            `pezzi` float NOT NULL DEFAULT '0',
            `totale` float NOT NULL DEFAULT '0',
            `totale_calcolato` float NOT NULL DEFAULT '0',
            `punti_transazione` float NOT NULL DEFAULT '0',
            `punti_articolo` float NOT NULL DEFAULT '0',
            `punti_target` float NOT NULL DEFAULT '0',
            `punti_utilizzati` float NOT NULL DEFAULT '0',
            `sconto_totale` float NOT NULL DEFAULT '0',
            `carta` varchar(13) NOT NULL DEFAULT '',
            PRIMARY KEY (`data`,`negozio`,`cassa`,`transazione`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });
    
    if (!$sth->execute()) {
        print "Errore durante l'esecuzione di una query su db! " .$dbh->errstr."\n";
        return 0;
    }
    
    $sth->finish();    
    
    $sth_update = $dbh->prepare(qq{ update $database.testate_ncr set pezzi = ?,totale = ?,totale_calcolato = ?, punti_articolo = ?, punti_transazione = ?,
                                    punti_target = ?, punti_utilizzati = ?, sconto_totale = ?, carta = ? where data = ? and negozio = ? and cassa = ?
                                    and transazione = ?});
      
    $sth_insert = $dbh->prepare(qq{ insert into $database.testate_ncr(data, ora, negozio, cassa, transazione, pezzi, totale, totale_calcolato,
                                    punti_articolo, punti_transazione, punti_target, punti_utilizzati, sconto_totale, carta)
                                    values (?,?,?,?,?,?,?,?,?,?,?,?,?,?)});
                                    
    $sth_drop = $dbh->prepare(qq{ drop table if exists $database.totali_ncr});
    $sth_totali = $dbh->prepare(qq{create table $database.totali_ncr as select negozio, data, count(*) as `clienti`, round(sum(totale),2) as `totale` from $database.testate_ncr group by 1,2 order by 1,2});
    $sth_indici = $dbh->prepare(qq{alter table $database.totali_ncr add primary key(`negozio`,`data`)});
 
    
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