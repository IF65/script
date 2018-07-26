<?php
	if (count($argv) != 3) {
		die("Numero di parametri errato.");
	}
	
	$dataRichiesta = null;
	$sedeRichiesta = null;
	foreach ($argv as $arg) {
			if (preg_match('/^\d{4}\-\d{2}\-\d{2}$/', $arg)) {
				$dataRichiesta = $arg;
			}
			if (preg_match('/^\d{4}$/', $arg)) {
				$sedeRichiesta = $arg;
			}
	}
	
	if ($dataRichiesta == null || $sedeRichiesta == null) {
		die("Parametri non corretti.");
	}
	
	$user = "root";
	$pass = "mela";
	
	$negozi = "select codice, catalina_codice_catena, catalina_codice_negozio from archivi.negozi where societa in ('01','04','31','36')";
	
	$datacollect = "select d1.record
					from catalina.datacollect_negozio as d1 join
					(select transazione, numcassa from catalina.datacollect_negozio where `tiporec`='i' and body like '%9770110003000%') as d2
					on d1.transazione=d2.transazione and d1.numcassa=d2.numcassa order by d1.id";
	
	$sql =  "select case when NEGOZIO like '01%' and NEGOZIO <> '0123' then lpad(substr(NEGOZIO,3,2),4,0)
							 when NEGOZIO like '0123' then concat('01',substr(NEGOZIO,3,2))
							 when NEGOZIO like '04%' then concat('00',substr(NEGOZIO,3,2)) 
							 when NEGOZIO like '36%' and NEGOZIO <> '3654' then concat('16',substr(NEGOZIO,3,2))
							 when NEGOZIO like '3654' then concat('36',substr(NEGOZIO,3,2))
							 when NEGOZIO like '31%' then concat('01',substr(NEGOZIO,3,2))
							 else NEGOZIO 
							 end as NEGOZIO,
						concat('20',DATA)                   as DATA,
						ORA_TRANSAZIONE                     as ORA,
						lpad(NUMCASSA,3,0)                  as CASSA,
						lpad(substr(CASSIERE,2,3),10,0)     as OPERATORE,
						lpad(   case 
								when TIPO_PAGAMENTO in ('01|','01|01|') then '001'
								when TIPO_PAGAMENTO = '02|' then '002'
								when TIPO_PAGAMENTO in ('03|', '04|') then '003'
								when TIPO_PAGAMENTO in ('10|','11|','12|','13|','14|','15|','30|','31|','32|','33|','34|') then '004'  
								when TIPO_PAGAMENTO in ('16|', '35|') then '006'
								else '005'
								end
						,3,0)                               as TIPO_PAGAMENTO,
						lpad(TESSERA,20,0)                  as CARTA_FEDELTA,
						case when binary tiporec = 'm' then lpad(trim(substr(body,13,12)),16,0) else lpad(   case 
								when BARCODE_ITM = '' 
								then concat(2,substr(articolo,1,6))
								else    case 
										when length(trim(substr(body,1,16))) in (1,2,3,4,5,6,7,10)
										then trim(substr(body,1,16))
										else substr(trim(substr(body,1,16)),1,length(trim(substr(body,1,16)))-1)
										end
								end
						,16,0) end                              as UPC,
						case when binary tiporec = 'm' then '0000000001' else lpad(CODE4,10,0) end                    as REPARTO,
						case when binary tiporec = 'm' then '0001' else 
						case when   QTA_VENDUTA < 0
						then        case 
									when length(trim(substr(body,1,16))) = 13 and substr(trim(substr(body,1,16)),1,5) = 99777 then lpad(truncate(abs(QTA_VENDUTA),0),4,0) 
									else concat('-',lpad(truncate(case when length(trim(substr(body,1,16))) = 13 and substr(trim(substr(body,1,16)),1,1) = 2 then 1 else abs(QTA_VENDUTA) end,0),3,0))
									end
						else concat('',lpad(truncate(case when length(trim(substr(body,1,16))) = 13 and substr(trim(substr(body,1,16)),1,1) = 2 then 1 else abs(QTA_VENDUTA) end,0)   ,4,0))
						end end                                  as QUANTITA,
						
						case when TRUNCATE(VALORE_NETTO + QUOTA_SC_TRAN + quota_sc_tran_0061 + quota_sc_rep_0481,0) < 0
						then concat('-',lpad(TRUNCATE(VALORE_NETTO + QUOTA_SC_TRAN + quota_sc_tran_0061 + quota_sc_rep_0481,0)*-1,8,0))
						else concat('',lpad(TRUNCATE(VALORE_NETTO + QUOTA_SC_TRAN + quota_sc_tran_0061 + quota_sc_rep_0481,0),9,0))
						end                                 as VALORE,
						LPAD(TRANSAZIONE,4,0)               as NUM_TRANSAZIONE
			from        catalina.datacollect_negozio
			WHERE       VALORE_NETTO + QUOTA_SC_TRAN + quota_sc_tran_0061 + quota_sc_rep_0481<> 0 or (binary tiporec = 'm' and (body like '%CAT99%' or body like '%CAT98%' or body like '%CAT97%'))
			AND         DATADC = '$dataRichiesta'";

	try {
		$db = new PDO('mysql:host=127.0.0.1;dbname=catalina', $user, $pass);
		
		$catenaCatalina = [];
		$codiceCatalina = [];
		$stmt = $db->prepare($negozi);
		if ($stmt->execute()) {
			$negozi = $stmt->fetchAll(\PDO::FETCH_ASSOC);
			foreach($negozi as $negozio) {
				$catenaCatalina[$negozio['codice']] = $negozio['catalina_codice_catena'];
				$codiceCatalina[$negozio['codice']] = $negozio['catalina_codice_negozio'];
			}
		}
		
		$buoni = [];
		$stmt = $db->prepare($datacollect);
		if ($stmt->execute()) {
			$righe = $stmt->fetchAll(\PDO::FETCH_NUM);
			for ($indice = 0; $indice < count($righe); $indice++) {
				if (preg_match('/:i:.*9770110003000/', $righe[$indice][0])) {
					if (preg_match('/^.{4}:(\d{3}):\d{6}:\d{6}:(\d{4}):\d{3}:C:\d{3}:(\d{4}):..:(.{12}).\+(\d{4})....\-(\d{9})$/',$righe[$indice + 1][0], $matches)) {
						$cassa = $matches[1];
						$transazione = $matches[2];
						$reparto = $matches[3];
						$barcode = str_pad(preg_replace('/\s+/', '', $matches[4]), 16, "0", STR_PAD_LEFT);
						$quantita = $matches[5]*1;
						$importo = $matches[6]*1;
						
						$buoni[] = [
								'cassa' => $cassa,
								'transazione' => $transazione,
								'reparto' => $reparto,
								'barcode' => $barcode,
								'quantita' => $quantita,
								'importo' => $importo
							];
					}
				}
			}
		}
		
		$righe = '';
		$stmt = $db->prepare($sql);
		if ($stmt->execute()) {
			$results = $stmt->fetchAll(\PDO::FETCH_ASSOC);
			foreach($results as $row) {
				$importo = $row['VALORE']*1;
				
				$rigaBuono = '';
				foreach ($buoni as $index => $buono) {
					if ($row['CASSA'] == $buono['cassa'] && $row['NUM_TRANSAZIONE'] == $buono['transazione'] && $row['UPC'] == $buono['barcode']) {
						$rigaBuono .= $row['NEGOZIO']."\t";
						$rigaBuono .= $row['DATA']."\t";
						$rigaBuono .= $row['ORA']."\t";
						$rigaBuono .= $row['CASSA']."\t";
						$rigaBuono .= $row['OPERATORE']."\t";
						$rigaBuono .= $row['TIPO_PAGAMENTO']."\t";
						$rigaBuono .= $row['CARTA_FEDELTA']."\t";
						$rigaBuono .= "0000977011000300\t"; //$row['UPC']."\t";
						$rigaBuono .= $row['REPARTO']."\t";
						$rigaBuono .= $row['QUANTITA']."\t";
						$rigaBuono .= sprintf('%09d',$buono['importo']*-1)."\t";
						$rigaBuono .= $row['NUM_TRANSAZIONE']."\n";
						
						$importo  += $buono['importo'];
						unset($buoni[$index]);
						break;
					}
				}
				
				$rigaPunti = '';
				if ($row['UPC'] >= '29908530' && $row['UPC'] <= '29909999') {
					$rigaPunti .= $row['NEGOZIO']."\t";
					$rigaPunti .= $row['DATA']."\t";
					$rigaPunti .= $row['ORA']."\t";
					$rigaPunti .= $row['CASSA']."\t";
					$rigaPunti .= $row['OPERATORE']."\t";
					$rigaPunti .= $row['TIPO_PAGAMENTO']."\t";
					$rigaPunti .= $row['CARTA_FEDELTA']."\t";
					$rigaPunti .= str_pad(preg_replace('/\s+/', '', $row['UPC']), 16, "0", STR_PAD_LEFT)."\t";
					$rigaPunti .= $row['REPARTO']."\t";
					$rigaPunti .= $row['QUANTITA']."\t";
					$rigaPunti .= sprintf('%09d',0)."\t";
					$rigaPunti .= $row['NUM_TRANSAZIONE']."\n";
				}
				
				$riga = "";
				$riga .= $row['NEGOZIO']."\t";
				$riga .= $row['DATA']."\t";
				$riga .= $row['ORA']."\t";
				$riga .= $row['CASSA']."\t";
				$riga .= $row['OPERATORE']."\t";
				$riga .= $row['TIPO_PAGAMENTO']."\t";
				$riga .= $row['CARTA_FEDELTA']."\t";
				$riga .= $row['UPC']."\t";
				$riga .= $row['REPARTO']."\t";
				$riga .= $row['QUANTITA']."\t";
				$riga .= sprintf('%09d',$importo)."\t";
				$riga .= $row['NUM_TRANSAZIONE']."\n";
				
				$righe .= $riga;
				if ($rigaBuono != '') {
					$righe .= $rigaBuono;
				}
				if ($rigaPunti != '') {
					$righe .= $rigaPunti;
				}
			}
		}
		///preparazione/file_catalina/
		$fileName = "it.".$catenaCatalina[$sedeRichiesta].'.'.$codiceCatalina[$sedeRichiesta].".tab.".str_replace('-','',$dataRichiesta)."010101.eur";
		
		file_put_contents ( '/Users/if65/Desktop/'.$fileName , $righe );
		
		$db = null;
	} catch (PDOException $e) {
		print "Error!: " . $e->getMessage() . "<br/>";
		die();
	}