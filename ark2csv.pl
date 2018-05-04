# Questo script permette di convertire in formato CSV un file di testo UFAS proveniente dal DPS7000

#!/perl/bin/perl
use strict; # pragma che dice all'interprete di essere rigido nel controllo della sintassi
use warnings; # pragma che dice all'interprete di mostrare eventuali warnings
use Getopt::Long;
use File::Basename;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
my %opts;
use Log::Log4perl;
use Text::Unidecode;

eval("use DBI;"); die "[err] DBI is not installed.\n" if $@;


# define our command line flags (long and short versions).
GetOptions(\%opts, 'fdfile|f=s',    # fd file da utilizzzare come struttura   
                   'archive|a=s',   # archivio txt da convertire 
                   'table|t=s',     # nome della tabella da creare
                   'guft|g=s',      # flag 0 o 1 per sapere se il file proviene da un trasferimento GUFT o no
                   'field|x=s',     # nome del campo da utilizzare come filtro 
                   'value|v=s',     # valore che deve essere assunto dal campo di filtro
                   'inverted|i=s',  # flag che indica se il filtro deve essere applicato in modo inverso (tutti i record il cui valore dal campo filtro è diverso da...)
                   'db|d=s',        # nome del database (default ARCHIVI)
                   'zip|z=s',       # flag che indica se zippare o no l'originale (default = )
);

# at the very least, we need our login information.
die "[err] FD-File name missing, use --fdfile or -f.\n" unless $opts{fdfile};
die "[err] Archive name missing, use --archive or -a.\n"  unless $opts{archive};
die "[err] Table name missing, use --table or -t.\n"  unless $opts{table};

my $zip = 1;
if ($opts{zip}) {
    if ( $opts{zip} =~ /^n$/ig) {
     $zip = 0;
    }
}

my $tablename = basename($opts{archive}); #nome della tabella
$tablename =~ s/\.\w+$//; # rimuovo l'estensione

my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
my $date = sprintf("%04d%02d%02d%02d%02d%02d", $year+1900, $mon+1, $mday,$hour, $min, $sec);

my $LOG_PATH = "/it/log/";
my($app_name, $directory, $suffix) = fileparse($0);
$app_name =~ s/\.(pl|exe)$//ig;
my $log_file_name = "${LOG_PATH}$app_name.log";

# Configuration log in a string ...
my $conf = q(
    log4perl.category.itmlog            = DEBUG, Logfile, Screen

    log4perl.appender.Logfile           = Log::Log4perl::Appender::File
    log4perl.appender.Logfile.filename  = sub{logname();};
    log4perl.appender.Logfile.mode      = append
    log4perl.appender.Logfile.layout    = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Logfile.layout.ConversionPattern = [%d] [%p{3}] %m %n

    log4perl.appender.Screen            = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr     = 0
    log4perl.appender.Screen.layout     = Log::Log4perl::Layout::SimpleLayout
);

# ... passed as a reference to init()
Log::Log4perl::init( \$conf );

sub logname{
    return $log_file_name;
}

my $logger = Log::Log4perl::get_logger("itmlog");



$logger->info("-" x 76) ; # merely a visual seperator.
$logger->info("Elaborazione in corso per l'archivio $opts{table}");
$logger->info("Conversione da file ad indici a CSV: Attendere prego...");

my %params;
$params{archive}    = $opts{archive};
$params{fdfile}     = $opts{fdfile};
$params{guft}       = $opts{guft};
$params{field}      = $opts{field};
$params{value}      = $opts{value};
$params{inverted}   = $opts{inverted};
$params{db}         = $opts{db};
$params{table}      = $opts{table};

if (&ark2csv(%params)) {
    $logger->debug("Conversione completata con successo");
} else {
    $logger->debug("Conversione completata con errori");
    die;
} 

sub ark2csv {
    my (%params, @other) = @_;
    
    my $fd_file_name    = $params{fdfile};
    my $ark_file_name   = $params{archive};
    
    my $GUFT            = 0;  # flag per stabilire se il file proviene da un file transfer GUFT (per gestire la compressione)
    if ($params{guft}) {
        $GUFT = $params{guft}
    };        
    
    my $criteria_field  = ""; # campo da valutare per filtrare i record
    if ($params{field}) {
        $criteria_field  = $params{field}; 
    }
    my $criteria_value  = ""; # valore del campo da valutare per filtrare i record
    if (defined $params{value}) {
         $criteria_value  = $params{value};       
    }
    my $test_inverted   = 0;  
    if ($params{inverted}) { # flag per stabilire se per filtrare i campi il valore deve essere uguale o diverso
        $test_inverted = $params{inverted};    
    }       
    my $dbname   = "ARCHIVI";  
    if ($params{db}) { # flag per stabilire se per filtrare i campi il valore deve essere uguale o diverso
        $dbname = $params{db};    
    }   

    my $table = basename($ark_file_name);
    if ($params{table}) {
        $table = $params{table};
    }
        
    $logger->debug("File description = $fd_file_name");
    $logger->debug("Archivio         = $ark_file_name"); 
    $logger->debug("Tabella          = $table"); 
    $logger->debug("Protocollo GUFT  = $GUFT");    
    $logger->debug("Campo di filtro  = $criteria_field");    
    $logger->debug("Valore di filtro = $criteria_value");    
    $logger->debug("Filtro Inverso   = $test_inverted"); 
    
    # controllo i paramteri in ingresso
    my $arg;
    if (!$fd_file_name) { #FD  file
        $logger->debug("ERRORE! Specificare il file FD da analizzare !");
        return 0;
    }
    if (!$ark_file_name) { # archivio
        $logger->debug("ERRORE! Specificare l'archivio da analizzare !");
        return 0;
    }
    
    my $test_enabled = 0;       # attivazione filtro

    if ($criteria_field && defined($criteria_value)) {
        $test_enabled = 1;
    }  
    else {
        $criteria_field = "";
        $criteria_value = "";
    }

    # file di input/output
    my @tree; # sequenza ordinata di campi (con occurrence esplicite)
    my $filler = 1;
    my $comp = 1;
    my $recsize = 0;
    
    if (!&FDParser($fd_file_name,\@tree,\$recsize,\$filler,\$comp)) {
        return 0;
    }
    if (!&Write_FD_CSV($fd_file_name, @tree)) {
        return 0;
    }
    if (!&SQLWriter($ark_file_name, $table, $dbname, @tree)) {
        return 0;
    }
    if (!&CSVWriter($ark_file_name, $table, $recsize, $comp, $test_enabled, $criteria_field, $criteria_value, $test_inverted, $GUFT, @tree)) {
        return 0;
    } 
    
    # al termine della conversione il file archivio viene rinominato e zippato
    if ($zip) {
        my $newname = $ark_file_name."\.".$date;
        if (!rename $ark_file_name, $newname) {
            $logger->debug("Impossibile rinominare $ark_file_name in $newname");
        }
        else {
            &ZipFile($newname);
        }
    }
    
    return 1;
}    

sub SQLWriter {
    my ($output_file_name, $tablename, $dbname, @tree,@other) = @_;
    
    my $output_file_handler;
    
    my($filename, $directories, $suffix) = fileparse($output_file_name);
    $output_file_name = $directories.$tablename.".sql"; 
    
    if (! open $output_file_handler, ">", $output_file_name) {
        $logger->debug("ERRORE! Impossibile creare il file $output_file_name");
        return 0;
    }
    
    my $script;
    $script = "CREATE TABLE IF NOT EXISTS ".$dbname.".$tablename (\n  ";  
    
    my $i = 0;
    while ($i <= $#tree) {
        $script.= "`".$tree[$i]->{'DESC'}."` ";
        if($tree[$i]->{'TYPE'} eq "GROUP") {
            $script.="VARCHAR(".$tree[$i]->{'SIZE'}."),\n  ";
        }
        else {
            $script.=$tree[$i]->{'TYPE'}.",\n  ";
        }
        $i++;
    } 
    
    $script =~ s/,\n\s{2}$/\n\)ENGINE = MyISAM;\n/;
    print $output_file_handler "$script";
    close($output_file_handler);
    $logger->debug("Creazione del file $output_file_name");
    return 1;
}

sub CSVWriter {
    my ($ark_file_name, $table, $recsize, $comp, $test_enabled, $criteria_field, $criteria_value, $test_inverted, $GUFT, @tree, @other) = @_;
    
    # apro il file in lettura
    my $ark_file_handler;
    $logger->debug("Inizio ad analizzare il file $ark_file_name");
    if (open $ark_file_handler, "<", $ark_file_name) { # il file è aperto con successo
        
        my $arksize = (stat($ark_file_handler))[7];
        my $tot_record = int($arksize/($recsize+2));
        
        $logger->debug("Dimensione dell'archivio (byte): $arksize");
        $logger->debug("Numero record (approx): ".$tot_record."");
    
        if ($comp > 1) {
            $logger->debug("Archivio compresso");
        } 
        
        my $csv_file_handler;
        my($filename, $directories, $suffix) = fileparse($ark_file_name);
        my $csv_file_name = $directories.$table.".csv";   
        if (! open $csv_file_handler, ">", $csv_file_name ) {
            $logger->debug("ERRORE! Impossibile aprire il file $csv_file_name: $!");
            return 0;
        }
        
        # intestazione (descrizione dei campi)
        my $result = "";
        foreach my $ref_field (@tree) {
            $result = $result . $ref_field->{"DESC"} . ";";
        }
        print $csv_file_handler $result."\n";
        
        my $linecounter = 0;
        my $ignored = 0;
        my $perc = 0;
        my $linea;
        
#        $logger->debug("Elaborazione in corso:  $perc\%";
        
#        while(! eof ($ark_file_handler))  { #leggo il file, una linea per volta
#            $linea= <$ark_file_handler>;

        while(read($ark_file_handler, $linea, $recsize+1)) {
            
            if ($comp > 1) {
                &Decomp(\$linea, $GUFT, @tree);
            }
            
            # sostituisco eventuali caratteri null con uno spazio
            if ($linea =~ s/\0/\x20/g) {
#                $logger->debug("La linea contiene il carattere NULL");
            } 
            if ($linea =~ s/;/,/ig) {
                $logger->debug("La linea $linecounter contiene il carattere ; sostituito con ,");
            }
            
            if ($linea =~ s/\\/\//ig) {
                $logger->debug("La linea $linecounter contiene il carattere \\ sostituito con /  ");
            }            
            
            if (length($linea) < $recsize) {
                $logger->debug("La linea $linecounter ignorata perchè non conforme con la lunghezza del record");
                next;
            }
            
#            if (length($linea) > $recsize) {
#                $linea=substr($linea,0,$recsize);
#            }          
            
            $result = "";
            my $skip_line = $test_enabled;
            foreach my $ref_field (@tree) {
                my $value = substr($linea, $ref_field->{"START"}, $ref_field->{"SIZE"});
                if (!length($value)) { 
                    printf( "Problemi linea %s %s %s %d %d \n", $linecounter, $ref_field->{"DESC"}, $ref_field->{"START"}, $ref_field->{"SIZE"});
                }
                if ($ref_field->{"SIGN"}) {
                    &AddSign(\$value);
                }
                #20071004: sostituisco con 0 ogni spazio presente in un valore definito DECIMAL
                if ($ref_field->{'TYPE'} =~ "DECIMAL") {
                    if ($value =~ s/\s/0/ig) {
                        #$logger->debug("Sostituiti gli spazi in un valore numerico: $value");
                    }
                }
                if ($ref_field->{"DEC"} > 0) { # inserisco il punto come separatore decimale
                
                    my $dec = $ref_field->{"DEC"};
                    my $gap = $ref_field->{"SIZE"}-$dec;
                    #$logger->debug("$value --> ";
                    $value =~ s/(\d{$gap})(\d{$dec})/$1\.$2/;
                    #$logger->debug("$value");
                }
                if ($test_enabled) {
                    if ( $ref_field->{"DESC"} =~ /$criteria_field/ ) {
                        if ($value =~ /^$criteria_value$/) {
                            if ($test_inverted) {
                                $skip_line = 1;
                                last;
                            }
                            else {
                                $skip_line = 0;
                            }
                        } 
                        else {
                            if ($test_inverted) {
                                $skip_line = 0;
                            }
                            else {
                                $skip_line = 1;
                                last;
                            }
                        }
                    }
                }
                $value = unidecode($value);
                $result = $result . $value . ";";
            }
            if (! $skip_line) {
                $linecounter++;
                print $csv_file_handler $result."\n";
            }
            else {
                $ignored++;
            }
        }
        close($ark_file_handler);
        close($csv_file_handler);
        $logger->debug("Linee analizzate: $linecounter");
        $logger->debug("Linee ignorate: $ignored");        
        $logger->debug("Ho creato il file $csv_file_name");
    } 
    else { # problemi durante l'apertura del file
       $logger->debug("ERRORE! Impossibile aprire il file $ark_file_name: $!");
       return 0;
    }
    return 1;
}

sub FDParser {
    my ($fd_file_name,$ref_tree,$recsize,$ref_filler,$ref_comp, @other) = @_;
    my @struct; # lista di linee del file fd
    
    # apro il file in lettura
    my $fd_file_handler;
    $logger->debug("Inizio ad analizzare il file $fd_file_name");
    if (open $fd_file_handler, "<", $fd_file_name) { # il file è aperto con successo
      
        my $linecounter = 0;
        my $statement = "";
        while(! eof ($fd_file_handler))  { #leggo il file, una linea per volta
            $linecounter++;
            
            my $linea = <$fd_file_handler>;
            
            if ($linea =~ /^\s*\*/)  { # ignoro i commenti
                next;
            }
            
            # cerco le linee che contengono il null
            # il carattere null è sostituito con il carattere "spazio"
            if ($linea =~ s/\0/\x20/ig) {
                #$logger->debug("La linea $linecounter contiene il carattere NULL");
            }
            if ($linea =~ s/;/,/ig) {
                $logger->debug("La linea $linecounter contiene il carattere ;");
            }
            
            if ($linea =~ s/\\/\//ig) {
                $logger->debug("La linea $linecounter contiene il carattere \ ");
            }            
            
            $statement = $statement." ".$linea; # nel caso lo statement sia su più linee
            
            # rimuovo gli spazi all'inizio e alla fine della linea
            $statement =~ s/^\s+//;
            $statement =~ s/\s+$//;       
            
            if ($statement !~ /\.$/) { #la linea non termina con il punto: l'istruzione è su più linee
                next;
            }
            else {
                $statement =~ s/\s*\.$//; #rimuovo il punto finale
            }
            
            # considero solo le linee che contengono il livello ad inizio linea
            if (    ($statement =~ /^\d{1,2}\s+/i)  # considero solo le linee che iniziano con il livello
                &&  ($statement !~ /\sVALUE\s/i)    # non considero le linee con i valori
                &&  ($statement !~ /\sRENAMES\s/i)) {# non considero le linee con il Renames 
                
                    my %field;
                    $field{"LEVEL"} = 0;
                    $field{"DESC"}  = "";
                    $field{"OCCURS"}= 1;
                    $field{"TYPE"}  = "GROUP";
                    $field{"SIZE"}  = 0;
                    $field{"RSIZE"}  = 0;
                    $field{"START"} = 0;
                    $field{"SIGN"}  = 0;
                    $field{"COMP"}  = 1;
                    $field{"REDEFINES"} = "";
                    $field{"DEC"} = 0;
                    
                    &ReadLine($statement, \%field, $ref_filler, $ref_comp);
                    
                    push(@struct, \%field); # accodo la linea
            }
            else {
                $logger->debug("La linea $statement non considerata");
            }
            
            $statement="";
        }
        close($fd_file_handler);
        
        my $i = 0;
        my $level = 0;
        
        while ($i <= $#struct) {
            my $suffix = "";   
             &Explode(\$i, $suffix, $ref_tree, @struct);
        }
        
        my $prev_start = 0;
        my $prev_level = 0;        
        $i = 0;     
        while ($i < scalar @$ref_tree) {
            my $s = (scalar @$ref_tree) - 1;
            $ref_tree->[$i]->{"SIZE"} = GetSize($ref_tree,$i,$s);
            $ref_tree->[$i]->{"RSIZE"} = GetRealSize($ref_tree,$i,$s);
            $ref_tree->[$i]->{"START"} = GetStart($ref_tree,$i,$s,\$prev_start,\$prev_level);            
            $i++;
        }      
        $$recsize = $ref_tree->[0]->{"RSIZE"};
        my $s = scalar @$ref_tree -1;
        $logger->debug("Linee analizzate: $linecounter");
        $logger->debug("Linee significative: ".$#struct."");
        $logger->debug("Campi individuati: ".$s."");
        $logger->debug("Lunghezza record (byte): ".$$recsize."");
    } 
    else { # problemi durante l'apertura del file
       $logger->debug("ERRORE! Impossibile aprire il file $fd_file_name: $!");
       return 0;
    }
    return 1;
}

sub Write_FD_CSV {
    my ($fd_file_name, @tree, @other) = @_;
    my $output_file_handler;
    my $output_file_name = $fd_file_name;
    $logger->debug("Pronto per scrivere $output_file_name");
    $output_file_name =~ s/\.\w+$//ig; # rimuovo l'estensione
    $output_file_name.= ".csv";     
    if (! open $output_file_handler, ">", $output_file_name) {
        $logger->debug("ERRORE! Impossibile creare il file $output_file_name");
        return 0;
    }
    
    #intestazione
    print $output_file_handler "LEVEL;DESC;OCCURS;TYPE;SIZE;RSIZE;START;SIGN;COMP;REDEFINES;\n";
    
    my $i = 0;
    while ($i <= $#tree) {
        print $output_file_handler "$tree[$i]->{'LEVEL'};";
        print $output_file_handler "$tree[$i]->{'DESC'};";
        print $output_file_handler "$tree[$i]->{'OCCURS'};";
        print $output_file_handler "$tree[$i]->{'TYPE'};";
        print $output_file_handler "$tree[$i]->{'SIZE'};";
        print $output_file_handler "$tree[$i]->{'RSIZE'};";
        print $output_file_handler "$tree[$i]->{'START'};";
        print $output_file_handler "$tree[$i]->{'SIGN'};";
        print $output_file_handler "$tree[$i]->{'COMP'};";
        print $output_file_handler "$tree[$i]->{'REDEFINES'};\n";
        $i++;
    } 

    close($output_file_handler);
    $logger->debug("Creazione del file $output_file_name");   
    return 1;
}

sub Explode {
    my ($ref_i, $suffix, $ref_tree, @struct, @other) = @_;
    
    my $orig_suffix = $suffix;
    my $orig_idx = $$ref_i;
    my $next = $orig_idx;
      
    if ($struct[$orig_idx]->{"OCCURS"} > 1) { # elemento ripetuto        
        for (my $j = 1; $j<= $struct[$orig_idx]->{"OCCURS"}; $j++) {
            $suffix = $orig_suffix."_".$j;
            my %field;
            $field{"LEVEL"} = $struct[$orig_idx]->{"LEVEL"};
            $field{"DESC"}  = $struct[$orig_idx]->{"DESC"}.$suffix;
            $field{"OCCURS"}= $struct[$orig_idx]->{"OCCURS"};
            $field{"TYPE"}  = $struct[$orig_idx]->{"TYPE"};
            $field{"SIZE"}  = $struct[$orig_idx]->{"SIZE"};
            $field{"RSIZE"}  = $struct[$orig_idx]->{"RSIZE"};
            $field{"START"} = $struct[$orig_idx]->{"START"};
            $field{"SIGN"}  = $struct[$orig_idx]->{"SIGN"};
            $field{"COMP"}  = $struct[$orig_idx]->{"COMP"};
            $field{"REDEFINES"} = $struct[$orig_idx]->{"REDEFINES"};
            $field{"DEC"}   = $struct[$orig_idx]->{"DEC"};
            push(@$ref_tree, \%field); # accodo la linea
            
            if ($struct[$orig_idx]->{"TYPE"} eq "GROUP") {
                my $grouplevel = $struct[$orig_idx]->{"LEVEL"};
                $$ref_i++;
                while($struct[$$ref_i]->{"LEVEL"} > $grouplevel) {
#                    $logger->debug("$$ref_i\t".$struct[$$ref_i]->{"LEVEL"}."");
                    &Explode($ref_i, $suffix,$ref_tree, @struct);
#                    $logger->debug("$$ref_i\t".$struct[$$ref_i]->{"LEVEL"}."");
                } 
                $next = $$ref_i;
                $$ref_i = $orig_idx;
            }
        }
        if ($struct[$orig_idx]->{"TYPE"} eq "GROUP") {
            $$ref_i = $next-1;
        }
    }
    else { # elemento non ripetuto
        my %field;
        $field{"LEVEL"} = $struct[$orig_idx]->{"LEVEL"};
        $field{"DESC"}  = $struct[$orig_idx]->{"DESC"}.$suffix;
        $field{"OCCURS"}= $struct[$orig_idx]->{"OCCURS"};
        $field{"TYPE"}  = $struct[$orig_idx]->{"TYPE"};
        $field{"SIZE"}  = $struct[$orig_idx]->{"SIZE"};
        $field{"RSIZE"}  = $struct[$orig_idx]->{"RSIZE"};
        $field{"START"} = $struct[$orig_idx]->{"START"};
        $field{"SIGN"}  = $struct[$orig_idx]->{"SIGN"};
        $field{"COMP"}  = $struct[$orig_idx]->{"COMP"};
        $field{"REDEFINES"} = $struct[$orig_idx]->{"REDEFINES"};
        $field{"DEC"}   = $struct[$orig_idx]->{"DEC"};
        push(@$ref_tree, \%field); # accodo la linea
    }  

    $$ref_i++;
}

sub GetSize {
    my ($ref_tree, $i, $tot, @other) = @_;
    
    if ($ref_tree->[$i]->{"SIZE"} > 0) {
#        return ($ref_tree->[$i]->{"SIZE"}) * ($ref_tree->[$i]->{"OCCURS"});
        return ($ref_tree->[$i]->{"SIZE"});
    }
    
    if ($ref_tree->[$i]->{"TYPE"} eq "GROUP") {
        my $j = $i;
        $j++;
        if ($j > $tot) {
            $logger->debug("ERRORE! Struttura dati anomala !");
            return 0;
        }
        my $child_level = $ref_tree->[$j]->{"LEVEL"};        
        while ($ref_tree->[$j]->{"LEVEL"} > ($ref_tree->[$i]->{"LEVEL"})) {
            if (    ($ref_tree->[$j]->{"LEVEL"} == $child_level) 
                &&  ($ref_tree->[$j]->{"REDEFINES"} eq "")){
                $ref_tree->[$i]->{"SIZE"}+= GetSize($ref_tree, $j, $tot);
#                $logger->debug("->".$ref_tree->[$i]->{"SIZE"};
            }    
            $j++;
            last if ($j > $tot);
        }
    }  
#    return ($ref_tree->[$i]->{"SIZE"}) * ($ref_tree->[$i]->{"OCCURS"});
    return ($ref_tree->[$i]->{"SIZE"});
}

sub GetRealSize {
    my ($ref_tree, $i, $tot, @other) = @_;
    
    if ($ref_tree->[$i]->{"RSIZE"} > 0) {
        return ($ref_tree->[$i]->{"RSIZE"});
    }
    
    if ($ref_tree->[$i]->{"TYPE"} eq "GROUP") {
        my $j = $i;
        $j++;
        if ($j > $tot) {
            $logger->debug("ERRORE! Struttura dati anomala !");
            return 0;
        }
        my $child_level = $ref_tree->[$j]->{"LEVEL"};        
        while ($ref_tree->[$j]->{"LEVEL"} > ($ref_tree->[$i]->{"LEVEL"})) {
            if (    ($ref_tree->[$j]->{"LEVEL"} == $child_level) 
                &&  ($ref_tree->[$j]->{"REDEFINES"} eq "")){
                $ref_tree->[$i]->{"RSIZE"}+= GetRealSize($ref_tree, $j, $tot);
            }    
            $j++;
            last if ($j > $tot);
        }
    }  
    return ($ref_tree->[$i]->{"RSIZE"});
}

sub GetStart {
    my ($ref_tree, $i, $tot, $ref_prev_start, $ref_prev_level, @other) = @_;
    
    if ($ref_tree->[$i]->{"LEVEL"} == 1) {
        $$ref_prev_start=0;
        $$ref_prev_level=0;
    }
    
#    $logger->debug("".$$ref_prev_level. " VS ". $ref_tree->[$i]->{"LEVEL"}."");
    
    # livello più interno
    if ($ref_tree->[$i]->{"LEVEL"} > $$ref_prev_level) { # il primo campo di un campo di gruppo
        $$ref_prev_level = $ref_tree->[$i]->{"LEVEL"};    
#        $logger->debug("Modifica: ".$$ref_prev_level."");
        return $$ref_prev_start; # il campo inizia dall'inizio del campo di gruppo
    }
    
    # stesso livello del precedente o livello più esterno
    if ($ref_tree->[$i]->{"REDEFINES"} eq "") {
        $$ref_prev_start+=$ref_tree->[$i-1]->{"SIZE"};
        $$ref_prev_level = $ref_tree->[$i]->{"LEVEL"};    
#        $logger->debug("Nuovo livello: ".$$ref_prev_level."");
        return $$ref_prev_start;
    }
    else {
        my $redef = $ref_tree->[$i]->{"REDEFINES"}; # nome del campo ridefinito
        my $j = $i;
        while ($ref_tree->[$j]->{"DESC"} ne $redef) { #cerco a ritroso il campo ridefinito
           $j--; 
        }
        $$ref_prev_start = $ref_tree->[$j]->{"START"};
        $$ref_prev_level = $ref_tree->[$i]->{"LEVEL"};    
#        $logger->debug("Nuovo livello: ".$$ref_prev_level."");
        return $$ref_prev_start;
    }
}

sub ReadLine {
    my ($linea, $field, $ref_filler, $ref_comp, @other) = @_;
    
    if ($linea =~ /^(\d{1,2})(\s+)([\w,-]+)(\s*)/i) {
#        $logger->debug($output_file_handler "Field description: $1\t$3\t";
        $field->{"LEVEL"} = int($1);
        $field->{"DESC"} = $3;
        if ($field->{"DESC"} eq "FILLER") {
            $field->{"DESC"} = "FILLER".$$ref_filler;
            $$ref_filler++;
        }
    }
    else {
        $logger->debug("Linea anomala: $linea");
    }
    
    # OCCURS
    my $occurs=1;
    if ($linea =~ /(\sOCCURS\s+)(\d+)/i) {
        $occurs=$2;
    }
    $field->{"OCCURS"} = $occurs;
    
    #REDEFINES
    if ($linea =~ /(\sREDEFINES\s+)([\w,-]+)/i) {
        $field->{"REDEFINES"} = $2;
    }

    #  PICTURE
    if ($linea =~ /\sPIC\s+/i) {
        &Picture($linea, $field, $ref_comp);
    }
    
    
    #divido la linea nelle singole parole
#    my @word = split(/\s+/,$linea);
#    my $fpos = 0;
#    my $level = $word[$fpos];
#    $fpos++;    

#    if ($level < 2) {
#        $logger->debug($output_file_handler "Tipo Record: $linea";
#    }
  
    
#    $logger->debug("$level");
#    foreach my $parola (@word) {
#    $logger->debug("\"$parola\" ";
#    }
#    $logger->debug("");
            
}

sub Picture {
    my ($linea, $field, $ref_comp,@other) = @_;
    my $tipo;
    my $sign = 0;
    my $size; 
    my $dec = 0;
    
    if ($linea =~ /\sPIC\s+([\d,X,\(,\),V,S,-]+)/i) {
        my $pic = $1;
        #$logger->debug( "\n$pic\t";
       
        if ($pic =~ /X/i) {
            $tipo = "VARCHAR";
            #$logger->debug( "VARCHAR";
            if ($pic =~ /^(X\()(\d+)(\))/i) {
                #$logger->debug( "($2)\t";
                $size = int($2);
                $tipo=$tipo."(".$size.")";
            }
            else {
                #$logger->debug( "(" . length($pic) . ")\t";
                $size = length($pic);
                $tipo=$tipo."(" . $size . ")";   
            }
        }
        elsif ($pic =~ /[-\+,]/i) {
            $tipo = "VARCHAR";
            #$logger->debug( "VARCHAR";
            
            while($pic =~ /(9\()(\d+)(\))/) {
                my $n9 = $2;
                my $st = "";
                for (my $n=0; $n< $n9; $n++) {
                    $st.="9";
                }
                $pic =~ s/9\(${n9}\)/$st/;
            }
            $size = length($pic);
            #$logger->debug("($size)\t";
            $tipo=$tipo."(" . $size . ")";
        }
        else {            
            if ($pic =~ /^S/i) {
                $logger->debug("$pic SIGNED\t");
                $sign = 1;
            }
            #$logger->debug( "DECIMAL";
            $tipo = "DECIMAL";
            
            if ($pic =~ /V/i) { #decimale con virgola
                my ($left,$right);
                if ($pic =~ /(9\()(\d+)(\))V/i) {
                    $left=$2;
                }
                elsif ($pic =~ /(9+)V/i) {
                    $left=length($1);
                }
                
                if ($pic =~ /(V9\()(\d+)(\))/i) {
                    $right=$2;
                }
                elsif ($pic =~ /V(9+)/i) {
                    $right=length($1);
                }
                $size = $right+$left;
                #$logger->debug( "($size,$right)\t";
                $tipo=$tipo."(".$size.",".int($right).")";
                $dec = int($right);
            }
            elsif ($pic =~ /(9\()(\d+)(\))/i) {
                #$logger->debug( "($2,0)\t";
                $size=int($2);
                $tipo=$tipo."(".$size.",0)";
                $dec = 0;
            }
            else {
                $size = length($pic) - $sign;
                #$logger->debug( "($size,0)\t";
                $tipo=$tipo."(".$size.",0)";
                $dec = 0;
            } 
        }
        
        if ($linea =~ /\sCOMP-3/i) {
            $field->{"COMP"}=2;
            $$ref_comp = 2;
        }
        else {
            $field->{"COMP"}=1;
        }
        
        $field->{"TYPE"}=$tipo;
        $field->{"SIGN"}=$sign;
        $field->{"SIZE"}=$size;
        $field->{"DEC"}=$dec;
        
        if ($field->{"COMP"} > 1) {        
            my $rsize = (($field->{"SIZE"}+$sign)/2)+0.1;
            $field->{"RSIZE"} = sprintf "%.0f", $rsize; # questa è la lunghezza reale del campo (caratteri da leggere)       
        }
        else {
            $field->{"RSIZE"} = $field->{"SIZE"};
        }
            
    }
    else {
        $logger->debug("PICTURE anomala: $linea");
    }
}

sub AddSign {
    my ($ref_value, @other) = @_;
    if($$ref_value =~ tr/[\{,A,B,C,D,E,F,G,H,I]/[0,1,2,3,4,5,6,7,8,9]/) {
       $$ref_value = "+". $$ref_value;
    }
    elsif ($$ref_value =~ tr/[\},J,K,L,M,N,O,P,Q,R]/[0,1,2,3,4,5,6,7,8,9]/) {
        $$ref_value = "-". $$ref_value;
    }
}

sub Decomp {
    my ($ref_linea, $GUFT, @tree, @other) = @_;
    
    # tabella di conversione ASCII --> EBCDIC
    my $cp_037;

    if ($GUFT) {
        $cp_037 = 
        '\000\001\002\003\234\011\206\177\227\215\216\013\014\015\016\017' .
        '\020\021\022\023\235\205\010\207\030\031\222\217\034\035\036\037' .
        '\200\201\202\203\204\012\027\033\210\211\212\213\214\005\006\007' .
        '\220\221\026\223\224\225\226\004\230\231\232\233\024\025\236\032' .
        '\040\240\342\344\340\341\343\345\347\361\242\056\074\050\053\174' .
        '\046\351\352\353\350\355\356\357\354\337\041\044\052\051\073\254' .
        '\055\057\302\304\300\301\303\305\307\321\246\054\045\137\076\077' .
        '\370\311\312\313\310\315\316\317\314\140\072\043\100\047\075\042' .
        '\330\141\142\143\144\145\146\147\150\151\253\273\360\375\376\261' .
        '\260\152\153\154\155\156\157\160\161\162\252\272\346\270\306\244' .
        '\265\176\163\164\165\166\167\170\171\172\241\277\320\335\336\256' .
        '\136\243\245\267\251\247\266\274\275\276\133\135\257\250\264\327' .
        '\173\101\102\103\104\105\106\107\110\111\255\364\366\362\363\365' .
        '\175\112\113\114\115\116\117\120\121\122\271\373\374\371\372\377' .
        '\134\367\123\124\125\126\127\130\131\132\262\324\326\322\323\325' .
        '\060\061\062\063\064\065\066\067\070\071\263\333\334\331\332\237' ;  
    } else { #FTP
        $cp_037 =
        '\000\001\002\003\067\055\056\057\026\005\045\013\014\015\016\017'.
        '\020\021\022\023\074\075\062\046\030\031\077\047\034\035\036\037'.
        '\100\132\177\173\133\154\120\175\115\135\134\116\153\140\113\141'.
        '\360\361\362\363\364\365\366\367\370\371\172\136\114\176\156\157'.
        '\174\301\302\303\304\305\306\307\310\311\321\322\323\324\325\326'.
        '\327\330\331\342\343\344\345\346\347\350\351\255\340\275\232\155'.
        '\171\201\202\203\204\205\206\207\210\211\221\222\223\224\225\226'.
        '\227\230\231\242\243\244\245\246\247\250\251\300\117\320\137\007'.
        '\040\041\042\043\044\025\006\027\050\051\052\053\054\011\012\033'.
        '\060\061\032\063\064\065\066\010\070\071\072\073\004\024\076\341'.
        '\101\102\103\104\105\106\107\110\111\121\122\123\124\125\126\127'.
        '\130\131\142\143\144\145\146\147\150\151\160\161\162\163\164\165'.
        '\166\167\170\200\212\213\214\215\216\217\220\152\233\234\235\236'.
        '\237\240\252\253\254\112\256\257\260\261\262\263\264\265\266\267'.
        '\270\271\272\273\274\241\276\277\312\313\314\315\316\317\332\333'.
        '\334\335\336\337\352\353\354\355\356\357\372\373\374\375\376\377' ;
    }
    
    
    my $decompos = 0;
    foreach my $field (@tree) {
        my $compression = $field->{"COMP"};
        my $signed = $field->{"SIGN"};
        if ($compression > 1) {
        
            if ($field->{"START"} >= $decompos) {
        
                my $size = (($field->{"SIZE"}+$signed)/2)+0.1;
                my $x = sprintf "%.0f", $size; # questa è la lunghezza reale del campo (caratteri da leggere)
                my $comp_string = substr($$ref_linea, $field->{"START"}, $x); #leggo i caratteri in ASCII

                my $ebcdic_string = $comp_string;
                if ($GUFT) {
                    eval '$ebcdic_string =~ tr/' . $cp_037 . '/\000-\377/';
                }
                else { #FTP
                    eval '$ebcdic_string =~ tr/\000-\377/' . $cp_037 . '/';
                }

                my $value = unpack "H*", $ebcdic_string; 
#                if ($signed) {
#                    $logger->debug("$value"); # questo è il VALORE non compresso
#                }
                
#            $esad=~ s/([0-9]{2})/pack "c", hex $1/eg; 
#            $esad =~ s/(.*)c$/+$1/;
#            $esad =~ s/(.*)d$/-$1/; 
#            $logger->debug("$esad");
               
#            $$ref_linea = substr($$ref_linea, 0, $field->{"START"}).$value.substr($$ref_linea, $field->{"START"}+$x);

                if ($signed) {
                    $value =~ s/0d$/\}/; 
                    $value =~ s/1d$/J/; 
                    $value =~ s/2d$/K/; 
                    $value =~ s/3d$/L/; 
                    $value =~ s/4d$/M/; 
                    $value =~ s/5d$/N/; 
                    $value =~ s/6d$/O/; 
                    $value =~ s/7d$/P/; 
                    $value =~ s/8d$/Q/; 
                    $value =~ s/9d$/R/; 
                    $value =~ s/0c$/\{/; 
                    $value =~ s/1c$/A/; 
                    $value =~ s/2c$/B/; 
                    $value =~ s/3c$/C/; 
                    $value =~ s/4c$/D/; 
                    $value =~ s/5c$/E/; 
                    $value =~ s/6c$/F/; 
                    $value =~ s/7c$/G/; 
                    $value =~ s/8c$/H/; 
                    $value =~ s/9c$/I/; 
                }
                
#                $logger->debug("$comp_string";
#                my $ascii_string = unpack "H*", $comp_string; 
#                $logger->debug("--> $ascii_string";
#                $logger->debug("-->$value\t ". $field->{"SIZE"}."");
                
                my $left = $field->{"START"};
#                $$ref_linea =~ s/^(.{$left})($comp_string)/$1$value/;
                $$ref_linea = substr($$ref_linea, 0, $left).$value.substr($$ref_linea, $left+length($comp_string));
                $decompos= $field->{"START"}+$field->{"SIZE"};
            }
            else {
                # questa parte della linea è già stata decompressa
            }
        }
        else {            
        }
    }    
}

sub ZipFile {
    my($filename, @other) = @_;
    
    if ($filename =~ /\.txt\.\d{14}$/ig) {
        my($name, $directories, $suffix) = fileparse($filename);
        my $zipfile_name    = $filename.".zip";
        
        my $zip = Archive::Zip->new();

        if(! $zip->addFile($filename, $name)) {
            print "Errore ZIP (addFile)\n";
            return;
        }

        if ($zip->writeToFileNamed($zipfile_name) != AZ_OK) {
            print "Errore ZIP (writeToFileNamed)\n";
            return;
        }
        
        if (! unlink($filename)) { # cancello il file
            $logger->debug("Impossibile eliminare il File: $filename");
        }
        else {
            $logger->debug("File eliminato: $filename");
        }
    }   
}