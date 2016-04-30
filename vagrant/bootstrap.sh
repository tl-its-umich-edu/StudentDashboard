#!/usr/bin/env bash

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
#echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
apt-get -y install oracle-java8-installer
apt-get install oracle-java8-set-default

echo "check setting JAVA_HOME"
export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which javac))))
echo "new JAVA_HOME: $JAVA_HOME"

apt-get install -y tomcat7 tomcat7-docs tomcat7-examples tomcat7-admin

# Linking /vagrant to /var/www allowing changes to html file in shared directory
if ! [ -L /var/www ]; then
  rm -rf /var/www
  ln -fs /vagrant /var/www
fi

#end
