#!/bin/bash
## run server that doesn't check for changes but reports 
## startup errors far better.
if [ -e ./server/log/sinatra.log ]; then
    rm ./server/log/sinatra.log
fi
bundle exec rackup -p 3000
#end
