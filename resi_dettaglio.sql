drop table if exists archivi.resi_dettaglio;

create table archivi.resi_dettaglio as select r.data,date_format(r.`data`,'%Y%m') `mese`,concat(r.`negozio`,' - ', n.`negozio_descrizione`) `negozio`, r.`cassa`, r.`transazione`, 
ifnull((select ora from archivi.pagamenti as p where r.`cassa`=p.`cassa` and r.`transazione`=p.`transazione` and r.`data`=p.`data` and r.`negozio`=p.`negozio` limit 1),'') `ora`,
case when r.`tipo` = '4' then 'R' when r.`tipo`='7' then 'S' else 'A' end `tipo_movimento`,
ifnull((select carta from archivi.pagamenti as p where r.`cassa`=p.`cassa` and r.`transazione`=p.`transazione` and r.`data`=p.`data` and r.`negozio`=p.`negozio` limit 1),'') `carta`,
case when (select pos_id from archivi.pagamenti as p where pos_id = '01' and r.`cassa`=p.`cassa` and r.`transazione`=p.`transazione` and r.`data`=p.`data` and r.`negozio`=p.`negozio` limit 1) is not null then 'Contante' else 'Altro' end `pagamento`,
r.`reparto`,r.`barcode`,
case when r.`barcode`<>'' then 'B' else 'R' end `tipo`,
r.`importo`/100 `importo`,
ifnull((select totale/100 from archivi.pagamenti as p where r.`cassa`=p.`cassa` and r.`transazione`=p.`transazione` and r.`data`=p.`data` and r.`negozio`=p.`negozio` limit 1),0) `totale_scontrino`
from archivi.resi as r left join archivi.negozi as n on r.`negozio`=n.`codice`;