#!/usr/bin/perl –w
use strict;
use warnings;
use Mac::iTunes::Library;

  my $library = Mac::iTunes::Library->new();
  my $item = Mac::iTunes::Library::Item->new(
        'Track ID' => 1,
        'Name' => 'The Fooiest Song',
        'Artist' => 'The Bar Band',
        );
  $library->add($item);
  print "This library has only " . $library->num() . "item.\n";