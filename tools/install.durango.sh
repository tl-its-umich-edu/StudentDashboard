#!/usr/bin/env bash
set -x
# build
# make sure tomcat isn't running
# empty tomcat logs
# empty webapps
# copy war file as ROOT.war
# link server/local properties
# needs to know where it is running from to get links right
HERE=$(pwd)
echo "HERE: [$HERE]"
TOMCAT=/usr/local/ctools/user/dlhaines/ws/sd/TOMCAT/apache-tomcat-7.0.64
TL_HOME=/usr/local/ctools/app/ctools/tl/home
#WEBAPPS=$TOMCAT/webapps

rm -rf $TOMCAT/webapps/ROOT*
rm $TOMCAT/logs

cp ./ARTIFACTS/StudentDashboard.*.war $TOMCAT/webapps/ROOT.war

#ln -s /usr/local/ctools/user/dlhaines/ws/sd/GITHUB/tl-its-umich-edu/StudentDashboard/server/local .local

#/usr/local/ctools/user/dlhaines/ws/sd/TOMCAT/apache-tomcat-7.0.64
#end
