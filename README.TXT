Based on: 
http://proquest.safaribooksonline.com.proxy.lib.umich.edu/book/web-development/ruby/9781782168218

simple web server based on sinatra.  Uses 
- slim for templates
- bootstrap for styling
- guard to restart web server on changes

ACTIVE:


TTD:
- return fake data in real format
- add properties file
- query canvas

DONE:
- add a parameter to url to select the courses for a user.
- rename address book to courselist
- call ruby to handle url data

COMMANDS:
guard - (run in a separate terminal window to bring up a running version
that reloads on changes.  
bundle exec rackup -p 3000 - will run on port 3000 but need to tell it
about updates yourself.
bundle - by itself will update gems
bundle exec rspec - will run tests

