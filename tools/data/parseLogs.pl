#!/usr/bin/env perl

# Read Student Dashboard logfiles and extract elapsed times from 'stopwatch' lines.
# Format output as a 3 tuple <iso8601 date, elapsed time (seconds), url>

($use,$skip) = (0,0);

# skip localhost calls
$skipLocalhost = 1;

while (<>) {
  next if (/localhost/i) && $skipLocalhost;
  next unless (/stopwatch/i);
  next if (/Courselist:before/i);
  next if (/stopwatch:0x/i);
  next unless(/\shttp/i);
  
  # get the stopwatch result for http requests.
  if (/\[(\d\d\d\d-\d\d-\d.+) \#.+\].+stopwatch:\s+([.0-9]+),.+\s(http.*)/i) {
    print "$1\t$2\t$3\n";
    $use++;
  } else {
    print "----: $_";
    $skip++;
  }
}
END {
  #  print "use: $use skip: $skip\n"; # for debugging.
}
#end
