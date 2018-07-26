<?php
	
	$data = '2018-07-23';
	$societa = '0101';
	
	// Configurazione
	// ------------------------------------------------------------------------------------------------
	if (! date_default_timezone_set ( "Europe/Rome" )) {
		die("Time Zone non impostato.");	
	}
	
	$path = "/Users/if65/Desktop/test";
	
	$crlf = "\r\n";
	
	$user = "root";
	$pass = "mela";
	
	
	$tipoIva = [
		3 => "374",
		8 => "A2",
		16 => "22",
		31 => "FC2"
	];
	
	$sedi = [
		'SM5' => '0094',
		'SM6' => '0109',
		'SM7' => '0105',
		'SM15' => '0108',
		'SM16' => '0093',
		'SM17' => '0093',
		'SM18' => '0103',
		'SM19' => '0088',
		'SM26' => '0099',
		'SM27' => '0100',
		'SM28' => '0092',
		'SM32' => '0069',
		'SM35' => '0092',
		'SM37' => '0102',
		'SM39' => '0096',
		'SM41' => '0070',
		'SM46' => '0078'
	];
	
	$sqlNegoziPresentiInData = "
		select distinct v.`negozio`
		from db_sm.magazzino as m join righe_vendita as v on m.`codice`= v.`codice` join scontrini as s on s.`id_scontrino`=v.`id_scontrino`
		where v.`negozio` in ('SM5','SM6','SM7','SM15','SM16','SM17','SM18','SM19','SM26','SM27','SM28','SM32','SM35','SM37','SM39','SM41','SM46') and v.data = '$data' and
		((m.`codice_famiglia` = '08' and m.`codice_sottofamiglia` in ('1','2','3','4','5','6','7','8')) or
		(m.`codice_famiglia` = '18' and m.`codice_sottofamiglia` in ('1','2','3','4','5','6','7','8','9','10','11')))";
	
	$sql =  "
		select 
			s.`id_scontrino` `Cod_PK`, v.`negozio` `codiceNegozioSm`,s.`data`,s.`numero_upb` `numeroScontrino`,
			case when m.`codice_padre` <> ''
			then
				(select descrizione from db_sm.magazzino where codice = m.`codice_padre`)
			else
				m.`descrizione`
			end `descrizione`,
			case when m.`codice_padre` <> '' then 'U' else '' end `usato`, 
			case when m.`codice_padre` <> '' then m.`codice_padre` else m.`codice` end `codice`, 
			case when m.`codice_padre` <> ''
			then 
				(select ean from ean where codice = m.`codice_padre` order by 1 limit 1)
			else 
				(select ean from ean where codice = m.`codice` order by 1 limit 1) 
			end `codice`, 
			m.`tipo_iva`, m.`aliquota_iva`, v.`quantita`,v.`prezzo_unitario` `prezzoUnitario`, v.`importo_totale` `importoVendita`
		from db_sm.magazzino as m join righe_vendita as v on m.`codice`= v.`codice` join scontrini as s on s.`id_scontrino`=v.`id_scontrino`
		where v.`negozio` = :negozio and v.data = '$data' and
		((m.`codice_famiglia` = '08' and m.`codice_sottofamiglia` in ('1','2','3','4','5','6','7','8')) or
		(m.`codice_famiglia` = '18' and m.`codice_sottofamiglia` in ('1','2','3','4','5','6','7','8','9','10','11')))
		order by v.data, v.codice;";

	try {
		$db = new PDO('mysql:host=10.11.14.78;dbname=db_sm', $user, $pass);
		
		// recupero i codici negozio della giornata
		$stmt = $db->prepare($sqlNegoziPresentiInData);
		if ($stmt->execute()) {
			$negozi = $stmt->fetchAll(\PDO::FETCH_NUM);
		}
		
		foreach ($negozi as $negozio) {
			$righe = [];
			$stmt = $db->prepare($sql);
			if ($stmt->execute([':negozio' => $negozio[0]])) {
				$results = $stmt->fetchAll(\PDO::FETCH_ASSOC);
				foreach($results as $result) {
					
					$codiceIva = "22";
					if (key_exists($result['tipo_iva'], $tipoIva)) {
						$codiceIva = $tipoIva[$result['tipo_iva']];
					}
					$riga = "";
					$riga .= sprintf('"%s";', $result['Cod_PK']);
					$riga .= sprintf('"%s";', $sedi[$result['codiceNegozioSm']]);
					$riga .= (new DateTime($result['data']))->format('Ymd').";";
					$riga .= sprintf('"%s";', $result['numeroScontrino']);
					$riga .= sprintf('%d;', '0');
					$riga .= sprintf('"%s";', $result['codice'].$result['usato']);
					$riga .= sprintf('"%s";', filter_var($result['descrizione'], FILTER_SANITIZE_STRING));
					$riga .= sprintf('%+d;',intval($result['quantita'])*100);
					$riga .= sprintf('%+d;',intval($result['prezzoUnitario'])*100);
					$riga .= sprintf('%+d;',intval($result['importoVendita'])*100);
					$riga .= sprintf('%+d;',intval($result['importoVendita'])*100);
					$riga .= sprintf('"%s";',$codiceIva);
					$riga .= sprintf('"%s";',($result['usato'] == 'U' ? 'VU' : 'VE'));
					$riga .= sprintf('"%s";',"");
					$riga .= sprintf('"%s";',"");
					$riga .= sprintf('%d;',0);
					$riga .= sprintf('%d;',0);
					$riga .= (new DateTime())->format('Ymd');
					
					$righe[] = $riga;
				}
			}
			$fileName = "RCT_I_".$sedi[$negozio[0]]."_Scontrini_". (new DateTime())->format('Y-m-d_H-i-s').'.txt';
			file_put_contents ( "$path/$fileName" , implode($crlf,$righe));
		}
		$db = null;
	} catch (PDOException $e) {
		print "Error!: " . $e->getMessage() . "<br/>";
		die();
	}