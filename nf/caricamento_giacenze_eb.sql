select max(data) into @my_var from db_eb.temp_stock;

insert ignore into db_eb.giacenze select t.codice, t.negozio, t.giacenza, t.data from db_eb.temp_stock as t left join 
(select * from db_eb.giacenze as g1 
	where data = (
		select max(g2.data) 
		from db_eb.giacenze as g2 
		where g1.codice = g2.codice and g1.negozio = g2.negozio and g2.data <= @my_var)
	) as g on t.codice=g.codice and t.negozio=g.negozio 
	where (g.codice is not null and g.giacenza<>t.giacenza) or g.codice is null 
order by t.codice;
