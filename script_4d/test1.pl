#!/usr/bin/perl –w
use strict;
use warnings;

#-- check if process 1525 is running
$exists = kill 0, 1525;
print "Process is running\n" if ( $exists );
