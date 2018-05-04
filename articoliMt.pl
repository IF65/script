#!/usr/bin/perl

use strict;
use warnings;

use DBI;
use Getopt::Long;
use XML::LibXML;

# database
# --------------------------------------------------------------------------------------
my $hostname = '10.11.14.78';
my $username = 'root';
my $password = 'mela';
my $database = 'db_sm';
my $table = 'listino_usato';

# handler
# --------------------------------------------------------------------------------------
my $dbh;
my $sth;

# input arguments
# --------------------------------------------------------------------------------------
my $filename;
my $help;
if (@ARGV == 0) {
    $help = 1
}

GetOptions(
	'f=s{1,1}'	=> \$filename,
    'help'      => \$help,
) or die "parametri non corretti!\n";

if ($help) {
    print "Utilizzo: perl [path]articoliMt.pl -f /path/fileName [--help]\n\n";
    
    die "\n";
}

if (&ConnessioneDB) {

    my $parser = XML::LibXML->new();
    my $xmldoc = $parser->parse_file($filename);
    
    for my $node ($xmldoc->findnodes('/BEESTORE/HEADER/Articolo')) {
        # creo il singolo hash dell'articolo che sto' leggendo
        my %articolo =();
        
        # recupero il riferimento a tutti i nodi contenuto in ogni articolo 
        foreach my $property ($node->findnodes('./*')) {
             $articolo{$property->nodeName()} = $property->textContent();
        }
        
        my $barcode = $articolo{'Modello'};
        my $barcodeAggiuntivo = $articolo{'BarCode'};
        my $provenienza = $articolo{'Nota'};
        my $tipo = $articolo{'DSStagione'};
        my $piattaforma = $articolo{'DSReparto'};
        my $descrizione = $articolo{'DSArticolo'};
        my $marca = $articolo{'DSMarca'};
        my $dayOne = $articolo{'DayOne'};
        my $codiceIva = $articolo{'CodIva'};
        my $aliquotaIva = 22;
        my $prezzoVenditaIvato = $articolo{'PrezzoIvato'};
        my $costo = $articolo{'Costo'};
        
        
        $barcode =~ s/^\s+|\s+$//g;
        $barcodeAggiuntivo =~ s/^\s+|\s+$//g;
        $provenienza =~ s/^\s+|\s+$//g;
        $piattaforma =~ s/^\s+|\s+$//g;
        if ($descrizione =~ /^.*\|(.*)$/) {
            $descrizione = $1;
        }
        $descrizione =~ s/^\s+|\s+$//g;
        if($dayOne =~ /^(\d{2})\/(\d{2})\/(\d{4})$/) {
            $dayOne = $3.'-'.$2.'-'.$1;
        }
        $marca =~ s/^\s+|\s+$//g;
        $prezzoVenditaIvato =~ s/\,/\./gi;
        $costo =~ s/\,/\./gi; 
               
        if(0) {       
			print "file: $filename\n";       
			print "barcode: $barcode\n";
			print "barcode Agg.: $barcodeAggiuntivo\n";
			print "tipo: $tipo\n";
			print "provenienza: $provenienza\n";
			print "piattaforma: $piattaforma\n";
			print "descrizione: $descrizione\n";
			print "marca: $marca\n";
			print "dayOne: $dayOne\n";
			print "codice Iva: $codiceIva\n";
			print "aliquota Iva: $aliquotaIva\n";
			print "prezzo Vendita: $prezzoVenditaIvato\n";
			print "costo: $costo\n";
		}
        
        if( !$sth->execute($barcode,$barcodeAggiuntivo,$tipo,$provenienza,$piattaforma,$descrizione,$marca,$dayOne,$codiceIva,$aliquotaIva*1,$prezzoVenditaIvato*1,$costo*1)) {
            print "Errore nell'inserimento della promozione \n";
        };
        
    }
    
    $sth->finish();
    $dbh->disconnect();
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
        CREATE DATABASE IF NOT EXISTS `$database`
        DEFAULT CHARACTER SET = latin1
        DEFAULT COLLATE = latin1_swedish_ci
    });
    if (!$sth->execute()) {
        print "Errore durante la creazione del database `$database`! " .$dbh->errstr."\n";
        return 0;
    }
    $dbh->disconnect();
    
    # connessione al database
    $dbh = DBI->connect("DBI:mysql:$database:$hostname", $username, $password);
    if (! $dbh) {
        print "Errore durante la connessione al database `$database`!\n";
        return 0;
    }
    
    # creazione della tabella campagne
    $sth = $dbh->prepare(qq{
        CREATE TABLE IF NOT EXISTS `$table` (
            `barcode` varchar(13) NOT NULL DEFAULT '',
            `barcodeAggiuntivo` varchar(13) NOT NULL,
            `tipo` varchar(50) NOT NULL,
            `provenienza` varchar(50) NOT NULL DEFAULT '',
            `piattaforma` varchar(50) NOT NULL,
            `descrizione` varchar(100) NOT NULL DEFAULT '',
            `marca` varchar(100) NOT NULL DEFAULT '',
            `dayOne` date NOT NULL,
            `codiceIva` varchar(10) NOT NULL DEFAULT '2200',
            `aliquotaIva` float NOT NULL DEFAULT '22',
            `prezzoVenditaIvato` float NOT NULL DEFAULT '0',
            `costo` float NOT NULL DEFAULT '0',
            `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`barcode`)
        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });
    if (!$sth->execute()) {
        print "Errore durante la creazione della tabella `$table`! " .$dbh->errstr."\n";
        return 0;
    }
    $sth->finish();
    
    # inserimento/aggiornamento tabella campagne
    $sth = $dbh->prepare(qq{
        INSERT INTO `$table`
                (barcode, barcodeAggiuntivo, tipo, provenienza, piattaforma, descrizione, marca, dayOne, codiceIva, aliquotaIva, prezzoVenditaIvato, costo)
        VALUES  (?,?,?,?,?,?,?,?,?,?,?,?)
        ON DUPLICATE KEY UPDATE
                barcodeAggiuntivo=values(barcodeAggiuntivo),
                tipo=values(tipo),
                provenienza=values(provenienza),
                piattaforma=values(piattaforma),
                descrizione=values(descrizione),
                marca=values(marca),
                dayOne=values(dayOne),
                codiceIva=values(codiceIva),
                aliquotaIva=values(aliquotaIva),
                prezzoVenditaIvato=values(prezzoVenditaIvato),
                costo=values(costo);});
    
    
		
    return 1;
}