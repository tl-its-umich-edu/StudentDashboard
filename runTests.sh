#!/bin/bash

# Run from spec directory so the test scripts don't have
# to figure out where to find modules.
echo "test_WAPI.rb"
(cd server/spec;
    ruby ./test_WAPI.rb
)
echo "integration_test_WAPI.rb"
(cd server/spec;
    ruby ./integration_test_WAPI.rb
)
#end
