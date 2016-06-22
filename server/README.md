# Student Dashboard data access

# Data providers
Dashboard gets data from three sources:

* MPathways - via calls to an ESB API.
* Canvas - via an ESB API.
* CTools - via direct calls to CTools.

Data provider methods are supplied for the different approaches to retrieval.
Sensitive connection information is always segregated to the security.yml file.

## WAPI data Format

Regardless of the retrieval method the data is returned wrapped in some additional 
status json.  This is provided so 
that the user of the data can always count on getting a json return string even
if there is an error during retrieval.  E.g. an error indicating that the
remote service has timed out could be returned and the user of the provider doesn't
need to worry about trapping errors, just about responding to the condition reported to it
in the status.

The calls to the internal API bypass the UI and will always return a wrapped value in the JSON format below.

{ Meta: {httpStatus: <extended http status>,"Message" : <something cool with words>},
  More: <url for additional data if appropriate>,
  Result: <result>
  }

The Meta httpStatus reflects the result of the call.  If the API call was successful it will match the 
httpStatus
from the remote API.  "Successful" here means that the remote API source handled the call and returned.
It does not mean that the data was retrieved, just that the result is one from successful communication
with the remote server. If there is a problem that required the Dashboard code to act  
then the Meta httpStatus will be an UNKNOWN_ERROR.  See the file WAPI_STATUS.rb for a list of possible status
values.
The Meta Message and the Result section likely have more information but this is not assured.  The More
section will have an entry only if the request returned a header with a URL pointing to additional
information.

Note that the value in the result is what was returned from the API call. It is not assured to be valid JSON
when evaluated. If you expect a JSON result it will be returned as a string and that string will need to be parsed.

### Performance analysis :
To make understanding performance of external dependencies easier there are a few scripts in the tools/data directory.

* getDashLogs.sh - Copy, via scp, log files from a dash server to a local directory.
* parseLogs.pl - Extract performance data from log files to a csv (tab separated) format.
* formatjson.pl - Format csv data as JSON that can be used by the following web page.
* Dash-Externals.html - Expects a file 'data.js' as formatted by formatjson.pl.  Displays url query times by 
url.

To look at performance data use these scripts to:

* retrieve log data with getDashLogs.sh.
* extract out the performance data from the logs with parseLogs.pl.
* format the data for the display page with formatjson.pl.  This data needs to be put in the file 'data.js'.
* Load the html page Dash-Externals.html.  This needs to load from the directory containing the 'data.js' file.

The following line is an example of looking at all the logs in a directory, formatting them and putting them
into a js file that can be used for input to the analysis html page.

> ./parseLogs.pl durango.2016-02-04-10-24/* | ./formatJson.pl >| ./durango.2016-02-04-10-24.js


