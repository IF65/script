<?php
    namespace Database\Tables;

	use Database\Database;

	class Anagdafi extends Database {

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
                $sql = "CREATE TABLE `anagdafi` (
                            `data` date NOT NULL,
                            `anno` smallint(5) unsigned NOT NULL DEFAULT '0',
                            `codice` varchar(7) NOT NULL DEFAULT '',
                            `negozio` varchar(4) NOT NULL DEFAULT '',
                            `bloccato` varchar(1) NOT NULL DEFAULT '',
                            `dataBlocco` date DEFAULT NULL,
                            `tipo` varchar(3) NOT NULL DEFAULT '',
                            `prezzoOfferta` decimal(9,2) NOT NULL DEFAULT '0.00',
                            `dataFineOfferta` date DEFAULT NULL,
                            `prezzoVendita` decimal(9,2) NOT NULL DEFAULT '0.00',
                            `prezzoVenditaLocale` decimal(9,2) NOT NULL DEFAULT '0.00',
                            `dataRiferimento` date NOT NULL,
                            PRIMARY KEY (`data`,`codice`,`negozio`),
                            KEY `codice` (`anno`,`codice`,`negozio`,`bloccato`,`dataBlocco`,`tipo`,`prezzoOfferta`,`dataFineOfferta`,`prezzoVendita`,`prezzoVenditaLocale`)
                        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
                $this->pdo->exec($sql);

				return true;
            } catch (PDOException $e) {
                die($e->getMessage());
            }
        }

        public function salvaRecord($record) {
             try {
                $this->pdo->beginTransaction();

				$sql = "insert into anagdafi
							( data,anno,codice,negozio,bloccato,dataBlocco,tipo,prezzoOfferta,dataFineOfferta,prezzoVendita,prezzoVenditaLocale,dataRiferimento )
						values
							( :data,:anno, :codice,:negozio,:bloccato,:dataBlocco,:tipo,:prezzoOfferta,:dataFineOfferta,:prezzoVendita,:prezzoVenditaLocale,:dataRiferimento )
                        on duplicate key update
                            data = :data,codice = :codice,negozio = :negozio,bloccato = :bloccato,dataBlocco = :dataBlocco,tipo =:tipo,prezzoOfferta =:prezzoOfferta,
							dataFineOfferta = :dataFineOfferta,prezzoVendita = :prezzoVendita,prezzoVenditaLocale = :prezzoVenditaLocale,dataRiferimento = :dataRiferimento";
				$stmt = $this->pdo->prepare($sql);
                $stmt->execute(array(	":data" => $record['data'],
                						":anno" => $record['anno'],
										":codice" => $record['codice'],
                                        ":negozio" => $record['negozio'],
                                        ":bloccato" => $record['bloccato'],
                                        ":dataBlocco" => $record['dataBlocco'],
                                        ":tipo" => $record['tipo'],
                                        ":prezzoOfferta" => $record['prezzoOfferta'],
                                        ":dataFineOfferta" => $record['dataFineOfferta'],
                                        ":prezzoVendita" => $record['prezzoVendita'],
                                        ":prezzoVenditaLocale" => $record['prezzoVenditaLocale'],
                                        ":dataRiferimento" => $record['dataRiferimento']
									)
							   );

                $stmt->closeCursor();

                $this->pdo->commit();

                $error = $stmt->errorInfo();
                if ($error[0] != 0) {
                    return $error[2];
                } else {
                    return '';
                }
            } catch (PDOException $e) {
                $this->pdo->rollBack();
                return($e->getMessage());
            }
        }

        public function cancellaRecord($codice, $data, $negozio) {
            try {
                $this->pdo->beginTransaction();

                $sql = "delete from anagdafi where data = :data and codice => :codice and negozio = :negozio";
                $stmt = $this->pdo->prepare($sql);
                $stmt->execute(array(":data" => $data, ":codice" => $codice, ":negozio" => $negozio));
                $stmt->closeCursor();

                $this->pdo->commit();

                return true;
            } catch (PDOException $e) {
                $this->pdo->rollBack();

                die($e->getMessage());
            }
        }

        public function caricabile($data, $negozio, $timeZone = null) {
            if (! isset($timeZone)) {
                $timeZone = new \DateTimeZone('Europe/Rome');
            }

            $sql = "select n.`data_inizio`, n.`data_fine` from archivi.negozi as n where n.`codice` = :negozio;";
            $stmt = $this->pdo->prepare($sql);
			$stmt->execute(array(":negozio" => $negozio) );
			$data_inizio = $result['data_inizio'];
			$data_fine = $result['data_fine'];
			$today = \DateTime::createFromFormat('Y-m-d', $data, $timeZone)->format('Y-m-d');

        	$giornoSequenziale = \DateTime::createFromFormat('Y-m-d', $data, $timeZone)->format('z');
        	if ($giornoSequenziale or $data_inizio == $today) {
        		$yesterday = \DateTime::createFromFormat('Y-m-d', $data, $timeZone)->sub(new \DateInterval('P1D'))->format('Y-m-d');
				$sql = "select count(*) `count` from anagdafi where data = :data and negozio = :negozio and codice = '0000000';";
				$stmt = $this->pdo->prepare($sql);
				$stmt->execute(array(":data" => $yesterday,":negozio" => $negozio) );
				$result = $stmt->fetch();
				$count = $result['count'];

				if ($count) {
					return "1";
				} else {
					return "0";
				};
			} else
				return "1";
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
                $csv .= $record['tipo']."\t";
                $csv .= $record['prezzoOfferta']."\t";
                $csv .= ($record['dataFineOfferta'] == null) ? 'NULL'."\t" : $record['dataFineOfferta']."\t";
                $csv .= $record['prezzoVendita']."\t";
                $csv .= $record['prezzoVenditaLocale']."\t";
                $csv .= $record['dataRiferimento']."\n";
            }

            file_put_contents ( "/anagdafi/export.txt" , $csv);
        }

		public function prezziDelGiorno($data, $negozio) {
        	try {
                $sql = "select a.*
                        from (
                                select a.`negozio`, a.`codice`,max(a.`data`) `data`
                                from anagdafi as a
                                where a.`negozio`= :negozio and a.`data`<=:data
                                group by 1,2
                            ) as d join anagdafi as a on d.`negozio`=a.`negozio` and d.`codice`=a.`codice` and d.`data`=a.`data`
                        order by a.`codice`";
                $stmt = $this->pdo->prepare($sql);
				$stmt->execute(array(":data" => $data,":negozio" => $negozio) );
                $data = $stmt->fetchAll(\PDO::FETCH_ASSOC);

				return array("recordsTotal"=>count($data),"data"=>$data);

            } catch (PDOException $e) {
                die($e->getMessage());
            }
        }

        public function ricerca($query) {
            try {
            	$draw = $query["draw"];
            	$dataIniziale = $query["query"]["dataIniziale"];
            	$dataFinale = $query["query"]["dataFinale"];
            	$negozio = $query["query"]["negozio"];
            	$codice = $query["query"]["codice"];
            	$tipo = $query["query"]["tipo"];
            	$inizio = $query["inizio"];
            	$lunghezza = $query["lunghezza"];
            	$colonne = $query["colonne"];
            	$ordinamento = $query["ordinamento"];

				if ($dataIniziale != $dataFinale and preg_match("/^\d{7}$/",$codice)) {
					$sql = "select SQL_CALC_FOUND_ROWS a.* from anagdafi as a where a.`negozio`= :negozio and a.`data`>=:dataIniziale and a.`data`<=:dataFinale and a.`codice`=:codice";

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
									select a.`negozio`, a.`codice`,max(a.`data`) `data`
									from anagdafi as a
									where a.`negozio`= :negozio and a.`data`<=:data
									group by 1,2
								) as d join anagdafi as a on d.`negozio`=a.`negozio` and d.`codice`=a.`codice` and d.`data`=a.`data`";

					if (preg_match("/^\d{7}$/",$codice)) {
						$sql = "$sql\nwhere a.`codice`='$codice'";
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
