#!/bin/bash
# Build script to assemble and test StudentDashboard.

set +x

RUBY_VERSION=ruby-1.9.3-p484

## Setup RVM
source ~/.rvm/scripts/rvm
# verify that it is setup
type rvm | head -n 1

# select and setup a particular ruby version.

rvm use $RUBY_VERSION

########### utilities ############
## make a clean directory to hold any build artifacts
function makeArtifactsDir {

    if [ -e ./artifacts ]; then
        rm -rf ./artifacts;
    fi

    mkdir ./artifacts
}

## Make a tar from the configuration files.
function makeConfigTar {
    set +x
    ( cd server; tar -c -f ../artifacts/configuration-files.tar ./local/studentdash*yml )
}

###################

# make sure the ruby bundle is correct.
bundle install

## should test return code
./runTests.sh

makeArtifactsDir

### make the war file
warble
mv *.war ./artifacts

## make the configuration tar file and put in artifacts directory
makeConfigTar

# display the artifacts created
ls -l ./artifacts
#end
