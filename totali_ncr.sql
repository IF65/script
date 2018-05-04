drop table if exists controllo.totali_ncr;

create table controllo.totali_ncr as 
select negozio, data, count(*) as `clienti`, round(sum(ifnull(totale,0)),2) as `totale`
from controllo.testate_ncr 
group by 1,2 
order by 1,2;

alter table controllo.totali_ncr add primary key(`negozio`,`data`);
