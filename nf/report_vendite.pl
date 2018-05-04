#!/usr/bin/perl -w
use strict;
use File::HomeDir;
use Getopt::Long;
use Excel::Writer::XLSX;
use Excel::Writer::XLSX::Utility;
use DBI;
use DateTime;

# calendario
#------------------------------------------------------------------------------------------------------------
my %settimane_gfk = (
					'201301' => { anno => 2013, mese => 1, settimana => 1, inizio => '2012-12-31', fine => '2013-01-06'},
					'201302' => { anno => 2013, mese => 1, settimana => 2, inizio => '2013-01-07', fine => '2013-01-13'},
					'201303' => { anno => 2013, mese => 1, settimana => 3, inizio => '2013-01-14', fine => '2013-01-20'},
					'201304' => { anno => 2013, mese => 1, settimana => 4, inizio => '2013-01-21', fine => '2013-01-27'},
					'201305' => { anno => 2013, mese => 2, settimana => 5, inizio => '2013-01-28', fine => '2013-02-03'},
					'201306' => { anno => 2013, mese => 2, settimana => 6, inizio => '2013-02-04', fine => '2013-02-10'},
					'201307' => { anno => 2013, mese => 2, settimana => 7, inizio => '2013-02-11', fine => '2013-02-17'},
					'201308' => { anno => 2013, mese => 2, settimana => 8, inizio => '2013-02-18', fine => '2013-02-24'},
					'201309' => { anno => 2013, mese => 2, settimana => 9, inizio => '2013-02-25', fine => '2013-03-03'},
					'201310' => { anno => 2013, mese => 3, settimana => 10, inizio => '2013-03-04', fine => '2013-03-10'},
					'201311' => { anno => 2013, mese => 3, settimana => 11, inizio => '2013-03-11', fine => '2013-03-17'},
					'201312' => { anno => 2013, mese => 3, settimana => 12, inizio => '2013-03-18', fine => '2013-03-24'},
					'201313' => { anno => 2013, mese => 3, settimana => 13, inizio => '2013-03-25', fine => '2013-03-31'},
					'201314' => { anno => 2013, mese => 4, settimana => 14, inizio => '2013-04-01', fine => '2013-04-07'},
					'201315' => { anno => 2013, mese => 4, settimana => 15, inizio => '2013-04-08', fine => '2013-04-14'},
					'201316' => { anno => 2013, mese => 4, settimana => 16, inizio => '2013-04-15', fine => '2013-04-21'},
					'201317' => { anno => 2013, mese => 4, settimana => 17, inizio => '2013-04-22', fine => '2013-04-28'},
					'201318' => { anno => 2013, mese => 5, settimana => 18, inizio => '2013-04-29', fine => '2013-05-05'},
					'201319' => { anno => 2013, mese => 5, settimana => 19, inizio => '2013-05-06', fine => '2013-05-12'},
					'201320' => { anno => 2013, mese => 5, settimana => 20, inizio => '2013-05-13', fine => '2013-05-19'},
					'201321' => { anno => 2013, mese => 5, settimana => 21, inizio => '2013-05-20', fine => '2013-05-26'},
					'201322' => { anno => 2013, mese => 5, settimana => 22, inizio => '2013-05-27', fine => '2013-06-02'},
					'201323' => { anno => 2013, mese => 6, settimana => 23, inizio => '2013-06-03', fine => '2013-06-09'},
					'201324' => { anno => 2013, mese => 6, settimana => 24, inizio => '2013-06-10', fine => '2013-06-16'},
					'201325' => { anno => 2013, mese => 6, settimana => 25, inizio => '2013-06-17', fine => '2013-06-23'},
					'201326' => { anno => 2013, mese => 6, settimana => 26, inizio => '2013-06-24', fine => '2013-06-30'},
					'201327' => { anno => 2013, mese => 7, settimana => 27, inizio => '2013-07-01', fine => '2013-07-07'},
					'201328' => { anno => 2013, mese => 7, settimana => 28, inizio => '2013-07-08', fine => '2013-07-14'},
					'201329' => { anno => 2013, mese => 7, settimana => 29, inizio => '2013-07-15', fine => '2013-07-21'},
					'201330' => { anno => 2013, mese => 7, settimana => 30, inizio => '2013-07-22', fine => '2013-07-28'},
					'201331' => { anno => 2013, mese => 8, settimana => 31, inizio => '2013-07-29', fine => '2013-08-04'},
					'201332' => { anno => 2013, mese => 8, settimana => 32, inizio => '2013-08-05', fine => '2013-08-11'},
					'201333' => { anno => 2013, mese => 8, settimana => 33, inizio => '2013-08-12', fine => '2013-08-18'},
					'201334' => { anno => 2013, mese => 8, settimana => 34, inizio => '2013-08-19', fine => '2013-08-25'},
					'201335' => { anno => 2013, mese => 8, settimana => 35, inizio => '2013-08-26', fine => '2013-09-01'},
					'201336' => { anno => 2013, mese => 9, settimana => 36, inizio => '2013-09-02', fine => '2013-09-08'},
					'201337' => { anno => 2013, mese => 9, settimana => 37, inizio => '2013-09-09', fine => '2013-09-15'},
					'201338' => { anno => 2013, mese => 9, settimana => 38, inizio => '2013-09-16', fine => '2013-09-22'},
					'201339' => { anno => 2013, mese => 9, settimana => 39, inizio => '2013-09-23', fine => '2013-09-29'},
					'201340' => { anno => 2013, mese => 10, settimana => 40, inizio => '2013-09-30', fine => '2013-10-06'},
					'201341' => { anno => 2013, mese => 10, settimana => 41, inizio => '2013-10-07', fine => '2013-10-13'},
					'201342' => { anno => 2013, mese => 10, settimana => 42, inizio => '2013-10-14', fine => '2013-10-20'},
					'201343' => { anno => 2013, mese => 10, settimana => 43, inizio => '2013-10-21', fine => '2013-10-27'},
					'201344' => { anno => 2013, mese => 11, settimana => 44, inizio => '2013-10-28', fine => '2013-11-03'},
					'201345' => { anno => 2013, mese => 11, settimana => 45, inizio => '2013-11-04', fine => '2013-11-10'},
					'201346' => { anno => 2013, mese => 11, settimana => 46, inizio => '2013-11-11', fine => '2013-11-17'},
					'201347' => { anno => 2013, mese => 11, settimana => 47, inizio => '2013-11-18', fine => '2013-11-24'},
					'201348' => { anno => 2013, mese => 11, settimana => 48, inizio => '2013-11-25', fine => '2013-12-01'},
					'201349' => { anno => 2013, mese => 12, settimana => 49, inizio => '2013-12-02', fine => '2013-12-08'},
					'201350' => { anno => 2013, mese => 12, settimana => 50, inizio => '2013-12-09', fine => '2013-12-15'},
					'201351' => { anno => 2013, mese => 12, settimana => 51, inizio => '2013-12-16', fine => '2013-12-22'},
					'201352' => { anno => 2013, mese => 12, settimana => 52, inizio => '2013-12-23', fine => '2013-12-29'},
					'201401' => { anno => 2014, mese => 1, settimana => 1, inizio => '2013-12-30', fine => '2014-01-05'},
					'201402' => { anno => 2014, mese => 1, settimana => 2, inizio => '2014-01-06', fine => '2014-01-12'},
					'201403' => { anno => 2014, mese => 1, settimana => 3, inizio => '2014-01-13', fine => '2014-01-19'},
					'201404' => { anno => 2014, mese => 1, settimana => 4, inizio => '2014-01-20', fine => '2014-01-26'},
					'201405' => { anno => 2014, mese => 1, settimana => 5, inizio => '2014-01-27', fine => '2014-02-02'},
					'201406' => { anno => 2014, mese => 2, settimana => 6, inizio => '2014-02-03', fine => '2014-02-09'},
					'201407' => { anno => 2014, mese => 2, settimana => 7, inizio => '2014-02-10', fine => '2014-02-16'},
					'201408' => { anno => 2014, mese => 2, settimana => 8, inizio => '2014-02-17', fine => '2014-02-23'},
					'201409' => { anno => 2014, mese => 2, settimana => 9, inizio => '2014-02-24', fine => '2014-03-02'},
					'201410' => { anno => 2014, mese => 3, settimana => 10, inizio => '2014-03-03', fine => '2014-03-09'},
					'201411' => { anno => 2014, mese => 3, settimana => 11, inizio => '2014-03-10', fine => '2014-03-16'},
					'201412' => { anno => 2014, mese => 3, settimana => 12, inizio => '2014-03-17', fine => '2014-03-23'},
					'201413' => { anno => 2014, mese => 3, settimana => 13, inizio => '2014-03-24', fine => '2014-03-30'},
					'201414' => { anno => 2014, mese => 4, settimana => 14, inizio => '2014-03-31', fine => '2014-04-06'},
					'201415' => { anno => 2014, mese => 4, settimana => 15, inizio => '2014-04-07', fine => '2014-04-13'},
					'201416' => { anno => 2014, mese => 4, settimana => 16, inizio => '2014-04-14', fine => '2014-04-20'},
					'201417' => { anno => 2014, mese => 4, settimana => 17, inizio => '2014-04-21', fine => '2014-04-27'},
					'201418' => { anno => 2014, mese => 5, settimana => 18, inizio => '2014-04-28', fine => '2014-05-04'},
					'201419' => { anno => 2014, mese => 5, settimana => 19, inizio => '2014-05-05', fine => '2014-05-11'},
					'201420' => { anno => 2014, mese => 5, settimana => 20, inizio => '2014-05-12', fine => '2014-05-18'},
					'201421' => { anno => 2014, mese => 5, settimana => 21, inizio => '2014-05-19', fine => '2014-05-25'},
					'201422' => { anno => 2014, mese => 5, settimana => 22, inizio => '2014-05-26', fine => '2014-06-01'},
					'201423' => { anno => 2014, mese => 6, settimana => 23, inizio => '2014-06-02', fine => '2014-06-08'},
					'201424' => { anno => 2014, mese => 6, settimana => 24, inizio => '2014-06-09', fine => '2014-06-15'},
					'201425' => { anno => 2014, mese => 6, settimana => 25, inizio => '2014-06-16', fine => '2014-06-22'},
					'201426' => { anno => 2014, mese => 6, settimana => 26, inizio => '2014-06-23', fine => '2014-06-29'},
					'201427' => { anno => 2014, mese => 7, settimana => 27, inizio => '2014-06-30', fine => '2014-07-06'},
					'201428' => { anno => 2014, mese => 7, settimana => 28, inizio => '2014-07-07', fine => '2014-07-13'},
					'201429' => { anno => 2014, mese => 7, settimana => 29, inizio => '2014-07-14', fine => '2014-07-20'},
					'201430' => { anno => 2014, mese => 7, settimana => 30, inizio => '2014-07-21', fine => '2014-07-27'},
					'201431' => { anno => 2014, mese => 7, settimana => 31, inizio => '2014-07-28', fine => '2014-08-03'},
					'201432' => { anno => 2014, mese => 8, settimana => 32, inizio => '2014-08-04', fine => '2014-08-10'},
					'201433' => { anno => 2014, mese => 8, settimana => 33, inizio => '2014-08-11', fine => '2014-08-17'},
					'201434' => { anno => 2014, mese => 8, settimana => 34, inizio => '2014-08-18', fine => '2014-08-24'},
					'201435' => { anno => 2014, mese => 8, settimana => 35, inizio => '2014-08-25', fine => '2014-08-31'},
					'201436' => { anno => 2014, mese => 9, settimana => 36, inizio => '2014-09-01', fine => '2014-09-07'},
					'201437' => { anno => 2014, mese => 9, settimana => 37, inizio => '2014-09-08', fine => '2014-09-14'},
					'201438' => { anno => 2014, mese => 9, settimana => 38, inizio => '2014-09-15', fine => '2014-09-21'},
					'201439' => { anno => 2014, mese => 9, settimana => 39, inizio => '2014-09-22', fine => '2014-09-28'},
					'201440' => { anno => 2014, mese => 10, settimana => 40, inizio => '2014-09-29', fine => '2014-10-05'},
					'201441' => { anno => 2014, mese => 10, settimana => 41, inizio => '2014-10-06', fine => '2014-10-12'},
					'201442' => { anno => 2014, mese => 10, settimana => 42, inizio => '2014-10-13', fine => '2014-10-19'},
					'201443' => { anno => 2014, mese => 10, settimana => 43, inizio => '2014-10-20', fine => '2014-10-26'},
					'201444' => { anno => 2014, mese => 10, settimana => 44, inizio => '2014-10-27', fine => '2014-11-02'},
					'201445' => { anno => 2014, mese => 11, settimana => 45, inizio => '2014-11-03', fine => '2014-11-09'},
					'201446' => { anno => 2014, mese => 11, settimana => 46, inizio => '2014-11-10', fine => '2014-11-16'},
					'201447' => { anno => 2014, mese => 11, settimana => 47, inizio => '2014-11-17', fine => '2014-11-23'},
					'201448' => { anno => 2014, mese => 11, settimana => 48, inizio => '2014-11-24', fine => '2014-11-30'},
					'201449' => { anno => 2014, mese => 12, settimana => 49, inizio => '2014-12-01', fine => '2014-12-07'},
					'201450' => { anno => 2014, mese => 12, settimana => 50, inizio => '2014-12-08', fine => '2014-12-14'},
					'201451' => {anno => 2014, mese => 12, settimana => 51, inizio => '2014-12-15', fine => '2014-12-21'},
					'201452' => {anno => 2014, mese => 12, settimana => 52, inizio => '2014-12-22', fine => '2014-12-28'},
					'201453' => {anno => 2014, mese => 12, settimana => 53, inizio => '2014-12-22', fine => '2014-12-28'},
					'201501' => {anno => 2015, mese => 1, settimana => 1, inizio => '2014-12-29', fine => '2015-01-04'},
					'201502' => {anno => 2015, mese => 1, settimana => 2, inizio => '2015-01-05', fine => '2015-01-11'},
					'201503' => {anno => 2015, mese => 1, settimana => 3, inizio => '2015-01-12', fine => '2015-01-18'},
					'201504' => {anno => 2015, mese => 1, settimana => 4, inizio => '2015-01-19', fine => '2015-01-25'},
					'201505' => {anno => 2015, mese => 1, settimana => 5, inizio => '2015-01-26', fine => '2015-02-01'},
					'201506' => {anno => 2015, mese => 2, settimana => 6, inizio => '2015-02-02', fine => '2015-02-08'},
					'201507' => {anno => 2015, mese => 2, settimana => 7, inizio => '2015-02-09', fine => '2015-02-15'},
					'201508' => {anno => 2015, mese => 2, settimana => 8, inizio => '2015-02-16', fine => '2015-02-22'},
					'201509' => {anno => 2015, mese => 2, settimana => 9, inizio => '2015-02-23', fine => '2015-03-01'},
					'201510' => {anno => 2015, mese => 3, settimana => 10, inizio => '2015-03-02', fine => '2015-03-08'},
					'201511' => {anno => 2015, mese => 3, settimana => 11, inizio => '2015-03-09', fine => '2015-03-15'},
					'201512' => {anno => 2015, mese => 3, settimana => 12, inizio => '2015-03-16', fine => '2015-03-22'},
					'201513' => {anno => 2015, mese => 3, settimana => 13, inizio => '2015-03-23', fine => '2015-03-29'},
					'201514' => {anno => 2015, mese => 4, settimana => 14, inizio => '2015-03-30', fine => '2015-04-05'},
					'201515' => {anno => 2015, mese => 4, settimana => 15, inizio => '2015-04-06', fine => '2015-04-12'},
					'201516' => {anno => 2015, mese => 4, settimana => 16, inizio => '2015-04-13', fine => '2015-04-19'},
					'201517' => {anno => 2015, mese => 4, settimana => 17, inizio => '2015-04-20', fine => '2015-04-26'},
					'201518' => {anno => 2015, mese => 5, settimana => 18, inizio => '2015-04-27', fine => '2015-05-03'},
					'201519' => {anno => 2015, mese => 5, settimana => 19, inizio => '2015-05-04', fine => '2015-05-10'},
					'201520' => {anno => 2015, mese => 5, settimana => 20, inizio => '2015-05-11', fine => '2015-05-17'},
					'201521' => {anno => 2015, mese => 5, settimana => 21, inizio => '2015-05-18', fine => '2015-05-24'},
					'201522' => {anno => 2015, mese => 5, settimana => 22, inizio => '2015-05-25', fine => '2015-05-31'},
					'201523' => {anno => 2015, mese => 6, settimana => 23, inizio => '2015-06-01', fine => '2015-06-07'},
					'201524' => {anno => 2015, mese => 6, settimana => 24, inizio => '2015-06-08', fine => '2015-06-14'},
					'201525' => {anno => 2015, mese => 6, settimana => 25, inizio => '2015-06-15', fine => '2015-06-21'},
					'201526' => {anno => 2015, mese => 6, settimana => 26, inizio => '2015-06-22', fine => '2015-06-28'},
					'201527' => {anno => 2015, mese => 7, settimana => 27, inizio => '2015-06-29', fine => '2015-07-05'},
					'201528' => {anno => 2015, mese => 7, settimana => 28, inizio => '2015-07-06', fine => '2015-07-12'},
					'201529' => {anno => 2015, mese => 7, settimana => 29, inizio => '2015-07-13', fine => '2015-07-19'},
					'201530' => {anno => 2015, mese => 7, settimana => 30, inizio => '2015-07-20', fine => '2015-07-26'},
					'201531' => {anno => 2015, mese => 7, settimana => 31, inizio => '2015-07-27', fine => '2015-08-02'},
					'201532' => {anno => 2015, mese => 8, settimana => 32, inizio => '2015-08-03', fine => '2015-08-09'},
					'201533' => {anno => 2015, mese => 8, settimana => 33, inizio => '2015-08-10', fine => '2015-08-16'},
					'201534' => {anno => 2015, mese => 8, settimana => 34, inizio => '2015-08-17', fine => '2015-08-23'},
					'201535' => {anno => 2015, mese => 8, settimana => 35, inizio => '2015-08-24', fine => '2015-08-30'},
					'201536' => {anno => 2015, mese => 9, settimana => 36, inizio => '2015-08-31', fine => '2015-09-06'},
					'201537' => {anno => 2015, mese => 9, settimana => 37, inizio => '2015-09-07', fine => '2015-09-13'},
					'201538' => {anno => 2015, mese => 9, settimana => 38, inizio => '2015-09-14', fine => '2015-09-20'},
					'201539' => {anno => 2015, mese => 9, settimana => 39, inizio => '2015-09-21', fine => '2015-09-27'},
					'201540' => {anno => 2015, mese => 10, settimana => 40, inizio => '2015-09-28', fine => '2015-10-04'},
					'201541' => {anno => 2015, mese => 10, settimana => 41, inizio => '2015-10-05', fine => '2015-10-11'},
					'201542' => {anno => 2015, mese => 10, settimana => 42, inizio => '2015-10-12', fine => '2015-10-18'},
					'201543' => {anno => 2015, mese => 10, settimana => 43, inizio => '2015-10-19', fine => '2015-10-25'},
					'201544' => {anno => 2015, mese => 10, settimana => 44, inizio => '2015-10-26', fine => '2015-11-01'},
					'201545' => {anno => 2015, mese => 11, settimana => 45, inizio => '2015-11-02', fine => '2015-11-08'},
					'201546' => {anno => 2015, mese => 11, settimana => 46, inizio => '2015-11-09', fine => '2015-11-15'},
					'201547' => {anno => 2015, mese => 11, settimana => 47, inizio => '2015-11-16', fine => '2015-11-22'},
					'201548' => {anno => 2015, mese => 11, settimana => 48, inizio => '2015-11-23', fine => '2015-11-29'},
					'201549' => {anno => 2015, mese => 12, settimana => 49, inizio => '2015-11-30', fine => '2015-12-06'},
					'201550' => {anno => 2015, mese => 12, settimana => 50, inizio => '2015-12-07', fine => '2015-12-13'},
					'201551' => {anno => 2015, mese => 12, settimana => 51, inizio => '2015-12-14', fine => '2015-12-20'},
					'201552' => {anno => 2015, mese => 12, settimana => 52, inizio => '2015-12-21', fine => '2015-12-27'},
					'201553' => {anno => 2015, mese => 12, settimana => 53, inizio => '2015-12-28', fine => '2016-01-03'},
					'201601' => {anno => 2016, mese => 1, settimana => 1, inizio => '2016-01-04', fine => '2016-01-10'},
					'201602' => {anno => 2016, mese => 1, settimana => 2, inizio => '2016-01-11', fine => '2016-01-17'},
					'201603' => {anno => 2016, mese => 1, settimana => 3, inizio => '2016-01-18', fine => '2016-01-24'},
					'201604' => {anno => 2016, mese => 1, settimana => 4, inizio => '2016-01-25', fine => '2016-01-31'},
					'201605' => {anno => 2016, mese => 1, settimana => 5, inizio => '2016-02-01', fine => '2016-02-07'},
					'201606' => {anno => 2016, mese => 2, settimana => 6, inizio => '2016-02-08', fine => '2016-02-14'},
					'201607' => {anno => 2016, mese => 2, settimana => 7, inizio => '2016-02-15', fine => '2016-02-21'},
					'201608' => {anno => 2016, mese => 2, settimana => 8, inizio => '2016-02-22', fine => '2016-02-28'},
					'201609' => {anno => 2016, mese => 2, settimana => 9, inizio => '2016-02-29', fine => '2016-03-06'},
					'201610' => {anno => 2016, mese => 3, settimana => 10, inizio => '2016-03-07', fine => '2016-03-13'},
					'201611' => {anno => 2016, mese => 3, settimana => 11, inizio => '2016-03-14', fine => '2016-03-20'},
					'201612' => {anno => 2016, mese => 3, settimana => 12, inizio => '2016-03-21', fine => '2016-03-27'},
					'201613' => {anno => 2016, mese => 3, settimana => 13, inizio => '2016-03-28', fine => '2016-04-03'},
					'201614' => {anno => 2016, mese => 4, settimana => 14, inizio => '2016-04-04', fine => '2016-04-10'},
					'201615' => {anno => 2016, mese => 4, settimana => 15, inizio => '2016-04-11', fine => '2016-04-17'},
					'201616' => {anno => 2016, mese => 4, settimana => 16, inizio => '2016-04-18', fine => '2016-04-24'},
					'201617' => {anno => 2016, mese => 4, settimana => 17, inizio => '2016-04-25', fine => '2016-05-01'},
					'201618' => {anno => 2016, mese => 5, settimana => 18, inizio => '2016-05-02', fine => '2016-05-08'},
					'201619' => {anno => 2016, mese => 5, settimana => 19, inizio => '2016-05-09', fine => '2016-05-15'},
					'201620' => {anno => 2016, mese => 5, settimana => 20, inizio => '2016-05-16', fine => '2016-05-22'},
					'201621' => {anno => 2016, mese => 5, settimana => 21, inizio => '2016-05-23', fine => '2016-05-29'},
					'201622' => {anno => 2016, mese => 5, settimana => 22, inizio => '2016-05-30', fine => '2016-06-05'},
					'201623' => {anno => 2016, mese => 6, settimana => 23, inizio => '2016-06-06', fine => '2016-06-12'},
					'201624' => {anno => 2016, mese => 6, settimana => 24, inizio => '2016-06-13', fine => '2016-06-19'},
					'201625' => {anno => 2016, mese => 6, settimana => 25, inizio => '2016-06-20', fine => '2016-06-26'},
					'201626' => {anno => 2016, mese => 6, settimana => 26, inizio => '2016-06-27', fine => '2016-07-03'},
					'201627' => {anno => 2016, mese => 7, settimana => 27, inizio => '2016-07-04', fine => '2016-07-10'},
					'201628' => {anno => 2016, mese => 7, settimana => 28, inizio => '2016-07-11', fine => '2016-07-17'},
					'201629' => {anno => 2016, mese => 7, settimana => 29, inizio => '2016-07-18', fine => '2016-07-24'},
					'201630' => {anno => 2016, mese => 7, settimana => 30, inizio => '2016-07-25', fine => '2016-07-31'},
					'201631' => {anno => 2016, mese => 7, settimana => 31, inizio => '2016-08-01', fine => '2016-08-07'},
					'201632' => {anno => 2016, mese => 8, settimana => 32, inizio => '2016-08-08', fine => '2016-08-14'},
					'201633' => {anno => 2016, mese => 8, settimana => 33, inizio => '2016-08-15', fine => '2016-08-21'},
					'201634' => {anno => 2016, mese => 8, settimana => 34, inizio => '2016-08-22', fine => '2016-08-28'},
					'201635' => {anno => 2016, mese => 8, settimana => 35, inizio => '2016-08-29', fine => '2016-09-04'},
					'201636' => {anno => 2016, mese => 9, settimana => 36, inizio => '2016-09-05', fine => '2016-09-11'},
					'201637' => {anno => 2016, mese => 9, settimana => 37, inizio => '2016-09-12', fine => '2016-09-18'},
					'201638' => {anno => 2016, mese => 9, settimana => 38, inizio => '2016-09-19', fine => '2016-09-25'},
					'201639' => {anno => 2016, mese => 9, settimana => 39, inizio => '2016-09-26', fine => '2016-10-02'},
					'201640' => {anno => 2016, mese => 10, settimana => 40, inizio => '2016-10-03', fine => '2016-10-09'},
					'201641' => {anno => 2016, mese => 10, settimana => 41, inizio => '2016-10-10', fine => '2016-10-16'},
					'201642' => {anno => 2016, mese => 10, settimana => 42, inizio => '2016-10-17', fine => '2016-10-23'},
					'201643' => {anno => 2016, mese => 10, settimana => 43, inizio => '2016-10-24', fine => '2016-10-30'},
					'201644' => {anno => 2016, mese => 10, settimana => 44, inizio => '2016-10-31', fine => '2016-11-06'},
					'201645' => {anno => 2016, mese => 11, settimana => 45, inizio => '2016-11-07', fine => '2016-11-13'},
					'201646' => {anno => 2016, mese => 11, settimana => 46, inizio => '2016-11-14', fine => '2016-11-20'},
					'201647' => {anno => 2016, mese => 11, settimana => 47, inizio => '2016-11-21', fine => '2016-11-27'},
					'201648' => {anno => 2016, mese => 11, settimana => 48, inizio => '2016-11-28', fine => '2016-12-04'},
					'201649' => {anno => 2016, mese => 12, settimana => 49, inizio => '2016-12-05', fine => '2016-12-11'},
					'201650' => {anno => 2016, mese => 12, settimana => 50, inizio => '2016-12-12', fine => '2016-12-18'},
					'201651' => {anno => 2016, mese => 12, settimana => 51, inizio => '2016-12-19', fine => '2016-12-25'},
					'201652' => {anno => 2016, mese => 12, settimana => 52, inizio => '2016-12-26', fine => '2017-01-01'}
				);

my %settimane_if65 = (
					'201501' => {anno => 2015, mese => 1, settimana => 1, inizio => '2014-12-28', fine => '2015-01-04'},
					'201502' => {anno => 2015, mese => 1, settimana => 2, inizio => '2015-01-05', fine => '2015-01-11'},
					'201503' => {anno => 2015, mese => 1, settimana => 3, inizio => '2015-01-12', fine => '2015-01-18'},
					'201504' => {anno => 2015, mese => 1, settimana => 4, inizio => '2015-01-19', fine => '2015-01-25'},
					'201505' => {anno => 2015, mese => 1, settimana => 5, inizio => '2015-01-26', fine => '2015-02-01'},
					'201506' => {anno => 2015, mese => 2, settimana => 6, inizio => '2015-02-02', fine => '2015-02-08'},
					'201507' => {anno => 2015, mese => 2, settimana => 7, inizio => '2015-02-09', fine => '2015-02-15'},
					'201508' => {anno => 2015, mese => 2, settimana => 8, inizio => '2015-02-16', fine => '2015-02-22'},
					'201509' => {anno => 2015, mese => 2, settimana => 9, inizio => '2015-02-23', fine => '2015-03-01'},
					'201510' => {anno => 2015, mese => 3, settimana => 10, inizio => '2015-03-02', fine => '2015-03-08'},
					'201511' => {anno => 2015, mese => 3, settimana => 11, inizio => '2015-03-09', fine => '2015-03-15'},
					'201512' => {anno => 2015, mese => 3, settimana => 12, inizio => '2015-03-16', fine => '2015-03-22'},
					'201513' => {anno => 2015, mese => 3, settimana => 13, inizio => '2015-03-23', fine => '2015-03-29'},
					'201514' => {anno => 2015, mese => 4, settimana => 14, inizio => '2015-03-30', fine => '2015-04-05'},
					'201515' => {anno => 2015, mese => 4, settimana => 15, inizio => '2015-04-06', fine => '2015-04-12'},
					'201516' => {anno => 2015, mese => 4, settimana => 16, inizio => '2015-04-13', fine => '2015-04-19'},
					'201517' => {anno => 2015, mese => 4, settimana => 17, inizio => '2015-04-20', fine => '2015-04-26'},
					'201518' => {anno => 2015, mese => 5, settimana => 18, inizio => '2015-04-27', fine => '2015-05-03'},
					'201519' => {anno => 2015, mese => 5, settimana => 19, inizio => '2015-05-04', fine => '2015-05-10'},
					'201520' => {anno => 2015, mese => 5, settimana => 20, inizio => '2015-05-11', fine => '2015-05-17'},
					'201521' => {anno => 2015, mese => 5, settimana => 21, inizio => '2015-05-18', fine => '2015-05-24'},
					'201522' => {anno => 2015, mese => 5, settimana => 22, inizio => '2015-05-25', fine => '2015-05-31'},
					'201523' => {anno => 2015, mese => 6, settimana => 23, inizio => '2015-06-01', fine => '2015-06-07'},
					'201524' => {anno => 2015, mese => 6, settimana => 24, inizio => '2015-06-08', fine => '2015-06-14'},
					'201525' => {anno => 2015, mese => 6, settimana => 25, inizio => '2015-06-15', fine => '2015-06-21'},
					'201526' => {anno => 2015, mese => 6, settimana => 26, inizio => '2015-06-22', fine => '2015-06-28'},
					'201527' => {anno => 2015, mese => 7, settimana => 27, inizio => '2015-06-29', fine => '2015-07-05'},
					'201528' => {anno => 2015, mese => 7, settimana => 28, inizio => '2015-07-06', fine => '2015-07-12'},
					'201529' => {anno => 2015, mese => 7, settimana => 29, inizio => '2015-07-13', fine => '2015-07-19'},
					'201530' => {anno => 2015, mese => 7, settimana => 30, inizio => '2015-07-20', fine => '2015-07-26'},
					'201531' => {anno => 2015, mese => 7, settimana => 31, inizio => '2015-07-27', fine => '2015-08-02'},
					'201532' => {anno => 2015, mese => 8, settimana => 32, inizio => '2015-08-03', fine => '2015-08-09'},
					'201533' => {anno => 2015, mese => 8, settimana => 33, inizio => '2015-08-10', fine => '2015-08-16'},
					'201534' => {anno => 2015, mese => 8, settimana => 34, inizio => '2015-08-17', fine => '2015-08-23'},
					'201535' => {anno => 2015, mese => 8, settimana => 35, inizio => '2015-08-24', fine => '2015-08-30'},
					'201536' => {anno => 2015, mese => 9, settimana => 36, inizio => '2015-08-31', fine => '2015-09-06'},
					'201537' => {anno => 2015, mese => 9, settimana => 37, inizio => '2015-09-07', fine => '2015-09-13'},
					'201538' => {anno => 2015, mese => 9, settimana => 38, inizio => '2015-09-14', fine => '2015-09-20'},
					'201539' => {anno => 2015, mese => 9, settimana => 39, inizio => '2015-09-21', fine => '2015-09-27'},
					'201540' => {anno => 2015, mese => 10, settimana => 40, inizio => '2015-09-28', fine => '2015-10-04'},
					'201541' => {anno => 2015, mese => 10, settimana => 41, inizio => '2015-10-05', fine => '2015-10-11'},
					'201542' => {anno => 2015, mese => 10, settimana => 42, inizio => '2015-10-12', fine => '2015-10-18'},
					'201543' => {anno => 2015, mese => 10, settimana => 43, inizio => '2015-10-19', fine => '2015-10-25'},
					'201544' => {anno => 2015, mese => 10, settimana => 44, inizio => '2015-10-26', fine => '2015-11-01'},
					'201545' => {anno => 2015, mese => 11, settimana => 45, inizio => '2015-11-02', fine => '2015-11-08'},
					'201546' => {anno => 2015, mese => 11, settimana => 46, inizio => '2015-11-09', fine => '2015-11-15'},
					'201547' => {anno => 2015, mese => 11, settimana => 47, inizio => '2015-11-16', fine => '2015-11-22'},
					'201548' => {anno => 2015, mese => 11, settimana => 48, inizio => '2015-11-23', fine => '2015-11-29'},
					'201549' => {anno => 2015, mese => 12, settimana => 49, inizio => '2015-11-30', fine => '2015-12-06'},
					'201550' => {anno => 2015, mese => 12, settimana => 50, inizio => '2015-12-07', fine => '2015-12-13'},
					'201551' => {anno => 2015, mese => 12, settimana => 51, inizio => '2015-12-14', fine => '2015-12-20'},
					'201552' => {anno => 2015, mese => 12, settimana => 52, inizio => '2015-12-21', fine => '2015-12-27'},
					'201553' => {anno => 2015, mese => 12, settimana => 53, inizio => '2015-12-28', fine => '2016-01-03'},
					'201601' => {anno => 2016, mese => 1, settimana => 1, inizio => '2016-01-04', fine => '2016-01-10'},
					'201602' => {anno => 2016, mese => 1, settimana => 2, inizio => '2016-01-11', fine => '2016-01-17'},
					'201603' => {anno => 2016, mese => 1, settimana => 3, inizio => '2016-01-18', fine => '2016-01-24'},
					'201604' => {anno => 2016, mese => 1, settimana => 4, inizio => '2016-01-25', fine => '2016-01-31'},
					'201605' => {anno => 2016, mese => 1, settimana => 5, inizio => '2016-02-01', fine => '2016-02-07'},
					'201606' => {anno => 2016, mese => 2, settimana => 6, inizio => '2016-02-08', fine => '2016-02-14'},
					'201607' => {anno => 2016, mese => 2, settimana => 7, inizio => '2016-02-15', fine => '2016-02-21'},
					'201608' => {anno => 2016, mese => 2, settimana => 8, inizio => '2016-02-22', fine => '2016-02-28'},
					'201609' => {anno => 2016, mese => 2, settimana => 9, inizio => '2016-02-29', fine => '2016-03-06'},
					'201610' => {anno => 2016, mese => 3, settimana => 10, inizio => '2016-03-07', fine => '2016-03-13'},
					'201611' => {anno => 2016, mese => 3, settimana => 11, inizio => '2016-03-14', fine => '2016-03-20'},
					'201612' => {anno => 2016, mese => 3, settimana => 12, inizio => '2016-03-21', fine => '2016-03-27'},
					'201613' => {anno => 2016, mese => 3, settimana => 13, inizio => '2016-03-28', fine => '2016-04-03'},
					'201614' => {anno => 2016, mese => 4, settimana => 14, inizio => '2016-04-04', fine => '2016-04-10'},
					'201615' => {anno => 2016, mese => 4, settimana => 15, inizio => '2016-04-11', fine => '2016-04-17'},
					'201616' => {anno => 2016, mese => 4, settimana => 16, inizio => '2016-04-18', fine => '2016-04-24'},
					'201617' => {anno => 2016, mese => 4, settimana => 17, inizio => '2016-04-25', fine => '2016-05-01'},
					'201618' => {anno => 2016, mese => 5, settimana => 18, inizio => '2016-05-02', fine => '2016-05-08'},
					'201619' => {anno => 2016, mese => 5, settimana => 19, inizio => '2016-05-09', fine => '2016-05-15'},
					'201620' => {anno => 2016, mese => 5, settimana => 20, inizio => '2016-05-16', fine => '2016-05-22'},
					'201621' => {anno => 2016, mese => 5, settimana => 21, inizio => '2016-05-23', fine => '2016-05-29'},
					'201622' => {anno => 2016, mese => 5, settimana => 22, inizio => '2016-05-30', fine => '2016-06-05'},
					'201623' => {anno => 2016, mese => 6, settimana => 23, inizio => '2016-06-06', fine => '2016-06-12'},
					'201624' => {anno => 2016, mese => 6, settimana => 24, inizio => '2016-06-13', fine => '2016-06-19'},
					'201625' => {anno => 2016, mese => 6, settimana => 25, inizio => '2016-06-20', fine => '2016-06-26'},
					'201626' => {anno => 2016, mese => 6, settimana => 26, inizio => '2016-06-27', fine => '2016-07-03'},
					'201627' => {anno => 2016, mese => 7, settimana => 27, inizio => '2016-07-04', fine => '2016-07-10'},
					'201628' => {anno => 2016, mese => 7, settimana => 28, inizio => '2016-07-11', fine => '2016-07-17'},
					'201629' => {anno => 2016, mese => 7, settimana => 29, inizio => '2016-07-18', fine => '2016-07-24'},
					'201630' => {anno => 2016, mese => 7, settimana => 30, inizio => '2016-07-25', fine => '2016-07-31'},
					'201631' => {anno => 2016, mese => 7, settimana => 31, inizio => '2016-08-01', fine => '2016-08-07'},
					'201632' => {anno => 2016, mese => 8, settimana => 32, inizio => '2016-08-08', fine => '2016-08-14'},
					'201633' => {anno => 2016, mese => 8, settimana => 33, inizio => '2016-08-15', fine => '2016-08-21'},
					'201634' => {anno => 2016, mese => 8, settimana => 34, inizio => '2016-08-22', fine => '2016-08-28'},
					'201635' => {anno => 2016, mese => 8, settimana => 35, inizio => '2016-08-29', fine => '2016-09-04'},
					'201636' => {anno => 2016, mese => 9, settimana => 36, inizio => '2016-09-05', fine => '2016-09-11'},
					'201637' => {anno => 2016, mese => 9, settimana => 37, inizio => '2016-09-12', fine => '2016-09-18'},
					'201638' => {anno => 2016, mese => 9, settimana => 38, inizio => '2016-09-19', fine => '2016-09-25'},
					'201639' => {anno => 2016, mese => 9, settimana => 39, inizio => '2016-09-26', fine => '2016-10-02'},
					'201640' => {anno => 2016, mese => 10, settimana => 40, inizio => '2016-10-03', fine => '2016-10-09'},
					'201641' => {anno => 2016, mese => 10, settimana => 41, inizio => '2016-10-10', fine => '2016-10-16'},
					'201642' => {anno => 2016, mese => 10, settimana => 42, inizio => '2016-10-17', fine => '2016-10-23'},
					'201643' => {anno => 2016, mese => 10, settimana => 43, inizio => '2016-10-24', fine => '2016-10-30'},
					'201644' => {anno => 2016, mese => 10, settimana => 44, inizio => '2016-10-31', fine => '2016-11-06'},
					'201645' => {anno => 2016, mese => 11, settimana => 45, inizio => '2016-11-07', fine => '2016-11-13'},
					'201646' => {anno => 2016, mese => 11, settimana => 46, inizio => '2016-11-14', fine => '2016-11-20'},
					'201647' => {anno => 2016, mese => 11, settimana => 47, inizio => '2016-11-21', fine => '2016-11-27'},
					'201648' => {anno => 2016, mese => 11, settimana => 48, inizio => '2016-11-28', fine => '2016-12-04'},
					'201649' => {anno => 2016, mese => 12, settimana => 49, inizio => '2016-12-05', fine => '2016-12-11'},
					'201650' => {anno => 2016, mese => 12, settimana => 50, inizio => '2016-12-12', fine => '2016-12-18'},
					'201651' => {anno => 2016, mese => 12, settimana => 51, inizio => '2016-12-19', fine => '2016-12-25'},
					'201652' => {anno => 2016, mese => 12, settimana => 52, inizio => '2016-12-26', fine => '2016-12-31'}
				);

# parametri di collegamento al database ITM
#------------------------------------------------------------------------------------------------------------
my $hostname			= "10.11.14.78";
my $username			= "root";
my $password			= "mela";
my $database			= "controllo";

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sth_riga;
	
# definizione dei parametri sulla linea di comando
#------------------------------------------------------------------------------------------------------------
my $societa = 'SM';
my $tipo_report = 2; 	#2=report settimana, 3=report mese, #4=report anno, 
						#5=progress mese, #6=progress anno
my $data_ac;
my $data_ap;
my $data_inizio_ac;
my $data_fine_ac;
my $data_inizio_ap;
my $data_fine_ap;

my $anno;
my $mese;
my $settimana;

my @ar_fileName = ();
my @ar_societa = ();
my @ar_tipo = ();
my @ar_data = ();

my $txt = 0;
GetOptions(
	'f=s{0,1}'		=> \@ar_fileName,
	's=s{1,1}'		=> \@ar_societa,
	't=s{1,1}'		=> \@ar_tipo,
	'd=s{0,4}'		=> \@ar_data,
	'txt!'			=> \$txt,
) or die "Uso errato dei parametri!\n";

my $output_file_name = 'report_vendite';
if (@ar_fileName == 1) {
	$output_file_name = $ar_fileName[0];
}

if (@ar_societa > 0) {
	if ($ar_societa[0] !~ /^(07|08|10|19|53)$/) {
		die "Tipo report Errato: $ar_tipo[0]\n";
	}
	$societa = $ar_societa[0];
}

if (@ar_tipo > 0) {
	if ($ar_tipo[0] !~ /^(1|2|3|4|5|6|7|8)$/) {
		die "Tipo report Errato: $ar_tipo[0]\n";
	}
	$tipo_report = $ar_tipo[0];
}

for (my $i=0;$i<@ar_data;$i++) {
	$ar_data[$i] =~ s/[^\d\-]/\-/ig;
	if ($ar_data[$i] =~ /^(\d{4})(\d{2})(\d{2})$/) {
		$ar_data[$i] = $1.'-'.$2.'-'.$3;
	} elsif ($ar_data[$i] =~ /^(\d+)\-(\d+)\-(\d+)$/) {
		$ar_data[$i] = sprintf('%04d-%02d-%02d',$1,$2,$3);
	} else {die "Formato data errato: $ar_data[$i]\n"};
	
	#$ar_data[$i] =~ s/\-//ig;
}
if (@ar_data == 1) {
	$data_ac = string2date($ar_data[0]); 
} else {
	$data_ac = DateTime->today(time_zone=>'local');
}

my $desktop = '/';#File::HomeDir->my_desktop;
my $output_file_handler;

# connessione al database di default
$dbh = DBI->connect("DBI:mysql:mysql:$hostname", $username, $password);
if (! $dbh) {
	print "Errore durante la connessione al database di default!\n";
	return 0;
}

my $mysql_data_inizio_ac;
my $mysql_data_fine_ac; 
my $mysql_data_inizio_ap;
my $mysql_data_fine_ap;

if ($tipo_report == 2) {
	$output_file_name = 'report_vendite_settimanali';
	
	my ($anno, $settimana) = $data_ac->week();
	($mysql_data_inizio_ap, $mysql_data_fine_ap) = settimana_limiti($anno-1, $settimana-1, 'IF65');
	($mysql_data_inizio_ac, $mysql_data_fine_ac) = settimana_limiti($anno, $settimana-1, 'IF65');
	
} elsif ($tipo_report == 3) {
	$output_file_name = 'report_vendite_mensili';
	
	my ($anno, $settimana) = $data_ac->week();
	my ($week_data_inizio_ac, $week_data_fine_ac) = settimana_limiti($anno, $settimana-1, 'IF65');
	
	$anno = $data_ac->year();
	my $mese = $data_ac->subtract(months => 1)->month();
	($mysql_data_inizio_ac, $mysql_data_fine_ac) = mese_limiti($anno, $mese, 'IF65');
	
	
	$mysql_data_fine_ac = $week_data_fine_ac;
	
	$mysql_data_inizio_ap = string2date($mysql_data_inizio_ac)->subtract(years => 1)->ymd('-');
	$mysql_data_fine_ap = string2date($mysql_data_fine_ac)->subtract(years => 1)->ymd('-');
	
} elsif ($tipo_report == 4) {
	$output_file_name = 'report_vendite_annuali';
	
	my ($anno, $settimana) = $data_ac->week();
	my ($week_data_inizio_ac, $week_data_fine_ac) = settimana_limiti($anno, $settimana-1, 'IF65');
	
	$anno = $data_ac->year();
	my $mese = $data_ac->month();
	($mysql_data_inizio_ac, $mysql_data_fine_ac) = anno_limiti($anno, 'IF65');
	
	
	$mysql_data_fine_ac = $week_data_fine_ac;
	
	$mysql_data_inizio_ap = string2date($mysql_data_inizio_ac)->subtract(years => 1)->ymd('-');
	$mysql_data_fine_ap = string2date($mysql_data_fine_ac)->subtract(years => 1)->ymd('-');
	
	
} elsif ($tipo_report == 5) {
	
} elsif ($tipo_report == 6) {
	
} elsif ($tipo_report == 7) {
	
} elsif ($tipo_report == 8) {

	$mysql_data_inizio_ac = $ar_data[0];
	$mysql_data_fine_ac = $ar_data[1];
	$mysql_data_inizio_ap = $ar_data[2];
	$mysql_data_fine_ap = $ar_data[3];
}

if ($societa eq '08') {
	$sth = $dbh->prepare(qq{call controllo.report_vendite_sm('$mysql_data_inizio_ap', '$mysql_data_fine_ap', '$mysql_data_inizio_ac', '$mysql_data_fine_ac');});
} else {
	$sth = $dbh->prepare(qq{call controllo.report_vendite_eb('$mysql_data_inizio_ap', '$mysql_data_fine_ap', '$mysql_data_inizio_ac', '$mysql_data_fine_ac');});
}
if ($sth->execute()) {
	if ($txt) {#esportazione in formato txt
		$output_file_name .= '.txt';
		open $output_file_handler, "+>", "$desktop/$output_file_name" or die "Non  stato possibile creare il file `$output_file_name`: $!\n";

		#titoli colonne
		print $output_file_handler "Mondo_\t";
		print $output_file_handler "Settore_\t";
		print $output_file_handler "Reparto_\t";
		print $output_file_handler "Famiglia_\t";
		print $output_file_handler "Sottofamiglia_\t";
		print $output_file_handler "Sede_\t";
		print $output_file_handler "Venduto_AP_\t";
		print $output_file_handler "Venduto_AC_\t";
		print $output_file_handler "Delta_V_\t";
		print $output_file_handler "Delta_VP_\t";
		print $output_file_handler "Pezzi_AP_\t";
		print $output_file_handler "Pezzi_AC_\t";
		print $output_file_handler "Delta_P_\t";
		print $output_file_handler "Delta_PP_\t";
		print $output_file_handler "Margine_AP_\t";
		print $output_file_handler "Margine_AC_\t";
		print $output_file_handler "Delta_M_\t";
		print $output_file_handler "Delta_MP_\t";
		print $output_file_handler "Vend_No_Iva_AP_\t";
		print $output_file_handler "Vend_No_Iva_AC_\n";
		
	
		while(my @row = $sth->fetchrow_array()) {
			print $output_file_handler "$row[0]\t";
			print $output_file_handler "$row[1]\t";
			print $output_file_handler "$row[2]\t";
			print $output_file_handler "$row[3]\t";
			print $output_file_handler "$row[4]\t";
			print $output_file_handler "$row[5]\t";
			print $output_file_handler "$row[8]\t";
			print $output_file_handler "$row[9]\t";
			print $output_file_handler "0\t";
			print $output_file_handler "0\t";
			print $output_file_handler "$row[6]\t";
			print $output_file_handler "$row[7]\t";
			print $output_file_handler "0\t";
			print $output_file_handler "0\t";
			print $output_file_handler "$row[10]\t";
			print $output_file_handler "$row[11]\t";
			print $output_file_handler "0\t";
			print $output_file_handler "0\t";
			print $output_file_handler "$row[12]\t";
			print $output_file_handler "$row[13]\t";
			print $output_file_handler "$row[14]\n";
		}
		close($output_file_handler);
	} else {#formato excel
		$output_file_name .= '.xlsm';
		my $workbook = Excel::Writer::XLSX->new("$desktop/$output_file_name");
		
		#creo il foglio di lavoro x l'anno
		my $rv_anno = $workbook->add_worksheet( 'RV_Anno' );
		
		#aggiungo un formato
    	my $format = $workbook->add_format();
    	$format->set_bold();
		
    	$format->set_color( 'Red' );
		$rv_anno->write( 0, 3, "Periodo corrente: dal $mysql_data_inizio_ac al $mysql_data_fine_ac", $format );
		$rv_anno->write( 1, 3, "Periodo storico: dal $mysql_data_inizio_ap al $mysql_data_fine_ap", $format );
		
		#titoli colonne
		$format->set_color( 'blue' );
		$rv_anno->write( 3, 0, "Mondo_", $format );
		$rv_anno->write( 3, 1, "Settore_", $format );
		$rv_anno->write( 3, 2, "Reparto_", $format );
		$rv_anno->write( 3, 3, "Famiglia_", $format );
		$rv_anno->write( 3, 4, "Sottofamiglia_", $format );
		$rv_anno->write( 3, 5, "Sede_", $format );
		$rv_anno->write( 3, 6, "Venduto_AP_", $format );
		$rv_anno->write( 3, 7, "Venduto_AC_", $format );
		$rv_anno->write( 3, 8, "Delta_V_", $format );
		$rv_anno->write( 3, 9, "Delta_VP_", $format );
		$rv_anno->write( 3,10, "Pezzi_AP_", $format );
		$rv_anno->write( 3,11, "Pezzi_AC_", $format );
		$rv_anno->write( 3,12, "Delta_P_", $format );
		$rv_anno->write( 3,13, "Delta_PP_", $format );
		$rv_anno->write( 3,14, "Margine_AP_", $format );
		$rv_anno->write( 3,15, "Margine_AC_", $format );
		$rv_anno->write( 3,16, "Delta_M_", $format );
		$rv_anno->write( 3,17, "Delta_MP_", $format );
		$rv_anno->write( 3,18, "Vend_No_Iva_AP_", $format );
		$rv_anno->write( 3,19, "Vend_No_Iva_AC_", $format );
		$rv_anno->write( 3,20, "Giacenza_", $format );
		
		my $row_counter = 3;
		while(my @row = $sth->fetchrow_array()) {
			$row_counter++;
			
			my $delta_venduto = "=".xl_rowcol_to_cell( $row_counter, 7)."-".xl_rowcol_to_cell( $row_counter, 6);
			my $delta_venduto_p = "=IF(".xl_rowcol_to_cell( $row_counter, 6)."<>0,(".xl_rowcol_to_cell( $row_counter, 7)."-".xl_rowcol_to_cell( $row_counter, 6).")/".xl_rowcol_to_cell( $row_counter, 6).",0)";
			my $delta_pezzi = "=".xl_rowcol_to_cell( $row_counter, 11)."-".xl_rowcol_to_cell( $row_counter, 10);
			my $delta_pezzi_p = "=IF(".xl_rowcol_to_cell( $row_counter, 10)."<>0,(".xl_rowcol_to_cell( $row_counter, 11)."-".xl_rowcol_to_cell( $row_counter, 10).")/".xl_rowcol_to_cell( $row_counter, 10).",0)";
			my $delta_margine = "=".xl_rowcol_to_cell( $row_counter, 15)."-".xl_rowcol_to_cell( $row_counter, 14);
			my $delta_margine_p = "=IF(".xl_rowcol_to_cell( $row_counter, 14)."<>0,(".xl_rowcol_to_cell( $row_counter, 15)."-".xl_rowcol_to_cell( $row_counter, 14).")/".xl_rowcol_to_cell( $row_counter, 14).",0)";
			
			$rv_anno->write( $row_counter, 0, "$row[0]");
			$rv_anno->write( $row_counter, 1, "$row[1]");
			$rv_anno->write( $row_counter, 2, "$row[2]");
			$rv_anno->write( $row_counter, 3, "$row[3]");
			$rv_anno->write( $row_counter, 4, "$row[4]");
			$rv_anno->write( $row_counter, 5, "$row[5]");
			$rv_anno->write( $row_counter, 6, "$row[8]");
			$rv_anno->write( $row_counter, 7, "$row[9]");
			$rv_anno->write( $row_counter, 8, $delta_venduto);
			$rv_anno->write( $row_counter, 9, $delta_venduto_p);
			$rv_anno->write( $row_counter,10, "$row[6]");
			$rv_anno->write( $row_counter,11, "$row[7]");
			$rv_anno->write( $row_counter,12, $delta_pezzi);
			$rv_anno->write( $row_counter,13, $delta_pezzi_p);
			$rv_anno->write( $row_counter,14, "$row[10]");
			$rv_anno->write( $row_counter,15, "$row[11]");
			$rv_anno->write( $row_counter,16, $delta_margine);
			$rv_anno->write( $row_counter,17, $delta_margine_p);
			$rv_anno->write( $row_counter,18, "$row[12]");
			$rv_anno->write( $row_counter,19, "$row[13]");
			$rv_anno->write( $row_counter,20, "$row[14]");
		}
		
		# Add the VBA project binary.
    $workbook->add_vba_project( '/script/vbaProject.bin' );
      
    # Add a button tied to a macro in the VBA project.
    $rv_anno->insert_button(
        'A1',
        {
            macro   => 'crea_pivot',
            caption => 'Crea Tabella Pivot',
            width   => 120,
            height  => 40
        }
    );
		#attivo il foglio di lavoro
    	$rv_anno->activate();
	}
	$sth->finish();
}

$dbh->disconnect();


sub string2date { #trasformo una data un oggetto DateTime
	my ($data) =@_;
	
	my $giorno = 1;
	my $mese = 1;
	my $anno = 1900;
	if ($data =~ /^(\d{4}).(\d{2}).(\d{2})$/) {
        $anno = $1*1;
		$mese = $2*1;
		$giorno = $3*1;
    }
    
	return DateTime->new(year=>$anno, month=>$mese, day=>$giorno);
}

sub settimana_limiti {
	my ($anno, $settimana, $tipo) = @_;
	
	my $chiave = sprintf('%04d%02d',$anno, $settimana);

	my $data_inizio;
	my $data_fine;
	if ($tipo eq 'GFK') {    
		$data_inizio = $settimane_gfk{$chiave}{inizio};
		$data_fine = $settimane_gfk{$chiave}{fine};
	} elsif ($tipo eq 'IF65') {
		$data_inizio = $settimane_if65{$chiave}{inizio};
		$data_fine = $settimane_if65{$chiave}{fine};
	}
	return $data_inizio, $data_fine;
}

sub mese_limiti {
	my ($anno, $mese, $tipo) =@_;
	
	my $data_inizio = '2099-12-31';
	my $data_fine = '1900-01-01';
	
	if ($tipo eq 'GFK') {    
		foreach my $chiave (keys %settimane_gfk) {
			if ($settimane_gfk{$chiave}{anno} == $anno && $settimane_gfk{$chiave}{mese} == $mese && $settimane_gfk{$chiave}{inizio} lt $data_inizio ) {
				$data_inizio = $settimane_gfk{$chiave}{inizio};
			}
			
			if ($settimane_gfk{$chiave}{anno} == $anno && $settimane_gfk{$chiave}{mese} == $mese && $settimane_gfk{$chiave}{fine} gt $data_fine ) {
				$data_fine = $settimane_gfk{$chiave}{fine};
			}
		}
	} elsif ($tipo eq 'IF65') {
		foreach my $chiave (keys %settimane_if65) {
			if ($settimane_if65{$chiave}{anno} == $anno && $settimane_if65{$chiave}{mese} == $mese && $settimane_if65{$chiave}{inizio} lt $data_inizio ) {
				$data_inizio = $settimane_if65{$chiave}{inizio};
			}
			
			if ($settimane_if65{$chiave}{anno} == $anno && $settimane_if65{$chiave}{mese} == $mese && $settimane_if65{$chiave}{fine} gt $data_fine ) {
				$data_fine = $settimane_if65{$chiave}{fine};
			}
		}
        
        $data_inizio = string2date($data_fine)->truncate(to => "month")->ymd('-');
	}
    
	return $data_inizio, $data_fine;
}

sub anno_limiti {
	my ($anno, $tipo) =@_;
	
	my $data_inizio = '2099-12-31';
	my $data_fine = '1900-01-01';
	
	if ($tipo eq 'GFK') {
		foreach my $chiave (keys %settimane_gfk) {
			if ($settimane_gfk{$chiave}{anno} == $anno && $settimane_gfk{$chiave}{inizio} lt $data_inizio ) {
				$data_inizio = $settimane_gfk{$chiave}{inizio};
			}
			
			if ($settimane_gfk{$chiave}{anno} == $anno && $settimane_gfk{$chiave}{fine} gt $data_fine ) {
				$data_fine = $settimane_gfk{$chiave}{fine};
			}
		}
	} elsif ($tipo eq 'IF65') {
		foreach my $chiave (keys %settimane_if65) {
			if ($settimane_if65{$chiave}{anno} == $anno && $settimane_if65{$chiave}{inizio} lt $data_inizio ) {
				$data_inizio = $settimane_if65{$chiave}{inizio};
			}
			
			if ($settimane_if65{$chiave}{anno} == $anno && $settimane_if65{$chiave}{fine} gt $data_fine ) {
				$data_fine = $settimane_if65{$chiave}{fine};
			}
		}
        
         $data_inizio = string2date($data_inizio)->truncate(to => "year")->ymd('-');
	}
	return $data_inizio, $data_fine;
}