#!/bin/bash
# Install a StudentDashboard build on a Vagrant VM for testing.
# Is assumes that:
# there is 1 war file in the ARTIFACTS directory under the vagrant launch
# directory on the host.
# There is also a configSD script to install the configuration.
#set -x
set -u
set -e

##### install the Student Dashboard configuration files.

### Values that change from install to install.
source /vagrant/VERSIONS.sh
##########

if [ ! -e $HOST_CONFIG_TAR ]; then
    echo "config_tar doesn't exist";
    exit 1;
fi

# make the configuration directory if it doesn't exist

if [ ! -d $LOCAL_CONFIG_DIR ]; then 
    mkdir -p $LOCAL_CONFIG_DIR
fi

# Expand tar into that directory. NOTE: replace if exists?
tar --warning=no-unknown-keyword -xvf $HOST_CONFIG_TAR -C $LOCAL_CONFIG_DIR

# link the correct local studentdashboard file.

# assume link is already in tar
# link to the value in ./local
ln -fs $LOCAL_CONFIG_DIR/local/studentdashboard.yml $LOCAL_CONFIG_DIR/studentdashboard.yml

# verify link
if [ ! -e "$LOCAL_CONFIG_DIR/studentdashboard.yml" ]; then
    echo "ERROR: no studentdashboard.yml file: [$LOCAL_CONFIG_DIR/studentdashboard.yml]";
    exit 1;
fi

# verify that security.yml is available from the host
if [ ! -r "$HOST_SECURITY_FILE" ]; then
    echo "ERROR: security file must be available: [$HOST_SECURITY_FILE]"
    exit 1;
fi

# link it up unless one is already linked.
if [ ! -e "$LOCAL_SECURITY_FILE" ]; then
    echo "linking up local security file";
    ln -s $HOST_SECURITY_FILE $LOCAL_SECURITY_FILE
else
    echo "security file already installed"
fi

#### install a setenv.sh file if it exists.
if [ -e /vagrant/setenv.sh ]; then
   echo "installing setenv.sh file for tomcat"
   mkdir /var/lib/tomcat7/bin
   chown tomcat7:tomcat7 /var/lib/tomcat7/bin
   sudo cp /vagrant/setenv.sh /var/lib/tomcat7/bin/setenv.sh
   sudo /etc/init.d/tomcat7 restart
fi

# Install a Student Dashboard war file from /vagrant to the tomcat webapps directory.
SRC=/vagrant/ARTIFACTS
WEBAPPS_DIR=/var/lib/tomcat7/webapps
DEST_FILE=$WEBAPPS_DIR/StudentDashboard.war

function help {
    echo "  Copy war file into a vagrant VM Tomcat from /vagrant."
    echo "  Must supply a single war file name as an argument."
    echo "  Other files must be installed by hand."
}

# verify that have argument supplied
# if [ $# -ne 1 ]; then
#     help;
#     exit 1;
# fi



WAR=`ls $SRC/S*war`
#ls -l $SRC/S*war
#ls -l $WAR

if [ ! -e "$WAR" ]; then
    echo "** can not find source war file: [$WAR]";
    exit 1;
fi

# list war files
echo "** list available war file"
ls -l $WAR
echo "** list installed webapps"
ls -l $WEBAPPS_DIR
echo "copying over war file"
cp -f $WAR $DEST_FILE ||  { echo "error copying $WAR rc: $?"; exit 1; }

sleep 10;
echo "** list post-install webapps"
ls -l $WEBAPPS_DIR

echo "StudentDashboard has been installed.  Log files are available on the VM"
echo "at /var/lib/tomcat7/logs."
#end
