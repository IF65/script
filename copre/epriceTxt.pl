#!/usr/bin/perl
use strict;
use warnings;

use lib "/usr/local/ActivePerl-5.18/site/lib";

use DBI;
use DateTime;
use List::MoreUtils qw(firstidx);
use File::HomeDir;
use POSIX;

my $desktop     = File::HomeDir->my_desktop;

# date
#------------------------------------------------------------------------------------------------------------
my $dataCorrente = DateTime->today(time_zone=>'local');
my $annoCorrente = $dataCorrente->year();
my $annoPrecedente = $annoCorrente - 1;
my $meseCorrente = $dataCorrente->month();

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "10.11.14.78";
my $username = "root";
my $password = "mela";

# parametri del file txt di output
#------------------------------------------------------------------------------------------------------------
my $fileName = "_Catalogo.txt";

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh; 
my $sth; 

my %clienti;

if (&ConnessioneDB) {
    
    #tabulato con politica vendita filtrato
    #-------------------------------------------------------------------------------------------------
    my @elencoClienti = ( keys %clienti );
    
    for (my $i = 0; $i < @elencoClienti; $i++) {
        if ($sth->execute($elencoClienti[$i], $clienti{$elencoClienti[$i]}{'categoria'}, $elencoClienti[$i])) {
  
            if (open my $fileHandler, "+>:crlf", $desktop.'/'.$elencoClienti[$i].$fileName) {
                
                print $fileHandler "Cat\t";
                print $fileHandler "Scat\t";
                print $fileHandler "Idprod\t";
                print $fileHandler "Codven\t";
                print $fileHandler "Titolo\t";
                print $fileHandler "Descrizione\t";
                print $fileHandler "Peso in decagrammi\t";
                print $fileHandler "Prezzo\t";
                print $fileHandler "Prezzo Listino\t";
                print $fileHandler "Iva\t";
                print $fileHandler "Marca/Brand.\t";
                print $fileHandler "Disponibilitˆ\t";
                print $fileHandler "Disponibilitˆ Futura\t";
                print $fileHandler "Data Disponibilitˆ futura\t";
                print $fileHandler "Prezzo Promozione\t";
                print $fileHandler "Data Inizio Promo\t";
                print $fileHandler "Data Fine Promo\t";
                print $fileHandler "codice ean\t"; 
                print $fileHandler "Siae\t";
                print $fileHandler "Raee\t";
                print $fileHandler "Link immagine\n";
                
                while (my @record = $sth->fetchrow_array()) {
                    
                    my $codice = $record[0]; 
                    my $barcode = $record[1]; 
                    my $modello = $record[2]; 
                    my $descrizione = $record[3]; 
                    my $ediel01 = $record[4]; 
                    my $ediel02 = $record[5]; 
                    my $ediel03 = $record[6]; 
                    my $ediel04 = $record[7]; 
                    my $marchio = $record[8]; 
                    my $canale = $record[9]; 
                    my $giacenza = $record[10]; 
                    my $inOrdine = $record[11]; 
                    my $prezzoAcquisto = $record[12]; 
                    my $ricaricoPercentuale = $record[13]/100; 
                    my $prezzoVendita = $record[14]; 
                    my $pndAC = $record[15]/100; 
                    my $pndAP = $record[16]/100; 
                    my $doppioNetto = $record[17]; 
                    my $ricarico01 = $record[18]/100; 
                    my $ricarico02 = $record[19]/100; 
                    my $ricarico03 = $record[20]/100; 
                    my $ricarico04 = $record[21]/100;
                    my $aliquotaIva = $record[22];
                    
                    my $prezzoVenditaNoIva = $prezzoVendita*100/(100 + $aliquotaIva);
                    my $feeCopre = $prezzoAcquisto*$ricaricoPercentuale/(1+$ricaricoPercentuale);
                    my $prezzoNetNet = $doppioNetto - $doppioNetto*($pndAC+$pndAP) + $feeCopre;
                    my $prezzoEPrice = $prezzoNetNet + $prezzoNetNet*($ricarico01 + $ricarico02 + $ricarico03 + $ricarico04);
        
                    print $fileHandler "$ediel01\t";
                    print $fileHandler "$ediel02\t";
                    print $fileHandler "$codice\t";
                    print $fileHandler "$modello\t";
                    print $fileHandler "$descrizione\t";
                    print $fileHandler "$descrizione\t";
                    print $fileHandler "\t";
                    if ($elencoClienti[$i] eq 'ONLINESTORE') {
                    	print $fileHandler sprintf('%.2f',&arrotonda($prezzoEPrice))."\t";
                    	print $fileHandler sprintf('%.2f',$prezzoVenditaNoIva)."\t";
                    } else {
                    	print $fileHandler sprintf('%.0f',&arrotonda($prezzoEPrice)*100)."\t";
                    	print $fileHandler sprintf('%.0f',$prezzoVenditaNoIva*100)."\t";
                    }
                    print $fileHandler "$aliquotaIva\t";
                    print $fileHandler "$marchio\t";
                    print $fileHandler "$giacenza\t";
                    print $fileHandler "$inOrdine\t";
                    print $fileHandler "\t";
                    print $fileHandler "\t";
                    print $fileHandler "\t";
                    print $fileHandler "\t";
                    print $fileHandler "$barcode\t";
                    print $fileHandler "\t";
                    print $fileHandler "\t";
                    print $fileHandler "\n";
                    
                }
            }
        }
        
    }
}

exit;

sub arrotonda {
    my ($importo) = @_;
 
    my $parteIntera = sprintf('%d', $importo)*1;
    my $parteDecimale = sprintf('%.2f', $importo - $parteIntera)*1;
    
    my $importoArrotondato = 0;
    if ($importo <10 && $importo > 0.03) {
        $importoArrotondato = $parteIntera + ceil($parteDecimale*10)/10;
    } elsif ($importo >= 10 && $importo < 100) {
        if ($parteDecimale < 0.20) {
            $importoArrotondato = $parteIntera;
        } elsif ($parteDecimale >= 0.20 && $parteDecimale < 0.70) {
            $importoArrotondato = $parteIntera + 0.5;
        } else {
             $importoArrotondato = $parteIntera + 1;
        }
        
    } else {
        if ($parteDecimale < 0.30) {
            $importoArrotondato = $parteIntera;
        } else {
            $importoArrotondato = $parteIntera + 1;
        }
    }
    
    return $importoArrotondato;
}

sub string2Date { #trasformo una data un oggetto DateTime
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

sub ConnessioneDB {
	# connessione al database negozi
	$dbh = DBI->connect("DBI:mysql:copre:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database!\n";
		return 0;
	}

    # caricamento elenco clienti
    $sth = $dbh->prepare(qq{select codice, categoria from clienti order by 1});
    if ($sth->execute()) {
        while (my @record = $sth->fetchrow_array()) {
            $clienti{$record[0]} = { 'categoria' => $record[1] };
        }
    }
    
    $sth = $dbh->prepare(qq{select 
                                t.`codice`, 
                                t.`barcode`, 
                                upper(t.`modello`),
                                upper(t.`descrizione`), 
                                e01.`descrizione` `ediel01`,
                                e02.`descrizione` `ediel02`, 
                                ifnull(e03.`descrizione`,'INDEFINITO') `ediel03`, 
                                ifnull(e04.`descrizione`,'INDEFINITO') `ediel04`,
                                upper(ifnull(m.`descrizione`,t.`marchioCopre`)), 
                                t.`canale`, 
                                t.`giacenza`, 
                                t.`inOrdine`, 
                                t.`prezzoAcquisto`, 
                                t.`ricaricoPercentuale`,
                                t.`prezzoVendita`,
                                t.`pndAC`, 
                                t.`pndAP`, 
                                t.`doppioNetto`,
                                c.`ricarico01`,
                                c.`ricarico02`,
                                c.`ricarico03`,
                                c.`ricarico04`,
                                t.`aliquotaIva`
                            from tabulatoCopre as t join tabulatoCliente as c on t.`codice`=c.`codiceArticolo` join ediel01 as e01 on t.`ediel01`= e01.`codice` join ediel02 as e02 on concat(t.`ediel01`,t.`ediel02`)= e02.`codice` left join ediel03 as e03 on concat(t.`ediel01`,t.`ediel02`,t.`ediel03`)= e03.`codice` left join ediel04 as e04 on concat(t.`ediel01`,t.`ediel02`,t.`ediel03`,t.`ediel04`)= e04.`codice` left join marcheGCC as m on t.`marchio`=m.`codice`
                            where c.`codiceCliente`= ? and (((t.`inOrdine`<>0 or t.`giacenza`<>0) and t.`canale` = 1 and t.`ordinabile` = 1) or (t.`codice` in (select distinct p.`codiceArticolo` from politicaVendita as p where p.`categoria`= ? and p.`codiceArticolo`<>''))) and t.`doppioNetto`<>0 and t.`marchio` not in ('ASK','BSE','CLL','EXT','GOP','LIE','LOE','MIE','NIK','NRD','NTM','SBS','SNS','TRB','YAM','EAS','MEP','CAO','BLC','VIT','FAB','ACT','ADI','APO','AQL','ASF','ATT','BKB','BLC','BLR','BLJ','BNM','BOC','BPO','CEL','WEB','WAR','WAM','FOX') and 
                            t.`marchioCopre` not in ('MIELE') and t.`doppioNetto`>= 5.00 and c.`data` = (select max(data) from tabulatoCliente where codiceCliente = ?) order by 1;});
        
    return 1;
}
