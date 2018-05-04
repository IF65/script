#!/usr/bin/perl -w

use Getopt::Long;
use IO::File;
use MIME::QuotedPrint;
use MIME::Base64;
use Mail::Sendmail;
use strict;
use warnings;

my $cc;
my $bcc;
GetOptions( 'cc=s' => \$cc, 'bcc=s' => \$bcc, );

my( $from, $to, $subject, $msgbody, $attachment_file ) = @ARGV;

my $attachment_data = encode_base64( read_file( $attachment_file, 1 ) );

my %mail = (
    To   => $to,
    From => $from,
    Subject => $subject,
    smtp => '10.11.14.234'
);

$mail{Cc} = $cc if $cc;
$mail{Bcc} = $bcc if $bcc;

my $boundary = "====" . time . "====";

$mail{'content-type'} = qq(multipart/mixed; boundary="$boundary");

$boundary = '--'.$boundary;

$mail{body} = <<END_OF_BODY;
$boundary
Content-Type: text/plain; charset="iso-8859-1"
Content-Transfer-Encoding: quoted-printable

$msgbody
$boundary
Content-Type: application/octet-stream; name="$attachment_file"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="$attachment_file"

$attachment_data
$boundary--
END_OF_BODY

sendmail(%mail) or die $Mail::Sendmail::error;

print "Sendmail Log says:\n$Mail::Sendmail::log\n";

sub read_file
{
    my( $filename, $binmode ) = @_;
    my $fh = new IO::File;
    $fh->open("< $filename")
        or die "Error opening $filename for reading - $!\n";
    $fh->binmode if $binmode;
    local $/;
    <$fh>
}