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
	
	if (count($argv) == 3 and preg_match('/^\d{8}$/',$argv[1]) and  preg_match('/^\d{4}$/',$argv[2]) ) {
		$data = DateTime::createFromFormat('Ymd', $argv[1], $timeZone)->format('Y-m-d');
		$negozio = $argv[2];
		
		$result = $anagdafi->caricabile($data, $negozio);
		
		echo "$result\n";
	} else
		echo "0\n";
?>
