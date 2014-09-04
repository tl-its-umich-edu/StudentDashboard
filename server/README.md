Readme file in markdown

https://help.github.com/articles/markdown-basics

Based on: 
http://proquest.safaribooksonline.com.proxy.lib.umich.edu/book/web-development/ruby/9781782168218

This implements a simple REST ruby web server based on sinatra. 
It expects to return data in json format.

The url format is:
http://localhost:3000/courses/jabba.json

Jabba is the user name.  The data currently is fake.

The ./runServer.sh script in this directory will start up a
development server on localhost port 3000 to exercise the SD back
end. 

----- TASKS -------

ACTIVE:
- GET GUARD to work
= get a bit of api documentation to work from template.
- query canvas for courses

TTD: (roughly in order)
- query canvas for courses
- CLEANUP comments, extra logging etc. (keep in TTD)
- make it detect json preference from header too
- add example path element to demonstrate how to do things.
- put in github
- add api/doc element to get documentation.
- Add API docs as slim template
- clean up route expressions (regex? trailing /?.....)


MAYBE:
- integrator level to design (ui, integrator, providers)
- add fake todo, schedule
- implement html version using template for looping 

DONE:
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

COMMANDS:


guard - (run in a separate terminal window to bring up a running version
that reloads on changes.  
bundle exec rackup -p 3000 - will run on port 3000 but need to tell it
about updates yourself.
bundle - by itself will update gems
bundle exec rspec - will run tests

