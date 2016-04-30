#!/usr/bin/env bash
# Adjust base linux installation.

# Install the vagrant cache plugin to avoid downloading large
# archives each time.

# download and install tomcat
function installTomcat {
    TOMCAT_DIR=$(pwd)
    # get the desired tomcat
    TOMCAT_NAME=apache-tomcat-${TOMCAT_NUMBER}
    TOMCAT_URL=${APACHE_HOST}/tomcat/tomcat-${TOMCAT_VERSION}/v${TOMCAT_NUMBER}/bin/${TOMCAT_NAME}.tar.gz
    set -x
    echo "TOMCAT_URL: ${TOMCAT_URL}"
    # get tar if don't have it.
    [ -e ./${TOMCAT_NAME}.tar.gz ] || wget ${TOMCAT_URL}
    tar -xzf ./${TOMCAT_NAME}.tar.gz
    # set generic link to this specific one.
    ln -s ${TOMCAT_DIR}/${TOMCAT_NAME} ${TOMCAT_DIR}/apache-tomcat
    # add tomcat user
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
