<?php
    namespace Database\Tables;
    
    require 'vendor/autoload.php';
    
    use GuzzleHttp\Client;
    use GuzzleHttp\Psr7;
    use GuzzleHttp\Exception\RequestException;
    use GuzzleHttp\Exception\ClientException;
    use GuzzleHttp\Exception\BadResponseException;
    use GuzzleHttp\Exception\GuzzleException;
	use Database\Database;

	class Check extends Database {

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
                $sql = "CREATE TABLE IF NOT EXISTS `checkLog` (
                            `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
                            `idConnessione` varchar(40) NOT NULL,
                            `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            `funzione` varchar(30) NOT NULL DEFAULT '',
                            `errori` int(11) NOT NULL DEFAULT '0',
                            `descrizione` varchar(255) NOT NULL DEFAULT '',
                            PRIMARY KEY (`id`)
                        ) ENGINE=InnoDB DEFAULT CHARSET=latin1;";
                $this->pdo->exec($sql);

				return true;
            } catch (PDOException $e) {
                die($e->getMessage());
            }
        }

        public function checkCall($kind, $smDetails) {
            $client = new Client();
            try {
                $response = $client->request('POST', $smDetails['baseUri'].'/monitor',
                                             ['headers' => ['Content-Type' => 'text/html; charset=utf-8'],
                                              'body' => 'funzione='.$kind,
                                              'connect_timeout' => 5.00,
                                              ]);
            } catch (GuzzleException $e) {
                return array('funzione' => $kind, 'errori' => -1, 'descrizione' => 'Mancata connessione al server: '.$smDetails['baseUri'].'/monitor');
            }

            unset($client);
            
            return (array) json_decode($response->getBody());
        
            /*
            $today = \DateTime::createFromFormat('Y-m-d', $data, $timeZone)->format('Y-m-d');

            $timeZone = new \DateTimeZone('Europe/Rome');
            $giornoSequenziale = \DateTime::createFromFormat('Y-m-d', $data, $timeZone)->format('z');
        	if ($giornoSequenziale or $data_inizio == $today) {
        		$yesterday = \DateTime::createFromFormat('Y-m-d', $data, $timeZone)->sub(new \DateInterval('P1D'))->format('Y-m-d');
        		
            $sqlDateString = "2014-09-23 18:45:23.534";
            $jsDateString = Replace(' ', 'T', $sqlDateString) . 'Z';
            $appDate = new DateTime($this->jsDateString,  new DateTimeZone("Europe/Amsterdam"));
            $jsonDateString = $appDate->format(DateTime::W3C);
    
            */
                
            
        }
        
        public function salvaRecord($record) {
             try {
                $this->pdo->beginTransaction();

				$sql = "insert into checkLog
							( funzione, errori, descrizione, idConnessione )
                        values
							( :funzione, :errori,:descrizione, :idConnessione)";
                $stmt = $this->pdo->prepare($sql);
                $stmt->execute(array(	":funzione" => $record['funzione'],
                                        ":errori" => $record['errori']*1,
                                        ":descrizione" => $record['descrizione'],
                                        ":idConnessione" => $record['idConnessione']
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

        public function __destruct() {
			parent::__destruct();
        }

    }
?>
