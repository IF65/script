delete table `db_sm`.`sm_fatture_ca_testate`

CREATE TABLE IF NOT EXISTS `db_sm`.`sm_fatture_ca_testate` (
  `numero` varchar(20) NOT NULL DEFAULT '',
  `data` date NOT NULL DEFAULT '0000-00-00',
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `descrizione` varchar(100) NOT NULL DEFAULT '',
  `codice_fornitore` varchar(10) NOT NULL DEFAULT '',
  `descrizione_fornitore` varchar(255) NOT NULL DEFAULT '',
  `numero_ddt` varchar(40) NOT NULL DEFAULT '',
  `data_bolla_fornitore` date NOT NULL DEFAULT '0000-00-00',
  `referenze_ddt` float NOT NULL DEFAULT '0',
  `pezzi_ddt` float NOT NULL DEFAULT '0',
  `totale_ddt`float NOT NULL DEFAULT '0',
  `totale_fattura` tinyint NOT NULL DEFAULT '0'
  PRIMARY KEY (`numero`),
  KEY `data` (`data`),
  KEY `ddt` (`negozio`,`numero_ddt`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;



-- AS SELECT
--    `f`.`numero` AS `numero`,
--    `f`.`data` AS `data`,
--    `n`.`codice_interno` AS `negozio`,
--    `n`.`negozio_descrizione` AS `descrizione`,
--    `fo`.`sm` AS `codice_fornitore`,(case when (`f`.`descrizione_fornitore` <> '') then `f`.`descrizione_fornitore` else 'COPRE' end) AS `descrizione_fornitore`,(case when (`f`.`numero_bolla_fornitore` <> '') then trim(leading '0'
-- FROM `f`.`numero_bolla_fornitore`) else `f`.`numero_consegna` end) AS `numero_ddt`,`f`.`data_bolla_fornitore` AS `data_bolla_fornitore`,count(0) AS `referenze ddt`,sum(`f`.`quantita`) AS `pezzi ddt`,sum(round((`f`.`quantita` * `f`.`prezzo_lordo`),2)) AS `totale ddt`,(select sum(round((`f1`.`quantita` * `f1`.`prezzo_lordo`),2)) from `db_sm`.`fatture_ca` `f1` where ((`f`.`numero` = `f1`.`numero`) and (`f`.`data` = `f1`.`data`))) AS `totale fatt.` from ((`db_sm`.`fatture_ca` `f` left join `archivi`.`negozi` `n` on((`n`.`codice_ca` = `f`.`codice_punto_consegna`))) left join `contabilita`.`sm_fornitori` `fo` on((`fo`.`copre` = `f`.`codice_fornitore`))) group by `f`.`numero`,`f`.`data`,`n`.`codice_interno`,`n`.`negozio_descrizione`,`f`.`codice_fornitore`,`f`.`descrizione_fornitore`,trim(leading '0' from `f`.`numero_bolla_fornitore`),`f`.`data_bolla_fornitore` order by `f`.`numero`,`f`.`data`,`n`.`codice_interno`,`n`.`negozio_descrizione`,`f`.`codice_fornitore`,`f`.`descrizione_fornitore`,trim(leading '0' from `f`.`numero_bolla_fornitore`),`f`.`data_bolla_fornitore`;