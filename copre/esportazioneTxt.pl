#!/usr/bin/perl
use strict;
use warnings;

use lib "/usr/local/ActivePerl-5.18/site/lib";

use DBI;
use DateTime;
use List::MoreUtils qw(firstidx);
use File::HomeDir;
use POSIX;

# date
#------------------------------------------------------------------------------------------------------------
my $dataCorrente = DateTime->today(time_zone=>'local');

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "10.11.14.78";#"localhost";
my $username = "root";
my $password = "mela";

# definizione cartelle
#----------------------------------------------------------------------------------------------------------------------
my $desktop = File::HomeDir->my_desktop;
my $mainFolder = "/catalogoB2B";
my $bkpFolder = "$mainFolder/bkp";

# Creazione cartelle locali (se non esistono)
#----------------------------------------------------------------------------------------------------------------------
unless (-e $mainFolder or mkdir $mainFolder) {die "Impossibile creare la cartella $mainFolder: $!\n";};
unless (-e $bkpFolder or mkdir $bkpFolder) {die "Impossibile creare la cartella $bkpFolder: $!\n";};


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
            
            if (open my $fileHandler, "+>:crlf", $mainFolder.'/'.$elencoClienti[$i].$fileName) {
                if ($elencoClienti[$i] eq 'EPRICE' || $elencoClienti[$i] eq 'ONLINESTORE') {
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
                    print $fileHandler "Disponibilitą\t";
                    print $fileHandler "Disponibilitą Futura\t";
                    print $fileHandler "Data Disponibilitą futura\t";
                    print $fileHandler "Prezzo Promozione\t";
                    print $fileHandler "Data Inizio Promo\t";
                    print $fileHandler "Data Fine Promo\t";
                    print $fileHandler "codice ean\t";
                    print $fileHandler "Siae\t";
                    print $fileHandler "Raee\t";
                    print $fileHandler "Link immagine\n";
                } elsif ($elencoClienti[$i] eq 'TEKWORLD') {
                    print $fileHandler "Cat;";
                    print $fileHandler "Scat;";
                    print $fileHandler "Idprod;";
                    print $fileHandler "Codven;";
                    print $fileHandler "Titolo;";
                    print $fileHandler "Descrizione;";
                    print $fileHandler "Peso in decagrammi;";
                    print $fileHandler "Prezzo;";
                    print $fileHandler "Prezzo Listino;";
                    print $fileHandler "Iva;";
                    print $fileHandler "Marca/Brand.;";
                    print $fileHandler "Disponibilita;";
                    print $fileHandler "Disponibilita Futura;";
                    print $fileHandler "Data Disponibilita futura;";
                    print $fileHandler "Prezzo Promozione;";
                    print $fileHandler "Data Inizio Promo;";
                    print $fileHandler "Data Fine Promo;";
                    print $fileHandler "codice ean;";
                    print $fileHandler "Siae;";
                    print $fileHandler "Raee;";
                    print $fileHandler "Link immagine\n";
                } elsif ($elencoClienti[$i] eq 'BRANDON') {
                	print $fileHandler "Cat;";
                    print $fileHandler "Scat;";
                    print $fileHandler "Idprod;";
                    print $fileHandler "Codven;";
                    print $fileHandler "Titolo;";
                    print $fileHandler "Descrizione;";
                    print $fileHandler "Peso in decagrammi;";
                    print $fileHandler "Prezzo;";
                    print $fileHandler "Prezzo Listino;";
                    print $fileHandler "Iva;";
                    print $fileHandler "Marca/Brand.;";
                    print $fileHandler "Disponibilitą;";
                    print $fileHandler "Disponibilitą Futura;";
                    print $fileHandler "Data Disponibilitą futura;";
                    print $fileHandler "Prezzo Promozione;";
                    print $fileHandler "Data Inizio Promo;";
                    print $fileHandler "Data Fine Promo;";
                    print $fileHandler "codice ean;";
                    print $fileHandler "Siae;";
                    print $fileHandler "Raee;";
                    print $fileHandler "Link immagine\n";
                } else {
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
                    print $fileHandler "Disponibilitą\t";
                    print $fileHandler "Disponibilitą Futura\t";
                    print $fileHandler "Data Disponibilitą futura\t";
                    print $fileHandler "Prezzo Promozione\t";
                    print $fileHandler "Data Inizio Promo\t";
                    print $fileHandler "Data Fine Promo\t";
                    print $fileHandler "codice ean\t";
                    print $fileHandler "Siae\t";
                    print $fileHandler "Raee\t";
                    print $fileHandler "Link immagine\n";
                }
                while (my @record = $sth->fetchrow_array()) {
                    
                    # lettura dei dati
                    # ---------------------------------------------------------------------------------------------------------------------------------------
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
                    my $prezzoCliente = $record[12];
                    my $prezzoNettoCliente = $record[13];
                    my $prezzoVendita = $record[14];
                    my $pndAC = $record[15]/100;
                    my $pndAP = $record[16]/100;
                    my $doppioNetto = $record[17];
                    my $ricarico01 = $record[18]/100;
                    my $ricarico02 = $record[19]/100;
                    my $ricarico03 = $record[20]/100;
                    my $ricarico04 = $record[21]/100;
                    my $aliquotaIva = $record[22];
                    my $inPromoDa = string2Date($record[23]);
                    my $inPromoA = string2Date($record[24]);
                    if($prezzoNettoCliente != 0) {                  
                        if ( DateTime->compare( $dataCorrente, $inPromoDa ) >= 0 and DateTime->compare( $dataCorrente, $inPromoA ) <= 0) {
                           $prezzoCliente = &arrotonda($prezzoNettoCliente);
                        }
                    }

                    my $prezzoVenditaNoIva = $prezzoVendita*100/(100 + $aliquotaIva);

        			# scrittura dati
                    # ---------------------------------------------------------------------------------------------------------------------------------------
                    if ($elencoClienti[$i] eq 'EPRICE') {
						print $fileHandler "$ediel01\t";
						print $fileHandler "$ediel02\t";
						print $fileHandler "$codice\t";
						print $fileHandler "$modello\t";
						print $fileHandler "$descrizione\t";
						print $fileHandler "$descrizione\t";
						print $fileHandler "\t";
						print $fileHandler sprintf('%.0f',$prezzoCliente*100)."\t";
						print $fileHandler sprintf('%.0f',$prezzoVenditaNoIva*100)."\t";
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
                    } elsif ($elencoClienti[$i] eq 'ONLINESTORE') {
						print $fileHandler "$ediel01\t";
						print $fileHandler "$ediel02\t";
						print $fileHandler "$codice\t";
						print $fileHandler "$modello\t";
						print $fileHandler "$descrizione\t";
						print $fileHandler "$descrizione\t";
						print $fileHandler "\t";
						print $fileHandler sprintf('%.2f',$prezzoCliente)."\t";
						print $fileHandler sprintf('%.2f',$prezzoVenditaNoIva)."\t";
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
                    } elsif ($elencoClienti[$i] eq 'TEKWORLD') {
						print $fileHandler "$ediel01;";
						print $fileHandler "$ediel02;";
						print $fileHandler "$codice;";
						print $fileHandler "$modello;";
						print $fileHandler "$descrizione;";
						print $fileHandler "$descrizione;";
						print $fileHandler ";";

						my $number;
						$number = sprintf('%.2f',$prezzoCliente);
						$number =~ s/\./\,/ig;
						print $fileHandler $number.";";

						$number = sprintf('%.2f',$prezzoVenditaNoIva);
						$number =~ s/\./\,/ig;
						print $fileHandler $number.";";

						print $fileHandler "$aliquotaIva;";
						print $fileHandler "$marchio;";
						print $fileHandler "$giacenza;";
						print $fileHandler "$inOrdine;";
						print $fileHandler ";";
						print $fileHandler ";";
						print $fileHandler ";";
						print $fileHandler ";";
						print $fileHandler "$barcode;";
						print $fileHandler ";";
						print $fileHandler ";";
						print $fileHandler "\n";
                   	} elsif ($elencoClienti[$i] eq 'BRANDON') {
                   		print $fileHandler "$ediel01;";
						print $fileHandler "$ediel02;";
						print $fileHandler "$codice;";
						print $fileHandler "$modello;";
						print $fileHandler "$descrizione;";
						print $fileHandler "$descrizione;";
						print $fileHandler ";";
						print $fileHandler sprintf('%.2f',$prezzoCliente).";";
						print $fileHandler sprintf('%.2f',$prezzoVenditaNoIva).";";
						print $fileHandler "$aliquotaIva;";
						print $fileHandler "$marchio;";
						print $fileHandler "$giacenza;";
						print $fileHandler "$inOrdine;";
						print $fileHandler ";";
						print $fileHandler ";";
						print $fileHandler ";";
						print $fileHandler ";";
						print $fileHandler "$barcode;";
						print $fileHandler ";";
						print $fileHandler ";";
						print $fileHandler "\n";
                   	} else {
                        print $fileHandler "$ediel01\t";
						print $fileHandler "$ediel02\t";
						print $fileHandler "$codice\t";
						print $fileHandler "$modello\t";
						print $fileHandler "$descrizione\t";
						print $fileHandler "$descrizione\t";
						print $fileHandler "\t";
						print $fileHandler sprintf('%.2f',$prezzoCliente)."\t";
						print $fileHandler sprintf('%.2f',$prezzoVenditaNoIva)."\t";
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
	if ($data =~ /^(\d{4}).(\d{2}).(\d{2})$/ and $data ne '0000-00-00') {
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
                                c.`prezzoCliente`,
                                c.`prezzoNettoCliente`,
                                t.`prezzoVendita`,
                                t.`pndAC`,
                                t.`pndAP`,
                                t.`doppioNetto`,
                                c.`ricarico01`,
                                c.`ricarico02`,
                                c.`ricarico03`,
                                c.`ricarico04`,
                                t.`aliquotaIva`,
                                c.`inPromoDa`,
                                c.`inPromoA`
								from tabulatoCopre as t join tabulatoCliente as c on t.`codice`=c.`codiceArticolo` join ediel01 as e01 on t.`ediel01`= e01.`codice` join ediel02 as e02 on concat(t.`ediel01`,t.`ediel02`)= e02.`codice` left join ediel03 as e03 on concat(t.`ediel01`,t.`ediel02`,t.`ediel03`)= e03.`codice` left join ediel04 as e04 on concat(t.`ediel01`,t.`ediel02`,t.`ediel03`,t.`ediel04`)= e04.`codice` left join marcheGCC as m on t.`marchio`=m.`codice`
								where c.`codiceCliente`= ? and
								(
									(((t.`giacenza`> 1 or t.`inOrdine`> 0) and t.`canale` = 1 and t.`ordinabile` = 1) or (t.`codice` in (select distinct p.`codiceArticolo` from politicaVendita as p where p.`categoria`= ? and p.`codiceArticolo`<>''))) or
									(t.`codice` in (select codice from articoliObbligatori))
								)
								and t.`doppioNetto`<>0 and t.`marchio` not in ('CLL','EXT','LIE','LOE','MIE','NRD','NTM','SBS','EAS','MEP','CAO','BLC','VIT','FAB','ACT','ADI','APO','AQL','ASF','ATT','BKB','BLC','BLR','BLJ','BPO','CEL','WEB','WAR','WAM','FOX','NTA') and t.`marchioCopre` not in ('MIELE') and t.`doppioNetto`>= 5.00 and c.`data` = (select max(data) from tabulatoCliente where codiceCliente = ?)  and
								t.`codice` <> '0702725087' and t.`codice` <> '0205764016' and t.`codice` <> '0212764005' and t.`codice` <> '0910762009' and t.`codice` <> '0208725002' and t.`codice` <> '0702725075' and t.`codice` <> '0702725088' and t.`codice` <> '0205725004' and t.`codice` <> '0205725008' and t.`codice` <> '4277251195' and t.`codice` <> '2212102014' and t.`codice` <> '2210102021' and t.`codice` <> '1305147003' and t.`codice` <> '0205253127' 
								order by 1;
							});

    return 1;
}

