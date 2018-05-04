<?php
	include('Database/bootstrap.php');

	use Database\Tables\Anagdafi;

	$anagdafi = new Anagdafi($sqlDetails);

    // impostazioni generali
	//--------------------------------------------------------------------------------
    @ini_set('memory_limit','2048M');
    $timeZone = new DateTimeZone('Europe/Rome');

    // parametri
	//--------------------------------------------------------------------------------
	$data = $argv[1];
	$negozio = $argv[2];
	
    // caricamento
    //--------------------------------------------------------------------------------

    $csv = file_get_contents('/anagdafi/ANAGDAFI.CSV', FILE_USE_INCLUDE_PATH);
    //$current_encoding = mb_detect_encoding($csv, 'UTF-7,UTF-8,UTF-16,UTF-32,ISO-8859-15');
    //if ($current_encoding != 'UTF-8') {
    //    $csv = mb_convert_encoding($csv, "UTF-8", 'UTF-16');
    //}
    $err = '';

	// creo il codice di controllo 0000000
	$righe = array();
	
	$record = array();
	$record['data'] = DateTime::createFromFormat('Ymd', $data, $timeZone)->format('Y-m-d');
	$record['anno'] = 0;
	$record['anno'] = DateTime::createFromFormat('Ymd', $data, $timeZone)->format('Y');
	$record['codice'] = '0000000';
	$record['negozio'] = $negozio;
	$record['bloccato'] = '';
	$record['dataBlocco'] = null;
	$record['tipo'] = '';
	$record['prezzoOfferta'] = 0.0;
	$record['prezzoVendita'] = 0.0;
	$record['prezzoVenditaLocale'] = DateTime::createFromFormat('Ymd', $data, $timeZone)->format('z');
	$record['dataRiferimento'] = DateTime::createFromFormat('Ymd', $data, $timeZone)->format('Y-m-d');
	array_push( $righe, $record );

    foreach ( preg_split("/\n/", $csv) as $row ) {
        if (preg_match('/^\d{8}\;\d{4}\;\d{7}\;/',$row)) {

            $fields = str_getcsv ($row, ";" );
			$fieldCount = count($fields);

            if (count($fields) >= 25 ) {
                $record = array();

				$record['data'] = null;
                if (!empty($data)) {
                    $record['data'] = DateTime::createFromFormat('Ymd', $data, $timeZone)->format('Y-m-d');
                }
                $record['anno'] = 0;
                 if (!empty($data)) {
                    $record['anno'] = DateTime::createFromFormat('Ymd', $data, $timeZone)->format('Y');
                }
				$record['codice'] = $fields[2];
                $record['negozio'] = $negozio;
                $record['bloccato'] = $fields[3] == ' ' ? 'L' : $fields[3];
                $record['dataBlocco'] = null;
				if (!empty($fields[24]) and $fields[24] != '00000000' and preg_match('/^\d{8}$/',$fields[24])) {
					if ($record['bloccato'] != 'L') {
                    	$record['dataBlocco'] = DateTime::createFromFormat('Ymd', $fields[24], $timeZone)->format('Y-m-d');
                    }
                }
                $record['tipo'] = trim($fields[13]);
                $record['prezzoOfferta'] = preg_match('/^\d{7}$/',$fields[11]) ? $fields[11]/100 : 0.0;
				$record['dataFineOfferta'] = null;
				if (!empty($fields[5]) and $fields[5] != '00000000' and preg_match('/^\d{8}$/',$fields[5])) {
                    $record['dataFineOfferta'] = DateTime::createFromFormat('Ymd', $fields[5], $timeZone)->format('Y-m-d');
                    //if ($record['dataFineOfferta'] <  $record['data']) {$record['dataFineOfferta'] = null;} meglio vedere l'anomalia nei dati
                }
                $record['prezzoVendita'] = preg_match('/^\d{7}$/',$fields[21]) ? $fields[21]/100 : 0.0;
                $record['prezzoVenditaLocale'] = preg_match('/^\d{7}$/',$fields[22]) ? $fields[22]/100 : 0.0;
                $record['dataRiferimento'] = null;
				if (!empty($fields[0]) and $fields[0] != '00000000' and preg_match('/^\d{8}$/',$fields[0])) {
                    $record['dataRiferimento'] = DateTime::createFromFormat('Ymd', $fields[0], $timeZone)->format('Y-m-d');
                }

				array_push( $righe, $record );
            } else {
               $err .= "$row\n";
            }
        } else {
            $err .= "$row\n";
        }
    }

	if (count($righe) > 0) {
		$anagdafi->esportaFile($righe);
	}
?>
