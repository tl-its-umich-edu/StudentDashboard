#!/bin/bash
# Build script to assemble and test StudentDashboard.
# This builds a war file to run under tomcat.  That
# will contain the JRuby jar as well so that does not
# need to be installed on the server.
# This will run on a development machine and on the build server.

set +x

## 
RUBY_VERSION=jruby-1.7.18

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
    # select and setup a particular ruby version.
    #    echo "updating ruby and dependencies"
    atStep "updating ruby and dependencies"
    
    rvm use $RUBY_VERSION
    
    gem install warbler
    bundle install >| ./ARTIFACTS/ruby.$ts.bundle
}
# Print verification that rvm is setup
type rvm | head -n 1

# specify the proper ruby version and set it up.
# will try to install it if necessary.
rvm use $RUBY_VERSION


# make sure war packaging gem is installed.
gem install warbler

########### utilities ############

# return a sortable timestamp as a string without a newline on the end.
function niceTimestamp {
    echo $(date +"%F-%H-%M")
}

# verify that rvm set up
function checkRvm {

    t=$(type rvm | head -1)
#    echo $t
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
        ts=$(niceTimestamp)
        # may need to add --format=gnu to
        # standard tar command when extracting to avoid some extra header info
        tar -c -f ../ARTIFACTS/configuration-files.$ts.tar ./local/studentdash*yml;
    )
}

## create the war file
function makeWarFile {
    echo "++++++++++++"
    warble
    ts=$(niceTimestamp)
    mv StudentDashboard.war StudentDashboard.$ts.war
    mv *.war ./ARTIFACTS
}

## make a file with some version information to
## to make it available in the build.
function makeVersion {
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
# die if there is an error
set -e

# setup build environment
makeARTIFACTSDir

# Document the ruby bundle for reference if
# there is a problem with the build later.
ts=$(niceTimestamp)


setupRVM
updateRuby

#bundle install >| ./ARTIFACTS/ruby.$ts.bundle

#Don't run tests by default. Should check the return code if do.
#./runTests.sh
## Tests are not run by default.
##./runTests.sh

# make version before making the war so that the build.yml
# can be included in the war file.
makeVersion

# Make and re-name war file and put in ARTIFACTS directory.
makeWarFile

## make and name the configuration file tar and put in ARTIFACTS directory.
makeConfigTar

# let anyone on the server read the artifacts.  All secure information is
# handled by back channels.
chmod a+r ./ARTIFACTS/*

# Display the ARTIFACTS created for confirmation.
echo "++++++++++++"
echo "List of build artifacts created."
ls -l ./ARTIFACTS

#echo "sample scp command to make build available is:"
#echo "# scp -rp ./ARTIFACTS durango.dsc.umich.edu:~"

echo "++++++++++++"
echo "NOTE: The unresolved specs error message seems to be harmless."
#end
