#!/usr/bin/perl
use LWP::Simple;
use File::stat;
use Time::localtime;

## START SETTINGS

$source = 'url'; # can be either 'file', 'database' or 'url'
$proxycache = 'proxycache.txt'; #filename of the file to keep list of proxies

#URL to grab fresh list of proxies from
$proxyurl = 'http://yoursite/proxylist.txt';

# Database settings. Leave empty if you're not planning to use database
$dbname = "";
$dbhost = "localhost";
$dbuser = "";
$dbpass = "";

## END SETTINGS

if ($source eq 'database') {
$dbh = DBI->connect("DBI:mysql:database=$dbname;host=$dbhost", $dbuser, $dbpass, {
                         mysql_enable_utf8 => 1
                    });
}

sub _readProxyFile {
   my $proxycache = shift;
   my $proxyurl = shift;
   open(OUTPUT_FILE, '>'.$proxycache) or die "Couldn't open $proxycache: $!";
   select(OUTPUT_FILE);  # Makes $_ point to the file

   my $document = get $proxyurl; # GET WHOLE MAIN PAGE FROM THE WWW
   if (!defined $document)
             { die "\nCouldn't read $proxyurl";}
   print OUTPUT_FILE $document;
   close(OUTPUT_FILE);
   return $document;
}

sub readProxiesFromURL {
    my @proxies;

    my $e = 1;
    my $document = '';
    open my $fh, '<', $proxycache or $e = 0;
    if ($e == 1) {
         my $timestamp = stat($fh)->mtime;
         my $hours = int(abs(time - $timestamp)/3600);
         if ($hours < 1) {#if the file was created less than an hour ago, use it
               $document = do {
                   local $/ = undef;
                   open my $fh, "<", $proxycache
                       or die "could not open $file: $!";
                   <$fh>;
               };
         } else {
               $document = _readProxyFile($proxycache, $proxyurl);
         }
    } else {
         $document = _readProxyFile($proxycache, $proxyurl);
    }
    @proxies = split("\n", $document);

    return @proxies;
}

sub readProxiesFromDB {
    my @proxies;

    $q = "SELECT proxy FROM proxies ORDER BY RAND() LIMIT 100";
    $records_fetch=$dbh->prepare($q);
    $records_fetch->execute;
    while ( ($proxy) = $records_fetch->fetchrow ) {
              push @proxies, $line;
    }
    return @proxies;
}
sub readProxiesFromFile {
     my @proxies;

     open SRC, $proxycache or die "Cannot read the proxy list";
     while(my $line = <SRC>){
             # remove empty spaces and line separation characters
             $line =~ s/^\s+//;
             $line =~ s/\s+$//;
             push @proxies, $line;
     }
     close SRC;
     return @proxies;
}
sub getHTTPContents {
    my @proxies;
    my $url = shift;
    my $agent = LWP::UserAgent->new;
    my $number_proxies_processed = 0;
    my $status = 0;
    my $content = '';

    if ($source eq 'database') {
      @proxies = readProxiesFromDB();
    } elsif ($source eq 'file'){
      @proxies = readProxiesFromFile();
    } else {
      @proxies = readProxiesFromURL();
    }

    $agent->agent('Mozilla/5.0 (Windows NT 6.1; WOW64; rv:21.0) Gecko/20100101 Firefox/21.0');
    $agent->timeout(20); # wait up to 20 sec. otherwise it would take too much time...

    foreach my $proxy(@proxies){
             $number_proxies_processed++;
             print STDOUT "\nConnecting to ",$url, " with ", $proxy, "\n";
             my $resp = '';
             my $res = '';
             my $success = 0;
             eval { #some wrong proxy addresses like -177-22-105-54.speedtravel.net.br:80 can possibly crash the script
                        #start: checking if proxy is still alive
                        $agent->agent("$0/0.1 " . $agent->agent);
                        $agent->proxy('http', "http://$proxy");

                        $req = HTTP::Request->new(HEAD => $url);
                        $req->header('Accept' => 'text/html');

                        $res = $agent->request($req);
                        #end: checking if proxy is still alive

                        if ($res->is_success) {#yes, that proxy is alive
                             $url = $res->request()->uri();
                             print STDOUT $number_proxies_processed." (connecting to real url)",$url,")\n";
                             $resp = $agent->get($url);
                             $success = $resp->is_success;
                             if ($success) {
                                  $content = $resp->decoded_content();
                                  return ($content, 1);
                             } else {
                                 print STDOUT "ERROR:".$resp->status_line."\n";
                             }
                        } else {
                             print STDOUT "ERROR:".$res->status_line."\n";
                        }

             } or do {
               my $e = $@;
               print STDOUT $e, "\n";
             };


      if (!$status) {
             print STDOUT $proxy, " is a bad proxy\n";
             if ($source eq 'database') {
                          $q = "UPDATE proxies SET failed = failed + 1 WHERE proxy = '$proxy'";
                          $sth = $dbh->prepare($q);
                          if (!$sth) {print STDOUT  "Cannot prepare: " . $dbh->errstr()."\n";}
                          $sth->execute();
             }
      }

     }
     if ($number_proxies_processed == 0) {
          print STDOUT "NO PROXIES FOUND. Quitting\n";
          exit;
     }
     return ($content, 0);
}
