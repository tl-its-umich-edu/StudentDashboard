#!/usr/bin/env bash
# retrieve dash server logs based on host name.

# TTD:
# - make table driven data mapping for host / host log dir
# - allow specifying cluster rather than individual host
# - yaml for properties? https://stackoverflow.com/questions/5014632/how-can-i-parse-a-yaml-file-from-a-linux-shell-script

shopt -s nocasematch

function niceTimestamp {
    echo $(date +"%F-%H-%M")
}

if [ "$#" -ne 1 ]; then
    echo "Must provide name of Dash server.  It adds '.dcs.umich.edu' to the name if necessary and treats 'durango' as special case."
    exit 1;
fi

TS=$(niceTimestamp)

### setup fully qualified host name"
HOST=$1

if [ "$HOST" == 'durango' ]; then
    HOST='durango.ctools.org'
fi

FULL_NAME=$(echo $HOST | perl -n -e '/\./ && print "yes"')

if [ "$FULL_NAME" == 'yes' ]; then
    SUFFIX=""
else
    SUFFIX=".dsc.umich.edu"
fi

USE_NAME=${HOST}${SUFFIX}

### setup remote directory

DIR=/usr/local/ctools/app/ctools/tl/logs
# special handling for t&l dev local server
if [ $USE_NAME == "durango.ctools.org" ]; then
    DIR=/usr/local/ctools/user/dlhaines/ws/sd/TOMCAT/apache-tomcat-7.0.64/logs
fi

# go get 'em
(
    set -x
    scp -r $USE_NAME:$DIR $HOST.$TS
)
#end
