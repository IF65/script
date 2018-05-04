replace into ncr.venduto_articolo_ncr
select      datadc                  as data_riferimento,
            data                    as data_record,
            negozio                 as codice_pdv,
            plu                     as barcode,
            articolo                as articolo,
            sum(valore_lordo)       as valore_lordo,
            sum(valore_netto)       as valore_netto,
            sum(valore_netto + quota_sc_tran)       as totale,
            sum(unita_vendute)      as unita_vendute,
            sum(qta_venduta)        as qta_venduta
from        ncr.datacollect_rich
group by    datadc      ,      
            data        , 
            negozio     ,
            plu         ,
            articolo    
having      totale <> 0;
