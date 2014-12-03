# Student Dashboard data server
This implements a simple REST ruby web server based on Ruby Sinatra DSL.
It expects to return data in json format.

The server also supports running the main dashboard UI page.

To get the UI page simply visit the base URL for 
the application.  E.g. https://<host>/StudentDashboard/
The root element of the URL can be configured.

The API is documented at : http://localhost:3000/StudentDashboard/api

# Data providers
There are data providers supplied:

* ESB / API based
* FB file based

## ESB Data provider
This provider used the UMich WSO2 based ESB to get user data.  Configuration
of this provider is entirely within the security.yml file.  See that file
for details.

## File based Data provider
The File based data provider will retrieve user data from
files on disk.  The specific directory to use is specified in the
studentdashboard.yml file by the *data_file_provider_directory*  entry.
This is documented further in each studentdashboard yml file.

The provider will expect to find a file named *user name.json* in that
directory. If no matching file is found then a 404 / empty string is returned.
No checking is done on the user so that the user name specified need not be a real
user. One advantage of this is that files can be constructed to contain
data with specific constructions or errors and can be used for testing.  E.g. the file *test-long-long-strings.json*
could be used to test data with particularly long strings.

The file based server currently only implements requests for the course
data. It could easily be extended to support other types such as term or todo data.

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

----
## Error handling

The WAPI module handles calls to the ESB.  It always returns a wrapper response as JSON in the format:
{ Meta: {httpStatus: <somethingcool>,"Message" : <something cool to say>}
  Result: <result>
  }

The meta httpStatus will reflect the httpstatus of the underlying request if appropriate.  If the value is
666 there has been an error doing the call.  The Message and Result section may have more information.

Note that the value in the result is what was returned from the API call.  It is not assured to be valid JSON
when evaluated. If you expect a JSON result it will be returned as a string and that string will need to be parsed.

-----

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

---------

GitHub readme files are formated in Markdown:

[Markdown Basics (Github)](https://help.github.com/articles/markdown-basics)

Markdown is supported directly in RubyMine.  A perl script for textwrangler is available at this [link](http://daringfireball.net/projects/downloads/Markdown_1.0.1.zip
)

There is a web based markdown viewer/editor [here](http://daringfireball.net/projects/markdown/dingus).
It has a good syntax summary on the right hand side.

----------------------

### TASKS

These are tracked by Jira currently.

ACTIVE:

TTD: (roughly in order)

- CLEANUP comments, extra logging etc. (keep in TTD)
- make it detect json preference from header too
- clean up route expressions (regex? trailing /?.....)

MAYBE:

DONE:


- implement ESB / API provider
- implement file based provider
- add procedure for supplying remote_user via url for testing.
- pass in the uniqname to the index.html file.
- CLEANUP comments, extra logging etc. (keep in TTD)
- add properties file [see http://stackoverflow.com/questions/98376/java-properties-file-equivalent-for-ruby]
- add .gitignore
- add log directory to git as empty.
- return course data as fixed array
- make it return json from explicit url type
- add logging
- return fake course data in real format as hash
- add a parameter to url to select the courses for a user.
- rename address book to courselist
- call ruby to handle url data
- use DataHelper instead of TinyHelper
- how do comments in slim template?  can use /! for an html comment)
- loop through hash in template
- loop over array in template
- add css
- GET GUARD to work
- get a bit of api documentation to work from template.
- add UI files
- put in github
- add api/doc element to get documentation.
- document file based provider
