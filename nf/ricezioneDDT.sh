#!/bin/bash

export PERL5LIB=/root/perl5/lib/perl5

#carico MT
perl /script/nf/ricezioneDDT_MT.pl

#carico COPRE
perl /script/nf/ricezioneDDT_COPRE.pl

#carico opportunity (emmelibri)
perl /script/nf/ricezioneArticoli_OPPORTUNITY.pl
perl /script/nf/ricezioneDDT_OPPORTUNITY.pl