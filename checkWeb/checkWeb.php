<?php
    require __DIR__.'/Database/bootstrap.php';
    
    use Database\Tables\Check;
    
    // impostazioni generali
	//--------------------------------------------------------------------------------
    @ini_set('memory_limit','2048M');
    $timeZone = new DateTimeZone('Europe/Rome');

    // parametri
	//--------------------------------------------------------------------------------
    
    $check = new Check($sqlDetails);
    
    $funzioni = array(
                      'maggiordomo' => 'Controlla se il metodo temporizzato \'scheduling-webMaggiordomo\' sia in esecuzione sul server',
                      'metodi_pianificati' => 'Controlla se il metodo temporizzato \'scheduling_metodiPianificati\' sia in esecuzione sul server',
                      'ordini_amazon' => 'Controlla se la procedura che scarica su Selene gli ordini Amazon abbia girato corretamente',
                      'ordini_ebay' => 'Controlla se la procedura che scarica su Selene gli ordini Ebay abbia girato corretamente',
                      'ordiniExt_SMW1' => 'Controlla che gli ordini esterni (Amazon e eBay) ricevuti siano stati inviati a SMW1',
                      'ordiniSito_SMW1' => 'Controlla che gli ordini del sito \'www.supermedia.it ricevuti\' siano stati inviati a SMW1',
                      'giacenze' => 'Controlla se la procedura che aggiorna le disponibilitˆ su Selene sia stata eseguita',
                      'cataloghi' => 'Controlla se la procedura che genera i cataloghi dei prodotti (per Trovaprezzi, Kelkoo, Doofinder, Amazon, eBay) sia stata eseguita'
                    );
    
    
    $uuid = uniqid(true);
    
    foreach ($funzioni as $funzione => $descrizione) {
        $response = $check->checkCall($funzione,$smDetails);
        
        $response['idConnessione'] = $uuid;
        $check->salvaRecord($response);
    }

	echo "$uuid";


