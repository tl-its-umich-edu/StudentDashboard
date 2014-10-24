#!/bin/bash
## run server that doesn't check for changes but reports 
## startup errors far better.

PORT=3000

## get rid of logs
if [ -e ./server/log/sinatra.log ]; then
    rm ./server/log/sinatra.log
fi

## check for a running server on this port
LINES=$(lsof -i TCP:$PORT | wc -l)

if [ $LINES != 0 ]; then
    echo "exiting: found previous server on port $PORT"
    echo $(lsof -i TCP:$PORT)
    exit 1;
fi

bundle exec rackup -p $PORT
#end
