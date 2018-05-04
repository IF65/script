delete from trasmissioni.job where tipo = 12;
update  trasmissioni.job
set     tipo = 12,    
        LOC_DIR     = "",
        LOC_FILE    = "",
        ACTION      = 'DELETE',
        ENABLED     = 1,
        TODO        = 1,
        SUCCESS     = 0,
        LAST_RUN    = "",
        ERROR_MSG   = ""
where   tipo=11
AND     SUCCESS=1;

update trasmissioni.job a
inner join trasmissioni.job b
on      a.idhost = b.idhost
and     b.tipo = 2
and     b.success = 0
and     b.todo = 1
and     b.enabled = 1
and     a.tipo = 12
set     a.todo = 0,
        a.enabled = 0,
        a.success = 0;