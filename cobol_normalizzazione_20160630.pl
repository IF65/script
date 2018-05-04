#!/usr/bin/perl
use strict;
use warnings;
use File::HomeDir;
use File::Copy;

my $desktop = File::HomeDir->my_desktop;

# cartella contenente i file da convertire
#------------------------------------------------------------------------------------------------------------
my $cartella_cobol = $desktop.'/cobol';
my $cartella_dati_da_convertire = $cartella_cobol.'/da_convertire';
my $cartella_dati_convertiti = $cartella_cobol.'/convertiti';
my $cartella_bkp = $desktop.'/cobol/bkp';

# Creazione cartelle locali (se non esistono)
#------------------------------------------------------------------------------------------------------------
unless(-e $cartella_cobol or mkdir $cartella_cobol) {die "Impossibile creare la cartella $cartella_cobol: $!\n";};
unless(-e $cartella_dati_da_convertire or mkdir $cartella_dati_da_convertire) {die "Impossibile creare la cartella $cartella_dati_da_convertire: $!\n";};
unless(-e $cartella_dati_convertiti or mkdir $cartella_dati_convertiti) {die "Impossibile creare la cartella $cartella_dati_convertiti: $!\n";};
unless(-e $cartella_bkp or mkdir $cartella_bkp) {die "Impossibile creare la cartella $cartella_bkp: $!\n";};

# parametri di conversione
#------------------------------------------------------------------------------------------------------------
my $lunghezza_max_linea = 66;


# ricerco i documenti contenuti in ognuna delle cartelle trovate
opendir my($DIR), "$cartella_dati_da_convertire" or die "Non è stato possibile aprire la cartella $cartella_dati_da_convertire: $!\n";
my @elenco_documenti = grep { /^[^\.]/ } readdir $DIR;
closedir $DIR;

foreach my $file (@elenco_documenti) {
    my $spazi_iniziali = 1;
    my @linee_normalizzate = ();
    if (open my $hdl_convertito, "+>", "$cartella_dati_convertiti/$file") {
        if (open my $hdl_da_convertire, "<:crlf", "$cartella_dati_da_convertire/$file") {
            
            while(! eof ($hdl_da_convertire) && $spazi_iniziali)  {
                if (<$hdl_da_convertire> !~ /^\s{6}/) {
                    $spazi_iniziali = 0
                }
            }
            seek $hdl_da_convertire, 0, 0;
            while(! eof ($hdl_da_convertire))  {
                my $linea = <$hdl_da_convertire>;
                
                if ($spazi_iniziali) {
                    $linea =~ s/^\s{6}//
                }
                $linea =~ s/\n$//ig;
                if ($linea =~ /^(\s*)([^\s].*)$/) {
                    my $indent = $1;
                    my $text = $2;
                    
                    #$text =~ s/\h+/ /g;
                    my $indent_length = length $indent;
                    my $text_length = length $text;
                    if ($linea !~ /^.{66}\./ && $linea !~ /^\*/ && $indent_length + $text_length > $lunghezza_max_linea) {
                        
                        my $apici_aperti = 0;
                        my @chars = split(//, $text);
                        for (my $i=0; $i<@chars; $i++) {
                            if ($chars[$i] eq '"') {$apici_aperti = not($apici_aperti)}
                            #if ($chars[$i] eq ' ' && $apici_aperti) {$chars[$i] = '@'}
                            if ($chars[$i] eq ' ') {$chars[$i] = '@'}
                        }
                        my $new_text = join('', @chars);
                        
                        my @words = split(/\@/, $new_text);
                        
                        my @linee_modificate = ();
                        my $linea_modificata = $indent;
                        foreach my $word (@words) {
                            my $word_length = length($word) + 1;
                            my $linea_modificata_length = length($linea_modificata);
                            if ($linea_modificata_length + $word_length < $lunghezza_max_linea) {
                               $linea_modificata .= $word.' ';
                            } else {
                                if ($word =~ /^".*"$/) {
                                    my $linea_modificata_1= substr($linea_modificata.$word, 0, $lunghezza_max_linea);
                                    my $linea_modificata_2= substr($linea_modificata.$word, $lunghezza_max_linea);
                                    
                                    my $inserisci_apice = 0;
                                    if ($linea_modificata_2 =~ /^[^"]*"/) {
                                        $linea_modificata_2 = '"'.$linea_modificata_2;
                                        $inserisci_apice = 1;
                                    };
                                    push @linee_modificate, $linea_modificata_1;
                                    $linea_modificata = $indent.$linea_modificata_2.' ';
                                    if ($inserisci_apice && $linea_modificata =~ /^[^"]*"/) {$linea_modificata =~ s/^./-/};
                                } else {
                                    push @linee_modificate, $linea_modificata;
                                    
                                    my $inserisci_apice = 0;
                                    my @characters = split(//,$linea_modificata);
                                    for (my $o=0; $o<@characters; $o++) {
                                    if ($characters[$o] eq '"') {$inserisci_apice = not($inserisci_apice)}
                                    }
#                                    if ($linea_modificata =~ /^([^\"]*\"[^\"]*\"|[^\"]*\"[^\"]*\"[^\"]*[^\"]*\"[^\"]*\").*$/) {$inserisci_apice = 1}
                                    
                                    $linea_modificata = $indent.$word.' ';
#                                   if ($inserisci_apice) {$linea_modificata = $indent.$word.'"'}
                                    if ($inserisci_apice) {$linea_modificata = $indent.'"'.$word}
                                    #$linea_modificata =~ s/^(\s*)(\s)([^\s\"].*)$/$1\ \"$3/;
                                    if ($inserisci_apice && $linea_modificata =~ /^.*"/) {$linea_modificata =~ s/^./-/};
                                }
                            }
                        }
                        push @linee_modificate, $linea_modificata;
                        
                        splice(@linee_normalizzate, @linee_normalizzate, 0, @linee_modificate);
                    } else {
                    	if ($linea =~ /^(.{66})\.$/) {
                    		push @linee_normalizzate, $1;
                    		push @linee_normalizzate, $indent.'.'
                    	}
                    	else {
                        	push @linee_normalizzate, $linea
                        }
                    }
                }
            }
            
            
            
            
            
            close $hdl_da_convertire;
            
            move("$cartella_dati_da_convertire/$file", "$cartella_bkp/$file");
        }
        
        foreach my $linea (@linee_normalizzate) {
            $linea =~ s/@/ /ig;
            #if ($spazi_iniziali) {
            if (0) { 
                $linea =~ s/^/      /
            }
            print $hdl_convertito "$linea\n";
        }
        close($hdl_convertito);
    }
}
	