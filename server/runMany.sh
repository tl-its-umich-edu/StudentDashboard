#!/bin/bash
sleep=5
function runPoll {
  sleep $sleep
  ruby ./poll_latte.rb &
}

## run in subshell to get separate process numbers
(
    (
    runPoll
    runPoll
    runPoll
    runPoll
    runPoll
    runPoll
    runPoll
    runPoll
    runPoll
    runPoll
    ) 2>runMany.$$.stderr >>runMany.$$.txt
)

#ruby ./poll_latte.rb &
#ruby ./poll_latte.rb &
#ruby ./poll_latte.rb &
#ruby ./poll_latte.rb &
#ruby ./poll_latte.rb &
#ruby ./poll_latte.rb &
#ruby ./poll_latte.rb &
#ruby ./poll_latte.rb &
#ruby ./poll_latte.rb &
#ruby ./poll_latte.rb &
#end

