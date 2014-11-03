#!/bin/bash
# Build script to assemble and test StudentDashboard.

set +x

RUBY_VERSION=ruby-1.9.3-p484

## Setup RVM
source ~/.rvm/scripts/rvm

# Print verification that RVm is setup
type rvm | head -n 1

# select and setup a particular ruby version.
rvm use $RUBY_VERSION

########### utilities ############

# return a sortable timestamp as a string without a newline on the end.
function niceTimestamp {
    echo $(date --iso-8601=min)
}

## make a clean directory to hold any build ARTIFACTS
function makeARTIFACTSDir {

    if [ -e ./ARTIFACTS ]; then
        rm -rf ./ARTIFACTS;
    fi

    mkdir ./ARTIFACTS
}

## Make a tar from the configuration files.
function makeConfigTar {
    set +x
    ( cd server;
        ts=$(niceTimestamp)
        tar -c -f ../ARTIFACTS/configuration-files.$ts.tar ./local/studentdash*yml;
        echo "++++++ list config files"
        tar -xvf ../ARTIFACTS/configuration-files.$ts.tar;
    )
}

## create the war file
function makeWarFile {
    warble
    ts=$(niceTimestamp)
    mv StudentDashboard.war StudentDashboard.$ts.war
    mv *.war ./ARTIFACTS
}

###################

makeARTIFACTSDir

# make sure the ruby bundle is correct.
ts=$(niceTimestamp)
bundle install >| ./ARTIFACTS/ruby.$ts.bundle

## should test return code
./runTests.sh

# Make and name war file.  Put in ARTIFACTS directory.
makeWarFile

## make and name the configuration file tar and put in ARTIFACTS directory.
makeConfigTar

# display the ARTIFACTS created
echo "++++++++++ ARTIFACTS created"
ls -l ./ARTIFACTS

#end
