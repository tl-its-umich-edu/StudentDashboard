## Utilities
1. Check the Rakefile for useful tasks for running tests and running the application in a local Vagrant server.  
To see the available command run the following command in the StudentDashboard directory above.
> rake -T
1. build.sh - Package the application as a war file.
1. runServerBundle.sh - Startup up a test instance on localhost 3000.

## To get performance data for external dependencies from a StudentDashboard instance:

1. Go to the tools/data directory.
1. Get Dashboard logs -  Run ./getDashLogs.sh with a server name for the source of the logs. The script
can expand a bare hostname to a fully qualified name for known servers. The logs will be placed in an appropriate 
local directory named with the host name and timestamp.
 E.g.
>   ./getDashLogs.sh skylark
1. Parse the logs - Run ./parseLogs.pl with the log files as input, format the output, and put it in a json filefile.
E.g.
>   ./parseLogs.pl skylark.2016-02-04-09-03/* | ./formatJson.pl >| data.js
1. Visit the local html page Dash-Externals.html to display URL requests and their elapsed times.  That page reads data 
from the file data.js.  It is convient to make data.js a symbolic link to a file with real data. The URLs displayed can 
be filtered by URL and date range. A flag in the html source can toggle between displaying each request on a separate
line or displaying all requests to the same URL on the same line.
On a Mac you can use the command line:
> open ./Dash-Externals.html
