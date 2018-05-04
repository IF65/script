#!/usr/bin/perl –w
use strict;
use warnings;
use Mail::IMAPClient;
  
 # returns an unconnected Mail::IMAPClient object:
 my $imap = Mail::IMAPClient->new;
 # ...
 # intervening code using the 1st object, then:
 # (returns a new, authenticated Mail::IMAPClient object)
 $imap = Mail::IMAPClient->new(
			Server   => 'mail-srv1.italmark.com:143',
			User     => 'marco.gnecchi@italmark.com',
			Password => 'mgnecchi',
			Clear    => 5,   # Unnecessary since '5' is the default
      		# ...            # Other key=>value pairs go here
  		) or die "Cannot connect: $@";
  		
# Seleziona la MailBox nella quale cercare il messaggio   		
$imap->select("INBOX") or die "Could not select: $@\n";
   		
# Carico l'elenco degli ID dei messaggi presenti nella MailBox selezionata  		
my @msgs = $imap->search('FROM','info@qberg.com');

print "@msgs\n";


$imap->logout;