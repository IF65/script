/*SUPERMEDIA
-----------------------------------------------------------------------------------------
*/
CREATE DATABASE IF NOT EXISTS `db_sm`;

CREATE TABLE IF NOT EXISTS `db_sm`.`logCaricamento` (
	`tsCreazione` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`tsModifica` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`sede` varchar(4) NOT NULL DEFAULT '',
	`data` date NOT NULL,
	`tipo` varchar(3) NOT NULL DEFAULT '',
	`descrizione` varchar(100) NOT NULL DEFAULT '',
	`vuoto` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`sede`,`data`,`tipo`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`magazzino` (
	`codice` varchar(7) NOT NULL DEFAULT '',
	`codice_mondo` varchar(20) NOT NULL DEFAULT '',
	`codice_settore` varchar(20) NOT NULL DEFAULT '',
	`codice_reparto` varchar(20) NOT NULL DEFAULT '',
	`codice_famiglia` varchar(20) NOT NULL DEFAULT '',
	`codice_sottofamiglia` varchar(20) NOT NULL DEFAULT '',
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`modello` varchar(255) NOT NULL DEFAULT '',
	`linea` varchar(255) NOT NULL DEFAULT '',
	`taglia` varchar(20) NOT NULL DEFAULT '',
	`colore` varchar(20) NOT NULL DEFAULT '',
	`stagionalita` int(11) NOT NULL DEFAULT 0,
	`costo_medio` float NOT NULL DEFAULT 0,
	`costo_ultimo` float NOT NULL DEFAULT 0,
	`listino_1` float NOT NULL DEFAULT 0,
	`listino_2` float NOT NULL DEFAULT 0,
	`listino_3` float NOT NULL DEFAULT 0,
	`listino_promo` float NOT NULL DEFAULT 0,
	`aliquota_iva` float NOT NULL DEFAULT 0,
	`tipo_iva` int(11) NOT NULL DEFAULT 0,
	`eliminato` tinyint(1) NOT NULL,
	`obsoleto` tinyint(1) NOT NULL,
	`griglia` varchar(30) NOT NULL DEFAULT '',
	`data_creazione` date NOT NULL DEFAULT '0000-00-00',
	`invio_gre` tinyint(1) NOT NULL,
	`giacenza_bloccata` tinyint(1) NOT NULL,
	`codice_padre` varchar(7) NOT NULL DEFAULT '',
	`contoVendita` tinyint(4) NOT NULL DEFAULT '0',
	PRIMARY KEY (`codice`),
	KEY `codice_mondo` (`codice_mondo`,`codice_settore`,`codice_reparto`,`codice_famiglia`,`codice_sottofamiglia`),
	KEY `descrizione` (`descrizione`),
	KEY `linea` (`linea`),
	KEY `eliminato` (`eliminato`),
	KEY `giacenza_bloccata` (`giacenza_bloccata`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`marche` (
	`linea` varchar(40) NOT NULL DEFAULT '',
	`marca` varchar(40) NOT NULL DEFAULT '',
	`codice_compratore` varchar(5) NOT NULL DEFAULT '',
	`invio_gre` tinyint(1) NOT NULL,
	`copre` tinyint(1) NOT NULL,
	PRIMARY KEY (`linea`),
	KEY `marca` (`marca`),
	KEY `codice_compratore` (`codice_compratore`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`mondi` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`settori` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`codice_mondo` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`reparti` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`codice_settore` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`famiglie` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`codice_reparto` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`sottofamiglie` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`codice_famiglia` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice_famiglia`,`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`ean` (
	`codice` varchar(7) NOT NULL DEFAULT '',
	`ean` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`ean`),
	KEY `codice` (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`righe_vendita` (
  `progressivo` varchar(36) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `ora` varchar(8) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `ean` varchar(13) NOT NULL DEFAULT '',
  `reparto` varchar(20) NOT NULL DEFAULT '',
  `famiglia` varchar(20) NOT NULL DEFAULT '',
  `sottofamiglia` varchar(20) NOT NULL DEFAULT '',
  `riga_non_fiscale` tinyint(1) NOT NULL,
  `riparazione` tinyint(1) NOT NULL,
  `numero_riparazione` varchar(13) NOT NULL DEFAULT '',
  `prezzo_unitario` float NOT NULL DEFAULT 0,
  `quantita` float NOT NULL DEFAULT 0,
  `importo_totale` float NOT NULL DEFAULT 0,
  `margine` float NOT NULL DEFAULT 0,
  `aliquota_iva` float NOT NULL DEFAULT 0,
  `tipo_iva` int(11) NOT NULL DEFAULT 0,
  `descrizione` varchar(255) NOT NULL DEFAULT '',
  `linea` varchar(40) NOT NULL DEFAULT '',
  `matricola_rc` varchar(10) NOT NULL DEFAULT '',
  `codice_operatore` varchar(4) NOT NULL DEFAULT '',
  `codice_venditore` varchar(4) NOT NULL DEFAULT '',
  `id_scontrino` varchar(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`progressivo`),
  KEY `data` (`data`,`negozio`,`codice`),
  KEY `codice` (`codice`),
  KEY `ean` (`ean`),
  KEY `id_scontrino` (`id_scontrino`),
  KEY `progressivo` (`progressivo`,`margine`),
  KEY `linea` (`linea`),
  KEY `codice_venditore` (`codice_venditore`),
  KEY `data_2` (`data`,`negozio`),
  KEY `codice_2` (`codice`,`negozio`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`scontrini` (
  `id_scontrino` varchar(32) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL,
  `data` date NOT NULL,
  `ora` varchar(8) NOT NULL DEFAULT '',
  `numero` int(11) NOT NULL,
  `numero_upb` int(11) NOT NULL,
  `scontrino_non_fiscale` tinyint(1) NOT NULL,
  `carta` varchar(13) NOT NULL DEFAULT '',
  `totale` float NOT NULL DEFAULT 0,
  `buoni` float NOT NULL DEFAULT 0,
  `ip` varchar(15) NOT NULL DEFAULT '',
  PRIMARY KEY (`id_scontrino`),
  KEY `negozio` (`negozio`,`data`),
  KEY `numero` (`numero`),
  KEY `numero_upb` (`numero_upb`),
  KEY `scontrino_non_fiscale` (`scontrino_non_fiscale`),
  KEY `carta` (`carta`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*CREATE TABLE IF NOT EXISTS `db_sm`.`margini` (
  `progressivo` varchar(36) NOT NULL DEFAULT '',
  `margine` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`progressivo`),
  KEY `progressivo` (`progressivo`,`margine`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;*/

/*CREATE TABLE IF NOT EXISTS `db_sm`. `giacenze` (
  `codice` varchar(7) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `giacenza` float NOT NULL DEFAULT 0,
  `data` date NOT NULL,
  PRIMARY KEY (`codice`,`negozio`,`data`),
  KEY `data` (`data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;*/

CREATE TABLE IF NOT EXISTS `db_sm`.`contributi` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`data` date NOT NULL,
	`competenza` int(11) NOT NULL,
	`marca` varchar(40) NOT NULL DEFAULT '',
	`livello_margine` varchar(2) NOT NULL DEFAULT '',
	`descrizione_contabile` varchar(80) NOT NULL DEFAULT '',
	`importo` float NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	KEY `marca` (`marca`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`arrivi` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`numero` varchar(25) NOT NULL DEFAULT '',
	`negozio` varchar(4) NOT NULL DEFAULT '',
	`data_arrivo` date NOT NULL DEFAULT '0000-00-00',
	`data_ddt` date NOT NULL DEFAULT '0000-00-00',
	`numero_ddt` varchar(20) NOT NULL DEFAULT '',
	`codice_fornitore` varchar(10) NOT NULL DEFAULT '',
	`bozza` tinyint(1) NOT NULL DEFAULT 0,
	`materiale_consumo` tinyint(1) NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	KEY `arrivo` (`negozio`,`data_arrivo`),
	KEY `ddt` (`data_ddt`,`numero_ddt`, `codice_fornitore`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`righe_arrivi` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`id_arrivi` varchar(36) NOT NULL DEFAULT '',
	`keycod` varchar(36) NOT NULL DEFAULT '',
	`codice_articolo` varchar(7) NOT NULL DEFAULT '',
	`codice_articolo_fornitore` varchar(15) NOT NULL DEFAULT '',
	`costo` float NOT NULL DEFAULT 0,
	`listino` float NOT NULL DEFAULT 0,
	`quantita` int NOT NULL DEFAULT 0,
	`quantita_evasa` int NOT NULL DEFAULT 0,
	`sconto_a` float NOT NULL DEFAULT 0,
	`sconto_b` float NOT NULL DEFAULT 0,
	`sconto_c` float NOT NULL DEFAULT 0,
	`sconto_d` float NOT NULL DEFAULT 0,
	`sconto_cassa` float NOT NULL DEFAULT 0,
	`sconto_commerciale` float NOT NULL DEFAULT 0,
	`sconto_extra` float NOT NULL DEFAULT 0,
	`sconto_importo` float NOT NULL DEFAULT 0,
	`sconto_merce` float NOT NULL DEFAULT 0,
	`spese_trasporto` float NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	KEY `arrivi` (`id_arrivi`),
	KEY `articolo` (`codice_articolo`,`codice_articolo_fornitore`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`trasferimenti_in` (
  `link` varchar(36) NOT NULL DEFAULT '',
  `negozio_partenza` varchar(4) NOT NULL DEFAULT '',
  `negozio_arrivo` varchar(4) NOT NULL DEFAULT '',
  `numero_ddt` varchar(13) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `fase` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `causale` varchar(28) NOT NULL DEFAULT '',
  `solo_giacenze` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`link`),
  KEY `negozio` (`negozio_partenza`, `negozio_arrivo`),
  KEY `ddt` (`numero_ddt`, `data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`righe_trasferimenti_in` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `link_trasferimento` varchar(36) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `ean` varchar(13) NOT NULL DEFAULT '',
  `quantita` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `link` (`link_trasferimento`),
  KEY `codici` (`codice`, `ean`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`trasferimenti_out` (
  `link` varchar(36) NOT NULL DEFAULT '',
  `negozio_partenza` varchar(4) NOT NULL DEFAULT '',
  `negozio_arrivo` varchar(4) NOT NULL DEFAULT '',
  `numero_ddt` varchar(13) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `fase` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `causale` varchar(28) NOT NULL DEFAULT '',
  `solo_giacenze` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`link`),
  KEY `negozio` (`negozio_partenza`, `negozio_arrivo`),
  KEY `ddt` (`numero_ddt`, `data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`righe_trasferimenti_out` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `link_trasferimento` varchar(36) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `ean` varchar(13) NOT NULL DEFAULT '',
  `quantita` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `link` (`link_trasferimento`),
  KEY `codici` (`codice`, `ean`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`diversi` (
  `link` varchar(36) NOT NULL DEFAULT '',
  `progressivo` varchar(36) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `numero_ddt` varchar(5) NOT NULL DEFAULT '',
  `definitivo` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`link`),
  KEY `progressivo` (`progressivo`),
  KEY `data` (`data`, `negozio`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`righe_diversi` (
  `progressivo` varchar(36) NOT NULL DEFAULT '',
  `link_diversi` varchar(36) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `ean` varchar(7) NOT NULL DEFAULT '',
  `quantita` float NOT NULL DEFAULT 0,
  `costo` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`progressivo`),
  KEY `link` (`link_diversi`),
  KEY `codici` (`codice`, `ean`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`giacenze_iniziali` (
  `codice` varchar(7) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `giacenza` float NOT NULL DEFAULT 0,
  `costo_medio` float NOT NULL DEFAULT 0,
  `anno_attivo` int NOT NULL DEFAULT 2015,
  PRIMARY KEY (`codice`,`negozio`,`anno_attivo`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`log_invio_dati` (
  `codice` varchar(4) NOT NULL DEFAULT '',
  `codice_interno` varchar(4) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `invio_gre` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `solo_giacenze` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`codice`,`codice_interno`,`data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`benefici` (
  `codice_campagna` varchar(5) NOT NULL DEFAULT '',
  `codice_promozione` varchar(9) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `descrizione` varchar(255) NOT NULL DEFAULT '',
  `id` varchar(36) NOT NULL DEFAULT '',
  `id_scontrino` varchar(36) NOT NULL DEFAULT '',
  `ora` varchar(10) NOT NULL DEFAULT '',
  `id_riga_vendita` varchar(36) NOT NULL DEFAULT '',
  `tipo` varchar(2) NOT NULL DEFAULT '',
  `valore` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `codici` (`codice_campagna`, `codice_promozione`),
  KEY `date` (`data`, `negozio`,tipo)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`venditori` (
  `matricola` varchar(6) NOT NULL DEFAULT '',
  `codice_buyer` varchar(5) NOT NULL DEFAULT '',
  `codice` varchar(4) NOT NULL DEFAULT '',
  `cognome` varchar(20) NOT NULL DEFAULT '',
  `nome` varchar(20) NOT NULL DEFAULT '',
  `data_nascita` date NOT NULL DEFAULT '0000-00-00',
  `data_assunzione` date NOT NULL DEFAULT '0000-00-00',
  `data_dimissioni` date NOT NULL DEFAULT '0000-00-00',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `contratto` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`matricola`),
  KEY `buyer` (`codice_buyer`),
  KEY `negozio` (`negozio`),
  KEY `date` (`data_assunzione`, `data_dimissioni`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`fornitore_articolo` (
	`codice_fornitore` varchar(10) NOT NULL DEFAULT '',
	`codice_articolo_fornitore` varchar(15) NOT NULL DEFAULT '',
	`codice_articolo` varchar(7) NOT NULL DEFAULT '',
	KEY (`codice_fornitore`,`codice_articolo_fornitore`,`codice_articolo`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`ordini` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `numero` varchar(10) NOT NULL DEFAULT '',
  `data_ordine` date NOT NULL DEFAULT '0000-00-00',
  `fornitore` varchar(10) NOT NULL DEFAULT '',
  `codice_buyer` varchar(10) NOT NULL DEFAULT '',
  `pagamento` varchar(8) NOT NULL DEFAULT '',
  `data_consegna` date NOT NULL DEFAULT '0000-00-00',
  `data_consegna_min` date NOT NULL DEFAULT '0000-00-00',
  `data_consegna_max` date NOT NULL DEFAULT '0000-00-00',
  `sospeso` tinyint(1) NOT NULL DEFAULT 0,
  `annullato` tinyint(1) NOT NULL DEFAULT 0,
  `stralciato` tinyint(1) NOT NULL DEFAULT 0,
  `spese_trasporto` float NOT NULL DEFAULT 0,
  `spese_trasporto_percentuali` float NOT NULL DEFAULT 0,
  `sconto_cassa_percentuale` float NOT NULL DEFAULT 0,
  `totale` float NOT NULL DEFAULT 0,
  `importo_BO` float NOT NULL DEFAULT 0,
  `pezzi_BO` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `principale` (`numero`, `data_ordine`,`fornitore`,`codice_buyer`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`ordini_sedi` (
	`id_ordini` varchar(36) NOT NULL DEFAULT '',
	`sede` varchar(4) NOT NULL DEFAULT '',
	PRIMARY KEY (`id_ordini`,`sede`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`ordini_righe` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`id_ordini` varchar(36) NOT NULL DEFAULT '',
	`id_suddivisione` int(11) NOT NULL DEFAULT 0, 
	`keycod` varchar(36) NOT NULL DEFAULT '',
	`codice_articolo` varchar(7) NOT NULL DEFAULT '',
	`codice_articolo_fornitore` varchar(15) NOT NULL DEFAULT '',
	`listino` float NOT NULL DEFAULT 0,
	`sconto_a` float NOT NULL DEFAULT 0,
	`sconto_b` float NOT NULL DEFAULT 0,
	`sconto_c` float NOT NULL DEFAULT 0,
	`sconto_d` float NOT NULL DEFAULT 0,
	`sconto_commerciale` float NOT NULL DEFAULT 0,
	`sconto_extra` float NOT NULL DEFAULT 0,
	`sconto_importo` float NOT NULL DEFAULT 0,
	`sconto_merce` float NOT NULL DEFAULT 0,
	`costo_finito` float NOT NULL DEFAULT 0,
	`quantita` int NOT NULL DEFAULT 0,
	`totale` float NOT NULL DEFAULT 0,
	`quantita_evasa` int NOT NULL DEFAULT 0,
	`sospeso` tinyint(1) NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	KEY `ordini` (`id_ordini`),
	KEY `articolo` (`codice_articolo`,`codice_articolo_fornitore`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`ordini_righe_quantita` (
	`id` int(11) NOT NULL DEFAULT 0,
	`id_righe` varchar(36) NOT NULL DEFAULT '',
	`sede` varchar(4) NOT NULL DEFAULT '',
	`quantita` int(11) NOT NULL DEFAULT 0,
	`sconto_merce` int(11) NOT NULL DEFAULT 0,
	`sospeso` tinyint(1) NOT NULL DEFAULT 0,
	KEY `righe` (`id_righe`),
	KEY `sede` (`sede`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`ordini_righe_quantita_ventilazione` (
	`id_quantita` varchar(36) NOT NULL DEFAULT '',
	`sede` varchar(4) NOT NULL DEFAULT '',
	`quantita` int(11) NOT NULL DEFAULT 0,
	PRIMARY KEY (`id_quantita`,`sede`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*solo supermedia*/
CREATE TABLE IF NOT EXISTS `db_sm`.`tabulato_copre` (
	`codice` varchar(10) NOT NULL DEFAULT '',
	`codiceSM` varchar(7) NOT NULL DEFAULT '',
	`codiceMarchio` varchar(3) NOT NULL DEFAULT '',
	`settore` varchar(3) NOT NULL DEFAULT '',
	`descrizioneSettore` varchar(40) NOT NULL DEFAULT '',
	`sottoSettore` varchar(4) NOT NULL DEFAULT '',
	`descrizioneSottoSettore` varchar(40) NOT NULL DEFAULT '',
	`descrizione` varchar(35) NOT NULL DEFAULT '',
	`modello` varchar(20) NOT NULL DEFAULT '',
	`marchio` varchar(20) NOT NULL DEFAULT '',
	`iva` float NOT NULL DEFAULT 0,
	`esclusiva` tinyint(1) NOT NULL DEFAULT 0,
	`novita` tinyint(1) NOT NULL DEFAULT 0,
	`eliminato` tinyint(1) NOT NULL DEFAULT 0,
	`barcode` varchar(13) NOT NULL DEFAULT '',
	`griglia` tinyint(1) NOT NULL DEFAULT 0,
	`grigliaObbligatorio` tinyint(1) NOT NULL DEFAULT 0,
	`giacenza` int(11) NOT NULL DEFAULT 0,
	`inOrdine` int(11) NOT NULL DEFAULT 0,
	`percentualeRicarico` float NOT NULL DEFAULT 0,
	`prezzoAcquisto` float NOT NULL DEFAULT 0,
	`prezzoAcquistoCalcolato` float NOT NULL DEFAULT 0,
	`prezzoRiordino` float NOT NULL DEFAULT 0,
	`prezzoVendita` float NOT NULL DEFAULT 0,
	PRIMARY KEY (`codice`),
	KEY `barcode` (`barcode`),
	KEY `codiceSM` (`codiceSM`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sm`.`fatture_ca` (
  `codice_ca` varchar(12) NOT NULL DEFAULT '',
  `numero` varchar(20) NOT NULL DEFAULT '',
  `numero_riga` int(11) NOT NULL DEFAULT 0,
  `data` date NOT NULL DEFAULT '0000-00-00',
  `tipo` varchar(20) NOT NULL DEFAULT '',
  `codice_cliente` varchar(6) NOT NULL DEFAULT '',
  `indirizzo_fatturazione` varchar(255) NOT NULL DEFAULT '',
  `codice_punto_consegna` varchar(6) NOT NULL DEFAULT '',
  `riferimento_riga_ordine` varchar(20) NOT NULL DEFAULT '',
  `riferimento_ordine` varchar(20) NOT NULL DEFAULT '',
  `numero_ordine_interno` varchar(20) NOT NULL DEFAULT '',
  `numero_consegna` varchar(20) NOT NULL DEFAULT '',
  `data_consegna` date NOT NULL DEFAULT '0000-00-00',
  `numero_riga_consegna` int(11) NOT NULL DEFAULT 0,
  `codice_ean` varchar(13) NOT NULL DEFAULT '',
  `codice_articolo_copre` varchar(20) NOT NULL DEFAULT '',
  `codice_articolo_interno` varchar(10) NOT NULL DEFAULT '',
  `codice_articolo_if` varchar(7) NOT NULL DEFAULT '',
  `modello_articolo` varchar(100) NOT NULL DEFAULT '',
  `quantita` float NOT NULL DEFAULT 0,
  `prezzo_netto` float NOT NULL DEFAULT 0,
  `scala_sconto_1` float NOT NULL DEFAULT 0,
  `scala_sconto_2` float NOT NULL DEFAULT 0,
  `scala_sconto_3` float NOT NULL DEFAULT 0,
  `scala_sconto_5` float NOT NULL DEFAULT 0,
  `scala_sconto_9` float NOT NULL DEFAULT 0,
  `prezzo_lordo` float NOT NULL DEFAULT 0,  
  `codice_iva` varchar(10) NOT NULL DEFAULT '',
  `aliquota_iva` float NOT NULL DEFAULT 0,
  `numero_bolla_fornitore` varchar(40) NOT NULL DEFAULT '',
  `data_bolla_fornitore` date NOT NULL DEFAULT '0000-00-00',
  `descrizione_articolo` varchar(100) NOT NULL DEFAULT '',
  `marca_articolo` varchar(100) NOT NULL DEFAULT '',
  `codice_fornitore` varchar(6) NOT NULL DEFAULT '',
  `descrizione_fornitore` varchar(255) NOT NULL DEFAULT '',
  `note_contributi` varchar(20) NOT NULL DEFAULT '',
  `note` varchar(255) NOT NULL DEFAULT '',
  `articolo_inesistente` tinyint NOT NULL DEFAULT 0,
  `sede` varchar(4) NOT NULL DEFAULT '',
  PRIMARY KEY (`codice_ca`,`numero`,`numero_riga`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

/*solo supermedia*/
CREATE TABLE IF NOT EXISTS `db_sm`.`verifica_arrivi` (
  `link` varchar(36) NOT NULL DEFAULT '',
  `codice_fornitore` varchar(10) NOT NULL DEFAULT '',
  `numero_bolla` varchar(20) NOT NULL DEFAULT '',
  `data_bolla` date NOT NULL DEFAULT '0000-00-00',
  `sede` varchar(4) NOT NULL DEFAULT '',
  `codice_fatturazione` varchar(15) NOT NULL DEFAULT '',
  `numero_fattura` varchar(20) NOT NULL DEFAULT '',
  `data_fattura` date NOT NULL DEFAULT '0000-00-00',
  `importo_fattura` float NOT NULL DEFAULT 0,
  `fase` int(11) NOT NULL DEFAULT 0,
  `stato`int(11) NOT NULL DEFAULT 0,
  `flag_cancellato` tinyint NOT NULL DEFAULT 0,
  `flag_bozza` tinyint NOT NULL DEFAULT 0,
  PRIMARY KEY (`link`),
  KEY `fornitore` (`codice_fornitore`,`numero_bolla`,`data_bolla`),
  KEY `fattura` (`numero_fattura`,`data_fattura`,`sede`),
  KEY `fase` (`fase`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `db_sm`.`temp_stock`;

/*SPORTLAND
-----------------------------------------------------------------------------------------
*/
CREATE DATABASE IF NOT EXISTS `db_sp`;

CREATE TABLE IF NOT EXISTS `db_sp`.`logCaricamento` (
	`tsCreazione` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`tsModifica` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`sede` varchar(4) NOT NULL DEFAULT '',
	`data` date NOT NULL,
	`tipo` varchar(3) NOT NULL DEFAULT '',
	`descrizione` varchar(100) NOT NULL DEFAULT '',
	`vuoto` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`sede`,`data`,`tipo`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`magazzino` (
	`codice` varchar(7) NOT NULL DEFAULT '',
	`codice_mondo` varchar(20) NOT NULL DEFAULT '',
	`codice_settore` varchar(20) NOT NULL DEFAULT '',
	`codice_reparto` varchar(20) NOT NULL DEFAULT '',
	`codice_famiglia` varchar(20) NOT NULL DEFAULT '',
	`codice_sottofamiglia` varchar(20) NOT NULL DEFAULT '',
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`modello` varchar(255) NOT NULL DEFAULT '',
	`linea` varchar(255) NOT NULL DEFAULT '',
	`taglia` varchar(20) NOT NULL DEFAULT '',
	`colore` varchar(20) NOT NULL DEFAULT '',
	`stagionalita` int(11) NOT NULL DEFAULT 0,
	`costo_medio` float NOT NULL DEFAULT 0,
	`costo_ultimo` float NOT NULL DEFAULT 0,
	`listino_1` float NOT NULL DEFAULT 0,
	`listino_2` float NOT NULL DEFAULT 0,
	`listino_3` float NOT NULL DEFAULT 0,
	`listino_promo` float NOT NULL DEFAULT 0,
	`aliquota_iva` float NOT NULL DEFAULT 0,
	`tipo_iva` int(11) NOT NULL DEFAULT 0,
	`eliminato` tinyint(1) NOT NULL,
	`obsoleto` tinyint(1) NOT NULL,
	`griglia` varchar(30) NOT NULL DEFAULT '',
	`data_creazione` date NOT NULL DEFAULT '0000-00-00',
	`invio_gre` tinyint(1) NOT NULL,
	`giacenza_bloccata` tinyint(1) NOT NULL,
	`codice_padre` varchar(7) NOT NULL DEFAULT '',
	`contoVendita` tinyint(4) NOT NULL DEFAULT '0',
	PRIMARY KEY (`codice`),
	KEY `codice_mondo` (`codice_mondo`,`codice_settore`,`codice_reparto`,`codice_famiglia`,`codice_sottofamiglia`),
	KEY `descrizione` (`descrizione`),
	KEY `linea` (`linea`),
	KEY `eliminato` (`eliminato`),
	KEY `giacenza_bloccata` (`giacenza_bloccata`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`marche` (
	`linea` varchar(40) NOT NULL DEFAULT '',
	`marca` varchar(40) NOT NULL DEFAULT '',
	`codice_compratore` varchar(5) NOT NULL DEFAULT '',
	`invio_gre` tinyint(1) NOT NULL,
	`copre` tinyint(1) NOT NULL,
	PRIMARY KEY (`linea`),
	KEY `marca` (`marca`),
	KEY `codice_compratore` (`codice_compratore`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`mondi` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`settori` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`codice_mondo` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`reparti` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`codice_settore` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`famiglie` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`codice_reparto` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`sottofamiglie` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`codice_famiglia` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice_famiglia`,`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`ean` (
	`codice` varchar(7) NOT NULL DEFAULT '',
	`ean` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`ean`),
	KEY `codice` (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`righe_vendita` (
  `progressivo` varchar(36) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `ora` varchar(8) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `ean` varchar(13) NOT NULL DEFAULT '',
  `reparto` varchar(20) NOT NULL DEFAULT '',
  `famiglia` varchar(20) NOT NULL DEFAULT '',
  `sottofamiglia` varchar(20) NOT NULL DEFAULT '',
  `riga_non_fiscale` tinyint(1) NOT NULL,
  `riparazione` tinyint(1) NOT NULL,
  `numero_riparazione` varchar(13) NOT NULL DEFAULT '',
  `prezzo_unitario` float NOT NULL DEFAULT 0,
  `quantita` float NOT NULL DEFAULT 0,
  `importo_totale` float NOT NULL DEFAULT 0,
  `margine` float NOT NULL DEFAULT 0,
  `aliquota_iva` float NOT NULL DEFAULT 0,
  `tipo_iva` int(11) NOT NULL DEFAULT 0,
  `descrizione` varchar(255) NOT NULL DEFAULT '',
  `linea` varchar(40) NOT NULL DEFAULT '',
  `matricola_rc` varchar(10) NOT NULL DEFAULT '',
  `codice_operatore` varchar(4) NOT NULL DEFAULT '',
  `codice_venditore` varchar(4) NOT NULL DEFAULT '',
  `id_scontrino` varchar(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`progressivo`),
  KEY `data` (`data`,`negozio`,`codice`),
  KEY `codice` (`codice`),
  KEY `ean` (`ean`),
  KEY `id_scontrino` (`id_scontrino`),
  KEY `progressivo` (`progressivo`,`margine`),
  KEY `linea` (`linea`),
  KEY `codice_venditore` (`codice_venditore`),
  KEY `data_2` (`data`,`negozio`),
  KEY `codice_2` (`codice`,`negozio`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`scontrini` (
  `id_scontrino` varchar(32) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL,
  `data` date NOT NULL,
  `ora` varchar(8) NOT NULL DEFAULT '',
  `numero` int(11) NOT NULL,
  `numero_upb` int(11) NOT NULL,
  `scontrino_non_fiscale` tinyint(1) NOT NULL,
  `carta` varchar(13) NOT NULL DEFAULT '',
  `totale` float NOT NULL DEFAULT 0,
  `buoni` float NOT NULL DEFAULT 0,
  `ip` varchar(15) NOT NULL DEFAULT '',
  PRIMARY KEY (`id_scontrino`),
  KEY `negozio` (`negozio`,`data`),
  KEY `numero` (`numero`),
  KEY `numero_upb` (`numero_upb`),
  KEY `scontrino_non_fiscale` (`scontrino_non_fiscale`),
  KEY `carta` (`carta`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`margini` (
  `progressivo` varchar(36) NOT NULL DEFAULT '',
  `margine` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`progressivo`),
  KEY `progressivo` (`progressivo`,`margine`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`. `giacenze` (
  `codice` varchar(7) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `giacenza` float NOT NULL DEFAULT 0,
  `data` date NOT NULL,
  PRIMARY KEY (`codice`,`negozio`,`data`),
  KEY `data` (`data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`contributi` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`data` date NOT NULL,
	`competenza` int(11) NOT NULL,
	`marca` varchar(40) NOT NULL DEFAULT '',
	`livello_margine` varchar(2) NOT NULL DEFAULT '',
	`descrizione_contabile` varchar(80) NOT NULL DEFAULT '',
	`importo` float NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	KEY `marca` (`marca`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`arrivi` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`numero` varchar(25) NOT NULL DEFAULT '',
	`negozio` varchar(4) NOT NULL DEFAULT '',
	`data_arrivo` date NOT NULL DEFAULT '0000-00-00',
	`data_ddt` date NOT NULL DEFAULT '0000-00-00',
	`numero_ddt` varchar(20) NOT NULL DEFAULT '',
	`codice_fornitore` varchar(10) NOT NULL DEFAULT '',
	`bozza` tinyint(1) NOT NULL DEFAULT 0,
	`materiale_consumo` tinyint(1) NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	KEY `arrivo` (`negozio`,`data_arrivo`),
	KEY `ddt` (`data_ddt`,`numero_ddt`, `codice_fornitore`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`righe_arrivi` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`id_arrivi` varchar(36) NOT NULL DEFAULT '',
	`keycod` varchar(36) NOT NULL DEFAULT '',
	`codice_articolo` varchar(7) NOT NULL DEFAULT '',
	`codice_articolo_fornitore` varchar(15) NOT NULL DEFAULT '',
	`costo` float NOT NULL DEFAULT 0,
	`listino` float NOT NULL DEFAULT 0,
	`quantita` int NOT NULL DEFAULT 0,
	`quantita_evasa` int NOT NULL DEFAULT 0,
	`sconto_a` float NOT NULL DEFAULT 0,
	`sconto_b` float NOT NULL DEFAULT 0,
	`sconto_c` float NOT NULL DEFAULT 0,
	`sconto_d` float NOT NULL DEFAULT 0,
	`sconto_cassa` float NOT NULL DEFAULT 0,
	`sconto_commerciale` float NOT NULL DEFAULT 0,
	`sconto_extra` float NOT NULL DEFAULT 0,
	`sconto_importo` float NOT NULL DEFAULT 0,
	`sconto_merce` float NOT NULL DEFAULT 0,
	`spese_trasporto` float NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	KEY `arrivi` (`id_arrivi`),
	KEY `articolo` (`codice_articolo`,`codice_articolo_fornitore`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`trasferimenti_in` (
  `link` varchar(36) NOT NULL DEFAULT '',
  `negozio_partenza` varchar(4) NOT NULL DEFAULT '',
  `negozio_arrivo` varchar(4) NOT NULL DEFAULT '',
  `numero_ddt` varchar(13) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `fase` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `causale` varchar(28) NOT NULL DEFAULT '',
  `solo_giacenze` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`link`),
  KEY `negozio` (`negozio_partenza`, `negozio_arrivo`),
  KEY `ddt` (`numero_ddt`, `data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`righe_trasferimenti_in` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `link_trasferimento` varchar(36) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `ean` varchar(13) NOT NULL DEFAULT '',
  `quantita` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `link` (`link_trasferimento`),
  KEY `codici` (`codice`, `ean`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`trasferimenti_out` (
  `link` varchar(36) NOT NULL DEFAULT '',
  `negozio_partenza` varchar(4) NOT NULL DEFAULT '',
  `negozio_arrivo` varchar(4) NOT NULL DEFAULT '',
  `numero_ddt` varchar(13) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `fase` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `causale` varchar(28) NOT NULL DEFAULT '',
  `solo_giacenze` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`link`),
  KEY `negozio` (`negozio_partenza`, `negozio_arrivo`),
  KEY `ddt` (`numero_ddt`, `data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`righe_trasferimenti_out` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `link_trasferimento` varchar(36) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `ean` varchar(13) NOT NULL DEFAULT '',
  `quantita` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `link` (`link_trasferimento`),
  KEY `codici` (`codice`, `ean`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`diversi` (
  `link` varchar(36) NOT NULL DEFAULT '',
  `progressivo` varchar(36) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `numero_ddt` varchar(5) NOT NULL DEFAULT '',
  `definitivo` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`link`),
  KEY `progressivo` (`progressivo`),
  KEY `data` (`data`, `negozio`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`righe_diversi` (
  `progressivo` varchar(36) NOT NULL DEFAULT '',
  `link_diversi` varchar(36) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `ean` varchar(7) NOT NULL DEFAULT '',
  `quantita` float NOT NULL DEFAULT 0,
  `costo` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`progressivo`),
  KEY `link` (`link_diversi`),
  KEY `codici` (`codice`, `ean`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`giacenze_iniziali` (
  `codice` varchar(7) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `giacenza` float NOT NULL DEFAULT 0,
  `costo_medio` float NOT NULL DEFAULT 0,
  `anno_attivo` int NOT NULL DEFAULT 2015,
  PRIMARY KEY (`codice`,`negozio`,`anno_attivo`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`log_invio_dati` (
  `codice` varchar(4) NOT NULL DEFAULT '',
  `codice_interno` varchar(4) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `invio_gre` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `solo_giacenze` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`codice`,`codice_interno`,`data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`benefici` (
  `codice_campagna` varchar(5) NOT NULL DEFAULT '',
  `codice_promozione` varchar(9) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `descrizione` varchar(255) NOT NULL DEFAULT '',
  `id` varchar(36) NOT NULL DEFAULT '',
  `id_scontrino` varchar(36) NOT NULL DEFAULT '',
  `ora` varchar(10) NOT NULL DEFAULT '',
  `id_riga_vendita` varchar(36) NOT NULL DEFAULT '',
  `tipo` varchar(2) NOT NULL DEFAULT '',
  `valore` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `codici` (`codice_campagna`, `codice_promozione`),
  KEY `date` (`data`, `negozio`,tipo)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`venditori` (
  `matricola` varchar(6) NOT NULL DEFAULT '',
  `codice_buyer` varchar(5) NOT NULL DEFAULT '',
  `codice` varchar(4) NOT NULL DEFAULT '',
  `cognome` varchar(20) NOT NULL DEFAULT '',
  `nome` varchar(20) NOT NULL DEFAULT '',
  `data_nascita` date NOT NULL DEFAULT '0000-00-00',
  `data_assunzione` date NOT NULL DEFAULT '0000-00-00',
  `data_dimissioni` date NOT NULL DEFAULT '0000-00-00',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `contratto` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`matricola`),
  KEY `buyer` (`codice_buyer`),
  KEY `negozio` (`negozio`),
  KEY `date` (`data_assunzione`, `data_dimissioni`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`fornitore_articolo` (
	`codice_fornitore` varchar(10) NOT NULL DEFAULT '',
	`codice_articolo_fornitore` varchar(15) NOT NULL DEFAULT '',
	`codice_articolo` varchar(7) NOT NULL DEFAULT '',
	KEY (`codice_fornitore`,`codice_articolo_fornitore`,`codice_articolo`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`ordini` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `numero` varchar(10) NOT NULL DEFAULT '',
  `data_ordine` date NOT NULL DEFAULT '0000-00-00',
  `fornitore` varchar(10) NOT NULL DEFAULT '',
  `codice_buyer` varchar(10) NOT NULL DEFAULT '',
  `pagamento` varchar(8) NOT NULL DEFAULT '',
  `data_consegna` date NOT NULL DEFAULT '0000-00-00',
  `data_consegna_min` date NOT NULL DEFAULT '0000-00-00',
  `data_consegna_max` date NOT NULL DEFAULT '0000-00-00',
  `sospeso` tinyint(1) NOT NULL DEFAULT 0,
  `annullato` tinyint(1) NOT NULL DEFAULT 0,
  `stralciato` tinyint(1) NOT NULL DEFAULT 0,
  `spese_trasporto` float NOT NULL DEFAULT 0,
  `spese_trasporto_percentuali` float NOT NULL DEFAULT 0,
  `sconto_cassa_percentuale` float NOT NULL DEFAULT 0,
  `totale` float NOT NULL DEFAULT 0,
  `importo_BO` float NOT NULL DEFAULT 0,
  `pezzi_BO` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `principale` (`numero`, `data_ordine`,`fornitore`,`codice_buyer`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`ordini_sedi` (
	`id_ordini` varchar(36) NOT NULL DEFAULT '',
	`sede` varchar(4) NOT NULL DEFAULT '',
	PRIMARY KEY (`id_ordini`,`sede`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`ordini_righe` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`id_ordini` varchar(36) NOT NULL DEFAULT '',
	`id_suddivisione` int(11) NOT NULL DEFAULT 0, 
	`keycod` varchar(36) NOT NULL DEFAULT '',
	`codice_articolo` varchar(7) NOT NULL DEFAULT '',
	`codice_articolo_fornitore` varchar(15) NOT NULL DEFAULT '',
	`listino` float NOT NULL DEFAULT 0,
	`sconto_a` float NOT NULL DEFAULT 0,
	`sconto_b` float NOT NULL DEFAULT 0,
	`sconto_c` float NOT NULL DEFAULT 0,
	`sconto_d` float NOT NULL DEFAULT 0,
	`sconto_commerciale` float NOT NULL DEFAULT 0,
	`sconto_extra` float NOT NULL DEFAULT 0,
	`sconto_importo` float NOT NULL DEFAULT 0,
	`sconto_merce` float NOT NULL DEFAULT 0,
	`costo_finito` float NOT NULL DEFAULT 0,
	`quantita` int NOT NULL DEFAULT 0,
	`totale` float NOT NULL DEFAULT 0,
	`quantita_evasa` int NOT NULL DEFAULT 0,
	`sospeso` tinyint(1) NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	KEY `ordini` (`id_ordini`),
	KEY `articolo` (`codice_articolo`,`codice_articolo_fornitore`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`ordini_righe_quantita` (
	`id` int(11) NOT NULL DEFAULT 0,
	`id_righe` varchar(36) NOT NULL DEFAULT '',
	`sede` varchar(4) NOT NULL DEFAULT '',
	`quantita` int(11) NOT NULL DEFAULT 0,
	`sconto_merce` int(11) NOT NULL DEFAULT 0,
	`sospeso` tinyint(1) NOT NULL DEFAULT 0,
	KEY `righe` (`id_righe`),
	KEY `sede` (`sede`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`ordini_righe_quantita_ventilazione` (
	`id_quantita` varchar(36) NOT NULL DEFAULT '',
	`sede` varchar(4) NOT NULL DEFAULT '',
	`quantita` int(11) NOT NULL DEFAULT 0,
	PRIMARY KEY (`id_quantita`,`sede`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_sp`.`setup_report` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`descrizione` varchar(100) NOT NULL DEFAULT '',
	`tipo` varchar(3) NOT NULL DEFAULT '',
	`tipo_descrizione` varchar(40) NOT NULL DEFAULT '',
	`data_creazione` date NOT NULL DEFAULT '0000-00-00',
	`ora_creazione` varchar(8) NOT NULL DEFAULT '',
	`parametri` varchar(3000) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `db_sp`.`temp_stock`;

/*R&S
-----------------------------------------------------------------------------------------
*/
CREATE DATABASE IF NOT EXISTS `db_ru`;

CREATE TABLE IF NOT EXISTS `db_ru`.`logCaricamento` (
	`tsCreazione` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`tsModifica` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`sede` varchar(4) NOT NULL DEFAULT '',
	`data` date NOT NULL,
	`tipo` varchar(3) NOT NULL DEFAULT '',
	`descrizione` varchar(100) NOT NULL DEFAULT '',
	`vuoto` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`sede`,`data`,`tipo`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`magazzino` (
	`codice` varchar(7) NOT NULL DEFAULT '',
	`codice_mondo` varchar(20) NOT NULL DEFAULT '',
	`codice_settore` varchar(20) NOT NULL DEFAULT '',
	`codice_reparto` varchar(20) NOT NULL DEFAULT '',
	`codice_famiglia` varchar(20) NOT NULL DEFAULT '',
	`codice_sottofamiglia` varchar(20) NOT NULL DEFAULT '',
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`modello` varchar(255) NOT NULL DEFAULT '',
	`linea` varchar(255) NOT NULL DEFAULT '',
	`taglia` varchar(20) NOT NULL DEFAULT '',
	`colore` varchar(20) NOT NULL DEFAULT '',
	`stagionalita` int(11) NOT NULL DEFAULT 0,
	`costo_medio` float NOT NULL DEFAULT 0,
	`costo_ultimo` float NOT NULL DEFAULT 0,
	`listino_1` float NOT NULL DEFAULT 0,
	`listino_2` float NOT NULL DEFAULT 0,
	`listino_3` float NOT NULL DEFAULT 0,
	`listino_promo` float NOT NULL DEFAULT 0,
	`aliquota_iva` float NOT NULL DEFAULT 0,
	`tipo_iva` int(11) NOT NULL DEFAULT 0,
	`eliminato` tinyint(1) NOT NULL,
	`obsoleto` tinyint(1) NOT NULL,
	`griglia` varchar(30) NOT NULL DEFAULT '',
	`data_creazione` date NOT NULL DEFAULT '0000-00-00',
	`invio_gre` tinyint(1) NOT NULL,
	`giacenza_bloccata` tinyint(1) NOT NULL,
	`codice_padre` varchar(7) NOT NULL DEFAULT '',
	`contoVendita` tinyint(4) NOT NULL DEFAULT '0',
	PRIMARY KEY (`codice`),
	KEY `codice_mondo` (`codice_mondo`,`codice_settore`,`codice_reparto`,`codice_famiglia`,`codice_sottofamiglia`),
	KEY `descrizione` (`descrizione`),
	KEY `linea` (`linea`),
	KEY `eliminato` (`eliminato`),
	KEY `giacenza_bloccata` (`giacenza_bloccata`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`marche` (
	`linea` varchar(40) NOT NULL DEFAULT '',
	`marca` varchar(40) NOT NULL DEFAULT '',
	`codice_compratore` varchar(5) NOT NULL DEFAULT '',
	`invio_gre` tinyint(1) NOT NULL,
	`copre` tinyint(1) NOT NULL,
	PRIMARY KEY (`linea`),
	KEY `marca` (`marca`),
	KEY `codice_compratore` (`codice_compratore`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`mondi` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`settori` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`codice_mondo` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`reparti` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`codice_settore` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`famiglie` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`codice_reparto` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`sottofamiglie` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`codice_famiglia` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice_famiglia`,`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`ean` (
	`codice` varchar(7) NOT NULL DEFAULT '',
	`ean` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`ean`),
	KEY `codice` (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`righe_vendita` (
  `progressivo` varchar(36) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `ora` varchar(8) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `ean` varchar(13) NOT NULL DEFAULT '',
  `reparto` varchar(20) NOT NULL DEFAULT '',
  `famiglia` varchar(20) NOT NULL DEFAULT '',
  `sottofamiglia` varchar(20) NOT NULL DEFAULT '',
  `riga_non_fiscale` tinyint(1) NOT NULL,
  `riparazione` tinyint(1) NOT NULL,
  `numero_riparazione` varchar(13) NOT NULL DEFAULT '',
  `prezzo_unitario` float NOT NULL DEFAULT 0,
  `quantita` float NOT NULL DEFAULT 0,
  `importo_totale` float NOT NULL DEFAULT 0,
  `margine` float NOT NULL DEFAULT 0,
  `aliquota_iva` float NOT NULL DEFAULT 0,
  `tipo_iva` int(11) NOT NULL DEFAULT 0,
  `descrizione` varchar(255) NOT NULL DEFAULT '',
  `linea` varchar(40) NOT NULL DEFAULT '',
  `matricola_rc` varchar(10) NOT NULL DEFAULT '',
  `codice_operatore` varchar(4) NOT NULL DEFAULT '',
  `codice_venditore` varchar(4) NOT NULL DEFAULT '',
  `id_scontrino` varchar(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`progressivo`),
  KEY `data` (`data`,`negozio`,`codice`),
  KEY `codice` (`codice`),
  KEY `ean` (`ean`),
  KEY `id_scontrino` (`id_scontrino`),
  KEY `progressivo` (`progressivo`,`margine`),
  KEY `linea` (`linea`),
  KEY `codice_venditore` (`codice_venditore`),
  KEY `data_2` (`data`,`negozio`),
  KEY `codice_2` (`codice`,`negozio`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`scontrini` (
  `id_scontrino` varchar(32) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL,
  `data` date NOT NULL,
  `ora` varchar(8) NOT NULL DEFAULT '',
  `numero` int(11) NOT NULL,
  `numero_upb` int(11) NOT NULL,
  `scontrino_non_fiscale` tinyint(1) NOT NULL,
  `carta` varchar(13) NOT NULL DEFAULT '',
  `totale` float NOT NULL DEFAULT 0,
  `buoni` float NOT NULL DEFAULT 0,
  `ip` varchar(15) NOT NULL DEFAULT '',
  PRIMARY KEY (`id_scontrino`),
  KEY `negozio` (`negozio`,`data`),
  KEY `numero` (`numero`),
  KEY `numero_upb` (`numero_upb`),
  KEY `scontrino_non_fiscale` (`scontrino_non_fiscale`),
  KEY `carta` (`carta`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`margini` (
  `progressivo` varchar(36) NOT NULL DEFAULT '',
  `margine` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`progressivo`),
  KEY `progressivo` (`progressivo`,`margine`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`. `giacenze` (
  `codice` varchar(7) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `giacenza` float NOT NULL DEFAULT 0,
  `data` date NOT NULL,
  PRIMARY KEY (`codice`,`negozio`,`data`),
  KEY `data` (`data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`contributi` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`data` date NOT NULL,
	`competenza` int(11) NOT NULL,
	`marca` varchar(40) NOT NULL DEFAULT '',
	`livello_margine` varchar(2) NOT NULL DEFAULT '',
	`descrizione_contabile` varchar(80) NOT NULL DEFAULT '',
	`importo` float NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	KEY `marca` (`marca`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`arrivi` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`numero` varchar(25) NOT NULL DEFAULT '',
	`negozio` varchar(4) NOT NULL DEFAULT '',
	`data_arrivo` date NOT NULL DEFAULT '0000-00-00',
	`data_ddt` date NOT NULL DEFAULT '0000-00-00',
	`numero_ddt` varchar(20) NOT NULL DEFAULT '',
	`codice_fornitore` varchar(10) NOT NULL DEFAULT '',
	`bozza` tinyint(1) NOT NULL DEFAULT 0,
	`materiale_consumo` tinyint(1) NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	KEY `arrivo` (`negozio`,`data_arrivo`),
	KEY `ddt` (`data_ddt`,`numero_ddt`, `codice_fornitore`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`righe_arrivi` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`id_arrivi` varchar(36) NOT NULL DEFAULT '',
	`keycod` varchar(36) NOT NULL DEFAULT '',
	`codice_articolo` varchar(7) NOT NULL DEFAULT '',
	`codice_articolo_fornitore` varchar(15) NOT NULL DEFAULT '',
	`costo` float NOT NULL DEFAULT 0,
	`listino` float NOT NULL DEFAULT 0,
	`quantita` int NOT NULL DEFAULT 0,
	`quantita_evasa` int NOT NULL DEFAULT 0,
	`sconto_a` float NOT NULL DEFAULT 0,
	`sconto_b` float NOT NULL DEFAULT 0,
	`sconto_c` float NOT NULL DEFAULT 0,
	`sconto_d` float NOT NULL DEFAULT 0,
	`sconto_cassa` float NOT NULL DEFAULT 0,
	`sconto_commerciale` float NOT NULL DEFAULT 0,
	`sconto_extra` float NOT NULL DEFAULT 0,
	`sconto_importo` float NOT NULL DEFAULT 0,
	`sconto_merce` float NOT NULL DEFAULT 0,
	`spese_trasporto` float NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	KEY `arrivi` (`id_arrivi`),
	KEY `articolo` (`codice_articolo`,`codice_articolo_fornitore`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`trasferimenti_in` (
  `link` varchar(36) NOT NULL DEFAULT '',
  `negozio_partenza` varchar(4) NOT NULL DEFAULT '',
  `negozio_arrivo` varchar(4) NOT NULL DEFAULT '',
  `numero_ddt` varchar(13) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `fase` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `causale` varchar(28) NOT NULL DEFAULT '',
  `solo_giacenze` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`link`),
  KEY `negozio` (`negozio_partenza`, `negozio_arrivo`),
  KEY `ddt` (`numero_ddt`, `data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`righe_trasferimenti_in` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `link_trasferimento` varchar(36) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `ean` varchar(13) NOT NULL DEFAULT '',
  `quantita` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `link` (`link_trasferimento`),
  KEY `codici` (`codice`, `ean`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`trasferimenti_out` (
  `link` varchar(36) NOT NULL DEFAULT '',
  `negozio_partenza` varchar(4) NOT NULL DEFAULT '',
  `negozio_arrivo` varchar(4) NOT NULL DEFAULT '',
  `numero_ddt` varchar(13) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `fase` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `causale` varchar(28) NOT NULL DEFAULT '',
  `solo_giacenze` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`link`),
  KEY `negozio` (`negozio_partenza`, `negozio_arrivo`),
  KEY `ddt` (`numero_ddt`, `data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`righe_trasferimenti_out` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `link_trasferimento` varchar(36) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `ean` varchar(13) NOT NULL DEFAULT '',
  `quantita` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `link` (`link_trasferimento`),
  KEY `codici` (`codice`, `ean`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`diversi` (
  `link` varchar(36) NOT NULL DEFAULT '',
  `progressivo` varchar(36) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `numero_ddt` varchar(5) NOT NULL DEFAULT '',
  `definitivo` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`link`),
  KEY `progressivo` (`progressivo`),
  KEY `data` (`data`, `negozio`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`righe_diversi` (
  `progressivo` varchar(36) NOT NULL DEFAULT '',
  `link_diversi` varchar(36) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `ean` varchar(7) NOT NULL DEFAULT '',
  `quantita` float NOT NULL DEFAULT 0,
  `costo` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`progressivo`),
  KEY `link` (`link_diversi`),
  KEY `codici` (`codice`, `ean`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`giacenze_iniziali` (
  `codice` varchar(7) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `giacenza` float NOT NULL DEFAULT 0,
  `costo_medio` float NOT NULL DEFAULT 0,
  `anno_attivo` int NOT NULL DEFAULT 2015,
  PRIMARY KEY (`codice`,`negozio`,`anno_attivo`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`log_invio_dati` (
  `codice` varchar(4) NOT NULL DEFAULT '',
  `codice_interno` varchar(4) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `invio_gre` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `solo_giacenze` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`codice`,`codice_interno`,`data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`benefici` (
  `codice_campagna` varchar(5) NOT NULL DEFAULT '',
  `codice_promozione` varchar(9) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `descrizione` varchar(255) NOT NULL DEFAULT '',
  `id` varchar(36) NOT NULL DEFAULT '',
  `id_scontrino` varchar(36) NOT NULL DEFAULT '',
  `ora` varchar(10) NOT NULL DEFAULT '',
  `id_riga_vendita` varchar(36) NOT NULL DEFAULT '',
  `tipo` varchar(2) NOT NULL DEFAULT '',
  `valore` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `codici` (`codice_campagna`, `codice_promozione`),
  KEY `date` (`data`, `negozio`,tipo)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`venditori` (
  `matricola` varchar(6) NOT NULL DEFAULT '',
  `codice_buyer` varchar(5) NOT NULL DEFAULT '',
  `codice` varchar(4) NOT NULL DEFAULT '',
  `cognome` varchar(20) NOT NULL DEFAULT '',
  `nome` varchar(20) NOT NULL DEFAULT '',
  `data_nascita` date NOT NULL DEFAULT '0000-00-00',
  `data_assunzione` date NOT NULL DEFAULT '0000-00-00',
  `data_dimissioni` date NOT NULL DEFAULT '0000-00-00',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `contratto` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`matricola`),
  KEY `buyer` (`codice_buyer`),
  KEY `negozio` (`negozio`),
  KEY `date` (`data_assunzione`, `data_dimissioni`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`fornitore_articolo` (
	`codice_fornitore` varchar(10) NOT NULL DEFAULT '',
	`codice_articolo_fornitore` varchar(15) NOT NULL DEFAULT '',
	`codice_articolo` varchar(7) NOT NULL DEFAULT '',
	KEY (`codice_fornitore`,`codice_articolo_fornitore`,`codice_articolo`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`ordini` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `numero` varchar(10) NOT NULL DEFAULT '',
  `data_ordine` date NOT NULL DEFAULT '0000-00-00',
  `fornitore` varchar(10) NOT NULL DEFAULT '',
  `codice_buyer` varchar(10) NOT NULL DEFAULT '',
  `pagamento` varchar(8) NOT NULL DEFAULT '',
  `data_consegna` date NOT NULL DEFAULT '0000-00-00',
  `data_consegna_min` date NOT NULL DEFAULT '0000-00-00',
  `data_consegna_max` date NOT NULL DEFAULT '0000-00-00',
  `sospeso` tinyint(1) NOT NULL DEFAULT 0,
  `annullato` tinyint(1) NOT NULL DEFAULT 0,
  `stralciato` tinyint(1) NOT NULL DEFAULT 0,
  `spese_trasporto` float NOT NULL DEFAULT 0,
  `spese_trasporto_percentuali` float NOT NULL DEFAULT 0,
  `sconto_cassa_percentuale` float NOT NULL DEFAULT 0,
  `totale` float NOT NULL DEFAULT 0,
  `importo_BO` float NOT NULL DEFAULT 0,
  `pezzi_BO` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `principale` (`numero`, `data_ordine`,`fornitore`,`codice_buyer`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`ordini_sedi` (
	`id_ordini` varchar(36) NOT NULL DEFAULT '',
	`sede` varchar(4) NOT NULL DEFAULT '',
	PRIMARY KEY (`id_ordini`,`sede`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`ordini_righe` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`id_ordini` varchar(36) NOT NULL DEFAULT '',
	`id_suddivisione` int(11) NOT NULL DEFAULT 0, 
	`keycod` varchar(36) NOT NULL DEFAULT '',
	`codice_articolo` varchar(7) NOT NULL DEFAULT '',
	`codice_articolo_fornitore` varchar(15) NOT NULL DEFAULT '',
	`listino` float NOT NULL DEFAULT 0,
	`sconto_a` float NOT NULL DEFAULT 0,
	`sconto_b` float NOT NULL DEFAULT 0,
	`sconto_c` float NOT NULL DEFAULT 0,
	`sconto_d` float NOT NULL DEFAULT 0,
	`sconto_commerciale` float NOT NULL DEFAULT 0,
	`sconto_extra` float NOT NULL DEFAULT 0,
	`sconto_importo` float NOT NULL DEFAULT 0,
	`sconto_merce` float NOT NULL DEFAULT 0,
	`costo_finito` float NOT NULL DEFAULT 0,
	`quantita` int NOT NULL DEFAULT 0,
	`totale` float NOT NULL DEFAULT 0,
	`quantita_evasa` int NOT NULL DEFAULT 0,
	`sospeso` tinyint(1) NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	KEY `ordini` (`id_ordini`),
	KEY `articolo` (`codice_articolo`,`codice_articolo_fornitore`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`ordini_righe_quantita` (
	`id` int(11) NOT NULL DEFAULT 0,
	`id_righe` varchar(36) NOT NULL DEFAULT '',
	`sede` varchar(4) NOT NULL DEFAULT '',
	`quantita` int(11) NOT NULL DEFAULT 0,
	`sconto_merce` int(11) NOT NULL DEFAULT 0,
	`sospeso` tinyint(1) NOT NULL DEFAULT 0,
	KEY `righe` (`id_righe`),
	KEY `sede` (`sede`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`ordini_righe_quantita_ventilazione` (
	`id_quantita` varchar(36) NOT NULL DEFAULT '',
	`sede` varchar(4) NOT NULL DEFAULT '',
	`quantita` int(11) NOT NULL DEFAULT 0,
	PRIMARY KEY (`id_quantita`,`sede`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_ru`.`setup_report` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`descrizione` varchar(100) NOT NULL DEFAULT '',
	`tipo` varchar(3) NOT NULL DEFAULT '',
	`tipo_descrizione` varchar(40) NOT NULL DEFAULT '',
	`data_creazione` date NOT NULL DEFAULT '0000-00-00',
	`ora_creazione` varchar(8) NOT NULL DEFAULT '',
	`parametri` varchar(3000) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `db_ru`.`temp_stock`;

#ECOBRICO
#-----------------------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS `db_eb`;

CREATE TABLE IF NOT EXISTS `db_eb`.`logCaricamento` (
	`tsCreazione` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
	`tsModifica` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
	`sede` varchar(4) NOT NULL DEFAULT '',
	`data` date NOT NULL,
	`tipo` varchar(3) NOT NULL DEFAULT '',
	`descrizione` varchar(100) NOT NULL DEFAULT '',
	`vuoto` tinyint(4) NOT NULL DEFAULT '0',
  PRIMARY KEY (`sede`,`data`,`tipo`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`magazzino` (
	`codice` varchar(7) NOT NULL DEFAULT '',
	`codice_mondo` varchar(20) NOT NULL DEFAULT '',
	`codice_settore` varchar(20) NOT NULL DEFAULT '',
	`codice_reparto` varchar(20) NOT NULL DEFAULT '',
	`codice_famiglia` varchar(20) NOT NULL DEFAULT '',
	`codice_sottofamiglia` varchar(20) NOT NULL DEFAULT '',
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`modello` varchar(255) NOT NULL DEFAULT '',
	`linea` varchar(255) NOT NULL DEFAULT '',
	`taglia` varchar(20) NOT NULL DEFAULT '',
	`colore` varchar(20) NOT NULL DEFAULT '',
	`stagionalita` int(11) NOT NULL DEFAULT 0,
	`costo_medio` float NOT NULL DEFAULT 0,
	`costo_ultimo` float NOT NULL DEFAULT 0,
	`listino_1` float NOT NULL DEFAULT 0,
	`listino_2` float NOT NULL DEFAULT 0,
	`listino_3` float NOT NULL DEFAULT 0,
	`listino_promo` float NOT NULL DEFAULT 0,
	`aliquota_iva` float NOT NULL DEFAULT 0,
	`tipo_iva` int(11) NOT NULL DEFAULT 0,
	`eliminato` tinyint(1) NOT NULL,
	`obsoleto` tinyint(1) NOT NULL,
	`griglia` varchar(30) NOT NULL DEFAULT '',
	`data_creazione` date NOT NULL DEFAULT '0000-00-00',
	`invio_gre` tinyint(1) NOT NULL,
	`giacenza_bloccata` tinyint(1) NOT NULL,
	`codice_padre` varchar(7) NOT NULL DEFAULT '',
	`contoVendita` tinyint(4) NOT NULL DEFAULT '0',
	PRIMARY KEY (`codice`),
	KEY `codice_mondo` (`codice_mondo`,`codice_settore`,`codice_reparto`,`codice_famiglia`,`codice_sottofamiglia`),
	KEY `descrizione` (`descrizione`),
	KEY `linea` (`linea`),
	KEY `eliminato` (`eliminato`),
	KEY `giacenza_bloccata` (`giacenza_bloccata`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`marche` (
	`linea` varchar(40) NOT NULL DEFAULT '',
	`marca` varchar(40) NOT NULL DEFAULT '',
	`codice_compratore` varchar(5) NOT NULL DEFAULT '',
	`invio_gre` tinyint(1) NOT NULL,
	`copre` tinyint(1) NOT NULL,
	PRIMARY KEY (`linea`),
	KEY `marca` (`marca`),
	KEY `codice_compratore` (`codice_compratore`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`mondi` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`settori` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`codice_mondo` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`reparti` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`codice_settore` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`famiglie` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`codice_reparto` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`sottofamiglie` (
	`codice` varchar(20) NOT NULL DEFAULT '',
	`ordinamento` int(11) NOT NULL DEFAULT 0,
	`descrizione` varchar(255) NOT NULL DEFAULT '',
	`codice_famiglia` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`codice_famiglia`,`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`ean` (
	`codice` varchar(7) NOT NULL DEFAULT '',
	`ean` varchar(20) NOT NULL DEFAULT '',
	PRIMARY KEY (`ean`),
	KEY `codice` (`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`righe_vendita` (
  `progressivo` varchar(36) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `ora` varchar(8) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `ean` varchar(13) NOT NULL DEFAULT '',
  `reparto` varchar(20) NOT NULL DEFAULT '',
  `famiglia` varchar(20) NOT NULL DEFAULT '',
  `sottofamiglia` varchar(20) NOT NULL DEFAULT '',
  `riga_non_fiscale` tinyint(1) NOT NULL,
  `riparazione` tinyint(1) NOT NULL,
  `numero_riparazione` varchar(13) NOT NULL DEFAULT '',
  `prezzo_unitario` float NOT NULL DEFAULT 0,
  `quantita` float NOT NULL DEFAULT 0,
  `importo_totale` float NOT NULL DEFAULT 0,
  `margine` float NOT NULL DEFAULT 0,
  `aliquota_iva` float NOT NULL DEFAULT 0,
  `tipo_iva` int(11) NOT NULL DEFAULT 0,
  `descrizione` varchar(255) NOT NULL DEFAULT '',
  `linea` varchar(40) NOT NULL DEFAULT '',
  `matricola_rc` varchar(10) NOT NULL DEFAULT '',
  `codice_operatore` varchar(4) NOT NULL DEFAULT '',
  `codice_venditore` varchar(4) NOT NULL DEFAULT '',
  `id_scontrino` varchar(32) NOT NULL DEFAULT '',
  PRIMARY KEY (`progressivo`),
  KEY `data` (`data`,`negozio`,`codice`),
  KEY `codice` (`codice`),
  KEY `ean` (`ean`),
  KEY `id_scontrino` (`id_scontrino`),
  KEY `progressivo` (`progressivo`,`margine`),
  KEY `linea` (`linea`),
  KEY `codice_venditore` (`codice_venditore`),
  KEY `data_2` (`data`,`negozio`),
  KEY `codice_2` (`codice`,`negozio`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`scontrini` (
  `id_scontrino` varchar(32) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL,
  `data` date NOT NULL,
  `ora` varchar(8) NOT NULL DEFAULT '',
  `numero` int(11) NOT NULL,
  `numero_upb` int(11) NOT NULL,
  `scontrino_non_fiscale` tinyint(1) NOT NULL,
  `carta` varchar(13) NOT NULL DEFAULT '',
  `totale` float NOT NULL DEFAULT 0,
  `buoni` float NOT NULL DEFAULT 0,
  `ip` varchar(15) NOT NULL DEFAULT '',
  PRIMARY KEY (`id_scontrino`),
  KEY `negozio` (`negozio`,`data`),
  KEY `numero` (`numero`),
  KEY `numero_upb` (`numero_upb`),
  KEY `scontrino_non_fiscale` (`scontrino_non_fiscale`),
  KEY `carta` (`carta`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`margini` (
  `progressivo` varchar(36) NOT NULL DEFAULT '',
  `margine` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`progressivo`),
  KEY `progressivo` (`progressivo`,`margine`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`. `giacenze` (
  `codice` varchar(7) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `giacenza` float NOT NULL DEFAULT 0,
  `data` date NOT NULL,
  PRIMARY KEY (`codice`,`negozio`,`data`),
  KEY `data` (`data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`contributi` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`data` date NOT NULL,
	`competenza` int(11) NOT NULL,
	`marca` varchar(40) NOT NULL DEFAULT '',
	`livello_margine` varchar(2) NOT NULL DEFAULT '',
	`descrizione_contabile` varchar(80) NOT NULL DEFAULT '',
	`importo` float NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	KEY `marca` (`marca`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`arrivi` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`numero` varchar(25) NOT NULL DEFAULT '',
	`negozio` varchar(4) NOT NULL DEFAULT '',
	`data_arrivo` date NOT NULL DEFAULT '0000-00-00',
	`data_ddt` date NOT NULL DEFAULT '0000-00-00',
	`numero_ddt` varchar(20) NOT NULL DEFAULT '',
	`codice_fornitore` varchar(10) NOT NULL DEFAULT '',
	`bozza` tinyint(1) NOT NULL DEFAULT 0,
	`materiale_consumo` tinyint(1) NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	KEY `arrivo` (`negozio`,`data_arrivo`),
	KEY `ddt` (`data_ddt`,`numero_ddt`, `codice_fornitore`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`righe_arrivi` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`id_arrivi` varchar(36) NOT NULL DEFAULT '',
	`keycod` varchar(36) NOT NULL DEFAULT '',
	`codice_articolo` varchar(7) NOT NULL DEFAULT '',
	`codice_articolo_fornitore` varchar(15) NOT NULL DEFAULT '',
	`costo` float NOT NULL DEFAULT 0,
	`listino` float NOT NULL DEFAULT 0,
	`quantita` int NOT NULL DEFAULT 0,
	`quantita_evasa` int NOT NULL DEFAULT 0,
	`sconto_a` float NOT NULL DEFAULT 0,
	`sconto_b` float NOT NULL DEFAULT 0,
	`sconto_c` float NOT NULL DEFAULT 0,
	`sconto_d` float NOT NULL DEFAULT 0,
	`sconto_cassa` float NOT NULL DEFAULT 0,
	`sconto_commerciale` float NOT NULL DEFAULT 0,
	`sconto_extra` float NOT NULL DEFAULT 0,
	`sconto_importo` float NOT NULL DEFAULT 0,
	`sconto_merce` float NOT NULL DEFAULT 0,
	`spese_trasporto` float NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	KEY `arrivi` (`id_arrivi`),
	KEY `articolo` (`codice_articolo`,`codice_articolo_fornitore`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`trasferimenti_in` (
  `link` varchar(36) NOT NULL DEFAULT '',
  `negozio_partenza` varchar(4) NOT NULL DEFAULT '',
  `negozio_arrivo` varchar(4) NOT NULL DEFAULT '',
  `numero_ddt` varchar(13) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `fase` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `causale` varchar(28) NOT NULL DEFAULT '',
  `solo_giacenze` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`link`),
  KEY `negozio` (`negozio_partenza`, `negozio_arrivo`),
  KEY `ddt` (`numero_ddt`, `data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`righe_trasferimenti_in` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `link_trasferimento` varchar(36) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `ean` varchar(13) NOT NULL DEFAULT '',
  `quantita` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `link` (`link_trasferimento`),
  KEY `codici` (`codice`, `ean`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`trasferimenti_out` (
  `link` varchar(36) NOT NULL DEFAULT '',
  `negozio_partenza` varchar(4) NOT NULL DEFAULT '',
  `negozio_arrivo` varchar(4) NOT NULL DEFAULT '',
  `numero_ddt` varchar(13) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `fase` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `causale` varchar(28) NOT NULL DEFAULT '',
  `solo_giacenze` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`link`),
  KEY `negozio` (`negozio_partenza`, `negozio_arrivo`),
  KEY `ddt` (`numero_ddt`, `data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`righe_trasferimenti_out` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `link_trasferimento` varchar(36) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `ean` varchar(13) NOT NULL DEFAULT '',
  `quantita` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `link` (`link_trasferimento`),
  KEY `codici` (`codice`, `ean`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`diversi` (
  `link` varchar(36) NOT NULL DEFAULT '',
  `progressivo` varchar(36) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `numero_ddt` varchar(5) NOT NULL DEFAULT '',
  `definitivo` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`link`),
  KEY `progressivo` (`progressivo`),
  KEY `data` (`data`, `negozio`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`righe_diversi` (
  `progressivo` varchar(36) NOT NULL DEFAULT '',
  `link_diversi` varchar(36) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `ean` varchar(7) NOT NULL DEFAULT '',
  `quantita` float NOT NULL DEFAULT 0,
  `costo` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`progressivo`),
  KEY `link` (`link_diversi`),
  KEY `codici` (`codice`, `ean`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`giacenze_iniziali` (
  `codice` varchar(7) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `giacenza` float NOT NULL DEFAULT 0,
  `costo_medio` float NOT NULL DEFAULT 0,
  `anno_attivo` int NOT NULL DEFAULT 2015,
  PRIMARY KEY (`codice`,`negozio`,`anno_attivo`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`log_invio_dati` (
  `codice` varchar(4) NOT NULL DEFAULT '',
  `codice_interno` varchar(4) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `invio_gre` tinyint(1) unsigned NOT NULL DEFAULT 0,
  `solo_giacenze` tinyint(1) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`codice`,`codice_interno`,`data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`benefici` (
  `codice_campagna` varchar(5) NOT NULL DEFAULT '',
  `codice_promozione` varchar(9) NOT NULL DEFAULT '',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `data` date NOT NULL,
  `descrizione` varchar(255) NOT NULL DEFAULT '',
  `id` varchar(36) NOT NULL DEFAULT '',
  `id_scontrino` varchar(36) NOT NULL DEFAULT '',
  `ora` varchar(10) NOT NULL DEFAULT '',
  `id_riga_vendita` varchar(36) NOT NULL DEFAULT '',
  `tipo` varchar(2) NOT NULL DEFAULT '',
  `valore` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `codici` (`codice_campagna`, `codice_promozione`),
  KEY `date` (`data`, `negozio`,tipo)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`venditori` (
  `matricola` varchar(6) NOT NULL DEFAULT '',
  `codice_buyer` varchar(5) NOT NULL DEFAULT '',
  `codice` varchar(4) NOT NULL DEFAULT '',
  `cognome` varchar(20) NOT NULL DEFAULT '',
  `nome` varchar(20) NOT NULL DEFAULT '',
  `data_nascita` date NOT NULL DEFAULT '0000-00-00',
  `data_assunzione` date NOT NULL DEFAULT '0000-00-00',
  `data_dimissioni` date NOT NULL DEFAULT '0000-00-00',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `contratto` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`matricola`),
  KEY `buyer` (`codice_buyer`),
  KEY `negozio` (`negozio`),
  KEY `date` (`data_assunzione`, `data_dimissioni`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`fornitore_articolo` (
	`codice_fornitore` varchar(10) NOT NULL DEFAULT '',
	`codice_articolo_fornitore` varchar(15) NOT NULL DEFAULT '',
	`codice_articolo` varchar(7) NOT NULL DEFAULT '',
	KEY (`codice_fornitore`,`codice_articolo_fornitore`,`codice_articolo`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`ordini` (
  `id` varchar(36) NOT NULL DEFAULT '',
  `numero` varchar(10) NOT NULL DEFAULT '',
  `data_ordine` date NOT NULL DEFAULT '0000-00-00',
  `fornitore` varchar(10) NOT NULL DEFAULT '',
  `codice_buyer` varchar(10) NOT NULL DEFAULT '',
  `pagamento` varchar(8) NOT NULL DEFAULT '',
  `data_consegna` date NOT NULL DEFAULT '0000-00-00',
  `data_consegna_min` date NOT NULL DEFAULT '0000-00-00',
  `data_consegna_max` date NOT NULL DEFAULT '0000-00-00',
  `sospeso` tinyint(1) NOT NULL DEFAULT 0,
  `annullato` tinyint(1) NOT NULL DEFAULT 0,
  `stralciato` tinyint(1) NOT NULL DEFAULT 0,
  `spese_trasporto` float NOT NULL DEFAULT 0,
  `spese_trasporto_percentuali` float NOT NULL DEFAULT 0,
  `sconto_cassa_percentuale` float NOT NULL DEFAULT 0,
  `totale` float NOT NULL DEFAULT 0,
  `importo_BO` float NOT NULL DEFAULT 0,
  `pezzi_BO` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `principale` (`numero`, `data_ordine`,`fornitore`,`codice_buyer`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`ordini_sedi` (
	`id_ordini` varchar(36) NOT NULL DEFAULT '',
	`sede` varchar(4) NOT NULL DEFAULT '',
	PRIMARY KEY (`id_ordini`,`sede`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`ordini_righe` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`id_ordini` varchar(36) NOT NULL DEFAULT '',
	`id_suddivisione` int(11) NOT NULL DEFAULT 0, 
	`keycod` varchar(36) NOT NULL DEFAULT '',
	`codice_articolo` varchar(7) NOT NULL DEFAULT '',
	`codice_articolo_fornitore` varchar(15) NOT NULL DEFAULT '',
	`listino` float NOT NULL DEFAULT 0,
	`sconto_a` float NOT NULL DEFAULT 0,
	`sconto_b` float NOT NULL DEFAULT 0,
	`sconto_c` float NOT NULL DEFAULT 0,
	`sconto_d` float NOT NULL DEFAULT 0,
	`sconto_commerciale` float NOT NULL DEFAULT 0,
	`sconto_extra` float NOT NULL DEFAULT 0,
	`sconto_importo` float NOT NULL DEFAULT 0,
	`sconto_merce` float NOT NULL DEFAULT 0,
	`costo_finito` float NOT NULL DEFAULT 0,
	`quantita` int NOT NULL DEFAULT 0,
	`totale` float NOT NULL DEFAULT 0,
	`quantita_evasa` int NOT NULL DEFAULT 0,
	`sospeso` tinyint(1) NOT NULL DEFAULT 0,
	PRIMARY KEY (`id`),
	KEY `ordini` (`id_ordini`),
	KEY `articolo` (`codice_articolo`,`codice_articolo_fornitore`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`ordini_righe_quantita` (
	`id` int(11) NOT NULL DEFAULT 0,
	`id_righe` varchar(36) NOT NULL DEFAULT '',
	`sede` varchar(4) NOT NULL DEFAULT '',
	`quantita` int(11) NOT NULL DEFAULT 0,
	`sconto_merce` int(11) NOT NULL DEFAULT 0,
	`sospeso` tinyint(1) NOT NULL DEFAULT 0,
	KEY `righe` (`id_righe`),
	KEY `sede` (`sede`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`ordini_righe_quantita_ventilazione` (
	`id_quantita` varchar(36) NOT NULL DEFAULT '',
	`sede` varchar(4) NOT NULL DEFAULT '',
	`quantita` int(11) NOT NULL DEFAULT 0,
	PRIMARY KEY (`id_quantita`,`sede`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

CREATE TABLE IF NOT EXISTS `db_eb`.`setup_report` (
	`id` varchar(36) NOT NULL DEFAULT '',
	`descrizione` varchar(100) NOT NULL DEFAULT '',
	`tipo` varchar(3) NOT NULL DEFAULT '',
	`tipo_descrizione` varchar(40) NOT NULL DEFAULT '',
	`data_creazione` date NOT NULL DEFAULT '0000-00-00',
	`ora_creazione` varchar(8) NOT NULL DEFAULT '',
	`parametri` varchar(3000) NOT NULL DEFAULT ''
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

DROP TABLE IF EXISTS `db_eb`.`temp_stock`;

