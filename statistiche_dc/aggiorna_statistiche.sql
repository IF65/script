insert into ncr.statistiche (   data             ,
                                idnegozio         ,
                                incasso           ,
                                incasso_tessere   ,
                                incid_incasso     ,
                                tessere           ,
                                scontrini         ,
                                scontrini_tessere ,
                                incid_scontrini   )
                                
select                          giorno            ,
                                idneg             ,
                                incasso_tot       ,
                                incasso_tessere   ,
                                incid_incasso     ,
                                num_tessere       ,
                                tot_scontrini     ,
                                scontrini_tessere ,
                                incid_scontrini   
from    ncr.incassi_last i
on      duplicate key update
        ncr.statistiche.incasso           = ifnull(i.incasso_tot        , ncr.statistiche.incasso           ),
        ncr.statistiche.incasso_tessere   = ifnull(i.incasso_tessere    , ncr.statistiche.incasso_tessere   ),
        ncr.statistiche.incid_incasso     = ifnull(i.incid_incasso      , ncr.statistiche.incid_incasso     ),
        ncr.statistiche.tessere           = ifnull(i.num_tessere        , ncr.statistiche.tessere           ),
        ncr.statistiche.scontrini         = ifnull(i.tot_scontrini      , ncr.statistiche.scontrini         ),
        ncr.statistiche.scontrini_tessere = ifnull(i.scontrini_tessere  , ncr.statistiche.scontrini_tessere ),
        ncr.statistiche.incid_scontrini   = ifnull(i.incid_scontrini    , ncr.statistiche.incid_scontrini   );		
