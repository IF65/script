#!/usr/bin/perl
use strict;
use warnings;
use Mac::iTunes::Library;
 use Mac::iTunes::Library::XML;

  my $library = Mac::iTunes::Library::XML->parse( '/Users/italmark/Music/iTunes/iTunes Music Library.xml' );
  print "This library has only " . $library->num() . "item.\n";