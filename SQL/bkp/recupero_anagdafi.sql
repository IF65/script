delete from trasmissioni.job where tipo = 11;

insert  into trasmissioni.job(idhost, tipo, REM_FILE)
select  idhost, 
        11,     
        'ANAGDAFI.CSV' 
from    trasmissioni.host 
where   societa in ('01')
and     abilita = 1;        
        
update  trasmissioni.job
set     USER        = "italfrutta",
        PASSWORD    = "italfrutta",
        LOC_DIR     = "C:/IT/etl/ncr/datacollect/anagdafi/",
        LOC_FILE    = "[SOC][NEG]_[YYYY][MM][DD]_[FILE]",
        ACTION      = 'DOWNLOAD',
        REM_DIR     = "hocidc",
        ENABLED     = 1,
        TODO        = 1
where   tipo=11;

