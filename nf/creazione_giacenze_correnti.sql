/*
viene calcolata nelle situazioni
drop table if exists db_sm.giacenze_correnti;
create table db_sm.giacenze_correnti as 
select g.codice, g.negozio, ifnull(g.giacenza,0) `giacenza` 
from (select negozio, max(data) as `data` from db_sm.giacenze group by 1) as d join db_sm.giacenze as g on g.data = d.data and g.negozio = d.negozio
order by 1,2;
alter table db_sm.giacenze_correnti add primary key(codice,negozio);
*/

drop table if exists db_sp.giacenze_correnti;
create table db_sp.giacenze_correnti as 
select g.codice, g.negozio, ifnull(g.giacenza,0) `giacenza` 
from (select negozio, max(data) as `data` from db_sp.giacenze group by 1) as d join db_sp.giacenze as g on g.data = d.data and g.negozio = d.negozio
order by 1,2;
alter table db_sp.giacenze_correnti add primary key(codice,negozio);


drop table if exists db_ru.giacenze_correnti;
create table db_ru.giacenze_correnti as 
select g.codice, g.negozio, ifnull(g.giacenza,0) `giacenza` 
from (select negozio, max(data) as `data` from db_ru.giacenze group by 1) as d join db_ru.giacenze as g on g.data = d.data and g.negozio = d.negozio
order by 1,2;
alter table db_ru.giacenze_correnti add primary key(codice,negozio);


drop table if exists db_eb.giacenze_correnti;
create table db_eb.giacenze_correnti as 
select g.codice, g.negozio, ifnull(g.giacenza,0) `giacenza` 
from (select negozio, max(data) as `data` from db_eb.giacenze group by 1) as d join db_eb.giacenze as g on g.data = d.data and g.negozio = d.negozio
order by 1,2;
alter table db_eb.giacenze_correnti add primary key(codice,negozio);
