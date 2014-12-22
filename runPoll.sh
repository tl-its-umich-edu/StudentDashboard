#!/bin/bash

## run specified ruby polling file in the server directory.

function runPoll {
    local file=$1
    echo "=================== running poll script: $file"
    (
        cd ./server
        bundle exec ruby ./$file
    )
}

runPoll poll_esb.rb

#end
