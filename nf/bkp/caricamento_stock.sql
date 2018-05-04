insert into giacenze select t.* from temp_stock as t left join giacenze as g on t.`codice`=g.`codice` and t.`negozio`=g.`negozio` where g.`codice` is null;

insert into giacenze select t.* from temp_stock as t left join giacenze as g on t.`codice`=g.`codice` and t.`negozio`=g.`negozio` where g.`codice` is not null and g.`giacenza`<>t.`giacenza` and g.`data`<>t.`data`;
