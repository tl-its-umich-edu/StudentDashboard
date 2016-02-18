## Utilities
1. Check the Rakefile for useful tasks for running tests and running the application in a local Vagrant server.  
To see the available commands run the following command in the main StudentDashboard directory.
> rake -T
1. build.sh - Package the application as a war file.
1. runServerBundle.sh - Startup up a test instance on localhost 3000.

## To get performance data for external dependencies from a StudentDashboard instance:

1. Go to the tools/data directory.
1. Get Dashboard logs -  Run ./getDashLogs.sh with a Dash server name to get it's logs. The script
can expand a bare hostname to a fully qualified name for known servers. The logs will be placed in an appropriate 
local directory named with the host name and timestamp.
E.g. To get logs from skylark.dsc.umich.edu use:
>   ./getDashLogs.sh skylark
1. Parse the logs - Run the ./parseLogs.pl script with the log files as input, format the output, and put it in a json 
format file.
E.g. For the specified skylark download run:
>   ./parseLogs.pl skylark.2016-02-04-09-03/* | ./formatJson.pl >| data.js
1. Visit the local html page *./Dash-Externals.html* to display the external URL requests and their elapsed times.  
That html page reads data 
from the file data.js.  It is convenient to make data.js a symbolic link to a file with real data. The URLs displayed can 
be filtered by URL and date range. A hardcoded flag in the html source *(singleLineDisplay)* can be used to toggle between displaying 
each request on a separate
line or displaying all requests to the same URL on the same line.
On a Mac you can open the page with the command line:
> open ./Dash-Externals.html
