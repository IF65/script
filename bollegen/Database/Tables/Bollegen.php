<?php
    namespace Database\Tables;

	use Database\Database;

	class Bollegen extends Database {

        public function __construct($sqlDetails) {
        	try {
				parent::__construct($sqlDetails);

                self::creaTabella();

            } catch (PDOException $e) {
                die($e->getMessage());
            }
        }

        public function creaTabella() {
        	try {
 		$sql = "CREATE TABLE `bollegen` (
 				`BG-KIAVE` varchar(30) DEFAULT NULL,
 				`BG-SOC` varchar(2) DEFAULT NULL,
 				`BG-NBOLLA` varchar(6) NOT NULL DEFAULT '',
 				`BG-DATBOLLA` decimal(8,0) NOT NULL DEFAULT '0',
 				`BG-AABOLLA` decimal(4,0) DEFAULT NULL,
 				`BG-MMBOLLA` decimal(2,0) DEFAULT NULL,
 				`BG-GGBOLLA` decimal(2,0) DEFAULT NULL,
 				`BG-SOCNEG` varchar(4) NOT NULL DEFAULT '',
 				`BG-CODSOC` varchar(2) DEFAULT NULL,
 				`BG-CODNEG` varchar(2) DEFAULT NULL,
 				`BG-CODCIN` varchar(7) NOT NULL DEFAULT '',
 				`BG-CODART` decimal(6,0) DEFAULT NULL,
 				`BG-CINART` decimal(1,0) DEFAULT NULL,
 				`BG-FAM` varchar(3) DEFAULT NULL,
 				`BG-RESTO` decimal(4,0) DEFAULT NULL,
 				`BG-SPAZI` varchar(3) DEFAULT NULL,
 				`BG-QTA` decimal(7,2) DEFAULT NULL,
 				`BG-PRCOFIN-E` decimal(7,2) DEFAULT NULL,
 				`BG-PRACQNET-E` decimal(7,2) DEFAULT NULL,
 				`BG-CODCINCLI` decimal(7,0) DEFAULT NULL,
 				`BG-COLLIMERSY` decimal(5,0) DEFAULT NULL,
 				`BG-PZ` decimal(4,0) DEFAULT NULL,
 				`BG-IVA` decimal(4,2) DEFAULT NULL,
 				`BG-COD-MAGA` varchar(2) DEFAULT NULL,
 				`BG-PVCASH-E` decimal(7,2) DEFAULT NULL,
 				`BG-PVIF-E` decimal(7,2) DEFAULT NULL,
 				`BG-PCMED-E` decimal(7,2) DEFAULT NULL,
 				`BG-PVIFZ-E` decimal(7,2) DEFAULT NULL,
 				`BG-UM` varchar(2) DEFAULT NULL,
 				`BG-FUNZ` varchar(3) DEFAULT NULL,
 				`BG-PVCES-OLD` decimal(7,2) DEFAULT NULL,
 				`BG-SEG-ST-BOLLA` varchar(1) DEFAULT NULL,
 				`BG-DATA-ESTR-X-FAT` decimal(8,0) DEFAULT NULL,
 				`BG-AA-EXF` decimal(4,0) DEFAULT NULL,
 				`BG-MM-EXFA` decimal(2,0) DEFAULT NULL,
 				`BG-GG-EXF` decimal(2,0) DEFAULT NULL,
 				`BG-SEG-ST-FATT` varchar(1) DEFAULT NULL,
 				PRIMARY KEY (`BG-NBOLLA`,`BG-DATBOLLA`,`BG-SOCNEG`,`BG-CODCIN`)
				) ENGINE=MyISAM DEFAULT CHARSET=latin1;";
                $this->pdo->exec($sql);

				return true;
            } catch (PDOException $e) {
                die($e->getMessage());
            }
        }


        public function esportaFile($rows) {
            $csv = '';

            foreach ($rows as $record) {
                $csv .= $record['data']."\t";
                $csv .= $record['anno']."\t";
                $csv .= $record['codice']."\t";
                $csv .= $record['negozio']."\t";
                $csv .= $record['bloccato']."\t";
                $csv .= ($record['dataBlocco'] == null) ? 'NULL'."\t" : $record['dataBlocco']."\t";
                $csv .= $record['numBolla']."\t";
                $csv .= $record['prezzoOfferta']."\t";
                $csv .= ($record['dataFineOfferta'] == null) ? 'NULL'."\t" : $record['dataFineOfferta']."\t";
                $csv .= $record['prezzoVendita']."\t";
                $csv .= $record['prezzoVenditaLocale']."\t";
                $csv .= $record['dataRiferimento']."\n";
            }

            file_put_contents ( "/bollegen/export.txt" , $csv);
        }
        

        public function ricerca($query) {
            try {
            	$draw = $query["draw"];
            	$dataIniziale = $query["query"]["dataIniziale"];
            	$dataFinale = $query["query"]["dataFinale"];
            	$negozio = $query["query"]["negozio"];
            	$codice = $query["query"]["codice"];
            	$numBolla = $query["query"]["numBolla"];
            	$famiglia = $query["query"]["famiglia"];
            	$inizio = $query["inizio"];
            	$lunghezza = $query["lunghezza"];
            	$colonne = $query["colonne"];
            	$ordinamento = $query["ordinamento"];

				if ($dataIniziale == $dataFinale or preg_match("/^\d{7}$/",$codice) or preg_match("/^\d{4}$/",$negozio)) {
					$sql = "select SQL_CALC_FOUND_ROWS 
					a.`BG-DATBOLLA`		DATBOLLA,
					a.`BG-CODCIN`		CODCIN,
					substr(d.`DESC_ARTICOLO`,1,30) DESC_ARTICOLO,
					a.`BG-PZ` * a.`BG-QTA`  		QTA,
					CAST((a.`BG-PVCASH-E` * a.`BG-PZ` * a.`BG-QTA`) AS DECIMAL(8,3))	`val_al_costo_cessione`, 
					CAST((a.`BG-PVIF-E` * a.`BG-PZ` * a.`BG-QTA`) AS DECIMAL(8,2))		`val_al_vendita`, 
					a.`BG-SOCNEG`		SOCNEG, 
					n.`negozio_descrizione`,
					a.`BG-NBOLLA`		NBOLLA ,
					d.`NOME_COMPRATORE`,
					d.`DESC_SOTTOREPARTO`,
					d.`DESC_FAMIGLIA`
					from bollegen as a
					join archivi.negozi as n 
					on a.`BG-SOCNEG` = n.`codice`
					left join mersy_viste.anagrafica_articolo d
					on		a.`BG-CODCIN`= d.`CODICE_ARTICOLO_BULL`
					where ((a.`BG-SOCNEG`=:negozio)
					or		(:negozio=''))
					and DATE_FORMAT(a.`BG-DATBOLLA`, \"%Y-%m-%d\")>=:dataIniziale 
					and DATE_FORMAT(a.`BG-DATBOLLA`, \"%Y-%m-%d\")<=:dataFinale 
					and ((a.`BG-NBOLLA`=:numBolla)
					or	(:numBolla=''))";
					if (preg_match("/^\d{7}$/",$codice)) {
						$sql = "$sql\nand a.`BG-CODCIN`='$codice'";
					}
					if (preg_match("/^\d{3}$/",$famiglia)) {
						$sql = "$sql\nand substr(a.`BG-CODCIN`,1,3) ='$famiglia'";
					}

					if (count($ordinamento)) {
						$sqlOrdinamento = array();
						for ($i=0; $i<count($ordinamento);$i++) {
							array_push($sqlOrdinamento, $colonne[$ordinamento[$i]["column"]]["data"]." ".$ordinamento[$i]["dir"]);
						}
						$sql = "$sql\norder by ".implode(",", $sqlOrdinamento);
					}
					if ($lunghezza > 0) {
						$sql = "$sql\nlimit $inizio,$lunghezza";
					}

					$stmt = $this->pdo->prepare($sql);
					$stmt->execute( array(":dataIniziale" => $dataIniziale,":dataFinale" => $dataFinale,":negozio" => $negozio, ":codice" => $codice, ":numBolla" => $numBolla) );
				} else {
					$sql = "select SQL_CALC_FOUND_ROWS a.*
							from (
									select  a.`BG-SOCNEG`,
											a.`BG-CODCIN`,
											max(a.`BG-DATBOLLA`) `BG-DATBOLLA`
									from	bollegen as a
									where ((a.`BG-SOCNEG`=:negozio)
									or		(:negozio=''))
									and		a.`BG-DATBOLLA`<=:data
									and a.`BG-CODCIN`=:codice 
									group by 1,2
								) as d 
								join bollegen as a 
								on	d.`BG-SOCNEG`	= a.`BG-SOCNEG` 
								and d.`BG-CODCIN`	= a.`BG-CODCIN` 
								and d.`BG-DATBOLLA`	= a.`BG-DATBOLLA`";

					if (preg_match("/^\d{7}$/",$codice)) {
						$sql = "$sql\nwhere a.`BG-CODCIN`='$codice'";
					}
					if (count($ordinamento)) {
						$sqlOrdinamento = array();
						for ($i=0; $i<count($ordinamento);$i++) {
							array_push($sqlOrdinamento, $colonne[$ordinamento[$i]["column"]]["data"]." ".$ordinamento[$i]["dir"]);
						}
						$sql = "$sql\norder by ".implode(",", $sqlOrdinamento);
					}
					if ($lunghezza > 0) {
						$sql = "$sql\nlimit $inizio,$lunghezza";
					}

					$stmt = $this->pdo->prepare($sql);
					$stmt->execute( array(":data" => $dataIniziale,":negozio" => $negozio) );
				}
                $data = $stmt->fetchAll(\PDO::FETCH_ASSOC);

                $recordsTotali = $this->pdo->query("select FOUND_ROWS();")->fetchColumn();

				return array("draw" => $draw, "recordsTotal"=>$recordsTotali*1,"recordsFiltered"=>$recordsTotali*1,"data"=>$data);
								$nl="<br/>";
				echo ">$nl";

            } catch (PDOException $e) {
                die($e->getMessage());
            }
        }

        public function __destruct() {
			parent::__destruct();
        }
        
        public function lista_negozi() {
			$sql = "select codice, negozio_descrizione from negozi where societa in ('00','01','04','31','36') order by codice";
			$result = $this->pdo->prepare($sql);
			$result->execute( array(":negozio" => $codice,":descrizione" => $negozio_descrizione) );
		
			$return_value = "<option selected value=\"\">TUTTI NEGOZI</option>";
			while($row = $result->fetch_assoc()) {
				$return_value .= "<option value=\"".$row["codice"]."\">".$row["codice"].' - '.$row["negozio_descrizione"]."</option>";
			};

		
		return $return_value;
		}
	

    }
?>
