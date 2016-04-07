#!/bin/bash
# Build script to assemble and test StudentDashboard.
# This builds a war file to run under tomcat.  That
# will contain the JRuby jar as well so that does not
# need to be installed on the server.
# This will run on a development machine and on the build server.

set +x

# NOTE: warbler does not yet support JRUBY 9k (2.x compatible).
# so we are stuck on jruby 1.7 (1.9.3) for the time being.

RUBY_VERSION=jruby-1.7.24

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
    rvm use $RUBY_VERSION
    gem install warbler

    bundle install >> ./ruby.$ts.bundle
    bundle outdated >> ./ruby.ts.bundle
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
    atStep "make config tar"
    (
        ## Go to sub directory so that the tar file doesn't have an extra level of
        ## useless directory.
        
        ## NOTE: need to use the "command" command as rvm
        ## mucks with cd and that kills the script in bash.
        
        command cd server;
        # may need to add --format=gnu to
        # standard tar command when extracting to avoid some extra header info
        tar -c -f ../ARTIFACTS/configuration-files.$ts.tar ./local/studentdash*yml ./local/configuration.mapping;
        echo "++++++ list config files"
        tar -xvf ../ARTIFACTS/configuration-files.$ts.tar;
    )
}

## create the war file
function makeWarFile {
    set -e
    atStep "make war file"
    warble
    mv StudentDashboard.war StudentDashboard.$ts.war
    mv *.war ./ARTIFACTS
}

## make a file with some version information to
## to make it available in the build.
function makeVersion {
    atStep "makeVersion"
    FILE="./server/local/build.yml"
    echo "build: " >| $FILE
    echo  "  project: TLPORTAL" >> $FILE
    echo  "  time: \"$ts\" " >> $FILE
    last_commit=$(git rev-parse HEAD);
    echo "  last_commit: $last_commit" >> $FILE
    echo -n "  tag: " >> $FILE
    echo $(git describe --all) >> $FILE

    remote=$(git remote show -n origin | grep -i 'fetch' | perl -n -e '/URL:\s+(\S+.git)$/ && print $1')
    if [[ -z "$remote" ]]; then
        user=$(whoami)
        remote=$(git remote show -n $user | grep -i 'fetch' | perl -n -e '/URL:\s+(\S+.git)$/ && print $1')
    fi

    # print out jenkins build info or locally obtained info
    if [[ ! -z "$BUILD_URL" ]]; then
        echo "  JENKINS_BUILD_URL: ${BUILD_URL}" >> $FILE
        echo "  JENKINS_GIT_URL: ${GIT_URL}" >> $FILE
        echo "  JENKINS_GIT_BRANCH: ${GIT_BRANCH}" >> $FILE
        echo "  JENKINS_GIT_COMMIT: ${GIT_COMMIT}" >> $FILE
    else
        echo -n "  repo: " >> $FILE
        echo $remote >> $FILE
        echo >> $FILE
    fi
}

function writeEnvironmentVariables {
    local TIMESTAMP_value=$(ls ARTIFACTS/StudentDashboard.*.war | perl -n -e 'm/.+\.(.+)\.war/ && print $1' )
    local WEBAPPNAME_value=StudentDashboard
    vars=`cat <<EOF
########################
# Environment variables for installation of this build.
# $(date)
WEBRELSRC=http://limpkin.dsc.umich.edu:6660/job/
JOBNAME=${JOB_NAME:-LOCAL}
BUILD=${BUILD_NUMBER:-imaginary}
ARTIFACT_DIRECTORY=artifact/ARTIFACTS
TIMESTAMP=${TIMESTAMP_value}
VERSION=StudentDashboard
WEBAPPNAME=${WEBAPPNAME_value}
WARFILENAME=ROOT
IMAGE_INSTALL_TYPE=war
IMAGE_NAME=${WEBAPPNAME_value}.${TIMESTAMP_value}.war
CONFIGURATION_NAME=configuration-files.${TIMESTAMP_value}.tar
#######################
ARTIFACTFILE=\\\${WEBRELSRC}/\\\${JOBNAME}/\\\${BUILD}/\\\${ARTIFACT_DIRECTORY}/\\\${IMAGE_NAME}
CONFIGFILE=\\\${WEBRELSRC}/\\\${JOBNAME}/\\\${BUILD}/\\\${ARTIFACT_DIRECTORY}/\\\${CONFIGURATION_NAME}
#######################
EOF`
    echo "${vars}"
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

# turn on failure on error after RVM scripts
set -e
#Run unit tests, don't run integration tests by default.
atStep "run unit tests"
./tools/runTests.sh
# ./runIntegrationTests.sh
#rake test:local
#rake test:resources


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

# write a file with the install variables in it.
writeEnvironmentVariables >| ./ARTIFACTS/VERSION.Makefile

# Display the ARTIFACTS created for confirmation.
atStep "display artifacts"
ls -l ./ARTIFACTS

# write the install variables to the log
writeEnvironmentVariables

echo "++++++++++++ NOTE: The unresolved specs error message seems to be harmless."

#end
