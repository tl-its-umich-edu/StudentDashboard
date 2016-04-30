#!/bin/bash
# Install a StudentDashboard build on a Vagrant VM for testing.
# It assumes that there is 1 war file in the ARTIFACTS directory
# under the vagrant launch directory on the host.

#set -x
set -u
set -e

##### install the Student Dashboard configuration files.

### Values that may change from install to install.
source /vagrant/VERSIONS.sh || source ./VERSIONS.sh
##########

if [ ! -e $HOST_CONFIG_TAR ]; then
    echo "config_tar doesn't exist";
    exit 1;
fi

# make the configuration directory if it doesn't exist
if [ ! -d $LOCAL_CONFIG_DIR ]; then 
    mkdir -p $LOCAL_CONFIG_DIR
fi

# Expand configuration file tar into that directory. NOTE: replace if exists?
tar --warning=no-unknown-keyword -xvf $HOST_CONFIG_TAR -C $LOCAL_CONFIG_DIR

# link the correct local studentdashboard file.

# assume link is already in tar
# link to the value in ./local
ln -fs $LOCAL_CONFIG_DIR/local/studentdashboard.yml $LOCAL_CONFIG_DIR/studentdashboard.yml

# validate configuration file link.
if [ ! -e "$LOCAL_CONFIG_DIR/studentdashboard.yml" ]; then
    echo "ERROR: no studentdashboard.yml file: [$LOCAL_CONFIG_DIR/studentdashboard.yml]";
    exit 1;
fi

# verify that security.yml is available from the host
if [ ! -r "$HOST_SECURITY_FILE" ]; then
    echo "ERROR: The security.yml file must be available from vagrant directory on the host where vagrant is started."
    exit 1;
fi

# make sure there is a security file link.
if [ ! -e "$LOCAL_SECURITY_FILE" ]; then
    echo "linking up local security file";
    ln -s $HOST_SECURITY_FILE $LOCAL_SECURITY_FILE
else
    echo "security file already linked."
fi

########## Install dashboard into tomcat
echo "install StudentDashboard into tomcat"
TOMCAT_HOME=$(pwd)/apache-tomcat

/bin/su - tomcat -c ${TOMCAT_HOME}/bin/shutdown.sh

#### install a setenv.sh file if it exists.
#set -x

if [ -e /vagrant/setenv.sh ]; then
    echo "installing setenv.sh file for tomcat"
    [ -d ${TOMCAT_HOME}/bin ] || mkdir ${TOMCAT_HOME}/bin
    cp /vagrant/setenv.sh ${TOMCAT_HOME}/bin/setenv.sh
fi

# Install a Student Dashboard war file from /vagrant to the tomcat webapps directory.
# Change war name during install.
SRC=/vagrant/ARTIFACTS
WEBAPPS_DIR=${TOMCAT_HOME}/webapps
WARFILENAME=ROOT
WEBAPPNAME=StudentDashboard
DEST_NAME=$WEBAPPS_DIR/$WARFILENAME
DEST_FILE=$DEST_NAME.war

function help {
    echo "  Copy war file into a vagrant VM Tomcat from /vagrant."
    echo "  Must supply a single war file name as an argument."
    echo "  Other files must be installed by hand."
}

WAR=`ls $SRC/$WEBAPPNAME*war`

if [ ! -e "$WAR" ]; then
    echo "** can not find war file to install: [$WAR]";
    exit 1;
fi

echo "** list installed webapps"
ls -l $WEBAPPS_DIR
echo "** war file to install"
ls -l $WAR
# Clean out old war from webapp directory.  Don't remove other files
# from webapps since this is a development setup.

rm -rf $DEST_NAME
rm -rf $DEST_FILE
echo "copying over $WAR to $DEST_FILE"
cp -f $WAR $DEST_FILE ||  { echo "error copying $WAR rc: $?"; exit 1; }

sleep 10;
echo "** list installed webapps"
ls -l $WEBAPPS_DIR

# start tomcat
echo "starting tomcat"
# make sure tomcat owns all those files.
chown -RH tomcat:tomcat ${TOMCAT_HOME}
# start it up
/bin/su - tomcat -c ${TOMCAT_HOME}/bin/startup.sh

echo "StudentDashboard has been installed.  Log files are available on the VM"
echo "in ${TOMCAT_HOME}/logs."
echo "On OSX you can open this Dash with the command: open http://localhost:9090/"
#end
