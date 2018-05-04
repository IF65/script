#!/perl/bin/perl
use strict;     # pragma che dice all'interprete di essere rigido nel controllo della sintassi
use warnings;   # pragma che dice all'interprete di mostrare eventuali warnings
use DBI;        # permette di comunicare con il database
#use DBD::Oracle;
use DateTime;
		
# Apertura connessione con il database Oracle
#---------------------------------------------------------------------------------------------
my $dbh = DBI->connect('dbi:Oracle:',q{visora/visora@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST= 11.0.1.81)(PORT=1521))
										(CONNECT_DATA=(SERVICE_NAME=orcl)))},"") or die;


# Preparazione della query "timbrature"
#---------------------------------------------------------------------------------------------
my $sth_timbrature = $dbh->prepare(qq{SELECT     DWA_PRIMTABLE.ID_PERIOD,
                 PERSON.ID_PERSON,
                 PERSON.NME_LASTNAME,
                 PERSON.NME_FIRSTNAME,
                 DWA_PRIMTABLE.COD_EMPLOYEEID,
                 LOCATION.ID_LOCATION,
                 DWA_PRIMTABLE.CODFULL_LOCATION,
                 EVCHGLOC.ID_EVCHANGE as ID_EVCHANGE_LOC,
                 EMPLOYMENTTYPE.ID_EMPTYPE,
                 DWA_PRIMTABLE.ID_EVEMPTP,
                 STATUS.ID_STATUS,
                 DWA_PRIMTABLE.COD_STATUS,
                 EVCHGST.ID_EVCHANGE as ID_EVCHANGE_ST,
                 DWA_PRIMTABLE.COD_CDCREL,
                 CDCREL.ID_CDCREL,
                 EVCHGCDC.ID_EVCHANGE as ID_EVCHANGE_CDC,
                 JOBASSIGN.ID_JOBASSIGN,
                 DWA_PRIMTABLE.COD_JOB,
                 EVCHGJOB.ID_EVCHANGE as ID_EVCHANGE_JOB,
                 DWA_PRIMTABLE.ID_COMPBAND,
                 CONTRACTTYPE.ID_CONTRACTTYPE,
                 DWA_PRIMTABLE.COD_CONTRACTTYPE,
                 EVCHGCT.ID_EVCHANGE as ID_EVCHANGE_CT,
                 ORGPOS.ID_ORGPOS,
                 DWA_PRIMTABLE.CODFULL_ORGPOS,
                 EVCHGORGPOS.ID_EVCHANGE as ID_EVCHANGE_POS,
                 CONTRACT.ID_CONTRACT,
                 DWA_PRIMTABLE.CODFULL_COMPENS_LEVEL,
                 EVCHGCONTR.ID_EVCHANGE as ID_EVCHANGE_CNTR,
                 JOBCLASS.ID_JOBCLASS,
                 DWA_PRIMTABLE.COD_JOBCLASS,
                 EVCHGJOBCLS.ID_EVCHANGE as ID_EVCHANGE_JCLS,
                 DWA_PRIMTABLE.ID_ASSTYPE,
                 DWA_PRIMTABLE.ID_PFMRATING1,
                 DWA_PRIMTABLE.ID_PFMRATING2,
                 DWA_PRIMTABLE.COD_COMPANY,
                 COMPANY.ID_COMPANY
FROM         DWA_PRIMTABLE LEFT OUTER JOIN
                      LOCATION ON DWA_PRIMTABLE.CODFULL_LOCATION = LOCATION.COD_COMPANY || ':' || LOCATION.COD_LOCATION LEFT OUTER JOIN
                      PERSON ON DWA_PRIMTABLE.COD_EMPLOYEEID = PERSON.COD_EMPLOYEEID LEFT OUTER JOIN
                      EMPLOYMENTTYPE ON DWA_PRIMTABLE.COD_EMPTYPE = EMPLOYMENTTYPE.COD_EMPTYPE LEFT OUTER JOIN
                      EVCHGLOC ON DWA_PRIMTABLE.COD_EVLOC = EVCHGLOC.COD_EVCHANGE LEFT OUTER JOIN
                      STATUS ON DWA_PRIMTABLE.COD_STATUS = STATUS.COD_STATUS LEFT OUTER JOIN
                      JOBASSIGN ON DWA_PRIMTABLE.COD_JOB = JOBASSIGN.COD_JOB LEFT OUTER JOIN
                      EVCHGCONTR ON DWA_PRIMTABLE.ID_EVCONTR = EVCHGCONTR.COD_EVCHANGE LEFT OUTER JOIN
                      V_XCDCREL2 ON DWA_PRIMTABLE.COD_CDCREL2 = V_XCDCREL2.COD_RESPCENTER LEFT OUTER JOIN
                      EVCHGORGPOS ON DWA_PRIMTABLE.COD_EVORGPOS = EVCHGORGPOS.COD_EVCHANGE LEFT OUTER JOIN
                      EVCHGCDC ON DWA_PRIMTABLE.COD_EVCDCREL = EVCHGCDC.COD_EVCHANGE LEFT OUTER JOIN
                      EVCHGCT ON DWA_PRIMTABLE.COD_EVCRTYPE = EVCHGCT.COD_EVCHANGE LEFT OUTER JOIN
                      COMPANY ON DWA_PRIMTABLE.COD_COMPANY = COMPANY.COD_COMPANY LEFT OUTER JOIN
                      EVCHGJOBCLS ON DWA_PRIMTABLE.COD_EVJOBCLS = EVCHGJOBCLS.COD_EVCHANGE LEFT OUTER JOIN
                      CONTRACTTYPE ON DWA_PRIMTABLE.COD_CONTRACTTYPE = CONTRACTTYPE.COD_CONTRACTTYPE LEFT OUTER JOIN
                      JOBCLASS ON DWA_PRIMTABLE.COD_JOBCLASS = JOBCLASS.COD_JOBCLASS LEFT OUTER JOIN
                      ORGPOS ON DWA_PRIMTABLE.CODFULL_ORGPOS = ORGPOS.COD_ORGUNIT || ':' || ORGPOS.COD_ORGPOS LEFT OUTER JOIN
                      CDCREL ON DWA_PRIMTABLE.COD_CDCREL = CDCREL.COD_RESPCENTER LEFT OUTER JOIN
                      EVCHGST ON DWA_PRIMTABLE.COD_EVSTATUS = EVCHGST.COD_EVCHANGE LEFT OUTER JOIN
                      EVCHGJOB ON DWA_PRIMTABLE.ID_EVJOB = EVCHGJOB.COD_EVCHANGE LEFT OUTER JOIN
                      CONTRACT ON
                      DWA_PRIMTABLE.CODFULL_COMPENS_LEVEL = CONTRACT.COD_CATEGORY_CNTR || ':' || CONTRACT.COD_COMPENS_CNTR || ':' || CONTRACT.COD_COMPENS_LEVEL});

# Esecuzione del query e scrittura dati sul file di interscambio 
#---------------------------------------------------------------------------------------------
if ($sth_timbrature->execute()) {
	while ( my @row = $sth_timbrature->fetchrow_array() ) {
		print "$row[0]\t";
	}
}

