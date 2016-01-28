#!/usr/bin/env perl -n
BEGIN {
  print "var fileData = '[\\\n";
}
#                formatQuery("https://one.durango.ctools.org/todolms/ralt/ctools", "2016-01-27T12:56:51.131000", 0.052) \
($time,$duration,$query) = split();
print "\tformatQuery(\"$query\", \"$time\",$duration),\\","\n";
END {
  print "];';\n";
}
#end
