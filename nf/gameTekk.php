<?php
	if (count($argv) == 2) { 
		$data = $argv[1];
		
		// incarico 240
		
		// Configurazione
		// ------------------------------------------------------------------------------------------------
		if (! date_default_timezone_set ( "Europe/Rome" )) {
			die("Time Zone non impostato.");	
		}
		
		$path = "/gameTekk";
		
		$invio = "$path/daInviare";
		$bkp = "$path/inviati";
		
		if (!file_exists($path)) {
			@mkdir($path, 0777, true) or die ("Cartella \"$path\" non creata! Procedura terminata.");
		}
		if (!file_exists($invio)) {
			@mkdir($invio, 0777, true) or die ("Cartella \"$invio\" non creata! Procedura terminata.");
		}
		if (!file_exists($bkp)) {
			@mkdir($bkp, 0777, true) or die ("Cartella \"$bkp\" non creata! Procedura terminata.");
		}
	
		$crlf = "\r\n";
		
		$user = "root";
		$pass = "mela";
		
		$tipoIva = [
			3 => "374",
			8 => "A2",
			16 => "22",
			31 => "FC2"
		];
		
		$sqlElencoNegozi = "select n.`codice_interno` `negozio`, n.`codice_gameTekk` `gameTekk` from archivi.negozi as n 
							where n.`data_inizio` <= '$data' and (n.`data_fine` is null or n.`data_fine`>= '$data') and n.`societa` = '08' and n.`tipo` in ('03','04') and
							codice_gameTekk <> ''
							order by lpad(substr(n.`codice_interno`,3),2,'0');";
							
		$sqlElencoNegoziMancanti = "	select n.negozio from 
										(select n.`codice_interno` `negozio` from archivi.negozi as n 
										where n.`data_inizio` <= '$data' and (n.`data_fine` is null or n.`data_fine`>= '$data') and n.`societa` = '08' and n.`tipo` in ('03','04') and
										n.`codice_gameTekk` <> ''
										order by lpad(substr(n.`codice_interno`,3),2,'0')) as n
										left join 
										(select s.`negozio` from db_sm.scontrini as s where s.`data` = '$data') as s 
										on n.`negozio` = s.`negozio`
										where s.`negozio` is null
										order by lpad(substr(n.`negozio`,3),2,'0');";
										
		$sqlElencoNegoziInviati = "	select n.codice_interno from lavori.incarichi as i join archivi.negozi as n on i.`negozio_codice`=n.codice 
									where i.`data`='$data' and i.`lavoro_codice` = 240 and i.`eseguito`= 1
									order by lpad(substr(n.`codice_interno`,3),2,'0');";
	
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
			
			// recupero i codici negozio che in questa giornata dovrebbero essere presenti
			// e creo un elenco usabile nella query successiva.
			$elencoNegozi = [];
			$stmt = $db->prepare($sqlElencoNegozi);
			if ($stmt->execute()) {
				$negozi = $stmt->fetchAll(\PDO::FETCH_NUM);
	
				foreach ($negozi as $negozio) {
					$elencoNegozi[$negozio[0]] = $negozio[1];
				}
			}
			
			// recupero l'elenco dei negozi mancanti nella giornata
			$elencoNegoziInviati = [];
			$stmt = $db->prepare($sqlElencoNegoziInviati);
			if ($stmt->execute()) {
				$negozi = $stmt->fetchAll(\PDO::FETCH_NUM);
	
				foreach ($negozi as $negozio) {
					$elencoNegoziInviati[] = $negozio[0];
				}
			}
			
			// recupero l'elenco dei negozi mancanti nella giornata
			$elencoNegoziMancanti = [];
			$stmt = $db->prepare($sqlElencoNegoziMancanti);
			if ($stmt->execute()) {
				$negozi = $stmt->fetchAll(\PDO::FETCH_NUM);
	
				foreach ($negozi as $negozio) {
					$elencoNegoziMancanti[] = $negozio[0];
				}
			}
				
			foreach ($elencoNegozi as $negozio => $gametekk) {
				if (! in_array($negozio, $elencoNegoziMancanti) && ! in_array($negozio, $elencoNegoziInviati)) {
					$righe = [];
					$stmt = $db->prepare($sql);
					if ($stmt->execute([':negozio' => $negozio])) {
						$results = $stmt->fetchAll(\PDO::FETCH_ASSOC);
						foreach($results as $result) {
							
							$codiceIva = "22";
							if (key_exists($result['tipo_iva'], $tipoIva)) {
								$codiceIva = $tipoIva[$result['tipo_iva']];
							}
							$riga = "";
							$riga .= sprintf('"%s";', $result['Cod_PK']);
							$riga .= sprintf('"%s";', $elencoNegozi[$result['codiceNegozioSm']]);
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
					$fileName = "RCT_I_".$gametekk."_Scontrini_". $data . substr((new DateTime())->format('Y-m-d_H-i-s'),10).'.txt';
					file_put_contents ( "$invio/$fileName" , implode($crlf,$righe));
					
					// sistema la tabella incarichi
					$sqlUpdateIncarichi = "	update lavori.incarichi as i join archivi.negozi as n on i.`negozio_codice`=n.codice 
											set i.`eseguito` = 1
											where i.`data`='$data' and i.`lavoro_codice` = 240 and n.codice_interno = '$negozio';";
					$stmt = $db->prepare($sqlUpdateIncarichi);
					$stmt->execute();
				}	
			}
			$db = null;
		} catch (PDOException $e) {
			print "Error!: " . $e->getMessage() . "<br/>";
			die();
		}
	}