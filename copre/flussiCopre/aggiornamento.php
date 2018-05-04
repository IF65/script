<?php
    require 'Database/Bootstrap.php';
    use Database\Tables\Backorder;
    
    // impostazioni generali
	//--------------------------------------------------------------------------------
    @ini_set('memory_limit','2048M');
    $timeZone = new DateTimeZone('Europe/Rome');

    $nomeFile = '/backorder.txt';
    $backorder = new Backorder($sqlDetails);
    
    if (file_exists($nomeFile)) {
    	unlink($nomeFile);
    }
    $dati = $backorder->scaricaDati($copreDetails);
    $backorder->esportazioneDumpMysql($dati,$nomeFile);
    
    echo "$nomeFile\n";
?>
