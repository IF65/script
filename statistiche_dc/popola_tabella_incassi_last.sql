create table if not exists ncr.incassi_last as 
select      datadc                                                          as giorno,
            negozio                                                         as idneg,
            round(sum(tot_scontrino)/100,2)                                 as incasso_tot,
            round(sum(case  when trim(tessera) <> '' 
                            then tot_scontrino 
                            else 0 end)/100,2)                              as incasso_tessere,
            round(100*round(sum(case  when trim(tessera) <> '' 
                            then tot_scontrino 
                            else 0 end)/100,2)/round(sum(tot_scontrino)/100,2),2)
                                                                            as incid_incasso,
            
            count(distinct tessera)                                         as num_tessere,
            
            count(*)                                                        as tot_scontrini,
            
            sum(case when trim(tessera) <> '' then 1 else 0 end)            as scontrini_tessere,
            
            round(100*(sum(case when trim(tessera) <> '' then 1 else 0 end)/count(*)),2)    
                                                                            as incid_scontrini        
        
from        ncr.datacollect_rich    
where       tipo_transazione = 1 
and         binary tiporec = 'F'
group by    negozio,
            datadc;
