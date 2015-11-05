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
# run without buffering the output.  This version works
# on osx.
script -q /dev/null ./runPoll.sh | tee ./poll.txt

#end
