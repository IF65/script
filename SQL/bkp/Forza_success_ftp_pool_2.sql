update trasmissioni.job
       set success = case when dayofweek(date(now())) = 1 then 0 else success end,
           todo    = case when dayofweek(date(now())) = 1 then 0 else todo    end
where  tipo = 2
and    idhost in(55);