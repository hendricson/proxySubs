#!/usr/bin/perl

use JSON;
use LWP::Simple; #this is the package with web access
do "proxySubs.pl";

$output_file = 'read_url.txt';
$url = 'http://hendricson.com';

open(OUTPUT_FILE, '>'.$output_file) or die "Couldn't open $Output_file: $!";
select(OUTPUT_FILE);  # Makes $_ point to the file

print STDOUT "\nURL = $url";

($content, $status) = getHTTPContents($url);

print STDOUT "status=", $status, "\n";
print STDOUT "content=", $content, "\n";

if (!defined $content)
    { die "\nCouldn't read $url";}
else {print STDERR "\nLength of page read = " . length $content;}

print OUTPUT_FILE $content;
close(OUTPUT_FILE);
