#!/usr/bin/perl -w
use strict;
use File::HomeDir;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
use DBI;
use DateTime;
use Getopt::Long;

# parametri di collegamento al database ITM
#------------------------------------------------------------------------------------------------------------
my $hostname			= "10.11.14.78";
my $username			= "root";
my $password			= "mela";
my $database			= "db_sm";

# date
#------------------------------------------------------------------------------------------------------------
my $current_date 	= DateTime->now(time_zone=>'local');
my $week = $current_date->week_number() - 1;
my $year = $current_date->year();

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sth_riga;

# recupero parametri dalla linea di comando
#----------------------------------------------------------------------------------------------------------------------
my $selettore_report;

if (@ARGV == 0) {
    die "Nessun parametro definito!\n";
}

GetOptions(
	's=s{1,1}'	=> \$selettore_report,
) or die "parametri non corretti!\n";

my $desktop = File::HomeDir->my_desktop;
my $output_file_handler;
my $output_file_name = $year."_W".$week."_".$selettore_report;

# connessione al database di default
$dbh = DBI->connect("DBI:mysql:mysql:$hostname", $username, $password);
if (! $dbh) {
	die "Errore durante la connessione al database di default!\n";
}

if ($selettore_report eq 'ACER') {
	$sth = $dbh->prepare(qq{select case when m.`eliminato`=1 and m.`obsoleto`=0 then 'E' when m.`eliminato`=1 and m.`obsoleto`=1 then 'O' else '' end `Stato`, concat(m.`codice_famiglia`,'.',m.`codice_sottofamiglia`) `F./S.F.`,m.`codice` `Codice`, m.`descrizione` `Descrizione`,m.`modello` `Modello`, m.`linea` `Marca`,m.`listino_1` `Listino`,m.`listino_promo` `List.Pr.`,substr(m.`griglia`,1,1) `Gr.`, ifnull(q.`giacenza`,0) `Giac.`, ifnull(q.`acquistati`,0) `Acq.`, ifnull(q.`venduto`,0) `Vend.`, ifnull(q.`in_ordine`,0) `In Ord.`, ifnull(q.`venduto_90`,0) `V.90`, ifnull(q.`venduto_30`,0) `V.30`, ifnull(q.`venduto_15`,0) `V.15`, ifnull(q.`venduto_7`,0) `V.7`, ifnull((select group_concat(e.`ean` separator ', ') from db_sm.`ean` as e where e.`codice`=m.`codice` group by e.`codice`),'')
	from db_sm.`magazzino` as m left join (select s.`codice_articolo` `codice`, sum(s.`giacenza`) `giacenza`, sum(s.`in_ordine`) `in_ordine`, sum(s.`acquistati`) `acquistati`, sum(s.`venduto`) `venduto`,sum(s.`venduto_7`) `venduto_7`, sum(s.`venduto_15`) `venduto_15`, sum(s.`venduto_30`) `venduto_30`, sum(s.`venduto_90`) `venduto_90` from db_sm.`situazioni` as s where s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD' group by s.`codice_articolo`) as q on m.`codice`=q.`codice`
	where (q.`giacenza` > 0 or q.`in_ordine` > 0 or m.`eliminato` = 0) and m.`linea`='ACER'});
} elsif ($selettore_report eq 'HISENSE') {
	$sth = $dbh->prepare(qq{select case when m.`eliminato`=1 and m.`obsoleto`=0 then 'E' when m.`eliminato`=1 and m.`obsoleto`=1 then 'O' else '' end `Stato`, concat(m.`codice_famiglia`,'.',m.`codice_sottofamiglia`) `F./S.F.`,m.`codice` `Codice`, m.`descrizione` `Descrizione`,m.`modello` `Modello`, m.`linea` `Marca`,m.`listino_1` `Listino`,m.`listino_promo` `List.Pr.`,substr(m.`griglia`,1,1) `Gr.`, ifnull(q.`giacenza`,0) `Giac.`, ifnull(q.`acquistati`,0) `Acq.`, ifnull(q.`venduto`,0) `Vend.`, ifnull(q.`in_ordine`,0) `In Ord.`, ifnull(q.`venduto_90`,0) `V.90`, ifnull(q.`venduto_30`,0) `V.30`, ifnull(q.`venduto_15`,0) `V.15`, ifnull(q.`venduto_7`,0) `V.7`, ifnull((select group_concat(e.`ean` separator ', ') from db_sm.`ean` as e where e.`codice`=m.`codice` group by e.`codice`),'')
	from db_sm.`magazzino` as m left join (select s.`codice_articolo` `codice`, sum(s.`giacenza`) `giacenza`, sum(s.`in_ordine`) `in_ordine`, sum(s.`acquistati`) `acquistati`, sum(s.`venduto`) `venduto`,sum(s.`venduto_7`) `venduto_7`, sum(s.`venduto_15`) `venduto_15`, sum(s.`venduto_30`) `venduto_30`, sum(s.`venduto_90`) `venduto_90` from db_sm.`situazioni` as s where s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD' group by s.`codice_articolo`) as q on m.`codice`=q.`codice`
	where (q.`giacenza` > 0 or q.`in_ordine` > 0 or m.`eliminato` = 0) and m.`linea`='HISENSE TEL'});
} elsif ($selettore_report eq 'BRONDI') {
	$sth = $dbh->prepare(qq{select case when m.`eliminato`=1 and m.`obsoleto`=0 then 'E' when m.`eliminato`=1 and m.`obsoleto`=1 then 'O' else '' end `Stato`, concat(m.`codice_famiglia`,'.',m.`codice_sottofamiglia`) `F./S.F.`,m.`codice` `Codice`, m.`descrizione` `Descrizione`,m.`modello` `Modello`, m.`linea` `Marca`,m.`listino_1` `Listino`,m.`listino_promo` `List.Pr.`,substr(m.`griglia`,1,1) `Gr.`, ifnull(q.`giacenza`,0) `Giac.`, ifnull(q.`acquistati`,0) `Acq.`, ifnull(q.`venduto`,0) `Vend.`, ifnull(q.`in_ordine`,0) `In Ord.`, ifnull(q.`venduto_90`,0) `V.90`, ifnull(q.`venduto_30`,0) `V.30`, ifnull(q.`venduto_15`,0) `V.15`, ifnull(q.`venduto_7`,0) `V.7`, ifnull((select group_concat(e.`ean` separator ', ') from db_sm.`ean` as e where e.`codice`=m.`codice` group by e.`codice`),'')
	from db_sm.`magazzino` as m left join (select s.`codice_articolo` `codice`, sum(s.`giacenza`) `giacenza`, sum(s.`in_ordine`) `in_ordine`, sum(s.`acquistati`) `acquistati`, sum(s.`venduto`) `venduto`,sum(s.`venduto_7`) `venduto_7`, sum(s.`venduto_15`) `venduto_15`, sum(s.`venduto_30`) `venduto_30`, sum(s.`venduto_90`) `venduto_90` from db_sm.`situazioni` as s where s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD' group by s.`codice_articolo`) as q on m.`codice`=q.`codice`
	where (q.`giacenza` > 0 or q.`in_ordine` > 0 or m.`eliminato` = 0) and m.`linea` like 'BRONDI%'});
} elsif ($selettore_report eq 'CANON') {
	$sth = $dbh->prepare(qq{select case when m.`eliminato`=1 and m.`obsoleto`=0 then 'E' when m.`eliminato`=1 and m.`obsoleto`=1 then 'O' else '' end `Stato`, concat(m.`codice_famiglia`,'.',m.`codice_sottofamiglia`) `F./S.F.`,m.`codice` `Codice`, m.`descrizione` `Descrizione`,m.`modello` `Modello`, m.`linea` `Marca`,m.`listino_1` `Listino`,m.`listino_promo` `List.Pr.`,substr(m.`griglia`,1,1) `Gr.`, ifnull(q.`giacenza`,0) `Giac.`, ifnull(q.`acquistati`,0) `Acq.`, ifnull(q.`venduto`,0) `Vend.`, ifnull(q.`in_ordine`,0) `In Ord.`, ifnull(q.`venduto_90`,0) `V.90`, ifnull(q.`venduto_30`,0) `V.30`, ifnull(q.`venduto_15`,0) `V.15`, ifnull(q.`venduto_7`,0) `V.7`, ifnull((select group_concat(e.`ean` separator ', ') from db_sm.`ean` as e where e.`codice`=m.`codice` group by e.`codice`),'')
	from db_sm.`magazzino` as m left join (select s.`codice_articolo` `codice`, sum(s.`giacenza`) `giacenza`, sum(s.`in_ordine`) `in_ordine`, sum(s.`acquistati`) `acquistati`, sum(s.`venduto`) `venduto`,sum(s.`venduto_7`) `venduto_7`, sum(s.`venduto_15`) `venduto_15`, sum(s.`venduto_30`) `venduto_30`, sum(s.`venduto_90`) `venduto_90` from db_sm.`situazioni` as s where s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD' group by s.`codice_articolo`) as q on m.`codice`=q.`codice`
	where (q.`giacenza` > 0 or q.`in_ordine` > 0 or m.`eliminato` = 0) and m.`linea` like 'CANON%'});
} elsif ($selettore_report eq 'NILOX') {
	$sth = $dbh->prepare(qq{select case when m.`eliminato`=1 and m.`obsoleto`=0 then 'E' when m.`eliminato`=1 and m.`obsoleto`=1 then 'O' else '' end `Stato`, concat(m.`codice_famiglia`,'.',m.`codice_sottofamiglia`) `F./S.F.`,m.`codice` `Codice`, m.`descrizione` `Descrizione`,m.`modello` `Modello`, m.`linea` `Marca`,m.`listino_1` `Listino`,m.`listino_promo` `List.Pr.`,substr(m.`griglia`,1,1) `Gr.`, ifnull(q.`giacenza`,0) `Giac.`, ifnull(q.`acquistati`,0) `Acq.`, ifnull(q.`venduto`,0) `Vend.`, ifnull(q.`in_ordine`,0) `In Ord.`, ifnull(q.`venduto_90`,0) `V.90`, ifnull(q.`venduto_30`,0) `V.30`, ifnull(q.`venduto_15`,0) `V.15`, ifnull(q.`venduto_7`,0) `V.7`, ifnull((select group_concat(e.`ean` separator ', ') from db_sm.`ean` as e where e.`codice`=m.`codice` group by e.`codice`),'')
	from db_sm.`magazzino` as m left join (select s.`codice_articolo` `codice`, sum(s.`giacenza`) `giacenza`, sum(s.`in_ordine`) `in_ordine`, sum(s.`acquistati`) `acquistati`, sum(s.`venduto`) `venduto`,sum(s.`venduto_7`) `venduto_7`, sum(s.`venduto_15`) `venduto_15`, sum(s.`venduto_30`) `venduto_30`, sum(s.`venduto_90`) `venduto_90` from db_sm.`situazioni` as s where s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD' group by s.`codice_articolo`) as q on m.`codice`=q.`codice`
	where (q.`giacenza` > 0 or q.`in_ordine` > 0 or m.`eliminato` = 0) and (m.`linea` = 'NILOX' or m.`linea` = 'NILOX CAM')});
} elsif ($selettore_report eq 'D-LINK_ACC') {
	$sth = $dbh->prepare(qq{select case when m.`eliminato`=1 and m.`obsoleto`=0 then 'E' when m.`eliminato`=1 and m.`obsoleto`=1 then 'O' else '' end `Stato`, concat(m.`codice_famiglia`,'.',m.`codice_sottofamiglia`) `F./S.F.`,m.`codice` `Codice`, m.`descrizione` `Descrizione`,m.`modello` `Modello`, m.`linea` `Marca`,m.`listino_1` `Listino`,m.`listino_promo` `List.Pr.`,substr(m.`griglia`,1,1) `Gr.`, ifnull(q.`giacenza`,0) `Giac.`, ifnull(q.`acquistati`,0) `Acq.`, ifnull(q.`venduto`,0) `Vend.`, ifnull(q.`in_ordine`,0) `In Ord.`, ifnull(q.`venduto_90`,0) `V.90`, ifnull(q.`venduto_30`,0) `V.30`, ifnull(q.`venduto_15`,0) `V.15`, ifnull(q.`venduto_7`,0) `V.7`, ifnull((select group_concat(e.`ean` separator ', ') from db_sm.`ean` as e where e.`codice`=m.`codice` group by e.`codice`),'')
	from db_sm.`magazzino` as m left join (select s.`codice_articolo` `codice`, sum(s.`giacenza`) `giacenza`, sum(s.`in_ordine`) `in_ordine`, sum(s.`acquistati`) `acquistati`, sum(s.`venduto`) `venduto`,sum(s.`venduto_7`) `venduto_7`, sum(s.`venduto_15`) `venduto_15`, sum(s.`venduto_30`) `venduto_30`, sum(s.`venduto_90`) `venduto_90` from db_sm.`situazioni` as s where s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD' group by s.`codice_articolo`) as q on m.`codice`=q.`codice`
	where (q.`giacenza` > 0 or q.`in_ordine` > 0 or m.`eliminato` = 0) and m.`linea` = 'D-LINK ACC'});
} elsif ($selettore_report eq 'HEWLETT_PACKARD') {
	$sth = $dbh->prepare(qq{select case when m.`eliminato`=1 and m.`obsoleto`=0 then 'E' when m.`eliminato`=1 and m.`obsoleto`=1 then 'O' else '' end `Stato`, concat(m.`codice_famiglia`,'.',m.`codice_sottofamiglia`) `F./S.F.`,m.`codice` `Codice`, m.`descrizione` `Descrizione`,m.`modello` `Modello`, m.`linea` `Marca`,m.`listino_1` `Listino`,m.`listino_promo` `List.Pr.`,substr(m.`griglia`,1,1) `Gr.`, ifnull(q.`giacenza`,0) `Giac.`, ifnull(q.`acquistati`,0) `Acq.`, ifnull(q.`venduto`,0) `Vend.`, ifnull(q.`in_ordine`,0) `In Ord.`, ifnull(q.`venduto_90`,0) `V.90`, ifnull(q.`venduto_30`,0) `V.30`, ifnull(q.`venduto_15`,0) `V.15`, ifnull(q.`venduto_7`,0) `V.7`, ifnull((select group_concat(e.`ean` separator ', ') from db_sm.`ean` as e where e.`codice`=m.`codice` group by e.`codice`),'')
	from db_sm.`magazzino` as m left join (select s.`codice_articolo` `codice`, sum(s.`giacenza`) `giacenza`, sum(s.`in_ordine`) `in_ordine`, sum(s.`acquistati`) `acquistati`, sum(s.`venduto`) `venduto`,sum(s.`venduto_7`) `venduto_7`, sum(s.`venduto_15`) `venduto_15`, sum(s.`venduto_30`) `venduto_30`, sum(s.`venduto_90`) `venduto_90` from db_sm.`situazioni` as s where s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD' group by s.`codice_articolo`) as q on m.`codice`=q.`codice`
	where (q.`giacenza` > 0 or q.`in_ordine` > 0 or m.`eliminato` = 0) and m.`linea` like 'HEWLETT PACKARD%' and m.`codice_famiglia` >= '14' and m.`codice_famiglia` <= '19'});
} elsif ($selettore_report eq 'KOBO') {
	$sth = $dbh->prepare(qq{select case when m.`eliminato`=1 and m.`obsoleto`=0 then 'E' when m.`eliminato`=1 and m.`obsoleto`=1 then 'O' else '' end `Stato`, concat(m.`codice_famiglia`,'.',m.`codice_sottofamiglia`) `F./S.F.`,m.`codice` `Codice`, m.`descrizione` `Descrizione`,m.`modello` `Modello`, m.`linea` `Marca`,m.`listino_1` `Listino`,m.`listino_promo` `List.Pr.`,substr(m.`griglia`,1,1) `Gr.`, ifnull(q.`giacenza`,0) `Giac.`, ifnull(q.`acquistati`,0) `Acq.`, ifnull(q.`venduto`,0) `Vend.`, ifnull(q.`in_ordine`,0) `In Ord.`, ifnull(q.`venduto_90`,0) `V.90`, ifnull(q.`venduto_30`,0) `V.30`, ifnull(q.`venduto_15`,0) `V.15`, ifnull(q.`venduto_7`,0) `V.7`, ifnull((select group_concat(e.`ean` separator ', ') from db_sm.`ean` as e where e.`codice`=m.`codice` group by e.`codice`),'')
	from db_sm.`magazzino` as m left join (select s.`codice_articolo` `codice`, sum(s.`giacenza`) `giacenza`, sum(s.`in_ordine`) `in_ordine`, sum(s.`acquistati`) `acquistati`, sum(s.`venduto`) `venduto`,sum(s.`venduto_7`) `venduto_7`, sum(s.`venduto_15`) `venduto_15`, sum(s.`venduto_30`) `venduto_30`, sum(s.`venduto_90`) `venduto_90` from db_sm.`situazioni` as s where s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD' group by s.`codice_articolo`) as q on m.`codice`=q.`codice`
	where (q.`giacenza` > 0 or q.`in_ordine` > 0 or m.`eliminato` = 0) and m.`linea` like 'KOBO%'});
} elsif ($selettore_report eq 'LOGITECH') {
	$sth = $dbh->prepare(qq{select case when m.`eliminato`=1 and m.`obsoleto`=0 then 'E' when m.`eliminato`=1 and m.`obsoleto`=1 then 'O' else '' end `Stato`, concat(m.`codice_famiglia`,'.',m.`codice_sottofamiglia`) `F./S.F.`,m.`codice` `Codice`, m.`descrizione` `Descrizione`,m.`modello` `Modello`, m.`linea` `Marca`,m.`listino_1` `Listino`,m.`listino_promo` `List.Pr.`,substr(m.`griglia`,1,1) `Gr.`, ifnull(q.`giacenza`,0) `Giac.`, ifnull(q.`acquistati`,0) `Acq.`, ifnull(q.`venduto`,0) `Vend.`, ifnull(q.`in_ordine`,0) `In Ord.`, ifnull(q.`venduto_90`,0) `V.90`, ifnull(q.`venduto_30`,0) `V.30`, ifnull(q.`venduto_15`,0) `V.15`, ifnull(q.`venduto_7`,0) `V.7`, ifnull((select group_concat(e.`ean` separator ', ') from db_sm.`ean` as e where e.`codice`=m.`codice` group by e.`codice`),'')
	from db_sm.`magazzino` as m left join (select s.`codice_articolo` `codice`, sum(s.`giacenza`) `giacenza`, sum(s.`in_ordine`) `in_ordine`, sum(s.`acquistati`) `acquistati`, sum(s.`venduto`) `venduto`,sum(s.`venduto_7`) `venduto_7`, sum(s.`venduto_15`) `venduto_15`, sum(s.`venduto_30`) `venduto_30`, sum(s.`venduto_90`) `venduto_90` from db_sm.`situazioni` as s where s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD' group by s.`codice_articolo`) as q on m.`codice`=q.`codice`
	where (q.`giacenza` > 0 or q.`in_ordine` > 0 or m.`eliminato` = 0) and m.`linea` like 'LOGITECH%' and m.`linea` not like 'LOGITECH SUPERMEDIA%'});
} elsif ($selettore_report eq 'SITECOM_FRESH') {
	$sth = $dbh->prepare(qq{select case when m.`eliminato`=1 and m.`obsoleto`=0 then 'E' when m.`eliminato`=1 and m.`obsoleto`=1 then 'O' else '' end `Stato`, concat(m.`codice_famiglia`,'.',m.`codice_sottofamiglia`) `F./S.F.`,m.`codice` `Codice`, m.`descrizione` `Descrizione`,m.`modello` `Modello`, m.`linea` `Marca`,m.`listino_1` `Listino`,m.`listino_promo` `List.Pr.`,substr(m.`griglia`,1,1) `Gr.`, ifnull(q.`giacenza`,0) `Giac.`, ifnull(q.`acquistati`,0) `Acq.`, ifnull(q.`venduto`,0) `Vend.`, ifnull(q.`in_ordine`,0) `In Ord.`, ifnull(q.`venduto_90`,0) `V.90`, ifnull(q.`venduto_30`,0) `V.30`, ifnull(q.`venduto_15`,0) `V.15`, ifnull(q.`venduto_7`,0) `V.7`, ifnull((select group_concat(e.`ean` separator ', ') from db_sm.`ean` as e where e.`codice`=m.`codice` group by e.`codice`),'')
	from db_sm.`magazzino` as m left join (select s.`codice_articolo` `codice`, sum(s.`giacenza`) `giacenza`, sum(s.`in_ordine`) `in_ordine`, sum(s.`acquistati`) `acquistati`, sum(s.`venduto`) `venduto`,sum(s.`venduto_7`) `venduto_7`, sum(s.`venduto_15`) `venduto_15`, sum(s.`venduto_30`) `venduto_30`, sum(s.`venduto_90`) `venduto_90` from db_sm.`situazioni` as s where s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD' group by s.`codice_articolo`) as q on m.`codice`=q.`codice`
	where (q.`giacenza` > 0 or q.`in_ordine` > 0 or m.`eliminato` = 0) and (m.`linea` = 'SITECOM ACC' or m.`linea` = 'FRESH N REBEL' or m.`linea` = 'NETIS ACC')});
} elsif ($selettore_report eq 'TIM') {
	$sth = $dbh->prepare(qq{select case when m.`eliminato`=1 and m.`obsoleto`=0 then 'E' when m.`eliminato`=1 and m.`obsoleto`=1 then 'O' else '' end `Stato`, concat(m.`codice_famiglia`,'.',m.`codice_sottofamiglia`) `F./S.F.`,m.`codice` `Codice`, m.`descrizione` `Descrizione`,m.`modello` `Modello`, m.`linea` `Marca`,m.`listino_1` `Listino`,m.`listino_promo` `List.Pr.`,substr(m.`griglia`,1,1) `Gr.`, ifnull(q.`giacenza`,0) `Giac.`, ifnull(q.`acquistati`,0) `Acq.`, ifnull(q.`venduto`,0) `Vend.`, ifnull(q.`in_ordine`,0) `In Ord.`, ifnull(q.`venduto_90`,0) `V.90`, ifnull(q.`venduto_30`,0) `V.30`, ifnull(q.`venduto_15`,0) `V.15`, ifnull(q.`venduto_7`,0) `V.7`, ifnull((select group_concat(e.`ean` separator ', ') from db_sm.`ean` as e where e.`codice`=m.`codice` group by e.`codice`),'')
	from db_sm.`magazzino` as m left join (select s.`codice_articolo` `codice`, sum(s.`giacenza`) `giacenza`, sum(s.`in_ordine`) `in_ordine`, sum(s.`acquistati`) `acquistati`, sum(s.`venduto`) `venduto`,sum(s.`venduto_7`) `venduto_7`, sum(s.`venduto_15`) `venduto_15`, sum(s.`venduto_30`) `venduto_30`, sum(s.`venduto_90`) `venduto_90` from db_sm.`situazioni` as s where s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD' group by s.`codice_articolo`) as q on m.`codice`=q.`codice`
	where (q.`giacenza` > 0 or q.`in_ordine` > 0 or m.`eliminato` = 0) and (m.`linea` = 'TIM' or m.`linea` = 'TIM PC')});
} elsif ($selettore_report eq 'WIND') {
	$sth = $dbh->prepare(qq{select case when m.`eliminato`=1 and m.`obsoleto`=0 then 'E' when m.`eliminato`=1 and m.`obsoleto`=1 then 'O' else '' end `Stato`, concat(m.`codice_famiglia`,'.',m.`codice_sottofamiglia`) `F./S.F.`,m.`codice` `Codice`, m.`descrizione` `Descrizione`,m.`modello` `Modello`, m.`linea` `Marca`,m.`listino_1` `Listino`,m.`listino_promo` `List.Pr.`,substr(m.`griglia`,1,1) `Gr.`, ifnull(q.`giacenza`,0) `Giac.`, ifnull(q.`acquistati`,0) `Acq.`, ifnull(q.`venduto`,0) `Vend.`, ifnull(q.`in_ordine`,0) `In Ord.`, ifnull(q.`venduto_90`,0) `V.90`, ifnull(q.`venduto_30`,0) `V.30`, ifnull(q.`venduto_15`,0) `V.15`, ifnull(q.`venduto_7`,0) `V.7`, ifnull((select group_concat(e.`ean` separator ', ') from db_sm.`ean` as e where e.`codice`=m.`codice` group by e.`codice`),'')
	from db_sm.`magazzino` as m left join (select s.`codice_articolo` `codice`, sum(s.`giacenza`) `giacenza`, sum(s.`in_ordine`) `in_ordine`, sum(s.`acquistati`) `acquistati`, sum(s.`venduto`) `venduto`,sum(s.`venduto_7`) `venduto_7`, sum(s.`venduto_15`) `venduto_15`, sum(s.`venduto_30`) `venduto_30`, sum(s.`venduto_90`) `venduto_90` from db_sm.`situazioni` as s where s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD' group by s.`codice_articolo`) as q on m.`codice`=q.`codice`
	where (q.`giacenza` > 0 or q.`in_ordine` > 0 or m.`eliminato` = 0) and (m.`linea` = 'WIND' or m.`linea` = 'WIND PC')});
} elsif ($selettore_report eq 'MICROSOFT') {
	$sth = $dbh->prepare(qq{select case when m.`eliminato`=1 and m.`obsoleto`=0 then 'E' when m.`eliminato`=1 and m.`obsoleto`=1 then 'O' else '' end `Stato`, concat(m.`codice_famiglia`,'.',m.`codice_sottofamiglia`) `F./S.F.`,m.`codice` `Codice`, m.`descrizione` `Descrizione`,m.`modello` `Modello`, m.`linea` `Marca`,m.`listino_1` `Listino`,m.`listino_promo` `List.Pr.`,substr(m.`griglia`,1,1) `Gr.`, ifnull(q.`giacenza`,0) `Giac.`, ifnull(q.`acquistati`,0) `Acq.`, ifnull(q.`venduto`,0) `Vend.`, ifnull(q.`in_ordine`,0) `In Ord.`, ifnull(q.`venduto_90`,0) `V.90`, ifnull(q.`venduto_30`,0) `V.30`, ifnull(q.`venduto_15`,0) `V.15`, ifnull(q.`venduto_7`,0) `V.7`, ifnull((select group_concat(e.`ean` separator ', ') from db_sm.`ean` as e where e.`codice`=m.`codice` group by e.`codice`),'')
	from db_sm.`magazzino` as m left join (select s.`codice_articolo` `codice`, sum(s.`giacenza`) `giacenza`, sum(s.`in_ordine`) `in_ordine`, sum(s.`acquistati`) `acquistati`, sum(s.`venduto`) `venduto`,sum(s.`venduto_7`) `venduto_7`, sum(s.`venduto_15`) `venduto_15`, sum(s.`venduto_30`) `venduto_30`, sum(s.`venduto_90`) `venduto_90` from db_sm.`situazioni` as s where s.`negozio` <> 'SMM1' and s.`negozio` <> 'SMM3' and s.`negozio` <> 'SMMD' group by s.`codice_articolo`) as q on m.`codice`=q.`codice`
	where (q.`giacenza` > 0 or q.`in_ordine` > 0 or m.`eliminato` = 0) and m.`linea` like 'MICROSOFT%' and m.`linea` <> 'MICROSOFT TEL'});
} else {
	die "Report $selettore_report non definito\n";
}

&esecuzione_report_tipo_dettagliato_excel();

$dbh->disconnect();

sub esecuzione_report_tipo_dettagliato_excel {
	if ($sth->execute()) {
		#formato excel
		$output_file_name .= '.xlsx';
		my $workbook = Excel::Writer::XLSX->new("$desktop/$output_file_name");
		
		#creo il foglio di lavoro x l'anno
		my $rv_report = $workbook->add_worksheet( $selettore_report );
		
		#aggiungo un formato
		my $format = $workbook->add_format();
		$format->set_bold();
		
		$rv_report->set_column( 0, 0, 7 );
		$rv_report->set_column( 1, 1, 7 );
		$rv_report->set_column( 2, 2, 7 );
		$rv_report->set_column( 3, 3, 50 );
		$rv_report->set_column( 4, 4, 20 );
		$rv_report->set_column( 5, 5, 20 );
		$rv_report->set_column( 6, 6, 7 );
		$rv_report->set_column( 7, 7, 7 );
		$rv_report->set_column( 8, 8, 5 );
		$rv_report->set_column( 9, 9, 7 );
		$rv_report->set_column( 10, 10, 7 );
		$rv_report->set_column( 11, 11, 7 );
		$rv_report->set_column( 12, 12, 7 );
		$rv_report->set_column( 13, 13, 7 );
		$rv_report->set_column( 14, 14, 7 );
		$rv_report->set_column( 15, 15, 7 );
		$rv_report->set_column( 16, 16, 7 );
		$rv_report->set_column( 17, 17, 30 );

		#titoli colonne
		$format->set_color( 'blue' );
		$format->set_align( 'center' );
		$rv_report->write_string( 0, 0, "Stato", $format );
		$rv_report->write_string( 0, 1, "F./S.F.", $format );
		$rv_report->write_string( 0, 2, "Codice", $format );
		$rv_report->write_string( 0, 3, "Descrizione", $format );
		$rv_report->write_string( 0, 4, "Modello", $format );
		$rv_report->write_string( 0, 5, "Marca", $format );
		$rv_report->write_string( 0, 6, "Listino", $format );
		$rv_report->write_string( 0, 7, "List.Pr.", $format );
		$rv_report->write_string( 0, 8, "Gr.", $format );
		$rv_report->write_string( 0, 9, "Giac.", $format );
		$rv_report->write_string( 0, 10, "Acq.", $format );
		$rv_report->write_string( 0, 11, "Vend.", $format );
		$rv_report->write_string( 0, 12, "In Ord.", $format );
		$rv_report->write_string( 0, 13, "V.90",$format );
		$rv_report->write_string( 0, 14, "V.30", $format );
		$rv_report->write_string( 0, 15, "V.15", $format );
		$rv_report->write_string( 0, 16, "V.7", $format );
		$rv_report->write_string( 0, 17, "EAN", $format );
		
		
		my $date_format = $workbook->add_format( num_format => 'dd/mm/yyyy' );
		my $integer_format = $workbook->add_format( num_format => '#,##0' );
		$integer_format->set_align( 'center' );
		my $currency_format = $workbook->add_format( num_format => '#,##0.00' );
		my $string_left = $workbook->add_format();
		$string_left->set_align( 'left' );
		my $string_centered = $workbook->add_format();
		$string_centered->set_align( 'center' );
		my $row_counter = 0;
		while(my @row = $sth->fetchrow_array()) {
			$row_counter++;
			
			$rv_report->write_string( $row_counter, 0, $row[0], $string_centered);
			$rv_report->write_string( $row_counter, 1, $row[1], $string_centered);
			$rv_report->write_string( $row_counter, 2, $row[2], $string_centered);
			$rv_report->write_string( $row_counter, 3, $row[3]);
			$rv_report->write_string( $row_counter, 4, $row[4]);
			$rv_report->write_string( $row_counter, 5, $row[5]);
			$rv_report->write( $row_counter, 6, $row[6], $currency_format);
			$rv_report->write( $row_counter, 7, $row[7], $currency_format);
			$rv_report->write_string( $row_counter, 8, $row[8], $string_centered);
			$rv_report->write( $row_counter, 9, $row[9], $integer_format);
			$rv_report->write( $row_counter, 10, $row[10], $integer_format);
			$rv_report->write( $row_counter, 11, $row[11], $integer_format);
			$rv_report->write( $row_counter, 12, $row[12], $integer_format);
			$rv_report->write( $row_counter, 13, $row[13], $integer_format);
			$rv_report->write( $row_counter, 14, $row[14], $integer_format);
			$rv_report->write( $row_counter, 15, $row[15], $integer_format);
			$rv_report->write( $row_counter, 16, $row[16], $integer_format);
			$rv_report->write_string( $row_counter, 17, $row[17]);
			
		}
		
		#attivo il foglio di lavoro
		$rv_report->activate();
	
		$sth->finish();
		
		print "$desktop/$output_file_name\n";
	}
}

sub string2date { #trasformo una data un oggetto DateTime
	my ($data) =@_;
	
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
