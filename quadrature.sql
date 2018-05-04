drop table if exists controllo.`quadrature`;

CREATE TABLE controllo.`quadrature` (
  `negozio` varchar(4) CHARACTER SET utf8 NOT NULL DEFAULT '',
  `data` date NOT NULL DEFAULT '0000-00-00',
  `clienti` int(11) NOT NULL DEFAULT '0',
  `totale` float NOT NULL DEFAULT '0',
  `buoni` float NOT NULL DEFAULT '0',
  PRIMARY KEY (`negozio`,`data`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

insert into controllo.`quadrature`
select
  concat(lpad(cast(r.`RIEP2-CODSO` as char),2,'0'),lpad(cast(r.`RIEP2-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(r.`RIEP2-DATA`,1,4),'-',substr(r.`RIEP2-DATA`,5,2),'-',substr(r.`RIEP2-DATA`,7,2)) as DATE) `data`,
  i.`INGE-TOTCLIE` `clienti`,
  r.`RIEP2-AZZ-E` `totale`,
  0 `buoni`
from controllo.riepazz2 as r left join controllo.incggeur as i on r.`RIEP2-DATA`=i.`INGE-DATA` and r.`RIEP2-CODSO`= i.`INGE-CODSO` and r.`RIEP2-CODNE`= i.`INGE-CODNE`
where r.`RIEP2-DATA` >= '20140101' 
order by 1,2;

update controllo.quadrature as q left join 
archivi.negozi as n on q.`negozio`=n.`codice` left join 
(select data, negozio, round(sum(buoni),2) as buoni from db_sp.scontrini where buoni<>0 group by 1,2) as s on s.`data`=q.`data` and s.`negozio`=n.`codice_interno` 
set q.`buoni` = s.`buoni` 
where q.`data`>='2015-01-01' and s.`buoni`<>0 and q.`negozio` like '07%';

update controllo.quadrature as q left join 
archivi.negozi as n on q.`negozio`=n.`codice` left join 
(select data, negozio, round(sum(buoni),2) as buoni from db_sm.scontrini where buoni<>0 group by 1,2) as s on s.`data`=q.`data` and s.`negozio`=n.`codice_interno` 
set q.`buoni` = s.`buoni` 
where q.`data`>='2015-01-01' and s.`buoni`<>0 and q.`negozio` like '08%';

update controllo.quadrature as q left join 
archivi.negozi as n on q.`negozio`=n.`codice` left join 
(select data, negozio, round(sum(buoni),2) as buoni from db_eb.scontrini where buoni<>0 group by 1,2) as s on s.`data`=q.`data` and s.`negozio`=n.`codice_interno` 
set q.`buoni` = s.`buoni` 
where q.`data`>='2015-01-01' and s.`buoni`<>0 and q.`negozio` like '10%';

update controllo.quadrature as q left join 
archivi.negozi as n on q.`negozio`=n.`codice` left join 
(select data, negozio, round(sum(buoni),2) as buoni from db_ru.scontrini where buoni<>0 group by 1,2) as s on s.`data`=q.`data` and s.`negozio`=n.`codice_interno` 
set q.`buoni` = s.`buoni` 
where q.`data`>='2015-01-01' and s.`buoni`<>0 and q.`negozio` like '53%';

/*
drop table if exists controllo.`incasso_reparti`;

CREATE TABLE controllo.`incasso_reparti` (
  `negozio` varchar(4) CHARACTER SET utf8 NOT NULL DEFAULT '',
  `data` date NOT NULL DEFAULT '0000-00-00',
  `reparto` int(11) NOT NULL DEFAULT '0',
  `clienti` int(11) NOT NULL DEFAULT '0',
  `ore` float NOT NULL DEFAULT '0',
  `importo` float NOT NULL DEFAULT '0',
  PRIMARY KEY (`negozio`,`data`,`reparto`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  0 `reparto`,
  i.`INGE-TOTCLIE` `clienti`,
  i.`INGE-TOTOREEFF` `ore`,
  i.`INGE-TOTINCEFF` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  1 `reparto`,
  i.`INGE-CLIENTI_1` `clienti`,
  i.`INGE-OREEFF_1` `ore`,
  i.`INGE-INCEFF_1` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  4 `reparto`,
  i.`INGE-CLIENTI_2` `clienti`,
  i.`INGE-OREEFF_2` `ore`,
  i.`INGE-INCEFF_2` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  2 `reparto`,
  i.`INGE-CLIENTI_3` `clienti`,
  i.`INGE-OREEFF_3` `ore`,
  i.`INGE-INCEFF_3` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  3 `reparto`,
  i.`INGE-CLIENTI_4` `clienti`,
  i.`INGE-OREEFF_4` `ore`,
  i.`INGE-INCEFF_4` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  5 `reparto`,
  i.`INGE-CLIENTI_5` `clienti`,
  i.`INGE-OREEFF_5` `ore`,
  i.`INGE-INCEFF_5` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  6 `reparto`,
  i.`INGE-CLIENTI_6` `clienti`,
  i.`INGE-OREEFF_6` `ore`,
  i.`INGE-INCEFF_6` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  7 `reparto`,
  i.`INGE-CLIENTI_7` `clienti`,
  i.`INGE-OREEFF_7` `ore`,
  i.`INGE-INCEFF_7` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  8 `reparto`,
  i.`INGE-CLIENTI_8` `clienti`,
  i.`INGE-OREEFF_8` `ore`,
  i.`INGE-INCEFF_8` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  9 `reparto`,
  i.`INGE-CLIENTI_9` `clienti`,
  i.`INGE-OREEFF_9` `ore`,
  i.`INGE-INCEFF_9` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  10 `reparto`,
  i.`INGE-CLIENTI_10` `clienti`,
  i.`INGE-OREEFF_10` `ore`,
  i.`INGE-INCEFF_10` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  11 `reparto`,
  i.`INGE-CLIENTI_11` `clienti`,
  i.`INGE-OREEFF_11` `ore`,
  i.`INGE-INCEFF_11` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  12 `reparto`,
  i.`INGE-CLIENTI_12` `clienti`,
  i.`INGE-OREEFF_12` `ore`,
  i.`INGE-INCEFF_12` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  13 `reparto`,
  i.`INGE-CLIENTI_13` `clienti`,
  i.`INGE-OREEFF_13` `ore`,
  i.`INGE-INCEFF_13` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  14 `reparto`,
  i.`INGE-CLIENTI_14` `clienti`,
  i.`INGE-OREEFF_14` `ore`,
  i.`INGE-INCEFF_14` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  15 `reparto`,
  i.`INGE-CLIENTI_15` `clienti`,
  i.`INGE-OREEFF_15` `ore`,
  i.`INGE-INCEFF_15` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

insert into controllo.`incasso_reparti`
select
  concat(lpad(cast(i.`INGE-CODSO` as char),2,'0'),lpad(cast(i.`INGE-CODNE` as char),2,'0')) `negozio`,
  cast(concat(substr(i.`INGE-DATA`,1,4),'-',substr(i.`INGE-DATA`,5,2),'-',substr(i.`INGE-DATA`,7,2)) as DATE) `data`,
  16 `reparto`,
  i.`INGE-CLIENTI_16` `clienti`,
  i.`INGE-OREEFF_16` `ore`,
  i.`INGE-INCEFF_16` `totale`
from controllo.incggeur as i 
where i.`INGE-DATA` >= '20140101' 
order by 1,2;

delete from controllo.`incasso_reparti` where `importo`=0 and `clienti`=0 and `ore`=0;
*/