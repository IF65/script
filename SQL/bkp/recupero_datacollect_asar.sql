delete from trasmissioni.job where tipo = 2 AND success = 1;

insert  into trasmissioni.job(idhost, tipo, REM_FILE)
select	idhost, 2, CONCAT(case 
                          when TIME_FORMAT(now(), '%H%i%s') >= 200000
                          then DATE_FORMAT(now(), '%y%m%d')
                          else DATE_FORMAT(date_sub(now(), interval 1 day),'%y%m%d')
                          end, 
                          '_dc.txt')
from    trasmissioni.host 
where   societa in ('01')
and     abilita = 1;
        
update  trasmissioni.job
set     USER        = "italfrutta",
        PASSWORD    = "italfrutta",
        LOC_DIR     = "C:/IT/etl/ncr/datacollect/hocidc/temp/",
        LOC_FILE    = "[SOC][NEG]_[YYYY][MM][DD]_[FILE]",
        ACTION      = 'DOWNLOAD',
        REM_DIR     = "hocidc",
        ENABLED     = 1,
        TODO        = 1
where   tipo=2;