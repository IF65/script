delete from etl.sql_script where id = 'STATISTICHE_DC';

insert into etl.sql_script values
("STATISTICHE_DC", 10, "C:/IT/ETL/ncr/STATISTICHE_DC/sql/SVUOTA_TABELLA_INCASSI_LAST.SQL"       , 1),
("STATISTICHE_DC", 20, "C:/IT/ETL/ncr/STATISTICHE_DC/sql/POPOLA_TABELLA_INCASSI_LAST.SQL"       , 1),
("STATISTICHE_DC", 30, "C:/IT/ETL/ncr/STATISTICHE_DC/sql/AGGIORNA_STATISTICHE.SQL"              , 1),
("STATISTICHE_DC", 40, "C:/IT/ETL/ncr/STATISTICHE_DC/sql/RIMUOVI_TABELLA_SCONTRINI_LAST.SQL"    , 1),
("STATISTICHE_DC", 50, "C:/IT/ETL/ncr/STATISTICHE_DC/sql/POPOLA_TABELLA_SCONTRINI_LAST.SQL"     , 1),
("STATISTICHE_DC", 60, "C:/IT/ETL/ncr/STATISTICHE_DC/sql/AGGIORNA_SCONTRINI.SQL"                , 1);




perl C:\IT\Bin\Table2Email.pl -i C:\IT\Bin\Table2Email_10.11.14.44.ini  -t DATACOLLECT_MANCANTI


update etl.excel_report
set 
       template = replace(lower(  template),'italmark', 'it'),
     excel_file = replace(lower(excel_file),'italmark', 'it'),
       txt_file = replace(lower(  txt_file),'italmark', 'it');