INSERT INTO NCR.VENDITE_CATALOGO (
        idnegozio   ,   
        cassa       ,   
        data        ,   
        ora         ,   
        transazione ,   
        riga        ,   
        articolo    ,   
        tessera     ,   
        code1       ,   
        code2       ,   
        code3       ,   
        qta_venduta ,   
        contributo  ,   
        ean         ,   
        punti_articolo,
		punti_target,
		quota_nonpagata)
SELECT  D.NEGOZIO,
        D.NUMCASSA,
        concat("20",D.DATA),
        D.ORA,
        D.TRANSAZIONE,
        D.RIGA,
        D.ARTICOLO,
        D.TESSERA,
        D.CODE1,
        D.CODE2,
        D.CODE3,
        D.QTA_VENDUTA,
        (D.VALORE_NETTO/100),
        D.BARCODE_ITM,
        D.PUNTI_ARTICOLO,
		D.PUNTI_TARGET,
		D.QUOTA_NONPAGATA		
from    ncr.datacollect_rich D
where   D.TIPOREC = 'S'
and     D.CODE1 = 1
and     (	(D.ARTICOLO >= 9250000 and D.ARTICOLO <  9500000)
or 			QUOTA_NONPAGATA <> 0
or			PUNTI_TARGET <> 0)
ON DUPLICATE KEY UPDATE
        ARTICOLO    = D.ARTICOLO,
        TESSERA     = D.TESSERA,
        CODE1       = D.CODE1,
        CODE2       = D.CODE2,
        CODE3       = D.CODE3,
        QTA_VENDUTA = D.QTA_VENDUTA,
        contributo  = D.VALORE_NETTO/100,
        EAN         = D.BARCODE_ITM,
		PUNTI_ARTICOLO = D.PUNTI_ARTICOLO,
		PUNTI_TARGET	= D.PUNTI_TARGET,
		QUOTA_NONPAGATA	= D.QUOTA_NONPAGATA;