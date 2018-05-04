select distinct data, negozio into @data, @negozio from db_sm.temp_stock limit 1;

delete from db_sm.giacenze where data = @data and negozio = @negozio;

insert ignore into db_sm.giacenze select t.codice, t.negozio, t.giacenza, t.data from db_sm.temp_stock as t 
where t.giacenza <> 0
order by t.codice;
