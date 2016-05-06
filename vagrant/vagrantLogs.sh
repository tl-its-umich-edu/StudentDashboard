#!/bin/bash
# get tomcat logs from standard location on vagrant server

function niceTimestamp {
    echo $(date +"%F-%H-%M")
}

FILE=/home/vagrant/apache-tomcat/logs
SERVER=localhost
DEST=logs.$(niceTimestamp)

OPTIONS=`vagrant ssh-config | grep -iv 'host' | awk -v ORS=' ' 'NF{print "-o " $1 "=" $2}'`
echo "copying logs to: $(pwd)/$DEST"
scp -r ${OPTIONS} vagrant@$SERVER:$FILE $DEST

#end
