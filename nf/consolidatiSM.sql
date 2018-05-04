drop table db_sm.consolidatiVendita;

CREATE TABLE db_sm.consolidatiVendita (
  `data` date NOT NULL,
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `quantita` double NOT NULL,
  `importo` double NOT NULL,
  PRIMARY KEY (`data`,`negozio`,`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

insert into db_sm.consolidatiVendita
select r.`data`, r.`negozio`, r.`codice`, round(sum(r.`quantita`),2) `quantita`, round(sum(r.`importo_totale`),2) `importo`
from db_sm.righe_vendita as r 
where r.`data` >= '2017-01-01' and r.`riga_non_fiscale`=0
group by 1,2,3;


set @data90=date_sub(current_date(), interval 90 day);
set @data30=date_sub(current_date(), interval 30 day);
set @data15=date_sub(current_date(), interval 15 day);
set @data7=date_sub(current_date(), interval 7 day);

drop table db_sm.ultimeVendite;

create table db_sm.ultimeVendite (
  `negozio` varchar(4) NOT NULL DEFAULT '',
  `codice` varchar(7) NOT NULL DEFAULT '',
  `data90` longtext,
  `v90` double(19,2) DEFAULT NULL,
  `q90` double DEFAULT NULL,
  `v30` double(19,2) DEFAULT NULL,
  `q30` double DEFAULT NULL,
  `v15` double(19,2) DEFAULT NULL,
  `q15` double DEFAULT NULL,
  `v7` double(19,2) DEFAULT NULL,
  `q7` double DEFAULT NULL,
  PRIMARY KEY (`negozio`,`codice`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

insert into db_sm.ultimeVendite
select 
	c.`negozio`, 
	c.`codice`, 
	@data90 `data90`,
	round(sum(c.`importo`),2) `v90`, 
	round(sum(c.`quantita`),2) `q90`,
	round(sum(case when c.`data`>=@data30 then c.`importo` else 0 end),2) `v30`, 
	round(sum(case when c.`data`>=@data30 then c.`quantita` else 0 end),2) `q30`,
	round(sum(case when c.`data`>=@data15 then c.`importo` else 0 end),2) `v15`, 
	round(sum(case when c.`data`>=@data15 then c.`quantita` else 0 end),2) `q15`,
	round(sum(case when c.`data`>=@data7 then c.`importo` else 0 end),2) `v7`, 
	round(sum(case when c.`data`>=@data7 then c.`quantita` else 0 end),2) `q7`
from db_sm.consolidatiVendita as c 
where c.`data`>=@data90 
group by 1,2;


