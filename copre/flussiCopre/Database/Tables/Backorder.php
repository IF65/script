<?php
    namespace Database\Tables;
    
    require 'vendor/autoload.php';
    
    use GuzzleHttp\Client;
    use GuzzleHttp\Psr7\Request;
	use Database\Database;

	class Backorder extends Database {

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
                $sql = "CREATE TABLE IF NOT EXISTS `backorder` (
                            `numeroOrdine` varchar(15) NOT NULL DEFAULT '',
                            `dataOrdine` date NOT NULL DEFAULT '0000-00-00',
                            `codiceCliente` varchar(8) NOT NULL DEFAULT '',
                            `rigaOrdine` int(10) unsigned NOT NULL,
                            `codiceCopre` varchar(12) NOT NULL DEFAULT '',
                            `codiceEan` varchar(15) NOT NULL DEFAULT '',
                            `prezzoUnitario` decimal(10,2) unsigned NOT NULL,
                            `quantitaOrdinata` smallint(5) unsigned NOT NULL,
                            `quantitaAllocata` int(10) unsigned NOT NULL,
                            `quantitaInRottura` int(10) unsigned NOT NULL,
                            `quantitaInPreparazione` int(10) unsigned NOT NULL,
                            `quantitaPreparata` int(10) unsigned NOT NULL,
                            `quantitaSpedita` int(10) unsigned NOT NULL,
                            `quantitaFatturata` int(10) unsigned NOT NULL,
                            `ultimoDdt` varchar(15) NOT NULL DEFAULT '',
                            `riferimentoOrdineCliente` varchar(30) NOT NULL DEFAULT '',
                            `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                            PRIMARY KEY (`numeroOrdine`,`dataOrdine`,`codiceCliente`,`rigaOrdine`)
                          ) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
                $this->pdo->exec($sql);

				return true;
            } catch (PDOException $e) {
                die($e->getMessage());
            }
        }

        public function scaricaDatiGrezzi($copreDetails) {
            //$client->setDefaultOption('verify', false);
            $client = new Client(['verify' => false, 'base_uri' => $copreDetails['baseUri']]);
    
            $response = $client->post('DownloadServiceOnDemand',
                    [
                        'headers' => ['Content-Type' => 'application/x-www-form-urlencoded'],
                        'form_params' => ['user' => $copreDetails['user'],'password' => $copreDetails['password'],'cliente' => $copreDetails['cliente'],'file' => 'BACKORDER']
                    ]);
            
            unset($client);
            
            return (string) $response->getBody();
        }
            
        public function scaricaDati($copreDetails) {
            $dati = $this->scaricaDatiGrezzi($copreDetails);
            
            $tabella = array();
            foreach ( preg_split("/\n/", $dati) as $riga ) {
                $record = array();
                if (preg_match('/^(ODV(?:\d|\s){12})(\d\d)(\d\d)(\d\d)..(\d{6})..((?:\d|\s){8})((?:\d|\s){12})((?:\d|\s){15})((?:\d|\s|\,){11})...(\d{8})(\d{8})(\d{8})(\d{8})(\d{8})(\d{8})(\d{8})...(.{15})(.{30}).{19}$/',$riga,$campi)) {
                    $record['numeroOrdine'] = trim($campi[1]); 
                    try {
                        $dateTime = new \DateTime('20'.$campi[4]."-".$campi[3]."-".$campi[2]);
                        $record['data'] = $dateTime->format(\DateTime::ATOM);
                    } catch(Exception $e) {
                        $record['data'] = '20'.$campi[4]."-".$campi[3]."-".$campi[2]."T00:00:00+00:00";
                    }
                    $record['codiceCliente'] = $campi[5]; 
                    $record['rigaOrdine'] = trim($campi[6])*1;
                    $record['codiceCopre'] = trim($campi[7]); 
                    $record['codiceEan'] = trim($campi[8]);
                    $record['prezzoUnitario'] = str_replace(',','',trim($campi[9]))/100; 
                    $record['quantitaOrdinata'] = trim($campi[10])*1; 
                    $record['quantitaAllocata'] = trim($campi[11])*1;
                    $record['quantitaInRottura'] = trim($campi[12])*1; 
                    $record['quantitaInPreparazione'] = trim($campi[13])*1;
                    $record['quantitaPreparata'] = trim($campi[14])*1; 
                    $record['quantitaSpedita'] = trim($campi[15])*1;
                    $record['quantitaFatturata'] = trim($campi[16])*1;
                    $record['ultimoDDt'] = trim($campi[17]); 
                    $record['riferimentoOrdineCliente'] = trim($campi[18]);
                    
                    array_push($tabella, $record);
                }
            }
            
            $risultato['recordCount'] = count($tabella);
            $risultato['data'] = $tabella;
            
            return json_encode($risultato, JSON_PRETTY_PRINT);
        }
        
        public function estraiDati() {
            try {
            	$sql = "select b.*,c.`codiceSM`,c.`descrizione`,t.`descrizione`, t.`modello`, t.`marchio` 
            			from copreFlussi.backorder as b left join archivi.negoziCancelletti as c on b.`codiceCliente`=c.`codiceCancelletto` join copre.tabulatoCopre as t on b.`codiceCopre`=t.`codice`";
                $stmt = $this->pdo->prepare($sql);
				$stmt->execute();
                $data = $stmt->fetchAll(\PDO::FETCH_ASSOC);
                
                $recordsTotali = count($data);
                
                return json_encode(array("draw" => 1, "recordsTotal"=>$recordsTotali,"recordsFiltered"=>$recordsTotali,"data"=>$data), JSON_PRETTY_PRINT);

            } catch (PDOException $e) {
                die($e->getMessage());
            }
        }
        
        public function esportazioneDumpMysql($dati, $filePathName = __DIR__."/exportDump.txt") {
            $righe = json_decode($dati, true);
            
            $risultato = '';
            foreach ( $righe['data'] as $riga ) {
                $risultato .= $riga['numeroOrdine']."\t"; 
                $risultato .= substr($riga['data'],0,10)."\t"; 
                $risultato .= $riga['codiceCliente']."\t"; 
                $risultato .= $riga['rigaOrdine']."\t";  
                $risultato .= $riga['codiceCopre']."\t"; 
                $risultato .= $riga['codiceEan']."\t"; 
                $risultato .= $riga['prezzoUnitario']."\t"; 
                $risultato .= $riga['quantitaOrdinata']."\t"; 
                $risultato .= $riga['quantitaAllocata']."\t"; 
                $risultato .= $riga['quantitaInRottura']."\t"; 
                $risultato .= $riga['quantitaInPreparazione']."\t"; 
                $risultato .= $riga['quantitaPreparata']."\t";
                $risultato .= $riga['quantitaSpedita']."\t"; 
                $risultato .= $riga['quantitaFatturata']."\t"; 
                $risultato .= $riga['ultimoDDt']."\t";
                $risultato .= $riga['riferimentoOrdineCliente']."\n";
            }
            
            file_put_contents($filePathName, $risultato);
        }
        
        public function esportazioneExcel($dati, $filePathName = __DIR__."/exportExcel.txt") {
            
        }
        
        public function salvaRecord($record) {
             try {
                $this->pdo->beginTransaction();

				$sql = "insert into backorder
							( numeroOrdine,dataOrdine,codiceCliente,rigaOrdine,codiceCopre,codiceEan,prezzoUnitario,quantitaOrdinata,quantitaAllocata,quantitaInRottura,quantitaInPreparazione,quantitaPreparata,quantitaSpedita,quantitaFatturata,ultimoDdt,riferimentoOrdineCliente )
						values
							( :numeroOrdine,:dataOrdine,:codiceCliente,:rigaOrdine,:codiceCopre,:codiceEan,:prezzoUnitario,:quantitaOrdinata,:quantitaAllocata,:quantitaInRottura,:quantitaInPreparazione,:quantitaPreparata,:quantitaSpedita,:quantitaFatturata,:ultimoDdt,:riferimentoOrdineCliente )
                        on duplicate key update
                            numeroOrdine = :numeroOrdine,dataOrdine = :dataOrdine,codiceCliente = :codiceCliente,rigaOrdine = :rigaOrdine,codiceCopre = :codiceCopre,codiceEan = :codiceEan,prezzoUnitario = :prezzoUnitario,
                            quantitaOrdinata = :quantitaOrdinata,quantitaAllocata = :quantitaAllocata,quantitaInRottura = :quantitaInRottura,quantitaInPreparazione = :quantitaInPreparazione,
                            quantitaPreparata = :quantitaPreparata,quantitaSpedita = :quantitaSpedita,quantitaFatturata = :quantitaFatturata,ultimoDdt = :ultimoDdt,riferimentoOrdineCliente = :riferimentoOrdineCliente";
				$stmt = $this->pdo->prepare($sql);
                $stmt->execute(array(	":numeroOrdine" => $record['numeroOrdine'],
                                        ":dataOrdine" => $record['dataOrdine'],
                                        ":codiceCliente" => $record['codiceCliente'],
                                        ":rigaOrdine" => $record['rigaOrdine'],
                                        ":codiceCopre" => $record['codiceCopre'],
                                        ":codiceEan" => $record['codiceEan'],
                                        ":prezzoUnitario" => $record['prezzoUnitario'],
                                        ":quantitaOrdinata" => $record['quantitaOrdinata'],
                                        ":quantitaAllocata" => $record['quantitaAllocata'],
                                        ":quantitaInRottura" => $record['quantitaInRottura'],
                                        ":quantitaInPreparazione" => $record['quantitaInPreparazione'],
                                        ":quantitaPreparata" => $record['quantitaPreparata'],
                                        ":quantitaSpedita" => $record['quantitaSpedita'],
                                        ":quantitaFatturata" => $record['quantitaFatturata'],
                                        ":ultimoDdt" => $record['ultimoDdt'],
                                        ":riferimentoOrdineCliente" => $record['riferimentoOrdineCliente']
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

        public function cancellaRecord($numeroOrdine,$dataOrdine,$codiceCliente,$rigaOrdine) {
            try {
                $this->pdo->beginTransaction();

                $sql = "delete from backorder where numeroOrdine = :numeroOrdine and dataOrdine = :dataOrdine and codiceCliente = :codiceCliente and rigaOrdine = :rigaOrdine";
                $stmt = $this->pdo->prepare($sql);
                $stmt->execute(array(":numeroOrdine" => $numeroOrdine, ":dataOrdine" => $dataOrdine, ":codiceCliente" => $codiceCliente, ":rigaOrdine" => $rigaOrdine));
                $stmt->closeCursor();

                $this->pdo->commit();

                return true;
            } catch (PDOException $e) {
                $this->pdo->rollBack();

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
                $csv .= $record['tipo']."\t";
                $csv .= $record['prezzoOfferta']."\t";
                $csv .= ($record['dataFineOfferta'] == null) ? 'NULL'."\t" : $record['dataFineOfferta']."\t";
                $csv .= $record['prezzoVendita']."\t";
                $csv .= $record['prezzoVenditaLocale']."\t";
                $csv .= $record['dataRiferimento']."\n";
            }

            file_put_contents ( "/anagdafi/export.txt" , $csv);
        }

        public function __destruct() {
			parent::__destruct();
        }

    }
?>
