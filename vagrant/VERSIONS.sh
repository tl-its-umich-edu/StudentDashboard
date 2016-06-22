# Contains variables that are used to populate a Student Dashboard Vagrant VM.
# Usually nothing will need to change.

#### Location of build artifacts on host server where you are running vagrant.
# By default assume that the latest local build artifacts should be used.  The
# location is relative to the location of the project source files on the host.
ARTIFACTS_SRC=$(pwd)/..

#### Locations of configuration files as seen within the Vagrant VM.  The tar in the
#### HOST will be expanded into the local configuration directory on the VM.
HOST_CONFIG_TAR=/vagrant/ARTIFACTS/configuration-files.*.tar
LOCAL_CONFIG_DIR=/usr/local/ctools/app/ctools/tl/home

#### Locations of security.yml file on Vagrant VM.  Since this is secure it can
#### not be part of the configuration tar.
HOST_SECURITY_FILE=/vagrant/security.yml
LOCAL_SECURITY_FILE=/usr/local/ctools/app/ctools/tl/home/security.yml

#http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.69/
APACHE_HOST=http://archive.apache.org/dist
TOMCAT_VERSION=7
TOMCAT_NUMBER=7.0.69

# end

