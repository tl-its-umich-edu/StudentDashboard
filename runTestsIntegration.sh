#!/bin/bash

## run specified ruby test files in the server/spec directory under here.

function runTest {
    local file=$1
    echo "=================== running test file: $file"
    (
        cd server/spec;
        ruby ./$file
    )
}

runTest test_integration_WAPI.rb
runTest test_integration_data_provider_esb.rb
runTest test_auth_check.rb
runTest test_ldap_check.rb
#end
