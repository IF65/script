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
my %scontrino;
my $codice_negozio;
my $data;
my $linea;
my $tipo_linea;

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
    print "Utilizzo: perl [path]carica_dc_epipoli.pl [-d path] -d data -s sede\n\n";
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
    my $file = 'DC'.$data->ymd('').'0'.$param_sede.'001.DAT';
    if (open my $file_handler, "<:crlf", $param_path.$file) {
        while(! eof ($file_handler))  {
            $linea = <$file_handler>;
            $linea =~ s/\n$//ig;
            
            &analizza_contenuto_linea($linea);      
        }
        close($file_handler)
    } else {die $param_path.$file.": $!\n"}
} else {die;}

$sth_update->finish();
$sth_insert->finish();

sub determina_tipo_linea{
    my($linea)          = @_    ;
    my $tipo_linea              ;   #0=testata; 1=movimento
    my $return_value    = 0     ;   #0=errore; 1=testata; 2=movimento; 3=totale
    
    if ($linea =~ /^(?:.{21})(0|1)/) {
        $tipo_linea = $1;
    } else {
        return 0;
    };

    if ($tipo_linea == 0) {
        $return_value = 1;
    } else {
        if ($linea =~ /^(?:.{23})(?:20)/) {
            $return_value = 3;
        } else {
            $return_value = 2;
        }
        
    }
    
    return $return_value;
}

sub analizza_contenuto_linea{
    my($linea) = @_;
    
    my $operazione_diretta;
    my $tipo_linea = &determina_tipo_linea($linea);
    
    if ($tipo_linea == 1) {
        &crea_nuovo_scontrino;
        
        if ($linea =~ /^(\d{4})(\d{2})(\d{2})(?:.{8})(\d{4})(?:.{4})(\d{4})\d(\d{3})(?:.{6})(?:.{8})(\d{2})(\d{2})((\s|\d){13})/) {
            $scontrino{'data'}          = $1.'-'.$2.'-'.$3;
            $scontrino{'ora'}           = $7.':'.$8.':00';
            $scontrino{'negozio'}       = $4;
            $scontrino{'cassa'}         = $6;
            $scontrino{'transazione'}   = $5;
            $scontrino{'carta'}         = $9;
        }
    } elsif ($tipo_linea == 2) {       
        # vendita generica tipo 01
        if ($linea =~ /^(?:.{22})(0|1)01(?:.{18})(\d{9})/) {
            if ($1 == '0') {
                $scontrino{'totale_calcolato'}  += $2/100;
            } else {
                $scontrino{'totale_calcolato'}  -= $2/100;
            }
        } elsif ($linea =~ /^(?:.{22})(0|1)02(?:.{18})(\d{9})/) { # reso tipo 01
            if ($1 == '0') {
                $scontrino{'totale_calcolato'}  -= $2/100;
            } else {
                $scontrino{'totale_calcolato'}  += $2/100;
            }
        }elsif ($linea =~ /^(?:.{22})(0|1)09(?:.{18})(\d{9})/) {# sconto generico tipo b tipo 09
            if ($1 == '0') {
                $scontrino{'totale_calcolato'}  -= $2/100;
                $scontrino{'sconto_totale'}     += $2/100;
            } else {
                $scontrino{'totale_calcolato'}  += $2/100;
                $scontrino{'sconto_totale'}     -= $2/100;
            }
        } elsif ($linea =~ /^(?:.{22})(0|1)10(?:.{18})(\d{9})/) {# sconto generico tipo c tipo 10
            if ($1 == '0') {
                $scontrino{'totale_calcolato'}  -= $2/100;
                $scontrino{'sconto_totale'}     += $2/100;
            } else {
                $scontrino{'totale_calcolato'}  += $2/100;
                $scontrino{'sconto_totale'}     -= $2/100;
            }
        } elsif ($linea =~ /^(?:.{22})(0|1)11(?:.{18})(\d{9})/) {# sconto generico tipo d tipo 11
            if ($1 == '0') {
                $scontrino{'totale_calcolato'}  -= $2/100;
                $scontrino{'sconto_totale'}     += $2/100;
            } else {
                $scontrino{'totale_calcolato'}  += $2/100;
                $scontrino{'sconto_totale'}     -= $2/100;
            }
        } elsif ($linea =~ /^(?:.{22})(0|1)13(?:.{18})(\d{9})/) {# sconto mass market tipo 13
            if ($1 == '0') {
                $scontrino{'totale_calcolato'}  -= $2/100;
                $scontrino{'sconto_totale'}     += $2/100;
            } else {
                $scontrino{'totale_calcolato'}  += $2/100;
                $scontrino{'sconto_totale'}     -= $2/100;
            }
        } elsif ($linea =~ /^(?:.{22})(0|1)51(?:.{18})(\d{9})/) {# sconto mass market tipo 51
            if ($1 == '0') {
                $scontrino{'totale_calcolato'}  -= $2/100;
            } else {
                $scontrino{'totale_calcolato'}  += $2/100;
            }
        } elsif ($linea =~ /^(?:.{22})(0|1)91(?:.{18})(\d{9})/) {# sconto articolo tipo 91
            if ($1 == '0') {
                $scontrino{'totale_calcolato'}  -= $2/100;
                $scontrino{'sconto_totale'}     += $2/100;
            } else {
                $scontrino{'totale_calcolato'}  += $2/100;
                $scontrino{'sconto_totale'}     -= $2/100;
            }
        } elsif ($linea =~ /^(?:.{22})(0|1)85(?:.{18})(\d{9})/) {# sconto reparto tipo 85
            if ($1 == '0') {
                $scontrino{'totale_calcolato'}  -= $2/100;
                $scontrino{'sconto_totale'}     += $2/100;
            } else {
                $scontrino{'totale_calcolato'}  += $2/100;
                $scontrino{'sconto_totale'}     -= $2/100;
            }
        } elsif ($linea =~ /^(?:.{22})(0|1)86(?:.{18})(\d{9})/) {# sconto transazione tipo 86
            if ($1 == '0') {
                $scontrino{'totale_calcolato'}  -= $2/100;
                $scontrino{'sconto_totale'}     += $2/100;
            } else {
                $scontrino{'totale_calcolato'}  += $2/100;
                $scontrino{'sconto_totale'}     -= $2/100;
            }
        } elsif ($linea =~ /^(?:.{22})(0|1)90(?:.{18})(\d{9})/) {# premio collection tipo 90
            if ($1 == '0') {
                $scontrino{'punti_utilizzati'}  += $2;
            } else {
                $scontrino{'punti_utilizzati'}  -= $2;
            }
        } elsif ($linea =~ /^(?:.{22})(0|1)98(?:.{18})(\d{9})/) {# premio set tipo 98
            if ($1 == '0') {
                $scontrino{'punti_utilizzati'}  += $2;
            } else {
                $scontrino{'punti_utilizzati'}  -= $2;
            }
        } elsif ($linea =~ /^(?:.{22})(0|1)77(?:.{18})(\d{9})/) {# beneficio transazionale tipo 77           
            $scontrino{'punti_transazione'} += $2;
        } elsif ($linea =~ /^(?:.{22})(0|1)89(?:.{18})(\d{9})/) {# punti articolo tipo 89
            $scontrino{'punti_articolo'}    += $2;
        } elsif ($linea =~ /^(?:.{22})(0|1)74(?:.{18})(\d{9})/) {# punti reparto tipo 74
            $scontrino{'punti_articolo'}    += $2;
        } elsif ($linea =~ /^(?:.{22})(0|1)93(?:.{18})(\d{9})/) {# punti collection multitarget tipo 93
            if ($1 == '0') {
                $scontrino{'punti_utilizzati'}  += $2;
            } else {
                $scontrino{'punti_utilizzati'}  -= $2;
            }
        } elsif ($linea =~ /^(?:.{22})(0|1)94(?:.{18})(\d{9})/) {# sconto multitarget tipo 94
            if ($1 == '0') {
                $scontrino{'totale_calcolato'}  -= $2/100;
            } else {
                $scontrino{'totale_calcolato'}  += $2/100;
            }
        } elsif($linea =~ /^(?:.{22})(0|1)(?:21|22|23|24|25|26|27|28|98)(?:.{18})((?:\-|\d){9})/) {
            
        }
        
    } elsif ($tipo_linea == 3) {
        if ($linea =~ /^(?:.{22})(?:.{21})((?:\-|\d){9})/) {
            $scontrino{'totale'}            = $1/100;
        }
        &salva_scontrino;
    } else {
        print "errore\n";
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
    
    my $sth = $dbh->prepare(qq{ select count(*) from $database.scontrini_ep where data = ? and negozio = ? and cassa = ? and transazione = ?});
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
        CREATE TABLE IF NOT EXISTS `scontrini_ep` (
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
    
    $sth_update = $dbh->prepare(qq{ update $database.scontrini_ep set pezzi = ?,totale = ?,totale_calcolato = ?, punti_articolo = ?, punti_transazione = ?,
                                    punti_target = ?, punti_utilizzati = ?, sconto_totale = ?, carta = ? where data = ? and negozio = ? and cassa = ?
                                    and transazione = ?});
      
    $sth_insert = $dbh->prepare(qq{ insert into $database.scontrini_ep(data, ora, negozio, cassa, transazione, pezzi, totale, totale_calcolato,
                                    punti_articolo, punti_transazione, punti_target, punti_utilizzati, sconto_totale, carta)
                                    values (?,?,?,?,?,?,?,?,?,?,?,?,?,?)});
    
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