<?php

// Attiva la visualizzazione degli errori in fase di debug (rimuovere in produzione)
error_reporting(E_ALL);
ini_set('display_errors', '1');

$sqlDetails = array(
	"user" 		=> "root",
	"password" 	=> "mela",
	"host" 		=> "10.11.14.78",
	"port" 		=> "",
	"db"   		=> "copreFlussi",
	"dsn" 		=> "",
	"pdoAttr" 	=> array()
);

$copreDetails = array(
    "baseUri" => 'https://cogeso.copre.it/',
    "user" => '200507',
    "password" =>'19673',
    "cliente"=>'200507'
)

?>
