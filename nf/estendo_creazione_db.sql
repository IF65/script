DROP TABLE IF EXISTS  `report`.`report_estendo`;

CREATE TABLE IF NOT EXISTS `report`.`report_estendo` (
  `data` date NOT NULL,
  `negozio` varchar(4) NOT NULL,
  `incasso` float NOT NULL DEFAULT '0',
  `estendo` float NOT NULL DEFAULT '0',
  PRIMARY KEY (`data`,`negozio`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

INSERT IGNORE INTO `report`.`report_estendo` (`data`,`negozio`,`incasso`,`estendo`)
SELECT s.`data`, s.`negozio`, round(sum(s.`totale`),2) `incasso`, 0.00 `estendo` 
FROM `db_sm`.`scontrini` AS s 
WHERE s.`data`>='2015-01-01' AND s.`scontrino_non_fiscale`= 0 
GROUP BY s.`data`,s.`negozio`;

UPDATE report.report_estendo AS rep SET rep.`estendo` = 
	(select ifnull(round(sum(r.`importo_totale`),2),0) `estendo` 
	from `db_sm`.`marche` as m left join `db_sm`.`magazzino` as mag on m.`linea`=mag.`linea` left join `db_sm`.`righe_vendita` as r on mag.`codice`=r.`codice` 
	where  r.`data` = rep.`data` and r.`negozio`=rep.`negozio` and m.`linea`='ESTENDO');

update report.report_estendo as rep left join archivi.`negozi` as n on rep.`negozio`=n.`codice_interno` left join controllo.`quadrature` as q on n.`codice`= q.`negozio` and q.`data`=rep.`data` 
set rep.`incasso`=q.`totale`  
where q.`negozio` is not null;