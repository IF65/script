#!/usr/bin/perl –w
use strict;
use warnings;

my $cmd ='/Applications/4D\ v12.3\ \(Custom\)/4D\ Server.app/Contents/MacOS/4D\ Server';




my $mypid = fork(); ##?? not sure how this actually works
	if (! $mypid)
		{
		# put your exec here to run in the child process.
		exec($cmd);
		}
	elsif (undef $mypid)
		{
		# fork() failed.
		}
		else
			{
			# put exec here to run in the parent process
			}
			# you may want to exit one or both processes somewhere in this block too...
