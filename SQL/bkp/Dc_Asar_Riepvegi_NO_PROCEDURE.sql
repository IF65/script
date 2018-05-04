DROP   TABLE IF EXISTS TEMP.RIEPVEGI;
DROP   TABLE IF EXISTS TEMP.RIEPVEGI_RIE;
DROP   TABLE IF EXISTS TEMP.NEWOFFERTEINCORSO;
DROP   TABLE IF EXISTS TEMP.OUTRIEPVEGI;

CREATE TABLE TEMP.RIEPVEGI(
       NEGOZIO               VARCHAR(4)       DEFAULT '0000',
       ARTICOLO              VARCHAR(7)       DEFAULT '0000000',
       BARCODE               varchar(13)        DEFAULT '',
       DATA                  VARCHAR(8)       DEFAULT '00000000',
       QTA_USC               DECIMAL(13,3)    DEFAULT 0,
       QTA_USC_OS            DECIMAL(13,3)    DEFAULT 0,
       QTA_USC_SCO           DECIMAL(13,3)    DEFAULT 0,
       SEGNO_TIPO_PREZZO     CHAR(1)          DEFAULT '0',
       FORZAPRE              CHAR(1)          DEFAULT '0',
       VAL_VEN_CASSE_E       DECIMAL(14,0)    DEFAULT 0,
       VAL_VEN_CED_E         DECIMAL(14,0)    DEFAULT 0,
       VAL_VEN_LOC_E         DECIMAL(14,0)    DEFAULT 0,
       VAL_VEN_OS_E          DECIMAL(14,0)    DEFAULT 0,
       VAL_VEN_SCO_E         DECIMAL(14,0)    DEFAULT 0,
       REPARTO               CHAR(2)          DEFAULT '00',
       CODFOR                VARCHAR(6)       DEFAULT '000000',
       SEGNO_RESO            CHAR(1)          DEFAULT '0',
       QTANX                 DECIMAL(14,0)    DEFAULT 0,
       TIPOLOGIA             VARCHAR(3)       DEFAULT '  ',
       PROMOLIST             VARCHAR(256)     DEFAULT '',
       LONGIDTRANSAZIONE     VARCHAR(17)      DEFAULT '')   ENGINE = MYISAM;
       
INSERT INTO TEMP.RIEPVEGI
SELECT LPAD(NEGOZIO,4,0)                    AS NEGOZIO,
       LPAD(ARTICOLO,7,0)                   AS ARTICOLO,
       CASE WHEN DEPREZZATO THEN 
            CASE WHEN PLU >= 2000000000000 and PLU <= 2199999999999
                 THEN concat(left(barcode_itm,6),9)                  
                 ELSE CONCAT(99999,ARTICOLO,funzioni.CIN(CONCAT(99999,ARTICOLO)))  
            END
            ELSE BARCODE_ITM END AS BARCODE,             
       CONCAT('20',DATA)              AS DATA  ,
       QTA_VENDUTA                    AS QTA_USC,
--     Considero come qta uscita in os, tutti le vendite con promolist (tranne promolist di tipo ....) 
--     G0034          = Punti transazionali
--     C0492(1111111) = deprezzato (a cui associo il barcode del deprezzato) 
--     D0061          = sconto transazionale (considero come sconto e non come promo) 
       CASE WHEN    PROMOLIST LIKE('%_C0027%') 
                 OR PROMOLIST LIKE('%_C0057%') 
                 OR PROMOLIST LIKE('%_C0493%') 
                 OR PROMOLIST LIKE('%_D0055%') 
                 OR PROMOLIST LIKE('%_D0504%') 
                 OR PROMOLIST LIKE('%_G0022%') 
                 OR PROMOLIST LIKE('%_G0023%') 
                 OR PROMOLIST LIKE('%_G0027%') 
                 OR PROMOLIST LIKE('%_G0505%') 
                 then QTA_VENDUTA
            ELSE 0
            END AS QTA_USC_OS,
       CASE WHEN VALORE_LORDO <> (valore_netto + quota_sc_tran) THEN QTA_VENDUTA ELSE 0 END AS QTA_USC_SCO,
       'L'      AS SEGNO_TIPO_PREZZO,
       '0'      AS FORZAPRE,     
       (VALORE_NETTO + quota_sc_tran)  AS VAL_VEN_CASSE_E,
        VALORE_LORDO                   AS VAL_VEN_CED_E,            
        VALORE_LORDO                   AS VAL_VEN_LOC_E,  
       CASE WHEN    PROMOLIST LIKE('%_C0027%')  
                 OR PROMOLIST LIKE('%_C0057%')  
                 OR PROMOLIST LIKE('%_C0493%')  
                 OR PROMOLIST LIKE('%_D0055%')  
                 OR PROMOLIST LIKE('%_D0504%')  
                 OR PROMOLIST LIKE('%_G0022%')  
                 OR PROMOLIST LIKE('%_G0023%')  
                 OR PROMOLIST LIKE('%_G0027%')  
                 OR PROMOLIST LIKE('%_G0505%')          
                 then (VALORE_NETTO + quota_sc_tran)
             ELSE 0
             END  AS VAL_VEN_OS_E,    
      (VALORE_LORDO - (valore_netto + quota_sc_tran))  AS VAL_VEN_SCO_E,
       SUBSTR(CODE4,3,2)               AS REPARTO,
       '000000'                        AS CODFOR,
       '0'                             AS SEGNORESO,
       CASE
       WHEN PROMOLIST LIKE('%_C0057%') THEN SUBSTR(PROMOLIST,(LOCATE('_C0057',PROMOLIST) +14) ,6)   
       ELSE 0
       END                             AS QTANX,
       '   '                           AS TIPOLIGIA,
       PROMOLIST                       AS PROMOLIST,
       LONGIDTRANSAZIONE               AS LONGIDTRANSAZIONE
FROM   NCR.DATACOLLECT_RICH
WHERE  TIPOREC = "S"
AND    TIPO_TRANSAZIONE = 1;

-- Creo offerte, considero tutte le offerte inizio <= data minima data collect e fine >=
-- data minima datacollect o con data inizio <= data massima data collect e fine >= 
-- data miassima datacollect o data inizio offerte >= a data minima datacollect e
-- data inizio <= data massima datacollect

DROP TABLE IF EXISTS TEMP.NEWOFFERTEINCORSO;
CREATE TABLE TEMP.NEWOFFERTEINCORSO AS
SELECT  B.`OFX2-DATAFI` AS IDPROMO,
        A.FILIALE AS FILIALE,
        B.`OFX2-CODCIN`      AS ARTICOLO,
        A.DAL                AS DATAIN,
        A.AL                 AS DATAFI,
        B.`OFX2-PVIFOS-EURO` AS PVIFOS,   
        B.`OFX2-PRENDI`      AS PRENDI,
        B.`OFX2-PAGHI`       AS PAGHI,
        B.`OFX2-TIPOLOGIA`   AS TIPOLOGIA,
        B.`OFX2-PVIFOS-EURO` AS VALOREPAGHI,
        '       '            AS RISERVATA
FROM    TEMP.GUIDAPROMO A
INNER   JOIN ARCHIVI.OFFERTX2 B
ON      A.IDPROMO = B.`OFX2-DATAFI`
AND     A.FILIALE =  (select NEGOZIO from temp.riepvegi LIMIT 1)
AND     A.TREK    = B.`OFX2-CODSOC`
WHERE  (A.DAL    <= (select min(DATA  )  from temp.riepvegi) 
AND     A.AL     >= (select min(DATA  )  from temp.riepvegi) 
or      A.DAL    <= (select max(DATA  )  from temp.riepvegi) 
and     A.AL     >= (select max(DATA  )  from temp.riepvegi) 
or      A.DAL    >= (select min(DATA  )  from temp.riepvegi) 
AND     A.AL     <= (select mAX(DATA  )  from temp.riepvegi));


INSERT INTO TEMP.NEWOFFERTEINCORSO 
SELECT B.`TRX2-DATAFI`      AS IDPROMO,
       A.FILIALE            AS FILIALE,
       B.`TRX2-CODCIN`      AS ARTICOLO,
       A.DAL                AS DATAIN,
       A.AL                 AS DATAFI,
       B.`TRX2-PVIFOS-EURO` AS PVIFOS,
       B.`TRX2-PRENDI`      AS PRENDI,
       B.`TRX2-PAGHI`       AS PAGHI,
       B.`TRX2-TIPOLOGIA`   AS TIPOLOGIA,
       B.`TRX2-VALOREPAGHI` AS VALOREPAGHI,
        '       '          AS RISERVATA
FROM    TEMP.GUIDAPROMO A
INNER   JOIN ARCHIVI.OFFNXMX2 B
ON      A.IDPROMO = B.`TRX2-DATAFI`
AND     A.FILIALE =  (select NEGOZIO from temp.riepvegi LIMIT 1)
AND     A.TREK    = B.`TRX2-CODSOC`
WHERE  (A.DAL    <= (select min(DATA  )  from temp.riepvegi) 
AND     A.AL     >= (select min(DATA  )  from temp.riepvegi) 
or      A.DAL    <= (select max(DATA  )  from temp.riepvegi) 
and     A.AL     >= (select max(DATA  )  from temp.riepvegi) 
or      A.DAL    >= (select min(DATA  )  from temp.riepvegi) 
AND     A.AL     <= (select mAX(DATA  )  from temp.riepvegi));

ALTER TABLE TEMP.NEWOFFERTEINCORSO ADD PRIMARY KEY(ARTICOLO,DATAIN,DATAFI), ENGINE=MYISAM;

UPDATE TEMP.RIEPVEGI A
INNER JOIN TEMP.NEWOFFERTEINCORSO B
ON    A.ARTICOLO = B.ARTICOLO
SET   QTA_USC_OS = QTA_USC, 
      VAL_VEN_OS_E = VAL_VEN_CASSE_E,
      A.TIPOLOGIA  = B.TIPOLOGIA
WHERE  DATA   >= DATAIN
AND    DATA   <= DATAFI
and   QTA_USC_OS = 0
AND   VAL_VEN_OS_E = 0
AND   PRENDI = 0
AND   PAGHI  = 0;

UPDATE TEMP.RIEPVEGI A
INNER JOIN TEMP.NEWOFFERTEINCORSO B
ON    A.ARTICOLO = B.ARTICOLO
SET   QTA_USC_OS = (CASE
                    WHEN QTA_USC <= PRENDI THEN PRENDI
                    ELSE TRUNCATE((QTA_USC / PRENDI), 0) * PRENDI END),
      VAL_VEN_OS_E = (CASE
                     WHEN B.TIPOLOGIA = "NXM" THEN      
                                             (CASE
                                              WHEN QTA_USC <= PRENDI THEN PRENDI
                                              ELSE TRUNCATE((QTA_USC / PRENDI), 0) * PRENDI END * (`VALOREPAGHI` / PRENDI) * 100) 
                     WHEN B.TIPOLOGIA = "NXV" THEN  
                                             (CASE
                                              WHEN QTA_USC <= PRENDI THEN PRENDI
                                              ELSE TRUNCATE((QTA_USC / PRENDI), 0) * PRENDI END * (`VALOREPAGHI` / PRENDI) * 100) 
                     ELSE                    (CASE
                                              WHEN QTA_USC <= PRENDI THEN PRENDI
                                              ELSE TRUNCATE((QTA_USC / PRENDI), 0) * PRENDI END * VAL_VEN_CASSE_E / QTA_USC) 
                     END),
      A.TIPOLOGIA  = B.TIPOLOGIA                    
WHERE DATA   >= DATAIN
AND   DATA   <= DATAFI
AND   PRENDI <> 0
AND   QTANX  <> 0;

DROP TABLE IF EXISTS TEMP.RIEPVEGI_RIE;
CREATE TABLE TEMP.RIEPVEGI_RIE AS
SELECT NEGOZIO,
       ARTICOLO,
       BARCODE,
       DATA,              
       SUM(QTA_USC)                AS QTA_USC,
       SUM(QTA_USC_OS)             AS QTA_USC_OS,
       SUM(QTA_USC_SCO)            AS QTA_USC_SCO,
       SUM(VAL_VEN_CASSE_E)        AS VAL_VEN_CASSE_E,
       SUM(VAL_VEN_CED_E)          AS VAL_VEN_CED_E,
       SUM(VAL_VEN_LOC_E)          AS VAL_VEN_LOC_E,
       SUM(VAL_VEN_OS_E)           AS VAL_VEN_OS_E,
       SUM(VAL_VEN_SCO_E)          AS VAL_VEN_SCO_E,
       SEGNO_TIPO_PREZZO,  
       FORZAPRE,         
       REPARTO,          
       CODFOR            
FROM          TEMP.RIEPVEGI A
GROUP BY      NEGOZIO,  
              ARTICOLO, 
              BARCODE,  
              DATA
ORDER BY      NEGOZIO,
              ARTICOLO,
              BARCODE,
              DATA;
              
UPDATE TEMP.RIEPVEGI_RIE A
INNER  JOIN DIMENSIONI.ARTICOLO B
ON     A.ARTICOLO = B.CODICE_ARTICOLO
SET    A.CODFOR   = B.CODICE_FORNITORE;  

-- UPDATE TEMP.RIEPVEGI_RIE A
-- INNER JOIN TEMP.ANAGDAFIALL B
-- ON    A.NEGOZIO = B.`ADF-SONE`
-- AND   A.ARTICOLO = B.`ADF-CODCIN`
-- AND   A.DATA = B.`ADF-DATA-RIFERIMENTO`
-- SET   A.SEGNO_TIPO_PREZZO = B.`ADF-SEG-LIB-BLOC`;

update temp.riepvegi_rie a
inner join temp.anagdafiall b
on    a.negozio = b.`adf-sone`
and   a.articolo = b.`adf-codcin`
and   a.data = b.`adf-data-riferimento`
set   a.val_ven_ced_e  = round(a.qta_usc * b.`adf-prz-vend-dett-e`,0),
      a.val_ven_loc_e  = round(a.qta_usc * b.`adf-prz-vend-loc-e`,0),
      a.segno_tipo_prezzo = b.`adf-seg-lib-bloc`;

-- Storni a tasto reparto di vendite passate a scanner;
-- Perdo la qta uscita a tasto casse corretta ma ottengo un valore corretto di venduto

UPDATE TEMP.RIEPVEGI_RIE A
SET    A.QTA_USC = -1
WHERE  A.VAL_VEN_CASSE_E < 0
AND    A.QTA_USC         > 0
AND    A.BARCODE = 0;

CREATE TABLE IF NOT EXISTS TEMP.OUTRIEPVEGI AS
SELECT  LPAD(NEGOZIO,4,0) AS NEGOZIO,
        data AS DATA,
        CONCAT('0',
              LPAD(NEGOZIO,4,0),
              LPAD(ARTICOLO,7,0),
              LPAD(BARCODE,13,0),
              DATA,
              LPAD(ABS(ROUND((QTA_USC * 100),0)),11,0),
              LPAD(ABS(ROUND((QTA_USC_OS * 100),0)),11,0),
              LPAD(ABS(ROUND((QTA_USC_SCO * 100),0)),11,0),
              LPAD(ABS(ROUND((VAL_VEN_CASSE_E * 1936.27 / 100),0)),12,0),
              LPAD(ABS(ROUND((VAL_VEN_CED_E * 1936.27 / 100),0)),12,0),
              LPAD(ABS(ROUND((VAL_VEN_LOC_E * 1936.27 / 100),0)),12,0),
              LPAD(ABS(ROUND((VAL_VEN_OS_E * 1936.27 / 100),0)),12,0),
              SEGNO_TIPO_PREZZO,
              FORZAPRE,
              '0000',
              LPAD(ABS(ROUND((VAL_VEN_SCO_E * 1936.27 / 100),0)),6,0),
              LPAD(ABS((VAL_VEN_CASSE_E)),12,0),
              LPAD(ABS((VAL_VEN_CED_E)),12,0),
              LPAD(ABS((VAL_VEN_LOC_E)),12,0),
              LPAD(ABS((VAL_VEN_OS_E)),12,0),
              LPAD(ABS((VAL_VEN_SCO_E)),12,0),
              REPARTO,
              CODFOR,
              '00000',
              CASE WHEN VAL_VEN_CASSE_E < 0     AND QTA_USC <= 0 THEN "R" ELSE "0" END) AS RIEPVEGI_RECORD
FROM          TEMP.RIEPVEGI_RIE A
GROUP BY      NEGOZIO,
              ARTICOLO,
              BARCODE,
              DATA
ORDER BY      NEGOZIO,
              ARTICOLO,
              BARCODE,
              DATA;
              
select      distinct
            @mystm:=  concat("SELECT RIEPVEGI_RECORD from TEMP.OUTRIEPVEGI into outfile 'C:/IT/ETL/NCR/Datacollect/Riepvegi/Temp/NUL_NO-EMAIL_",
                            DATE_FORMAT(now(),'%Y%m%d%h%i%s'),
                            "_DC-ASAR-RIEPVEGI_",
                            NEGOZIO,
                            "_",
                            DATA,
                            ".TXT'")
FROM        TEMP.OUTRIEPVEGI;

prepare stm from @mystm; 
execute     stm;
DEALLOCATE PREPARE stm;               

-- delete from trasmissioni.job where tipo = 10 and (todo = 0 or enabled = 0);
