Based on: 
http://proquest.safaribooksonline.com.proxy.lib.umich.edu/book/web-development/ruby/9781782168218

simple web server based on sinatra.  Uses: 
- slim for templates
- bootstrap for styling
- guard to restart web server on changes

----- TASKS -------

ACTIVE:
- add properties file [see http://stackoverflow.com/questions/98376/java-properties-file-equivalent-for-ruby]

TTD: (roughly in order)
- query canvas
- CLEANUP comments, extra logging etc. (keep in TTD)
- make it return json detecting from header also
- add doc element to get documentation.
- add example path element to demonstrate how to do things.
- put in github

MAYBE:
- integrator level to design (ui, integrator, providers)
- add fake todo, schedule
- implement html version using template for looping 


DONE:
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

