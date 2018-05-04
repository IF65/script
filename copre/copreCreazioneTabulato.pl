#!/usr/bin/perl
use strict;
use warnings;

use lib '/root/perl5/lib/perl5';

use DBI;
use REST::Client;
use DateTime;
use POSIX;

# data e ora di caricamento dei dati
#------------------------------------------------------------------------------------------------------------
my $currentDate = DateTime->now(time_zone=>'local');
my $timestamp   = $currentDate->ymd().' '.$currentDate->hms();
my $data        = $currentDate->ymd('-');

# parametri di collegamento a mysql
#------------------------------------------------------------------------------------------------------------
my $hostname = "10.11.14.78";
my $username = "root";
my $password = "mela";

# parametri di chiamata REST
#------------------------------------------------------------------------------------------------------------
my $requestUrl =  'https://cogeso.copre.it/DownloadService';
my $requestParams = 'user=200507&password=19673&cliente=200507&file=ARTICOLI_S';

# variabili globali
#------------------------------------------------------------------------------------------------------------
my $dbh;
my $sth;
my $sth_cliente;
my %pnd;
my %ricarico;
my %ricaricoVendita;
my %clienti;

my %articoliAnomali =  ('0205725002' => { 'codice' => '0205725002', 'prezzoAcquisto' => 227.12, 'doppioNetto' => 177.32},
                        '0205725009' => { 'codice' => '0205725009', 'prezzoAcquisto' => 255.57, 'doppioNetto' => 199.53},
                        '0205725011' => { 'codice' => '0205725011', 'prezzoAcquisto' => 480.46, 'doppioNetto' => 375.12},
                        '0205725013' => { 'codice' => '0205725013', 'prezzoAcquisto' => 394.58, 'doppioNetto' => 308.07},
                        '0205725014' => { 'codice' => '0205725014', 'prezzoAcquisto' => 300.57, 'doppioNetto' => 234.67},
                        '0205725015' => { 'codice' => '0205725015', 'prezzoAcquisto' => 227.56, 'doppioNetto' => 177.66},
                        '0205725016' => { 'codice' => '0205725016', 'prezzoAcquisto' => 261.66, 'doppioNetto' => 204.29},
                        '0205725017' => { 'codice' => '0205725017', 'prezzoAcquisto' => 221.75, 'doppioNetto' => 173.13},
                        '0205725018' => { 'codice' => '0205725018', 'prezzoAcquisto' => 204.63, 'doppioNetto' => 159.77},
                        '0205725019' => { 'codice' => '0205725019', 'prezzoAcquisto' => 289.84, 'doppioNetto' => 226.29},
                        '0205725020' => { 'codice' => '0205725020', 'prezzoAcquisto' => 614.65, 'doppioNetto' => 479.88},
                        '0205725021' => { 'codice' => '0205725021', 'prezzoAcquisto' => 252.35, 'doppioNetto' => 197.02},
                        '0205725022' => { 'codice' => '0205725022', 'prezzoAcquisto' => 344.73, 'doppioNetto' => 269.15},
                        '0205725023' => { 'codice' => '0205725023', 'prezzoAcquisto' => 396.73, 'doppioNetto' => 309.75},
                        '0208725001' => { 'codice' => '0208725001', 'prezzoAcquisto' => 221.75, 'doppioNetto' => 173.13},
                        '0212725001' => { 'codice' => '0212725001', 'prezzoAcquisto' => 285.30, 'doppioNetto' => 222.75},
                        '0212725002' => { 'codice' => '0212725002', 'prezzoAcquisto' => 370.95, 'doppioNetto' => 289.62},
                        '0212725004' => { 'codice' => '0212725004', 'prezzoAcquisto' => 671.30, 'doppioNetto' => 524.12},
                        '0212725005' => { 'codice' => '0212725005', 'prezzoAcquisto' => 413.43, 'doppioNetto' => 322.78},
                        '0250725001' => { 'codice' => '0250725001', 'prezzoAcquisto' => 35.96, 'doppioNetto' => 28.08},
                        '0302725004' => { 'codice' => '0302725004', 'prezzoAcquisto' => 770.66, 'doppioNetto' => 601.69},
                        '0302725005' => { 'codice' => '0302725005', 'prezzoAcquisto' => 723.07, 'doppioNetto' => 564.53},
                        '0302725006' => { 'codice' => '0302725006', 'prezzoAcquisto' => 861.54, 'doppioNetto' => 672.65},
                        '0302725007' => { 'codice' => '0302725007', 'prezzoAcquisto' => 287.24, 'doppioNetto' => 224.26},
                        '0302725008' => { 'codice' => '0302725008', 'prezzoAcquisto' => 235.30, 'doppioNetto' => 183.71},
                        '0302725009' => { 'codice' => '0302725009', 'prezzoAcquisto' => 784.30, 'doppioNetto' => 612.34},
                        '0302725010' => { 'codice' => '0302725010', 'prezzoAcquisto' => 319.44, 'doppioNetto' => 249.40},
                        '0302725011' => { 'codice' => '0302725011', 'prezzoAcquisto' => 506.76, 'doppioNetto' => 395.65},
                        '0302725012' => { 'codice' => '0302725012', 'prezzoAcquisto' => 769.66, 'doppioNetto' => 600.91},
                        '0302725013' => { 'codice' => '0302725013', 'prezzoAcquisto' => 789.86, 'doppioNetto' => 616.68},
                        '0302725015' => { 'codice' => '0302725015', 'prezzoAcquisto' => 347.20, 'doppioNetto' => 271.08},
                        '0302725016' => { 'codice' => '0302725016', 'prezzoAcquisto' => 364.54, 'doppioNetto' => 284.61},
                        '0302725017' => { 'codice' => '0302725017', 'prezzoAcquisto' => 789.86, 'doppioNetto' => 616.68},
                        '0402725002' => { 'codice' => '0402725002', 'prezzoAcquisto' => 265.05, 'doppioNetto' => 206.94},
                        '0402725003' => { 'codice' => '0402725003', 'prezzoAcquisto' => 201.90, 'doppioNetto' => 157.63},
                        '0402725004' => { 'codice' => '0402725004', 'prezzoAcquisto' => 251.00, 'doppioNetto' => 195.97},
                        '0502725001' => { 'codice' => '0502725001', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0502725006' => { 'codice' => '0502725006', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0502725007' => { 'codice' => '0502725007', 'prezzoAcquisto' => 276.83, 'doppioNetto' => 216.14},
                        '0502725010' => { 'codice' => '0502725010', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725012' => { 'codice' => '0502725012', 'prezzoAcquisto' => 160.59, 'doppioNetto' => 125.38},
                        '0502725013' => { 'codice' => '0502725013', 'prezzoAcquisto' => 501.16, 'doppioNetto' => 391.28},
                        '0502725014' => { 'codice' => '0502725014', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725016' => { 'codice' => '0502725016', 'prezzoAcquisto' => 145.80, 'doppioNetto' => 113.83},
                        '0502725018' => { 'codice' => '0502725018', 'prezzoAcquisto' => 1014.94, 'doppioNetto' => 792.41},
                        '0502725019' => { 'codice' => '0502725019', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725020' => { 'codice' => '0502725020', 'prezzoAcquisto' => 1045.16, 'doppioNetto' => 816.01},
                        '0502725021' => { 'codice' => '0502725021', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725022' => { 'codice' => '0502725022', 'prezzoAcquisto' => 1619.00, 'doppioNetto' => 1264.03},
                        '0502725023' => { 'codice' => '0502725023', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725024' => { 'codice' => '0502725024', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725025' => { 'codice' => '0502725025', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725026' => { 'codice' => '0502725026', 'prezzoAcquisto' => 336.95, 'doppioNetto' => 263.07},
                        '0502725027' => { 'codice' => '0502725027', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725028' => { 'codice' => '0502725028', 'prezzoAcquisto' => 501.16, 'doppioNetto' => 391.28},
                        '0502725029' => { 'codice' => '0502725029', 'prezzoAcquisto' => 731.56, 'doppioNetto' => 571.16},
                        '0502725030' => { 'codice' => '0502725030', 'prezzoAcquisto' => 603.56, 'doppioNetto' => 471.23},
                        '0502725031' => { 'codice' => '0502725031', 'prezzoAcquisto' => 603.56, 'doppioNetto' => 471.23},
                        '0502725032' => { 'codice' => '0502725032', 'prezzoAcquisto' => 603.56, 'doppioNetto' => 471.23},
                        '0502725033' => { 'codice' => '0502725033', 'prezzoAcquisto' => 603.56, 'doppioNetto' => 471.23},
                        '0502725034' => { 'codice' => '0502725034', 'prezzoAcquisto' => 603.56, 'doppioNetto' => 471.23},
                        '0502725035' => { 'codice' => '0502725035', 'prezzoAcquisto' => 501.16, 'doppioNetto' => 391.28},
                        '0502725036' => { 'codice' => '0502725036', 'prezzoAcquisto' => 501.16, 'doppioNetto' => 391.28},
                        '0502725037' => { 'codice' => '0502725037', 'prezzoAcquisto' => 501.16, 'doppioNetto' => 391.28},
                        '0502725038' => { 'codice' => '0502725038', 'prezzoAcquisto' => 501.16, 'doppioNetto' => 391.28},
                        '0502725039' => { 'codice' => '0502725039', 'prezzoAcquisto' => 501.16, 'doppioNetto' => 391.28},
                        '0502725040' => { 'codice' => '0502725040', 'prezzoAcquisto' => 622.76, 'doppioNetto' => 486.22},
                        '0502725041' => { 'codice' => '0502725041', 'prezzoAcquisto' => 501.16, 'doppioNetto' => 391.28},
                        '0502725042' => { 'codice' => '0502725042', 'prezzoAcquisto' => 501.16, 'doppioNetto' => 391.28},
                        '0502725043' => { 'codice' => '0502725043', 'prezzoAcquisto' => 501.16, 'doppioNetto' => 391.28},
                        '0502725044' => { 'codice' => '0502725044', 'prezzoAcquisto' => 488.36, 'doppioNetto' => 381.29},
                        '0502725045' => { 'codice' => '0502725045', 'prezzoAcquisto' => 622.76, 'doppioNetto' => 486.22},
                        '0502725046' => { 'codice' => '0502725046', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725047' => { 'codice' => '0502725047', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725048' => { 'codice' => '0502725048', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725049' => { 'codice' => '0502725049', 'prezzoAcquisto' => 1045.16, 'doppioNetto' => 816.01},
                        '0502725050' => { 'codice' => '0502725050', 'prezzoAcquisto' => 1045.16, 'doppioNetto' => 816.01},
                        '0502725051' => { 'codice' => '0502725051', 'prezzoAcquisto' => 1045.16, 'doppioNetto' => 816.01},
                        '0502725052' => { 'codice' => '0502725052', 'prezzoAcquisto' => 1045.16, 'doppioNetto' => 816.01},
                        '0502725053' => { 'codice' => '0502725053', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725054' => { 'codice' => '0502725054', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725055' => { 'codice' => '0502725055', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725056' => { 'codice' => '0502725056', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725057' => { 'codice' => '0502725057', 'prezzoAcquisto' => 1013.16, 'doppioNetto' => 791.02},
                        '0502725058' => { 'codice' => '0502725058', 'prezzoAcquisto' => 1045.16, 'doppioNetto' => 816.01},
                        '0502725059' => { 'codice' => '0502725059', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725060' => { 'codice' => '0502725060', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725061' => { 'codice' => '0502725061', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725062' => { 'codice' => '0502725062', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725063' => { 'codice' => '0502725063', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725064' => { 'codice' => '0502725064', 'prezzoAcquisto' => 1045.16, 'doppioNetto' => 816.01},
                        '0502725065' => { 'codice' => '0502725065', 'prezzoAcquisto' => 1045.16, 'doppioNetto' => 816.01},
                        '0502725066' => { 'codice' => '0502725066', 'prezzoAcquisto' => 1045.16, 'doppioNetto' => 816.01},
                        '0502725067' => { 'codice' => '0502725067', 'prezzoAcquisto' => 2278.00, 'doppioNetto' => 1778.54},
                        '0502725068' => { 'codice' => '0502725068', 'prezzoAcquisto' => 1045.16, 'doppioNetto' => 816.01},
                        '0502725070' => { 'codice' => '0502725070', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725071' => { 'codice' => '0502725071', 'prezzoAcquisto' => 1013.16, 'doppioNetto' => 791.02},
                        '0502725072' => { 'codice' => '0502725072', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725073' => { 'codice' => '0502725073', 'prezzoAcquisto' => 763.56, 'doppioNetto' => 596.15},
                        '0502725074' => { 'codice' => '0502725074', 'prezzoAcquisto' => 669.00, 'doppioNetto' => 522.32},
                        '0502725075' => { 'codice' => '0502725075', 'prezzoAcquisto' => 669.00, 'doppioNetto' => 522.32},
                        '0502725076' => { 'codice' => '0502725076', 'prezzoAcquisto' => 669.00, 'doppioNetto' => 522.32},
                        '0502725077' => { 'codice' => '0502725077', 'prezzoAcquisto' => 669.00, 'doppioNetto' => 522.32},
                        '0502725078' => { 'codice' => '0502725078', 'prezzoAcquisto' => 869.00, 'doppioNetto' => 678.47},
                        '0502725079' => { 'codice' => '0502725079', 'prezzoAcquisto' => 669.00, 'doppioNetto' => 522.32},
                        '0502725080' => { 'codice' => '0502725080', 'prezzoAcquisto' => 437.16, 'doppioNetto' => 341.31},
                        '0502725081' => { 'codice' => '0502725081', 'prezzoAcquisto' => 1016.96, 'doppioNetto' => 793.99},
                        '0502725082' => { 'codice' => '0502725082', 'prezzoAcquisto' => 669.00, 'doppioNetto' => 522.32},
                        '0502725083' => { 'codice' => '0502725083', 'prezzoAcquisto' => 424.36, 'doppioNetto' => 331.32},
                        '0502725084' => { 'codice' => '0502725084', 'prezzoAcquisto' => 669.00, 'doppioNetto' => 522.32},
                        '0502725085' => { 'codice' => '0502725085', 'prezzoAcquisto' => 552.36, 'doppioNetto' => 431.25},
                        '0502725086' => { 'codice' => '0502725086', 'prezzoAcquisto' => 869.00, 'doppioNetto' => 678.47},
                        '0502725087' => { 'codice' => '0502725087', 'prezzoAcquisto' => 603.56, 'doppioNetto' => 471.23},
                        '0505725001' => { 'codice' => '0505725001', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725003' => { 'codice' => '0505725003', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725004' => { 'codice' => '0505725004', 'prezzoAcquisto' => 219.94, 'doppioNetto' => 171.72},
                        '0505725005' => { 'codice' => '0505725005', 'prezzoAcquisto' => 320.40, 'doppioNetto' => 250.15},
                        '0505725006' => { 'codice' => '0505725006', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725008' => { 'codice' => '0505725008', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725009' => { 'codice' => '0505725009', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725010' => { 'codice' => '0505725010', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725011' => { 'codice' => '0505725011', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725012' => { 'codice' => '0505725012', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725013' => { 'codice' => '0505725013', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725014' => { 'codice' => '0505725014', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725015' => { 'codice' => '0505725015', 'prezzoAcquisto' => 955.56, 'doppioNetto' => 746.06},
                        '0505725017' => { 'codice' => '0505725017', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725018' => { 'codice' => '0505725018', 'prezzoAcquisto' => 963.86, 'doppioNetto' => 752.53},
                        '0505725019' => { 'codice' => '0505725019', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725020' => { 'codice' => '0505725020', 'prezzoAcquisto' => 1098.05, 'doppioNetto' => 857.30},
                        '0505725021' => { 'codice' => '0505725021', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725022' => { 'codice' => '0505725022', 'prezzoAcquisto' => 464.43, 'doppioNetto' => 362.60},
                        '0505725023' => { 'codice' => '0505725023', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725024' => { 'codice' => '0505725024', 'prezzoAcquisto' => 938.00, 'doppioNetto' => 732.34},
                        '0505725025' => { 'codice' => '0505725025', 'prezzoAcquisto' => 938.00, 'doppioNetto' => 732.34},
                        '0505725026' => { 'codice' => '0505725026', 'prezzoAcquisto' => 1138.00, 'doppioNetto' => 888.49},
                        '0505725027' => { 'codice' => '0505725027', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725028' => { 'codice' => '0505725028', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725029' => { 'codice' => '0505725029', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725030' => { 'codice' => '0505725030', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725031' => { 'codice' => '0505725031', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725032' => { 'codice' => '0505725032', 'prezzoAcquisto' => 1000.36, 'doppioNetto' => 781.03},
                        '0505725033' => { 'codice' => '0505725033', 'prezzoAcquisto' => 1231.20, 'doppioNetto' => 961.26},
                        '0505725034' => { 'codice' => '0505725034', 'prezzoAcquisto' => 1286.26, 'doppioNetto' => 1004.25},
                        '0505725035' => { 'codice' => '0505725035', 'prezzoAcquisto' => 1286.26, 'doppioNetto' => 1004.25},
                        '0505725036' => { 'codice' => '0505725036', 'prezzoAcquisto' => 2108.00, 'doppioNetto' => 1645.82},
                        '0505725037' => { 'codice' => '0505725037', 'prezzoAcquisto' => 2108.00, 'doppioNetto' => 1645.82},
                        '0505725038' => { 'codice' => '0505725038', 'prezzoAcquisto' => 2108.00, 'doppioNetto' => 1645.82},
                        '0505725039' => { 'codice' => '0505725039', 'prezzoAcquisto' => 1286.26, 'doppioNetto' => 1004.25},
                        '0505725040' => { 'codice' => '0505725040', 'prezzoAcquisto' => 2108.00, 'doppioNetto' => 1645.82},
                        '0505725042' => { 'codice' => '0505725042', 'prezzoAcquisto' => 2108.00, 'doppioNetto' => 1645.82},
                        '0505725043' => { 'codice' => '0505725043', 'prezzoAcquisto' => 2108.00, 'doppioNetto' => 1645.82},
                        '0510725005' => { 'codice' => '0510725005', 'prezzoAcquisto' => 422.83, 'doppioNetto' => 330.12},
                        '0510725007' => { 'codice' => '0510725007', 'prezzoAcquisto' => 1217.96, 'doppioNetto' => 950.92},
                        '0510725008' => { 'codice' => '0510725008', 'prezzoAcquisto' => 325.14, 'doppioNetto' => 253.85},
                        '0510725011' => { 'codice' => '0510725011', 'prezzoAcquisto' => 301.52, 'doppioNetto' => 235.41},
                        '0510725012' => { 'codice' => '0510725012', 'prezzoAcquisto' => 290.79, 'doppioNetto' => 227.03},
                        '0510725013' => { 'codice' => '0510725013', 'prezzoAcquisto' => 347.46, 'doppioNetto' => 271.28},
                        '0510725015' => { 'codice' => '0510725015', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725016' => { 'codice' => '0510725016', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725018' => { 'codice' => '0510725018', 'prezzoAcquisto' => 398.73, 'doppioNetto' => 311.30},
                        '0510725020' => { 'codice' => '0510725020', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725021' => { 'codice' => '0510725021', 'prezzoAcquisto' => 407.26, 'doppioNetto' => 317.97},
                        '0510725022' => { 'codice' => '0510725022', 'prezzoAcquisto' => 586.00, 'doppioNetto' => 457.51},
                        '0510725023' => { 'codice' => '0510725023', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725024' => { 'codice' => '0510725024', 'prezzoAcquisto' => 1128.36, 'doppioNetto' => 880.97},
                        '0510725025' => { 'codice' => '0510725025', 'prezzoAcquisto' => 367.54, 'doppioNetto' => 286.96},
                        '0510725026' => { 'codice' => '0510725026', 'prezzoAcquisto' => 347.68, 'doppioNetto' => 271.45},
                        '0510725027' => { 'codice' => '0510725027', 'prezzoAcquisto' => 425.48, 'doppioNetto' => 332.19},
                        '0510725028' => { 'codice' => '0510725028', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725029' => { 'codice' => '0510725029', 'prezzoAcquisto' => 935.00, 'doppioNetto' => 730.00},
                        '0510725030' => { 'codice' => '0510725030', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725031' => { 'codice' => '0510725031', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725032' => { 'codice' => '0510725032', 'prezzoAcquisto' => 446.79, 'doppioNetto' => 348.83},
                        '0510725033' => { 'codice' => '0510725033', 'prezzoAcquisto' => 391.99, 'doppioNetto' => 306.05},
                        '0510725034' => { 'codice' => '0510725034', 'prezzoAcquisto' => 383.04, 'doppioNetto' => 299.06},
                        '0510725035' => { 'codice' => '0510725035', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725036' => { 'codice' => '0510725036', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725037' => { 'codice' => '0510725037', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725038' => { 'codice' => '0510725038', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725039' => { 'codice' => '0510725039', 'prezzoAcquisto' => 1128.36, 'doppioNetto' => 880.97},
                        '0510725040' => { 'codice' => '0510725040', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725041' => { 'codice' => '0510725041', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725042' => { 'codice' => '0510725042', 'prezzoAcquisto' => 1128.36, 'doppioNetto' => 880.97},
                        '0510725043' => { 'codice' => '0510725043', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725044' => { 'codice' => '0510725044', 'prezzoAcquisto' => 1128.36, 'doppioNetto' => 880.97},
                        '0510725045' => { 'codice' => '0510725045', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725046' => { 'codice' => '0510725046', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725047' => { 'codice' => '0510725047', 'prezzoAcquisto' => 648.00, 'doppioNetto' => 505.93},
                        '0510725048' => { 'codice' => '0510725048', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725049' => { 'codice' => '0510725049', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725050' => { 'codice' => '0510725050', 'prezzoAcquisto' => 1128.36, 'doppioNetto' => 880.97},
                        '0510725051' => { 'codice' => '0510725051', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725052' => { 'codice' => '0510725052', 'prezzoAcquisto' => 1128.36, 'doppioNetto' => 880.97},
                        '0510725053' => { 'codice' => '0510725053', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725054' => { 'codice' => '0510725054', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725055' => { 'codice' => '0510725055', 'prezzoAcquisto' => 1224.36, 'doppioNetto' => 955.92},
                        '0510725061' => { 'codice' => '0510725061', 'prezzoAcquisto' => 883.00, 'doppioNetto' => 689.40},
                        '0520725001' => { 'codice' => '0520725001', 'prezzoAcquisto' => 1157.09, 'doppioNetto' => 903.39},
                        '0520725002' => { 'codice' => '0520725002', 'prezzoAcquisto' => 1098.05, 'doppioNetto' => 857.30},
                        '0520725003' => { 'codice' => '0520725003', 'prezzoAcquisto' => 910.19, 'doppioNetto' => 710.63},
                        '0520725004' => { 'codice' => '0520725004', 'prezzoAcquisto' => 1396.47, 'doppioNetto' => 1090.29},
                        '0520725006' => { 'codice' => '0520725006', 'prezzoAcquisto' => 1368.15, 'doppioNetto' => 1068.18},
                        '0520725007' => { 'codice' => '0520725007', 'prezzoAcquisto' => 1157.09, 'doppioNetto' => 903.39},
                        '0702725007' => { 'codice' => '0702725007', 'prezzoAcquisto' => 349.81, 'doppioNetto' => 273.11},
                        '0702725024' => { 'codice' => '0702725024', 'prezzoAcquisto' => 399.72, 'doppioNetto' => 312.08},
                        '0702725025' => { 'codice' => '0702725025', 'prezzoAcquisto' => 408.46, 'doppioNetto' => 318.90},
                        '0702725026' => { 'codice' => '0702725026', 'prezzoAcquisto' => 349.81, 'doppioNetto' => 273.11},
                        '0702725028' => { 'codice' => '0702725028', 'prezzoAcquisto' => 399.72, 'doppioNetto' => 312.08},
                        '0702725030' => { 'codice' => '0702725030', 'prezzoAcquisto' => 469.11, 'doppioNetto' => 366.26},
                        '0702725033' => { 'codice' => '0702725033', 'prezzoAcquisto' => 487.90, 'doppioNetto' => 380.92},
                        '0702725037' => { 'codice' => '0702725037', 'prezzoAcquisto' => 718.16, 'doppioNetto' => 560.70},
                        '0702725040' => { 'codice' => '0702725040', 'prezzoAcquisto' => 455.69, 'doppioNetto' => 355.78},
                        '0702725041' => { 'codice' => '0702725041', 'prezzoAcquisto' => 469.11, 'doppioNetto' => 366.26},
                        '0702725043' => { 'codice' => '0702725043', 'prezzoAcquisto' => 487.90, 'doppioNetto' => 380.92},
                        '0702725044' => { 'codice' => '0702725044', 'prezzoAcquisto' => 579.14, 'doppioNetto' => 452.16},
                        '0702725047' => { 'codice' => '0702725047', 'prezzoAcquisto' => 1395.52, 'doppioNetto' => 1089.55},
                        '0702725049' => { 'codice' => '0702725049', 'prezzoAcquisto' => 2139.50, 'doppioNetto' => 1670.41},
                        '0702725050' => { 'codice' => '0702725050', 'prezzoAcquisto' => 535.67, 'doppioNetto' => 418.22},
                        '0702725057' => { 'codice' => '0702725057', 'prezzoAcquisto' => 513.66, 'doppioNetto' => 401.04},
                        '0702725058' => { 'codice' => '0702725058', 'prezzoAcquisto' => 469.11, 'doppioNetto' => 366.26},
                        '0702725062' => { 'codice' => '0702725062', 'prezzoAcquisto' => 397.72, 'doppioNetto' => 310.52},
                        '0702725065' => { 'codice' => '0702725065', 'prezzoAcquisto' => 520.10, 'doppioNetto' => 406.07},
                        '0702725068' => { 'codice' => '0702725068', 'prezzoAcquisto' => 476.09, 'doppioNetto' => 371.71},
                        '0702725069' => { 'codice' => '0702725069', 'prezzoAcquisto' => 471.11, 'doppioNetto' => 367.82},
                        '0702725070' => { 'codice' => '0702725070', 'prezzoAcquisto' => 1308.30, 'doppioNetto' => 1021.46},
                        '0702725071' => { 'codice' => '0702725071', 'prezzoAcquisto' => 1210.18, 'doppioNetto' => 944.85},
                        '0702725072' => { 'codice' => '0702725072', 'prezzoAcquisto' => 648.23, 'doppioNetto' => 506.11},
                        '0702725073' => { 'codice' => '0702725073', 'prezzoAcquisto' => 397.72, 'doppioNetto' => 310.52},
                        '0702725074' => { 'codice' => '0702725074', 'prezzoAcquisto' => 648.23, 'doppioNetto' => 506.11},
                        '0702725076' => { 'codice' => '0702725076', 'prezzoAcquisto' => 485.93, 'doppioNetto' => 379.39},
                        '0702725078' => { 'codice' => '0702725078', 'prezzoAcquisto' => 1308.30, 'doppioNetto' => 1021.46},
                        '0702725079' => { 'codice' => '0702725079', 'prezzoAcquisto' => 485.93, 'doppioNetto' => 379.39},
                        '0702725083' => { 'codice' => '0702725083', 'prezzoAcquisto' => 571.43, 'doppioNetto' => 446.14},
                        '0702725084' => { 'codice' => '0702725084', 'prezzoAcquisto' => 554.33, 'doppioNetto' => 432.79},
                        '0702725085' => { 'codice' => '0702725085', 'prezzoAcquisto' => 1649.30, 'doppioNetto' => 1287.69});

if (&ConnessioneDB) {
    my $client = REST::Client->new();

    # nel caso di collegamento https non verifico il certificato
    $client->getUseragent()->ssl_opts(verify_hostname => 0);

    $client->POST($requestUrl);

    my $datiRicevuti = $client->POST($requestUrl, $requestParams, {'Content-type' => 'application/x-www-form-urlencoded'})->responseContent;
    my $tabulato = qq{$datiRicevuti};

 	#print "$requestUrl?$requestParams\n";
    #print $client->responseCode()."\n";

    if ( $client->responseCode() eq '200' ) {
    #if ( 1 ) {
        my $linea;
        open my $fh, '<:crlf', \$tabulato or die $!;
        #open my $fh, '<:crlf', '/Users/if65/Desktop/ARTICOLI_S.TXT' or die $!;

        while(! eof ($fh)) {
            $linea = <$fh>;
            $linea =~ s/\n$//ig;

            if ($linea =~ /^(\d{10}).{5}(.{11})(.{49})(\d{8})(\d{8})(\d{11})(\d{11})(\d{11})(.{2})(\w|\s)(\w|\s)(.{13})(.{15})(..)(.).(\d{2})(\d{2})(.{2})(.{2}).(.{3}).(\d{11})(\d{11})..(.)(.)..$/) {
                my $codice = rtrim($1);
                my $modello = rtrim($2);
                my $descrizione = rtrim($3);
                my $giacenza = $4 * 1;
                my $inOrdine = $5 * 1;
                my $prezzoAcquisto = $6 /100;
                my $prezzoRiordino = $7 /100;
                my $prezzoVendita = $8 /100;
                my $aliquotaIva = $9;
                my $novita = (rtrim($10) eq 'N');
                my $eliminato = (rtrim($10) eq 'X');
                my $esclusiva = (rtrim($11) ne '');
                my $ean = rtrim($12);
                my $marchioCopre = rtrim($13);
                my $griglia = rtrim($14);
                my $grigliaObbligo = (rtrim($15) ne '');
                my $ediel01 = rtrim($16);
                my $ediel02 = rtrim($17);
                my $ediel03 = rtrim($18);
                my $ediel04 = rtrim($19);

                my $marchio = rtrim($20);
                my $doppioNetto = $21/100;
                my $triploNetto = $22/100;
                my $ordinabile = (rtrim($23) eq 'Y');
                my $canale = $24;
                if ($codice =~ /160812504(0|2)/) {
                	$canale = 1;
                }

                if ($griglia eq 'C') {$griglia = ''};

                my $ricaricoPercentuale = 0;
                my $indiceRicarico = $ediel01.$ediel02;
                if (exists $ricarico{$indiceRicarico}) {
                    $ricaricoPercentuale = $ricarico{$indiceRicarico}{'ricarico'};
                } else {
                    my $indiceRicarico = $ediel01;
                    if (exists $ricarico{$indiceRicarico}) {
                        $ricaricoPercentuale = $ricarico{$indiceRicarico}{'ricarico'};
                    }
                }
                
                # Fatto inserire da Lovison x marchio SMEG
                if (exists $articoliAnomali{$codice}) {
                	$prezzoAcquisto =  $articoliAnomali{$codice}{'prezzoAcquisto'};
                    $prezzoAcquisto = sprintf('%.2f', 100/(100 + $ricaricoPercentuale) * $prezzoAcquisto)*1;
                    $doppioNetto = $articoliAnomali{$codice}{'doppioNetto'};
                    #print "codice: $codice, prezzoAcquisto: $articoliAnomali{$codice}{'prezzoAcquisto'}, prezzoAcquistoNetto: $prezzoAcquisto, doppioNetto: $articoliAnomali{$codice}{'doppioNetto'}\n";
                }

                my $pndAC = 0;
                my $pndAP = 0;
                my $indicePnd = $marchio.$ediel01.$ediel02.$ediel03.$ediel04;
                if (exists $pnd{$indicePnd}) {
                    $pndAC = $pnd{$indicePnd}{'pndAC'};
                    $pndAP = $pnd{$indicePnd}{'pndAP'};
                } else {
                    $indicePnd = $marchio.$ediel01.$ediel02.$ediel03;
                    if (exists $pnd{$indicePnd}) {
                        $pndAC = $pnd{$indicePnd}{'pndAC'};
                        $pndAP = $pnd{$indicePnd}{'pndAP'};
                    } else {
                        $indicePnd = $marchio.$ediel01.$ediel02;
                        if (exists $pnd{$indicePnd}) {
                            $pndAC = $pnd{$indicePnd}{'pndAC'};
                            $pndAP = $pnd{$indicePnd}{'pndAP'};
                        } else {
                            $indicePnd = $marchio.$ediel01;
                            if (exists $pnd{$indicePnd}) {
                                $pndAC = $pnd{$indicePnd}{'pndAC'};
                                $pndAP = $pnd{$indicePnd}{'pndAP'};
                            } else {
                                $indicePnd = $marchio;
                                if (exists $pnd{$indicePnd}) {
                                    $pndAC = $pnd{$indicePnd}{'pndAC'};
                                    $pndAP = $pnd{$indicePnd}{'pndAP'};
                                } else {
                                    $indicePnd = $ediel01.$ediel02.$ediel03;
                                    if (exists $pnd{$indicePnd}) {
                                        $pndAC = $pnd{$indicePnd}{'pndAC'};
                                        $pndAP = $pnd{$indicePnd}{'pndAP'};
                                    } else {
                                        $indicePnd = $ediel01.$ediel02;
                                        if (exists $pnd{$indicePnd}) {
                                            $pndAC = $pnd{$indicePnd}{'pndAC'};
                                            $pndAP = $pnd{$indicePnd}{'pndAP'};
                                        } else {
                                            $indicePnd = $ediel01;
                                            if (exists $pnd{$indicePnd}) {
                                                $pndAC = $pnd{$indicePnd}{'pndAC'};
                                                $pndAP = $pnd{$indicePnd}{'pndAP'};
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                my $feeCopre = $prezzoAcquisto*$ricaricoPercentuale/(100+$ricaricoPercentuale);
                my $nettoNetto = $doppioNetto - $doppioNetto*($pndAC+$pndAP)/100 + $feeCopre;
               #  if ($codice eq '0202001052') {
#                 	print "Prezzo Acquisto: $prezzoAcquisto\n";
#                 	print "Ricarico Copre : $ricaricoPercentuale\n";
#                 	print "Fee Copre      : $feeCopre\n";
#                 	print "Fee Copre      : ".sprintf('%.2f',$feeCopre)."\n";
#                 	print "Doppio Netto   : $doppioNetto\n";
#                 	print "PND Locale     : $pndAC\n";
#                 	print "PND Gre        : $pndAP\n";
#                 	print "Netto Netto    : $nettoNetto\n";
#                 	print "Netto Netto    : ".sprintf('%.2f',$nettoNetto)."\n";
#
#                 }

                my @elencoClienti = ( keys %clienti );

                for (my $i = 0; $i < @elencoClienti; $i++) {
                    my $ricaricoVendita01 = 0;
                    my $ricaricoVendita02 = 0;
                    my $ricaricoVendita03 = 0;
                    my $ricaricoVendita04 = 0;

                    my $indiceRicaricoVendita = $clienti{$elencoClienti[$i]}{'categoria'}.$codice;
                    if (exists $ricaricoVendita{$indiceRicaricoVendita}) {
                        $ricaricoVendita01 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita01'};
                        $ricaricoVendita02 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita02'};
                        $ricaricoVendita03 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita03'};
                        $ricaricoVendita04 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita04'};
                    } else {
                        $indiceRicaricoVendita = $clienti{$elencoClienti[$i]}{'categoria'}.$marchio.$ediel01.$ediel02.$ediel03.$ediel04;
                        if (exists $ricaricoVendita{$indiceRicaricoVendita}) {
                            $ricaricoVendita01 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita01'};
                            $ricaricoVendita02 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita02'};
                            $ricaricoVendita03 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita03'};
                            $ricaricoVendita04 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita04'};
                        } else {
                            $indiceRicaricoVendita = $clienti{$elencoClienti[$i]}{'categoria'}.$marchio.$ediel01.$ediel02.$ediel03;
                            if (exists $ricaricoVendita{$indiceRicaricoVendita}) {
                                $ricaricoVendita01 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita01'};
                                $ricaricoVendita02 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita02'};
                                $ricaricoVendita03 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita03'};
                                $ricaricoVendita04 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita04'};
                            } else {
                                $indiceRicaricoVendita = $clienti{$elencoClienti[$i]}{'categoria'}.$marchio.$ediel01.$ediel02;
                                if (exists $ricaricoVendita{$indiceRicaricoVendita}) {
                                    $ricaricoVendita01 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita01'};
                                    $ricaricoVendita02 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita02'};
                                    $ricaricoVendita03 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita03'};
                                    $ricaricoVendita04 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita04'};
                                } else {
                                    $indiceRicaricoVendita = $clienti{$elencoClienti[$i]}{'categoria'}.$marchio.$ediel01;
                                    if (exists $ricaricoVendita{$indiceRicaricoVendita}) {
                                        $ricaricoVendita01 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita01'};
                                        $ricaricoVendita02 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita02'};
                                        $ricaricoVendita03 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita03'};
                                        $ricaricoVendita04 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita04'};
                                    } else {
                                        $indiceRicaricoVendita = $clienti{$elencoClienti[$i]}{'categoria'}.$marchio;
                                        if (exists $ricaricoVendita{$indiceRicaricoVendita}) {
                                            $ricaricoVendita01 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita01'};
                                            $ricaricoVendita02 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita02'};
                                            $ricaricoVendita03 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita03'};
                                            $ricaricoVendita04 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita04'};
                                        } else {
                                            $indiceRicaricoVendita = $clienti{$elencoClienti[$i]}{'categoria'}.$ediel01.$ediel02.$ediel03;
                                            if (exists $ricaricoVendita{$indiceRicaricoVendita}) {
                                                $ricaricoVendita01 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita01'};
                                                $ricaricoVendita02 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita02'};
                                                $ricaricoVendita03 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita03'};
                                                $ricaricoVendita04 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita04'};
                                            } else {
                                                $indiceRicaricoVendita = $clienti{$elencoClienti[$i]}{'categoria'}.$ediel01.$ediel02;
                                                if (exists $ricaricoVendita{$indiceRicaricoVendita}) {
                                                    $ricaricoVendita01 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita01'};
                                                    $ricaricoVendita02 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita02'};
                                                    $ricaricoVendita03 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita03'};
                                                    $ricaricoVendita04 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita04'};
                                                } else {
                                                    $indiceRicaricoVendita = $clienti{$elencoClienti[$i]}{'categoria'}.$ediel01;
                                                    if (exists $ricaricoVendita{$indiceRicaricoVendita}) {
                                                        $ricaricoVendita01 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita01'};
                                                        $ricaricoVendita02 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita02'};
                                                        $ricaricoVendita03 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita03'};
                                                        $ricaricoVendita04 = $ricaricoVendita{$indiceRicaricoVendita}{'ricaricoVendita04'};
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    my $prezzoCliente = &arrotonda($nettoNetto + $nettoNetto*($ricaricoVendita01 + $ricaricoVendita02 + $ricaricoVendita03 + $ricaricoVendita04)/100);
                    if ($doppioNetto > 0.0) {
                    	$sth_cliente->execute($data, $elencoClienti[$i], $clienti{$elencoClienti[$i]}{'categoria'}, $codice, $doppioNetto, $nettoNetto, $ricaricoVendita01, $ricaricoVendita02, $ricaricoVendita03, $ricaricoVendita04, $prezzoCliente);
                    }
                }

                $sth->execute($timestamp, $codice, $modello, $descrizione, $giacenza, $inOrdine, $prezzoAcquisto, $prezzoRiordino, $prezzoVendita, $aliquotaIva, $novita,
                              $eliminato, $esclusiva, $ean, $marchioCopre, $griglia, $grigliaObbligo, $ediel01, $ediel02, $ediel03, $ediel04,
                              $marchio, $ricaricoPercentuale, $doppioNetto, $triploNetto, $nettoNetto, $ordinabile, $canale, $pndAC, $pndAP);



            }
        }
        $sth->finish();
        close $fh;
    }
}

sub ConnessioneDB {
	# connessione al database negozi
	$dbh = DBI->connect("DBI:mysql:copre:$hostname", $username, $password);
	if (! $dbh) {
		print "Errore durante la connessione al database!\n";
		return 0;
	}

    # cancellazione della tabelle precedenti (solo se serve)
    #$dbh->do(qq{drop table if exists `tabulatoCopre`});
    #$dbh->do(qq{drop table if exists `tabulatoCliente`});

    # creazione della table pnd
    $dbh->do(qq{
                CREATE TABLE IF NOT EXISTS `pnd` (
                    `marchio` varchar(3) NOT NULL DEFAULT '',
                    `ediel01` varchar(2) NOT NULL DEFAULT '',
                    `ediel02` varchar(2) NOT NULL DEFAULT '',
                    `ediel03` varchar(2) NOT NULL DEFAULT '',
                    `pndAC` float NOT NULL,
                    `pndAP` float NOT NULL
              ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });

    # creazione della table politica di vendita
    $dbh->do(qq{
                CREATE TABLE IF NOT EXISTS `politicaVendita` (
                    `id` int(11) unsigned NOT NULL,
                    `categoria` varchar(20) NOT NULL DEFAULT '',
                    `marchio` varchar(3) NOT NULL DEFAULT '',
                    `ediel01` varchar(2) NOT NULL DEFAULT '',
                    `ediel02` varchar(2) NOT NULL DEFAULT '',
                    `ediel03` varchar(2) NOT NULL DEFAULT '',
                    `ediel04` varchar(2) NOT NULL DEFAULT '',
                    `griglia` varchar(2) DEFAULT NULL,
                    `codiceArticolo` varchar(20) DEFAULT NULL,
                    `dataInizio` date DEFAULT NULL,
                    `dataFine` date DEFAULT NULL,
                    `ricarico01` float DEFAULT NULL,
                    `ricarico02` float DEFAULT NULL,
                    `ricarico03` float DEFAULT NULL,
                    `ricarico04` float DEFAULT NULL,
               PRIMARY KEY (`id`,`categoria`,`marchio`,`ediel01`,`ediel02`,`ediel03`,`ediel04`)
             ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });

    # creazione della table tabulatoCopre
    $dbh->do(qq{
                CREATE TABLE IF NOT EXISTS `tabulatoCopre` (
                    `idTime` datetime NOT NULL DEFAULT '0000-00-00 00:00:00',
                    `codice` varchar(10) NOT NULL DEFAULT '',
                    `modello` varchar(11) DEFAULT NULL,
                    `descrizione` varchar(49) DEFAULT NULL,
                    `giacenza` int(11) DEFAULT NULL,
                    `inOrdine` int(11) DEFAULT NULL,
                    `prezzoAcquisto` float DEFAULT NULL,
                    `prezzoRiordino` float DEFAULT NULL,
                    `prezzoVendita` float DEFAULT NULL,
                    `aliquotaIva` int(11) DEFAULT NULL,
                    `novita` tinyint(11) DEFAULT NULL,
                    `eliminato` tinyint(11) DEFAULT NULL,
                    `esclusiva` tinyint(11) DEFAULT NULL,
                    `barcode` varchar(13) DEFAULT NULL,
                    `marchioCopre` varchar(15) DEFAULT NULL,
                    `griglia` varchar(2) DEFAULT NULL,
                    `grigliaObbligatorio` tinyint(2) DEFAULT NULL,
                    `ediel01` varchar(2) DEFAULT NULL,
                    `ediel02` varchar(2) DEFAULT NULL,
                    `ediel03` varchar(2) DEFAULT NULL,
                    `ediel04` varchar(2) DEFAULT NULL,
                    `marchio` varchar(3) DEFAULT NULL,
                    `ricaricoPercentuale` float DEFAULT NULL,
                    `doppioNetto` float DEFAULT NULL,
                    `triploNetto` float DEFAULT NULL,
                    `nettoNetto` float DEFAULT NULL,
                    `ordinabile` tinyint(2) DEFAULT NULL,
                    `canale` int(2) DEFAULT NULL,
                    `pndAC` float DEFAULT NULL,
                    `pndAP` float DEFAULT NULL,
                PRIMARY KEY (`codice`),
  				KEY `ediel` (`ediel01`,`ediel02`,`ediel03`,`ediel04`),
  				KEY `marchio` (`marchio`),
  				KEY `idTime` (`idTime`)
                ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
    });

    # creazione della table tabulatoCliente
    $dbh->do(qq{
                CREATE TABLE IF NOT EXISTS `tabulatoCliente` (
                    `data` date NOT NULL,
                    `codiceCliente` varchar(20) NOT NULL DEFAULT '',
                    `categoria` varchar(20) NOT NULL DEFAULT '',
                    `codiceArticolo` varchar(10) NOT NULL DEFAULT '',
                    `doppioNetto` float DEFAULT 0,
                    `nettoNetto` float DEFAULT 0,
                    `ricarico01` float DEFAULT 0,
                    `ricarico02` float DEFAULT 0,
                    `ricarico03` float DEFAULT 0,
                    `ricarico04` float DEFAULT 0,
                    `prezzoCliente` float DEFAULT 0,
                PRIMARY KEY (`data`,`codiceCliente`,`codiceArticolo`)
              ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
});

    # caricamento pnd
    $sth = $dbh->prepare(qq{select concat(marchio,ediel01,ediel02,ediel03), marchio, ediel01, ediel02, ediel03, pndAC, pndAP from pnd order by 1});
    if ($sth->execute()) {
        while (my @record = $sth->fetchrow_array()) {
            $pnd{$record[0]} = {'marchio' => $record[1], 'ediel01' => $record[2], 'ediel02' => $record[3], 'ediel03' => $record[4], 'pndAC' => $record[5], 'pndAP' => $record[6]};
        }
    }

    # caricamento ricarico
    $sth = $dbh->prepare(qq{select ediel01, ediel02, ricarico from ricarico order by 1, 2});
    if ($sth->execute()) {
        while (my @record = $sth->fetchrow_array()) {
            if ($record[1] eq '') {
                $ricarico{$record[0]} = {'ricarico' => $record[2]};
            } else {
                $ricarico{$record[1]} = {'ricarico' => $record[2]};
            }
        }
    }

    # caricamento elenco clienti
    $sth = $dbh->prepare(qq{select codice, categoria from clienti order by 1});
    if ($sth->execute()) {
        while (my @record = $sth->fetchrow_array()) {
            $clienti{$record[0]} = { 'categoria' => $record[1] };
        }
    }

    # caricamento politica di vendita
    $sth = $dbh->prepare(qq{select concat(categoria,marchio,ediel01,ediel02,ediel03,ediel04,codiceArticolo), ricarico01, ricarico02, ricarico03, ricarico04 from politicaVendita order by 1, 2});
    if ($sth->execute()) {
        while (my @record = $sth->fetchrow_array()) {
            $ricaricoVendita{$record[0]} = {'ricaricoVendita01' => $record[1], 'ricaricoVendita02' => $record[2], 'ricaricoVendita03' => $record[3], 'ricaricoVendita04' => $record[4]};
        }
    }

    # caricamento della table tabulato copre
    $sth = $dbh->prepare(qq{replace into tabulatoCopre
                                (idTime, codice, modello, descrizione, giacenza, inOrdine, prezzoAcquisto, prezzoRiordino, prezzoVendita, aliquotaIva, novita,
                                 eliminato, esclusiva, barcode, marchioCopre, griglia, grigliaObbligatorio, ediel01, ediel02, ediel03, ediel04,
                                 marchio, ricaricoPercentuale, doppioNetto, triploNetto, nettoNetto, ordinabile, canale, pndAC, pndAP)
                            values
                                (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                            });

    # caricamento della table tabulato cliente
    $sth_cliente = $dbh->prepare(qq{replace into tabulatoCliente
                                        (data, codiceCliente, categoria, codiceArticolo, doppioNetto, nettoNetto, ricarico01, ricarico02, ricarico03, ricarico04, prezzoCliente)
                                    values
                                        (?,?,?,?,?,?,?,?,?,?,?)
                                });


    return 1;
}

sub arrotonda {
    my ($importo) = @_;

    my $parteIntera = sprintf('%d', $importo)*1;
    my $parteDecimale = sprintf('%.2f', $importo - $parteIntera)*1;

    my $importoArrotondato = 0;
    if ($importo <10 && $importo > 0.03) {
        $importoArrotondato = $parteIntera + ceil($parteDecimale*10)/10;
    } elsif ($importo >= 10 && $importo < 100) {
        if ($parteDecimale < 0.20) {
            $importoArrotondato = $parteIntera;
        } elsif ($parteDecimale >= 0.20 && $parteDecimale < 0.70) {
            $importoArrotondato = $parteIntera + 0.5;
        } else {
             $importoArrotondato = $parteIntera + 1;
        }

    } else {
        if ($parteDecimale < 0.30) {
            $importoArrotondato = $parteIntera;
        } else {
            $importoArrotondato = $parteIntera + 1;
        }
    }

    return $importoArrotondato;
}

sub ltrim { my $s = shift; $s =~ s/^\s+//;       return $s };
sub rtrim { my $s = shift; $s =~ s/\s+$//;       return $s };
sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; return $s };
