drop table if exists temp.anagrafica_negozi_csv;
create table temp.anagrafica_negozi_csv (
       data_riferimento   varchar(8)    default '00000000',
       sone               varchar(4)    default '0000',
       codcin             varchar(7)    default 0,
       seg_lib_bloc       varchar(1)    default ' ',
       seg_os_det         varchar(1)    default ' ',
       DATA_FINE_OS       varchar(8)    default '00000000',   
       PRENDI             decimal(2)    default 0,
       PAGHI              decimal(2)    default 0,
       VALORIPRENDI       decimal(7)    default 0,
       VALORIPAGHI        decimal(7)    default 0,
       PRZ_CATALOGO_NIMIS decimal(6)    default 0,
       PRZ_OS_DET_E       decimal(7)    default 0,
       TIPO_OS            varchar(2)    default '  ',
       TIPOLOS            varchar(3)    default '   ',
       SCPMXN             decimal(3)    default 0,
       SCVALMXN           decimal(7)    default 0,
       PUNTIAGG           varchar(4)    default '0000',
       SEGNONIMISNXM      varchar(1)    default ' ',
       SEGNO_BOLL         varchar(1)    default ' ',
       N_BOLL             varchar(5)    default '00000',
       SEG_ELIM           varchar(1)    default '0',
       PRZ_VEND_DETT_E    decimal(7)    default 0,
       PRZ_VEND_LOC_E     decimal(7)    default 0,
       PRZ_LISTLOC        decimal(7)    default 0)   engine=myisam;
       
load data infile        "C:/Italmark/REPORT/ANAGDAFI.CSV" 
into table              temp.anagrafica_negozi_csv 
FIELDS TERMINATED BY ';'
LINES TERMINATED  BY '\r\n';
      
drop table if exists temp.anagrafica_negozi;

create table temp.anagrafica_negozi like temp.anagrafica_negozi_csv;

alter table temp.anagrafica_negozi add primary key(data_riferimento,sone,codcin), engine=myisam;

replace into temp.anagrafica_negozi
select * from temp.anagrafica_negozi_csv;

update temp.anagrafica_negozi
set    seg_lib_bloc = (case when seg_lib_bloc = "0" OR " " THEN "L"   ELSE seg_lib_bloc END),
       seg_os_det   = (case when seg_os_det   = "0"        THEN " "   ELSE seg_os_det   END),
       TIPOLOS      = (case when TIPOLOS      = "000"      THEN "   " ELSE TIPOLOS      END),
       SEGNO_BOLL   = (case when SEGNO_BOLL   = "0"        THEN " "   ELSE SEGNO_BOLL   END);


----------------- DA CANCELLARE       
       
update temp.anagrafica_negozi
set    sone  = '0184',
       data_riferimento = '20131029',
       seg_os_det = "P";
       
update temp.riepvegi_rie     a
inner join temp.anagrafica_negozi b
on    a.negozio = b.SONE
and   a.data    = b.data_riferimento
and   a.articolo = b.codcin
set   a.segno_tipo_prezzo = b.seg_lib_bloc,
      a.val_ven_ced_e     = round(a.qta_usc * b.PRZ_VEND_DETT_E,0),
      a.val_ven_loc_e     = round(a.qta_usc * b.PRZ_VEND_LOC_E,0);
      
UPDATE temp.riepvegi_rie     a
INNER  JOIN temp.anagrafica_negozi b
on     a.negozio      = b.SONE
and    a.data         = b.data_riferimento
and    a.articolo     = b.codcin
SET    a.QTA_USC_OS   = a.QTA_USC, 
       a.VAL_VEN_OS_E = a.VAL_VEN_CASSE_E
WHERE  qta_usc_os     = 0
and    val_ven_os_e   = 0  
and    b.seg_os_det   = "P";    