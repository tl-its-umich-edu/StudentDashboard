#!/bin/bash
## run server that doesn't check for changes but reports 
## startup errors far better.

PORT=3000

export JRUBY_OPTS="-J-Xmn512m -J-Xms2048m -J-Xmx2048m -J-server -J-Djruby.thread.pooling=true -J-Djruby.thread.pool.min=4"

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

set -x
export LANG=en_US.UTF-8

# Sample of how to set latte options for command line ruby run.
# LATTE_OPTS can also be set and exported separately.
#LATTE_OPTS="--config_dir=/Users/dlhaines/dev/GITHUB/dlh-umich.edu/FORKS/StudentDashboard/tmp" bundle exec rackup -p $PORT
#LATTE_OPTS="--config_dir=/etc/"
echo "LATTE_OPTS: [$LATTE_OPTS]"
bundle exec rackup -p $PORT
#end
