# Student Dashboard data server
This implements a simple REST ruby web server based on Ruby Sinatra DSL.
It expects to return data in json format.

The server also supports running the main dashboard UI page.

To get the UI page simply visit the base URL for 
the application.  E.g. https://<host>/
The root element of the URL can be configured.

# Data providers
There are 3 data providers supplied:

* ESB - API based
* CTools Direct - Queries direct to CTools
* DFB - disk file based

The data is returned wrapped in some additional status json.  This is used so
that the user of the data can always count on a json return string even
if there is an error during retrieval.  E.g. an error indicating that the
remote service has timed out could be returned and the user of the provider doesn't
need to worry about trapping errors, just about responding to the condition reported to it
in the status.

## ESB Data provider
This provider used the UMich WSO2 based ESB to get user data.  Configuration
of this provider is entirely within the security.yml file.  See that file
for details.

## CTools Direct
This provider directly queries the CTools / Sakai direct API

## File based Data provider
The File based data provider will retrieve user data from
files on disk.  The specific directory to use is specified in the
studentdashboard.yml file by the *data_provider_file_directory*  entry.
This is documented further in each studentdashboard yml file.

The provider will expect to find a file named *user name.json* in that
directory. If no matching file is found then a 404 / empty string is returned.
No checking is done on the user so that the user name specified need not be a real
user. One advantage of this is that files can be constructed to contain
data with specific constructions or errors and can be used for testing.  E.g. the file *test-long-long-strings.json*
could be used to test data with particularly long strings.

The file based server currently only implements requests for the course
data. It could easily be extended to support other types such as term or todo data.

The json in the file can just be exactly the data that would be expected from a live service.  It will be wrapped
in the  status json automatically.  In order to make testing easier the disk file can also can
contain the status json explicitly.  In that case the file will be returned as is and will not be further wrapped.
See the "meta" files in the test-files/courses directory for examples.


----
## API Format

The calls to the internal API bypass the UI and will always return a wrapped value in the JSON format below.

{ Meta: {httpStatus: <somethingcool>,"Message" : <something cool with words>}
  Result: <result>
  }

The Meta httpStatus reflects the result of the call.  If the API call was successful it will match the httpStatus
from the remote API.  "Successful" here means that the remote API handled the call.  It does not mean that the call
worked.  It means that the Student Dashboard code didn't need to intrude on the call.
If there is a problem that required the Latte code to respond then the Meta httpStatus will be 666
The Meta Message and the Result section likely have more information but this is not assured.

Note that the value in the result is what was returned from the API call. It is not assured to be valid JSON
when evaluated. If you expect a JSON result it will be returned as a string and that string will need to be parsed.

The calls to the internal API bypass the UI and will always return a wrapped value in the JSON format below.

{ Meta: {httpStatus: <somethingcool>,"Message" : <something cool with words>}
  Result: <result>
  }

The Meta httpStatus reflects the result of the call.  If the API call was successful it will match the httpStatus
from the remote API.  "Successful" here means that the remote API handled the call.  It does not mean that the call
worked.  It means that the Student Dashboard code didn't need to intrude on the call.
If there is a problem that required the Latte code to respond then the Meta httpStatus will be 666
The Meta Message and the Result section likely have more information but this is not assured.

Note that the value in the result is what was returned from the API call. It is not assured to be valid JSON
when evaluated. If you expect a JSON result it will be returned as a string and that string will need to be parsed.


### Ruby COMMANDS:

Note that some of the scripts below package the commands to make things easier.

* guard - (run in a separate terminal window to bring up a running version
that reloads on changes.
* bundle exec rackup -p 3000 - will run on port 3000 but need to tell it
about updates yourself.
* bundle - by itself will update gems
* bundle exec rspec - will run tests

### Tips :

The command "lsof -i :3000" will check what is running using
port 3000.  This can be useful if you need to kill an existing Ruby server.

handy scripts:

* *runTests.sh* - run the standard set of unit and integration tests.

* *setup-rvm.sh* - setup the rvm environment.  This must be sourced into
the current shell rather than simply executed.

* *build.sh* - Run tests and build a war file for deployment to a Tomcat
server.  The war file depends on using jruby to run the code.

* *runServerGuard.sh* - run server via guard.  Will spawn xterms for
messages and the log if xterm is available.

* *runServerBundle.sh* - run server directly using bundle and rackup
better visibility for startup errors.

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

---------

GitHub readme files are formated in Markdown:

[Markdown Basics (Github)](https://help.github.com/articles/markdown-basics)

Markdown is supported directly in RubyMine.  A perl script for textwrangler is available at this [link](http://daringfireball.net/projects/downloads/Markdown_1.0.1.zip)

There is a web based markdown viewer/editor [here](http://daringfireball.net/projects/markdown/dingus).
It has a good syntax summary on the right hand side.

----------------------

