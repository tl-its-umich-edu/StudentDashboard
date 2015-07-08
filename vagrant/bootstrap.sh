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

## Optional installs - uncomment as desired
apt-get install -y default-jre
apt-get install -y default-jdk
apt-get install -y tomcat7 tomcat7-docs tomcat7-examples tomcat7-admin

# Linking /vagrant to /var/www allowing changes to html file in shared directory
if ! [ -L /var/www ]; then
  rm -rf /var/www
  ln -fs /vagrant /var/www
fi

#end
