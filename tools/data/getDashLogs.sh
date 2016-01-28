#!/usr/bin/env bash
# copy down dash server logs based on host name.

# TTD:
# - make table driven data mapping for host / host log dir
# - allow specifying cluster rather than individual host
# - yaml for properties? https://stackoverflow.com/questions/5014632/how-can-i-parse-a-yaml-file-from-a-linux-shell-script

function niceTimestamp {
    echo $(date +"%F-%H-%M")
}

if [ $# -eq 0 ]; then
    echo "$0: must provide Dash host name"
    exit 1
fi

TS=$(niceTimestamp)
HOST=$1

shopt -s nocasematch
case "$HOST" in
    "durango" ) USE_HOST="durango.ctools.org";;
    *) USE_HOST="$HOST.dsc.umich.edu";;
esac

DIR=/usr/local/ctools/app/ctools/tl/logs

# special handling for t&l dev local server
if [ $HOST == "durango" ]; then
   DIR=/usr/local/ctools/user/dlhaines/ws/sd/TOMCAT/apache-tomcat-7.0.64/logs
fi

echo "HOST: $HOST USE_HOST: $USE_HOST host log directory: $DIR"
echo "local output directory: $HOST.$DIR"

scp -r $USE_HOST:$DIR $HOST.$TS
#scp -r $HOST:/usr/local/ctools/app/ctools/tl/logs $HOST.$TS
#scp -r $HOST.dsc.umich.edu:/usr/local/ctools/app/ctools/tl/logs $HOST.$TS
#end
