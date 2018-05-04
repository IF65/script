<?php

#TDSVER=7.0 tsql -H 11.0.34.11 -p 1433 -U mtxadmin  

$data_corrente = date('Y-m-d', time());


$data = '2015-04-09';
$data = $data_corrente; # se vuoi caricare un giorno particolare commenta questa riga e imposta la data nella riga precedente

// parametri connessione mssql
$mssql_user = "mtxadmin";
$mssql_password = "mtxadmin";
$mssql_db = "mtx"; 

// parametri connessione mysql
$mysql_user = "root";
$mysql_password = "mela";
$mysql_db = "archivi"; 

// codici negozio
$ar_negozi = array("0101","0102","0103","0104","0105","0106","0107","0108","0109","0110","0111","0113","0114","0115","0119","0127","0128",
                   "0129","0130","0131","0132","0133","0134","0135","0138","0139","0140","0141","0142","0143","0144","0145","0146","0147",
                   "0148","0149","0170","0171","0172","0173","0176","0177","0178","0179","0180","0181","0184","3151","3152","3650","3652",
                   "3657","3658","3659","3661","3665","3666","3668","3670","3671","3673","3674","3675","3682","3683","3687","3689","3692",
                   "3693","3694","3695");

// connessione a mysql
$mysql_handle = new mysqli('localhost', $mysql_user, $mysql_password, 'archivi') or die("Unable to connect to MySQL");

foreach ($ar_negozi as &$negozio) {
//connection to the database
	if ($dbhandle = mssql_connect($negozio, $mssql_user, $mssql_password)) {
		if ($selected = mssql_select_db($mssql_db, $dbhandle)) {
						
			//cerco le righe 1001 nella tabella del giorno corrente
			$totale_corrente_importo = 0;
			$totale_corrente_clienti = 0;
			$query = "SELECT isnull(sum(AMOUNT), 0.00) as TOTALE, isnull(sum(CUSTOMERCOUNTER), 0.00) CLIENTI from IDC_DAILYFIN where FINANCIALTOTALID='1001' and DDATE = ".json_encode($data);
			$result = mssql_query($query);
			while($row = mssql_fetch_array($result)) {
				$totale_corrente_importo += $row['TOTALE']/100;
				$totale_corrente_clienti += $row['CLIENTI'];
			}
			
			//cerco le righe 1001 nella tabella dei totali
			$totale_chiusura_importo = 0;
			$totale_chiusura_clienti = 0;
			$query = "SELECT isnull(sum(AMOUNT), 0.00) as TOTALE, isnull(sum(CUSTOMERCOUNTER), 0.00) CLIENTI from IDC_EODFIN where FINANCIALTOTALID='1001' and DDATE = ".json_encode($data);
			$result = mssql_query($query);
			while($row = mssql_fetch_array($result)) {
				$totale_chiusura_importo += $row['TOTALE']/100;
				$totale_chiusura_clienti += $row['CLIENTI'];
			}
			
			mssql_close($dbhandle);
			
			$result = mysqli_query($mysql_handle, "SELECT negozio_descrizione from negozi where codice = $negozio");
			$row = mysqli_fetch_array($result);
			$negozio_descrizione = $row['negozio_descrizione'];
			
			if ($data_corrente == $data) {
				if ($totale_corrente_importo != 0 && $totale_chiusura_importo != 0) {
					echo $data."\t".$negozio."\t0\t0\t2\n";
				} elseif ($totale_corrente_importo != 0 && $totale_chiusura_importo == 0) {
					echo "$data\t$negozio\t$totale_corrente_importo\t$totale_corrente_clienti\t0\n";
				} elseif ($totale_corrente_importo == 0 && $totale_chiusura_importo != 0) {
					echo "$data\t$negozio\t$totale_chiusura_importo\t$totale_chiusura_clienti\t1\n";
				} else {
					echo $data."\t".$negozio."\t0\t0\t0\n";
				}
			} else {
				if ($totale_chiusura_importo != 0) {
					echo "$data\t$negozio\t$totale_chiusura_importo\t$totale_chiusura_clienti\t1\n";
				} else {
					echo $data."\t".$negozio."\t0\t0\t0\n";
				}
			}
		}
	}
}

mysqli_close($mysql_handle);
?>
