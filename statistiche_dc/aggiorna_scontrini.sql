insert into ncr.scontrini(      datadc            ,
                                negozio           ,
                                cassa             ,
                                giorno            ,
                                ora_transazione   ,
                                transazione       ,
                                tessera           ,
                                valore_scontrino  ,
                                tipo_pagamento    ,
                                cassiere          ,
                                longidtransazione                              
                                )
                                
select                          datadc            ,
                                negozio           ,
                                cassa             ,
                                giorno            ,
                                ora_transazione   ,
                                transazione       ,
                                tessera           ,
                                valore_scontrino  ,
                                tipo_pagamento    ,
                                cassiere          ,
                                longidtransazione  
                                
from    ncr.scontrini_last i
on      duplicate key update
        ncr.scontrini.datadc            = ifnull(i.datadc            , ncr.scontrini.datadc            ),
        ncr.scontrini.negozio           = ifnull(i.negozio           , ncr.scontrini.negozio           ),
        ncr.scontrini.cassa             = ifnull(i.cassa             , ncr.scontrini.cassa             ),
        ncr.scontrini.giorno            = ifnull(i.giorno            , ncr.scontrini.giorno            ),
        ncr.scontrini.ora_transazione   = ifnull(i.ora_transazione   , ncr.scontrini.ora_transazione   ),
        ncr.scontrini.transazione       = ifnull(i.transazione       , ncr.scontrini.transazione       ),
        ncr.scontrini.tessera           = ifnull(i.tessera           , ncr.scontrini.tessera           ),		
        ncr.scontrini.valore_scontrino  = ifnull(i.valore_scontrino  , ncr.scontrini.valore_scontrino  ),	
        ncr.scontrini.tipo_pagamento    = ifnull(i.tipo_pagamento    , ncr.scontrini.tipo_pagamento    ),	
        ncr.scontrini.cassiere          = ifnull(i.cassiere          , ncr.scontrini.cassiere          ),	
        ncr.scontrini.longidtransazione = ifnull(i.longidtransazione , ncr.scontrini.longidtransazione );
