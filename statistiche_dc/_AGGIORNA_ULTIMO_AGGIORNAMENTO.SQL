update	ncr.ultimo_aggiornamento
set		ultimo_inserimento_vendite_catalogo = 
(select max(data_inserimento) from ncr.vendite_catalogo);