drop table if exists archivi.giornateMancanti;

create table archivi.giornateMancanti as
select distinct r.`RVG-CODSOC` `codiceSocieta`,  r.`RVG-CODNEG` `codiceNegozio`, r.`RVG-DATA` `data` from archivi.consolidatiReparto as c right join archivi.riepvegi as r on c.`codiceSocieta`=r.`RVG-CODSOC` and c.`codiceNegozio`=r.`RVG-CODNEG` and c.`data`=r.`RVG-DATA` where c.`codiceSocieta` is null and r.`RVG-DATA`>='2017-01-01';

insert into archivi.consolidatiReparto (codice, codiceSocieta, codiceNegozio, data, reparto, importo)
select  concat(r.`RVG-CODSOC`, r.`RVG-CODNEG`) `codice`, r.`RVG-CODSOC` `codiceSocieta`, r.`RVG-CODNEG` `codiceNegozio`, r.`RVG-DATA` `data`, d.`REPARTO` `reparto`, sum(r.`RVG-VAL-VEN-CASSE-E`) `importo` 
from archivi.riepvegi as r left join dimensioni.`articolo` as d on d.`CODICE_ARTICOLO`=r.`RVG-CODICE` join
archivi.giornateMancanti as g on 
 r.`RVG-CODSOC`=g.codiceSocieta and r.`RVG-CODNEG` = g.codiceNegozio and r.`RVG-DATA` = g.data
group by 1,2,3,4;

drop table if exists archivi.giornateMancanti;

update archivi.consolidatiReparto as a join archivi.calendarioCed as c on a.`data` = c.`data` set a.`settimana`= c.`settimanaCalendario`, a.`settimanaCed`=c.`settimanaCed` 
where a.`settimana` is null or a.`settimanaCed` is null;

-- select * from archivi.consolidatiReparto as a join controllo.`testate_ncr` as t on a.`data`=t.`data` and a.`codice`=t.`negozio`;

drop table if exists archivi.clientiReparto;

create table archivi.clientiReparto as
select 
	substr(t.`negozio`,1,2) `codiceSocieta`,
	substr(t.`negozio`,3) `codiceNegozio`,
	t.`data`, 
	round(sum(t.`totale`),2) `importo`, 
	round(sum(case when t.`carta` then t.`totale` else 0 end),2) `importoNimis`,
	count(*) `clienti`,
	sum(case when t.`carta` then 1 else 0 end) `clientiNimis`
from controllo.testate_lrp as t group by 1,2,3
order by 1,2,3;

update archivi.consolidatiReparto as c join archivi.`clientiReparto` as r on c.`codiceSocieta`=r.`codiceSocieta` and c.`codiceNegozio`=r.`codiceNegozio` and r.`data`=c.`data` 
set c.`clienti` = r.`clienti`
where c.`reparto` = 1;

drop table if exists archivi.clientiReparto;