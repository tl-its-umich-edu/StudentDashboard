#!/bin/bash
# Build script to assemble and test StudentDashboard.

## Setup RVM
source ~/.rvm/scripts/rvm
# verify that it is setup
type rvm | head -n 1
# select and setup a particular ruby version.
rvm use ruby-1.9.3-p484
#rvm list

set -x

./runTests.sh

## should test return code

warble

#end
