/*sistemazione numero ddt*/
update `db_sm`.fatture_ca as fca set fca.`numero_bolla_fornitore`=trim(leading 'TC/' FROM fca.`numero_bolla_fornitore`)
where fca.`codice_fornitore`='100860' and fca.`numero_bolla_fornitore` like 'TC/%';

update `db_sm`.fatture_ca as fca set fca.`numero_bolla_fornitore`=trim(trailing '/K' FROM fca.`numero_bolla_fornitore`)
where fca.`codice_fornitore`='100438' and fca.`numero_bolla_fornitore` like '%/K';

update `db_sm`.fatture_ca as fca set fca.`numero_bolla_fornitore`=trim(trailing '/03' FROM fca.`numero_bolla_fornitore`)
where fca.`codice_fornitore`='000077' and fca.`numero_bolla_fornitore` like '%/03';

update `db_sm`.fatture_ca as fca set fca.`numero_bolla_fornitore`=trim(leading '1-' FROM fca.`numero_bolla_fornitore`)
where fca.`codice_fornitore`='100480' and fca.`numero_bolla_fornitore` like '1-%';

update `db_sm`.fatture_ca as fca set fca.`numero_bolla_fornitore`=trim(trailing '/WD' FROM fca.`numero_bolla_fornitore`)
where fca.`codice_fornitore`='100903' and fca.`numero_bolla_fornitore` like '%/WD';

update `db_sm`.fatture_ca as fca set fca.`numero_bolla_fornitore`=trim(leading 'F' FROM fca.`numero_bolla_fornitore`)
where fca.`codice_fornitore`='100912' and fca.`numero_bolla_fornitore` like 'F%';

update `db_sm`.fatture_ca as fca set fca.`numero_bolla_fornitore`=trim(trailing '/16' FROM fca.`numero_bolla_fornitore`)
where fca.`codice_fornitore`='100816' and fca.`numero_bolla_fornitore` like '%/16';

update `db_sm`.fatture_ca as fca set fca.`numero_bolla_fornitore`=trim(leading 'DT' FROM fca.`numero_bolla_fornitore`)
where fca.`codice_fornitore`='100293' and fca.`numero_bolla_fornitore` like 'DT%';
/*fine sistemazione numero ddt*/

update `db_sm`.`fatture_ca` as fca left join `db_sm`.`ean` as e on fca.`codice_ean`=e.`ean` 
set codice_articolo_if = ifnull(e.`codice`,'') 
where fca.`codice_articolo_if` = '' and fca.`codice_ean`<>'';

update `db_sm`.`fatture_ca` as fca left join `db_sm`.`fornitore_articolo` as far on fca.`codice_articolo_copre`=far.`codice_articolo_fornitore` 
set fca.`codice_articolo_if` = far.`codice_articolo` 
where fca.`codice_articolo_if` = '' and fca.`codice_articolo_copre`<>'';

drop table if exists `contabilita`.`fatture_ca_testate`;
create table `contabilita`.`fatture_ca_testate` as
select 
	fca.`numero`, 
	fca.`data`, 
	fca.`tipo`,
	n.`codice_interno`, 
	n.`negozio_descrizione`,
	fo.`sm` `codice_fornitore`,
	case when (`fo`.`descrizione_fornitore` <> '') then `fo`.`descrizione_fornitore` else 'COPRE' end `descrizione_fornitore`,
	(case when (`fca`.`numero_bolla_fornitore` <> '') then trim(trailing '-1' FROM trim(leading 'E7J-' FROM trim(leading 'GE0' FROM trim(trailing '/00' FROM trim(leading '0' FROM trim(leading 'DDT' FROM `fca`.`numero_bolla_fornitore`)))))) else trim(leading 'DDT' FROM `fca`.`numero_consegna`) end) AS `numero_ddt`,
	fca.`data_bolla_fornitore` `data_ddt`,
	fca.`contributi` `nota contr.`,
	count(*) `referenze_ddt`,
	sum(fca.`quantita`) `pezzi_ddt`,
	sum(round(fca.`prezzo_lordo`*fca.`quantita`,2)) `totale ddt`,
	(select sum(round(`prezzo_lordo`*`quantita`,2)) from `db_sm`.`fatture_ca` where fca.`numero`=`numero`) `totale_ft`
from `db_sm`.`fatture_ca` as fca 
left join `archivi`.`negozi` as n on fca.`codice_punto_consegna`= n.codice_ca
left join `contabilita`.`sm_fornitori` as fo on fca.`codice_fornitore`=fo.`copre`
group by fca.`numero`,(case when (`fca`.`numero_bolla_fornitore` <> '') then trim(trailing '-1' FROM trim(leading 'E7J-' FROM trim(leading 'GE0' FROM trim(trailing '/00' FROM trim(leading '0' FROM trim(leading 'DDT' FROM `fca`.`numero_bolla_fornitore`)))))) else trim(leading 'DDT' FROM `fca`.`numero_consegna`) end)
order by fca.`numero`;
alter table `contabilita`.`fatture_ca_testate` add primary key (`numero`, `codice_fornitore`, `numero_ddt`);

drop table if exists `contabilita`.`fatture_ca_righe`;
create table `contabilita`.`fatture_ca_righe` as
select 
	fca.`numero`, 
	fca.`data`, 
	n.`codice_interno`, 
	n.`negozio_descrizione`,
	fca.`numero_riga`,
	fca.`contributi`,
	fo.`sm` `codice_fornitore`,
	(case when (`fca`.`numero_bolla_fornitore` <> '') then trim(trailing '-1' FROM trim(leading 'E7J-' FROM trim(leading 'GE0' FROM trim(trailing '/00' FROM trim(leading '0' FROM trim(leading 'DDT' FROM `fca`.`numero_bolla_fornitore`)))))) else trim(leading 'DDT' FROM `fca`.`numero_consegna`) end) AS `numero_ddt`,
	fca.`data_bolla_fornitore` `data_ddt`,
	`fca`.`codice_articolo_copre` `codice_articolo_copre`,
	`fca`.`codice_ean` `codice_ean`,
	`fca`.`codice_articolo_interno` `codice_articolo_interno`,
	 ifnull(`fca`.`codice_articolo_if`,'-------') `codice`,
	 ifnull(`m`.`descrizione`,fca.`descrizione_articolo`) `descrizione`,
	 ifnull(`m`.`modello`,'-------') `modello`,
	 ifnull(`m`.`linea`,'-------') `linea`,
	 fca.`quantita`,
	 round(fca.`prezzo_lordo`*fca.`quantita`,2) `prezzo`
from `db_sm`.`fatture_ca` as fca 
left join `archivi`.`negozi` as n on fca.`codice_punto_consegna`= n.codice_ca
left join `contabilita`.`sm_fornitori` as fo on fca.`codice_fornitore`=fo.`copre`
left join `db_sm`.`magazzino` as m on `fca`.`codice_articolo_if`=m.`codice` 
order by fca.`numero`;
alter table `contabilita`.`fatture_ca_righe` add index (`numero`, `codice_fornitore`, `numero_ddt`, `numero_riga`);

drop table if exists `contabilita`.`arrivi_righe`;
create table `contabilita`.`arrivi_righe` as select a.`negozio`, a.`numero_ddt`,a.`codice_fornitore`,ar.`codice_articolo`, ar.`codice_articolo_fornitore`, ar.`quantita`, ar.`costo` `costo_unitario`, round(ar.`quantita`*ar.`costo`,2) `costo`  
from db_sm.`arrivi` as a left join db_sm.`righe_arrivi` as ar on a.`id` = ar.`id_arrivi`;
alter table `contabilita`.`arrivi_righe` add index (`negozio`,`numero_ddt`,`codice_fornitore`,`codice_articolo`);

drop table if exists `contabilita`.`dettaglio_fatture`;
create table `contabilita`.`dettaglio_fatture` as 
select ft.`numero`, ft.`data`, fr.`contributi`,ft.`codice_interno` `negozio`,ft.`negozio_descrizione` `descrizione neg.`,ft.`codice_fornitore` `fornitore`,
ft.`descrizione_fornitore` `descrizione forn.`,ft.`numero_ddt` `d.d.t.`,fr.`codice`,fr.`codice_articolo_copre`,fr.`codice_ean`,
fr.`descrizione`,fr.`modello`,fr.`linea`,fr.`quantita` `q.ta ddt`,ifnull(ar.`quantita`,0) `q.ta arr.`,ifnull(fr.`quantita`,0)- ifnull(ar.`quantita`,0) `delta q.ta`,
fr.`prezzo` `prezzo ddt`, ifnull(ar.`costo`,0) `prezzo arr.`, ifnull(fr.`prezzo`,0)- ifnull(ar.`costo`,0) `delta prezzo`
from `contabilita`.fatture_ca_testate as ft join `contabilita`.fatture_ca_righe as fr on ft.`numero`=fr.`numero` and ft.`codice_interno`=fr.`codice_interno` and ft.`codice_fornitore`=fr.`codice_fornitore` and ft.`numero_ddt`=fr.`numero_ddt` 
left join `contabilita`.arrivi_righe as ar on ft.`codice_fornitore`=ar.`codice_fornitore` and ft.`codice_interno`=ar.`negozio` and ft.`numero_ddt`=ar.`numero_ddt` and fr.`codice`=ar.`codice_articolo`;

update contabilita.fatture_ca_testate as t left join 
(select distinct f.numero `numero`, 
case when f.`codice_punto_consegna` in ('500113','500213','500313','500413','500513','500613','500713','500813','500913') then
		'500013' 
	else 
		case when f.`codice_punto_consegna` in ('500153','500253','500333') then
			'500053' 
		else 
			f.`codice_punto_consegna` 
		end 
	end `codice_punto_consegna`
, n.`codice_interno` `codice_interno`, n.`negozio_descrizione` `negozio_descrizione` from db_sm.fatture_ca as f 
left join archivi.negozi as n on 
	case when f.`codice_punto_consegna` in ('500113','500213','500313','500413','500513','500613','500713','500813','500913') then
		'500013' 
	else 
		case when f.`codice_punto_consegna` in ('500153','500253','500333') then
			'500053' 
		else 
			f.`codice_punto_consegna` 
		end 
	end =n.codice_ca) as f on t.`numero`=f.`numero` 
set t.codice_interno=f.codice_interno, t.negozio_descrizione=f.negozio_descrizione	
where t.`codice_interno` is null and t.`data`>='2017-01-01';