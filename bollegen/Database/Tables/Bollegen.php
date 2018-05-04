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
                $csv .= $record['numbolla']."\t";
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
            	$numbolla = $query["query"]["numbolla"];
            	$inizio = $query["inizio"];
            	$lunghezza = $query["lunghezza"];
            	$colonne = $query["colonne"];
            	$ordinamento = $query["ordinamento"NumBolla];

				if ($dataIniziale != $dataFinale and preg_match("/^\d{7}$/",$codice)) {
					$sql = "select SQL_CALC_FOUND_ROWS a.* from bollegen as a where a.`BG-SOCNEG`= :negozio and a.`BG-DATBOLLA`>=:dataIniziale and a.`BG-DATBOLLA`<=:dataFinale and a.`BG-CODCIN`=:codice and a.`BG-NBOLLA`=:NumBolla";

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
					$stmt->execute( array(":dataIniziale" => $dataIniziale,":dataFinale" => $dataFinale,":negozio" => $negozio, ":codice" => $codice) );
				} else {
					$sql = "select SQL_CALC_FOUND_ROWS a.*
							from (
									select  a.`BG-SOCNEG`,a.`BG-CODCIN`,max(a.`BG-DATBOLLA`) `data`
									from bollegen as a
									where a.`BG-SOCNEG` = :negozio and a.`BG-DATBOLLA`<=:data
									group by 1,2
								) as d join bollegen as a on d.`BG-SOCNEG`=a.`BG-SOCNEG` and d.`BG-CODCIN`=a.`BG-CODCIN` and d.`BG-DATBOLLA`=a.`BG-DATBOLLA`";

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

            } catch (PDOException $e) {
                die($e->getMessage());
            }
        }

        public function __destruct() {
			parent::__destruct();
        }

    }
?>
