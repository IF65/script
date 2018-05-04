#!/usr/bin/perl -w

# Always be safe
use strict;
use warnings;

# Use the module
use Mail::IMAPClient;
use MIME::Parser;
use Data::Dumper;

use constant {
    MULTIPART => "MULTIPART",
    TEXT => "TEXT"
};

my $imap = Mail::IMAPClient->new( 
        Server => "mail-srv1.italmark.com",
        User => 'marco.gnecchi@italmark.com',
        password => "mgnecchi", 
        Port => 143, 
        Ssl=> 0,
        Uid=> 1) or die "IMAP Failure: $@";

$imap->select("INBOX") or die "IMAP Select Error: $@";
foreach my $box qw( INBOX ) {
    # How many msgs are we going to process
    print "There are ". $imap->message_count($box).  " messages in the $box folder.\n";
    # Select the mailbox to get messages from
    $imap->select($box) or die "IMAP Select Error: $@";

    # Store each message as an array element
    my @msgseqnos = $imap->messages() or die "Couldn't get all messages $@\n";

    # Loop over the messages and store in file
    foreach my $seqno (@msgseqnos) {
        my $parser = MIME::Parser->new;
        my $entity = $parser->parse_data($imap->message_string($seqno));
        my $header = $entity->head;
        my $from = $header->get_all("From");
        my $msg_id = $header->get("message-id");
        my $to = $header->get_all("To");
        my $date = $header->get("date");
        my $subject = $header->get("subject");
        print "From: ". Dumper($from);
        print "Message-id:  $msg_id";
        print "To: $to";
        print "Date: $date";
        print "Subject: $subject";
        my $content = get_msg_content($entity);
        $entity->purge();
        print "Content: $content";
    }

# Expunge and close the folder
    $imap->expunge($box);
    $imap->close($box);
}

# We're all done with IMAP here
$imap->logout();

sub split_entity
{
    local $entity = shift;
    my $num_parts = $entity->parts; # how many mime parts?
    if ($num_parts) { # we have a multipart mime message
        foreach (1..$num_parts) {
            split_entity( $entity->parts($_ - 1) ); # recursive call
        }
    } else { # we have a single mime message/part
        if ($entity->effective_type =~ /^text\/plain$/) { # text message
            print "Part Content: " . $entity->bodyhandle->as_string;
        } else { # no text message
            print "Attachment Content: ". handle_other($entity->bodyhandle->path);
        }
    }
}

sub handle_other()
{
    local $path = shift;
    
}
