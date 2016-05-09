#!/usr/bin/env bash
# Adjust base linux installation.

# Install the vagrant cache plugin to avoid downloading large
# archives each time.

# download and install tomcat
#### INSTALL  catalina-jmx-remote.jar https://tomcat.apache.org/download-70.cgi in $CATALINA_HOME/lib  see: https://tomcat.apache.org/tomcat-7.0-doc/config/listeners.html and http://leranda.com/2012/02/jconsole-tomcat-and-virtualbox-nat/
#### Add ports to vagrantfile.

# JAVA_OPTS
#export JAVA_OPTS="-Dcom.sun.management.jmxremote=true \
    #                  -Dcom.sun.management.jmxremote.port=9090 \
    #                  -Dcom.sun.management.jmxremote.ssl=false \
    #                  -Dcom.sun.management.jmxremote.authenticate=false \
    #                  -Djava.rmi.server.hostname=50.112.22.47"

# server.xml
#<Listener className="org.apache.catalina.mbeans.JmxRemoteLifecycleListener"
#  rmiRegistryPortPlatform="9090" rmiServerPortPlatform="9091" />

#http://mirror.cogentco.com/pub/apache/tomcat/tomcat-7/v7.0.69/bin/extras/catalina-jmx-remote.jar

# need to add this to server.xml
#<Listener className="org.apache.catalina.mbeans.JmxRemoteLifecycleListener" rmiRegistryPortPlatform="10000" rmiServerPortPlatform="10001" />

# insert after match
#sed  '/\[option\]/a Hello World' input
# insert before match
#sed  '/\[option\]/i Hello World' input

# update the server.xml to include the jmx listener.  Uses fixed ports.
#JMX_LISTENER='<Listener className="org.apache.catalina.mbeans.JmxRemoteLifecycleListener" rmiRegistryPortPlatform="10000" rmiServerPortPlatform="10001" />'
function insertJmxListener {
    echo "install jxm server.xml"
    mv ${TOMCAT_DIR}/apache-tomcat/conf/server.xml ${TOMCAT_DIR}/apache-tomcat/conf/server.xml.bkp
    #    ${TOMCAT_DIR}/apache-tomcat/lib
    cp /vagrant/tomcat-${TOMCAT_VERSION}.server.xml.jmx ${TOMCAT_DIR}/apache-tomcat/conf/server.xml
    #    sed  "/<Server.+$/a ${JMX_LISTENER}" ${TOMCAT_DIR}/apache-tomcat/conf/server.xml.bkp >| ${TOMCAT_DIR}/apache-tomcat/conf/server.xml
}

function installTomcat {
    TOMCAT_DIR=$(pwd)
    # get the desired tomcat
    TOMCAT_NAME=apache-tomcat-${TOMCAT_NUMBER}
    TOMCAT_URL=${APACHE_HOST}/tomcat/tomcat-${TOMCAT_VERSION}/v${TOMCAT_NUMBER}/bin/${TOMCAT_NAME}.tar.gz
    TOMCAT_JMX_URL=${APACHE_HOST}/tomcat/tomcat-${TOMCAT_VERSION}/v${TOMCAT_NUMBER}/bin/extras/catalina-jmx-remote.jar
    set -x
    echo "TOMCAT_URL: ${TOMCAT_URL}"
    echo "TOMCAT_JMX_URL: ${TOMCAT_JMX_URL}"
    # get tar if don't have it.
    [ -e ./${TOMCAT_NAME}.tar.gz ] || wget ${TOMCAT_URL}
    tar -xzf ./${TOMCAT_NAME}.tar.gz
    # set generic link to this specific one.
    ln -s ${TOMCAT_DIR}/${TOMCAT_NAME} ${TOMCAT_DIR}/apache-tomcat
    # get the jmx jar if don't have it.
    [ -e ./catalina-jmx-remote.jar ] || wget ${TOMCAT_JMX_URL}
    mv ./catalina-jmx-remote.jar ${TOMCAT_DIR}/apache-tomcat/lib

    insertJmxListener
    
    # add tomcat user and have it own these files.
    sudo adduser --system --shell /bin/bash \
         --gecos 'Tomcat Java Servlet and JSP engine' \
         --group --disabled-password --home /home/tomcat tomcat
    chown -RH tomcat:tomcat ${TOMCAT_DIR}/apache-tomcat
}

# get the values that may change.  This includes the version
# of tomcat to use.
source /vagrant/VERSIONS.sh || source ./VERSIONS.sh

# reset the time zone
TIMEZONE="US/Michigan"
echo $TIMEZONE | sudo tee /etc/timezone
sudo dpkg-reconfigure --frontend noninteractive tzdata

apt-get update
apt-get install -y apache2
apt-get install -y vim
apt-get install -y emacs
apt-get install -y curl

apt-get -y install apt-file
apt-file update
apt-get -y install python-software-properties
apt-get -y install software-properties-common
add-apt-repository -y ppa:webupd8team/java
apt-get -y update

echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
apt-get -y install oracle-java8-installer
apt-get install oracle-java8-set-default

export TOMCAT_DIR=$(pwd)
# The packaged tomcat is not recent so we do a custom install.
# Set the version to be installed in the VERSIONS.sh file.
installTomcat

# Linking /vagrant to /var/www allowing changes to html file in shared directory
if ! [ -L /var/www ]; then
    rm -rf /var/www
    ln -fs /vagrant /var/www
fi

#end
