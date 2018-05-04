delete archivi.`riepvegi` from archivi.`riepvegi` join 
(select distinct substr(`NEGOZIO`,1,2) as `societa`,substr(`NEGOZIO`,3,2) as `negozio`,str_to_date(`DATA`,'%Y%m%d') as `data` from rvg.`RIEPVEGI_RIE`) as rr
on archivi.`riepvegi`.`RVG-CODSOC`=rr.`societa` and archivi.`riepvegi`.`RVG-CODNEG`=rr.`negozio` and archivi.`riepvegi`.`RVG-DATA`=rr.`data`;

insert into archivi.`riepvegi` 
	(`RVG-CODSOC`,`RVG-CODNEG`,`RVG-CODICE`,`RVG-CODBARRE`,`RVG-DATA`,`RVG-QTA-USC`,`RVG-QTA-USC-OS`,`RVG-QTA-USC-SCO`,`RVG-VAL-VEN-CASSE-E`
	,`RVG-VAL-VEN-CED-E`,`RVG-VAL-VEN-LOC-E`,`RVG-VAL-VEN-OS-E`,`RVG-VAL-VEN-SCO-E`,`RVG-SEGNO-TIPO-PREZZO`,`RVG-FORZAPRE`,`RVG-REPARTO`,`RVG-CODFOR`)
SELECT SUBSTR(`NEGOZIO`,1,2) AS `SOCIETA`,SUBSTR(`NEGOZIO`,3,2) AS `NEGOZIO`,ARTICOLO,BARCODE,STR_TO_DATE(`DATA`,'%Y%m%d') AS `DATA`,QTA_USC,QTA_USC_OS,QTA_USC_SCO,
	VAL_VEN_CASSE_E/100,VAL_VEN_CED_E/100,VAL_VEN_LOC_E/100,VAL_VEN_OS_E/100,VAL_VEN_SCO_E/100,SEGNO_TIPO_PREZZO,FORZAPRE,REPARTO,CODFOR
FROM rvg.RIEPVEGI_RIE;
