#!/bin/bash
## Run a number of polling jobs in parallel.  This will run as many polling jobs
## as the first argument to the script.  Default is 2

sleep=5

i=1
MAX=${1:-2}

function runPoll {
  sleep $sleep
  bundle exec ruby ./server/poll_latte.rb &
}

## run in subshell to get separate process numbers
(
    (
        while [ $i -le "$MAX" ]
        do
            runPoll
            i=$(($i+1))
        done
    ) 2>runMany.$$.stderr >>runMany.$$.stdout
)

#end
