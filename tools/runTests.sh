#!/bin/bash

## run specified ruby test files in the server/spec directory under here.

function runTest {
    # The 'set -e' will make build fail if there is a failing test.
    set -x
    set -e
    local file=$1
    echo "=================== running test file: $file"
    (
        pwd;
        cd server/spec;
        which ruby
        ruby ./$file
    )
}

runTest test_WAPI_result_wrapper.rb
runTest test_WAPI.rb
runTest test_data_provider_file.rb
runTest test_data_provider_esb.rb
#end
