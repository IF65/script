delete from trasmissioni.job where tipo = 2 AND success = 1;

insert  into trasmissioni.job(idhost, tipo, REM_FILE, USER, PASSWORD, REM_DIR, LOC_FILE)
select	idhost, 
        2, 
        CONCAT(case 
                          when TIME_FORMAT(now(), '%H%i%s') >= 200000
                          then DATE_FORMAT(now(), '%y%m%d')
                          else DATE_FORMAT(date_sub(now(), interval 1 day),'%y%m%d')
                          end, 
                          case when societa = '01' then '_dc.txt' else '.idc' end),
        case when societa = '01' then "italfrutta" else "nimis" end,
        case when societa = '01' then "italfrutta" else "nimis" end,
        case when societa = '01' then "hocidc" else "" end,
        concat("[SOC][NEG]_[YYYY][MM][DD]_", 
            CONCAT(case 
                          when TIME_FORMAT(now(), '%H%i%s') >= 200000
                          then DATE_FORMAT(now(), '%y%m%d')
                          else DATE_FORMAT(date_sub(now(), interval 1 day),'%y%m%d')
                          end, 
                          '_dc.txt'))
from    trasmissioni.host 
where   societa in ('01','30','31','36')
and     abilita = 1;
        
update  trasmissioni.job
set     LOC_DIR     = "C:/IT/etl/ncr/datacollect/hocidc/temp/",
        ACTION      = 'DOWNLOAD',
        ENABLED     = 1,
        TODO        = 1
where   tipo=2;