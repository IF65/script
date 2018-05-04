#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5
	
perl /script/consolidatiAggiornamento.pl #1>/dev/null 2>/dev/null

perl /script/aggiornamentoOre.pl #1>/dev/null 2>/dev/null
