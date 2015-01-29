#!/bin/bash
# Build script to assemble and test StudentDashboard.
# This builds a war file to run under tomcat.  That
# will contain the JRuby jar as well so that does not
# need to be installed on the server.
# This will run on a development machine and on the build server.

set +x

## 
RUBY_VERSION=jruby-1.7.18
#RUBY_VERSION=jruby-800

#### utility functions

# return a sortable timestamp as a string without a newline on the end.
function niceTimestamp {
    echo $(date +"%F-%H-%M")
}

function atStep {
    local msg=$1
    echo "+++ $1"
}

function setupRVM  {
    #   echo "setup rvm"
    atStep "setup rvm"
    ## Setup RVM
    source ~/.rvm/scripts/rvm
    # Print verification that rvm is setup
    type rvm | head -n 1
}

function updateRuby {

    atStep "updating ruby and dependencies for $RUBY_VERSION.  (The unresolved specs message is harmless.)"
    rm ./ruby.*.bundle
    echo  "updating ruby and dependencies for $RUBY_VERSION." >| ./ruby.$ts.bundle

    rvm install $RUBY_VERSION
    # What happens if does not exist?
    rvm use $RUBY_VERSION
    gem install warbler


    bundle install >> ./ruby.$ts.bundle
}

# verify that rvm set up
function checkRvm {

    t=$(type rvm | head -1)
    if [[ ! $t =~ 'rvm is a function' ]]; then
        echo "rvm is not set up correctly.  Try sourcing setup-rvm.sh"
        exit 1;
    fi
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
    (
        ## Go to sub directory so that the tar file doesn't have an extra level of
        ## useless directory.
        
        ## NOTE: need to use the "command" command as rvm
        ## mucks with cd and that kills the script in bash.
        
        command cd server;
#        ts=$(niceTimestamp)
        # may need to add --format=gnu to
        # standard tar command when extracting to avoid some extra header info
        tar -c -f ../ARTIFACTS/configuration-files.$ts.tar ./local/studentdash*yml;
    )
}

## create the war file
function makeWarFile {
    atStep "make war file"
    warble
#    ts=$(niceTimestamp)
    mv StudentDashboard.war StudentDashboard.$ts.war
    mv *.war ./ARTIFACTS
}

## make a file with some version information to
## to make it available in the build.
function makeVersion {
    atStep "makeVersion"
    FILE="./server/local/build.yml"
    echo  "build: TLPORTAL" >| $FILE
    echo  "time: $ts " >> $FILE
    last_commit=$(git rev-parse HEAD);
    echo "last_commit: $last_commit" >> $FILE
    echo -n "tag: " >> $FILE
    echo $(git describe --tags) >> $FILE
    echo >> $FILE
}

###################
# Never set -e as rvm will then die.


# Document the ruby bundle for reference if
# there is a problem with the build later.
ts=$(niceTimestamp)

setupRVM

# setup build environment
makeARTIFACTSDir

updateRuby

checkRvm

#Run unit tests, don't run integration tests by default.
atStep "run unit tests"
./runTests.sh
# ./runIntegrationTests.sh

# Create version information file before making the war so that the build.yml
# can be included in the war file.
makeVersion

# Make, re-name war file, and put in ARTIFACTS directory.
makeWarFile

# make sure the ruby bundle information is available in the artifacts.
cp ./*bundle ./ARTIFACTS

## make and name the configuration file tar and put in ARTIFACTS directory.
makeConfigTar

# Let anyone on the server read the artifacts.  All secure information is
# handled by back channels.
chmod a+r ./ARTIFACTS/*

# Display the ARTIFACTS created for confirmation.
atStep "display artifacts"
ls -l ./ARTIFACTS

echo "++++++++++++ NOTE: The unresolved specs error message seems to be harmless."
#end
