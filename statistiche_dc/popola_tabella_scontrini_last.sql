create table if not exists ncr.scontrini_last as 
select      datadc                      as datadc,
            negozio                     as negozio,
            numcassa                    as cassa,
            data                        as giorno,
            ora_transazione,
            transazione,
            tessera,
            round(tot_scontrino/100,2)  as valore_scontrino,
            tipo_pagamento,
            cassiere,
            longidtransazione
from        ncr.datacollect_rich    
where       tipo_transazione = 1 
and         tiporec = 'F'
group by    longidtransazione;
