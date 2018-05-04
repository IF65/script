replace into ncr.vendite_speciali
-- drop table if exists ncr.vendite_speciali;
-- create table if not exists ncr.vendite_speciali as
select  DATADC,
        NEGOZIO,
        ARTICOLO,
        count(distinct  NUMCASSA, TRANSAZIONE) 
                                    as SCONTRINI,
        sum(QTA_VENDUTA    )        as QTA_VENDUTA,
        sum(case when TESSERA <> '' then 1 else 0 end * QTA_VENDUTA) 
                                    as QTA_VENDUTA_TESSERA,
        sum(VALORE_LORDO   )/100    as VALORE_LORDO,
        sum(VALORE_NETTO   )/100    as VALORE_NETTO,
        sum(0)                      as FL01,
        sum(0*QTA_VENDUTA)          as QFL01,
        sum(FLAG02)                 as FL02,
        sum(FLAG02*QTA_VENDUTA)     as QFL02,
        sum(FLAG03)                 as FL03,
        sum(FLAG03*QTA_VENDUTA)     as QFL03,
        sum(FLAG04)                 as FL04,
        sum(FLAG04*QTA_VENDUTA)     as QFL04,
        sum(FLAG05)                 as FL05,
        sum(FLAG05*QTA_VENDUTA)     as QFL05,
        sum(FLAG06)                 as FL06,
        sum(FLAG06*QTA_VENDUTA)     as QFL06,
        sum(FLAG07)                 as FL07,
        sum(FLAG07*QTA_VENDUTA)     as QFL07,
        sum(FLAG08)                 as FL08,
        sum(FLAG08*QTA_VENDUTA)     as QFL08,
        sum(FLAG09)                 as FL09,
        sum(FLAG09*QTA_VENDUTA)     as QFL09,
        sum(FLAG10)                 as FL10,      
        sum(FLAG10*QTA_VENDUTA)     as QFL10         
from    ncr.datacollect_rich
group by DATADC,
        SOCNEG,
        articolo
having  FL01 <> 0 or
        FL02 <> 0 or
        FL03 <> 0 or
        FL04 <> 0 or
        FL05 <> 0 or
        FL06 <> 0 or
        FL07 <> 0 or
        FL08 <> 0 or
        FL09 <> 0 or
        FL10 <> 0 ;