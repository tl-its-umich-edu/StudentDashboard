# SD server
This implements a simple REST ruby web server based on sinatra.
It expects to return data in json format.

For development purposes it also supports running the main dashboard
page.

The url format is:
http://localhost:3000/courses/jabba.json

The API is self documented at : http://localhost:3000/api

See Tips section at the end for information on:
* useful scripts included
* useful links


# Data providers
There are three major data providers:
* file based
* ESB / API based (not implemented)
* Umiac / Canvas based (not implemented

## File based data provider
To supply data from files:
- install the StudentDashboard application via github.
- Configure the local/local.yml file to set the directory
containing the files and the name of the sub directory that contains
the type of files.
- name the file per the request.  E.g. The request localhost:3000/course/csev.json would
return the file courses/csev.json.  If no such file is found a 404 / empty string is returned.

This currently only implements the courses data type but could easily be extended to
support other types, e.g. todo, or events.



----- TASKS -------

ACTIVE:
- document file based provider

TTD: (roughly in order)
- add procedure for supplying remote_user via url for testing.
- implement ESB / API provider
- implement UMIAC / Canvas provider.
- CLEANUP comments, extra logging etc. (keep in TTD)
- make it detect json preference from header too
- clean up route expressions (regex? trailing /?.....)


MAYBE:
- integrator level to design (ui, integrator, providers)
- add fake todo, schedule
- implement html version using template for looping

DONE:
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

COMMANDS:

guard - (run in a separate terminal window to bring up a running version
that reloads on changes.
bundle exec rackup -p 3000 - will run on port 3000 but need to tell it
about updates yourself.
bundle - by itself will update gems
bundle exec rspec - will run tests

TIps :


handy scripts
runServerGuard.sh - run server via guard.  Will spawn xterms for
messages and the log if xterm is available.

runServerBundle.sh - run server directly using bundle and rackup
better visibility for startup errors.


GitHub readme files are formated in Markdown:
https://help.github.com/articles/markdown-basics

This script started out with:
http://proquest.safaribooksonline.com.proxy.lib.umich.edu/book/web-development/ruby/9781782168218

markdown perl script (for textwranger)
http://daringfireball.net/projects/downloads/Markdown_1.0.1.zip

