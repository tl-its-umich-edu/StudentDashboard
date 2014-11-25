#!/bin/bash

## run specified ruby test files in the server/spec directory under here.

function runTest {
    local file=$1
    echo "+++++"
    echo "+++++ running test file: $file"
    (
        cd server/spec;
        ruby ./$file
    )
}

runTest test_WAPI.rb
runTest test_integration_WAPI.rb
runTest test_auth_check.rb
runTest test_data_provider_file.rb
#runTest test_courselist.rb


#end
