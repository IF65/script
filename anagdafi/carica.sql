use dc;

-- select @negozio;
-- select @data;

insert into dc.`anagdafi`
select e.* from dc.`export` as e left join 
(select a.* from (select a.`negozio`, a.`codice`,max(a.`data`) `data` from anagdafi as a where a.`negozio`= @negozio and a.`data`< @data group by 1,2) as d join anagdafi as a on d.`negozio`=a.`negozio` and d.`codice`=a.`codice` and d.`data`=a.`data`) as a on e.`anno`=a.`anno` and e.`codice`=a.`codice` and e.`negozio`=a.`negozio`and e.`prezzoOfferta`=a.`prezzoOfferta` and e.`prezzoVendita`=a.`prezzoVendita` and e.`prezzoVenditaLocale`=a.`prezzoVenditaLocale` and e.`bloccato`=a.`bloccato` and e.`tipo`=a.`tipo` and e.`dataBlocco`=a.`dataBlocco` and e.`dataFineOfferta`=a.`dataFineOfferta`
where a.`codice` is null;
