#!/usr/bin/perl -w
use strict;
use DBI;

# parametri di configurazione del database oracle
#---------------------------------------------------------------------------------------
my $hostname_or = "10.11.14.109";
my $username_or = "test";
my $password_or = "user1";

# variabili globali
#---------------------------------------------------------------------------------------
my $dbh;
my $sth_select;

# Connessione al db
#---------------------------------------------------------------------------------------
if (&ConnessioneDB()) {
	if ($sth_select->execute()) {
		while (my @row = $sth_select->fetchrow_array()) {
			my $codice_carta = $row[0];
			my $codice_cliente = $row[1];
			my $codice_carta_primaria = $row[2];
			
			print $codice_carta.'~'.$codice_cliente.'~'.$codice_carta_primaria."\r\n";
		}
	}
}

$sth_select->finish();

sub ConnessioneDB{
	$dbh = DBI->connect('dbi:Oracle:',qq{$username_or/$password_or@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$hostname_or)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=orcl)))},"") or die;
	$sth_select = $dbh->prepare(
							qq{
								SELECT * from
								(
								(	select 
									carta as codice_carta, 
									id as codice_cliente, 
									carta as codice_carta_primaria
									--id as cliente_originale, 
									--STATUS_CARTA as status_carta_sostituita 
									from clienti
									where (id > '11' and status_carta <> 'Tessera Sostituita' and status_carta <> 'Tessera Trasferita')
								)
								UNION ALL
								(	select 
									case when carta_sostituita IS NULL then clienti.CARTA else carta_sostituita end as codice_carta, 
									clienti.id as codice_cliente, 
									clienti.CARTA as codice_carta_primaria
									--cliente_originale, 
									--status_carta_sostituita 
									from clienti
									join (
									select carta as carta_sostituita, id_cliente_originale as cliente_originale, STATUS_CARTA as status_carta_sostituita from clienti where status_carta = 'Tessera Sostituita' or status_carta = 'Tessera Trasferita'
								) sost on clienti.id = sost.cliente_originale
								where id > '11') 
								)
								order by CODICE_CLIENTE
							});

	return 1;
}
