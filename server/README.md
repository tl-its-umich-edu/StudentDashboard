Readme file in markdown

https://help.github.com/articles/markdown-basics

Based on: 
http://proquest.safaribooksonline.com.proxy.lib.umich.edu/book/web-development/ruby/9781782168218

This implements a simple REST ruby web server based on sinatra. 
It expects to return data in json format.

It also supports the main dashboard page for development purposes.

The url format is:
http://localhost:3000/courses/jabba.json

Handy scripts:

runServerGuard.sh - run server via guard.
runServerBundle.sh - run server directly using bundle and rackup
better visibility for startup errors.

----- TASKS -------

ACTIVE:

TTD: (roughly in order)

- rename server script to be specific to dev
- query canvas for courses
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

