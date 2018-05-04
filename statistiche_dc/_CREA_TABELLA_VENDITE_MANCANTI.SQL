create table if not exists	ncr.vendite_mancanti as
select 			V.* 
from 			ncr.vendite_catalogo		V
inner join  	ncr.ultimo_aggiornamento	U
on				V.data_inserimento > U.ultimo_inserimento_chiusura_prenotazioni
where			substr(V.articolo,1,3) >= 934
and				substr(articolo,1,3) <= 943;