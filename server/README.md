# SD server
This implements a simple REST ruby web server based on sinatra.
It expects to return data in json format.

For development purposes it also supports running the main dashboard
page.

To get the UI page simply visit the base URL for 
the application.  E.g. https://<host>/StudentDashboard/
The root element of the URL can be configured.

The url format for the courses data is:
http://localhost:3000/StudentDashboard/courses/jabba.json

The API is documented at : http://localhost:3000/StudentDashboard/api

See Tips section at the end for information on:

* useful scripts included
* useful links

# Data providers
There are three major data providers:

 * file based
 * ESB / API based (not implemented)

## File based data provider

By default the system will return matching json files from the
server/test-files/courses directory.  Whatever json is provided in
that file will be returned as the response to a courses
query. E.g.the query _https:myserver.edu//courses/csev.json_
will return the contents of the csev.json file.
The contents of the file will be parsed as json so syntax errors may
result in no response.

To add more users files create <user>.json files in the courses directory.

If no matching file is found then a 404 / empty string is returned.

While the server currently only implements the courses data type it could easily be extended to
support other types, e.g. todo, or events.

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

-----

### COMMANDS:

Note that the scripts package the commands to make things easier.

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

* runServerGuard.sh - run server via guard.  Will spawn xterms for
messages and the log if xterm is available.

* runServerBundle.sh - run server directly using bundle and rackup
better visibility for startup errors.

These scripts are both in the StudentDashboard directory and in the
server directory since it is convient to run them from either spot.

GitHub readme files are formated in Markdown:

https://help.github.com/articles/markdown-basics

This script started out with:
http://proquest.safaribooksonline.com.proxy.lib.umich.edu/book/web-development/ruby/9781782168218

markdown perl script (for textwranger)
http://daringfireball.net/projects/downloads/Markdown_1.0.1.zip

There is a markdown viewer/editor  on the web at:
http://daringfireball.net/projects/markdown/dingus
It also has a good syntax summary on the right hand side.


----------------------

### TASKS

ACTIVE:



TTD: (roughly in order)

- CLEANUP comments, extra logging etc. (keep in TTD)
- make it detect json preference from header too
- clean up route expressions (regex? trailing /?.....)


MAYBE:

- integrator level to design (ui, integrator, providers)
- add fake todo, schedule
- implement html version using template for looping

DONE:

- add procedure for supplying remote_user via url for testing.
- implement ESB / API provider
- document file based provider
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

