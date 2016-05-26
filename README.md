
# UMich Student Dashboard Repository

This application provides a single page view of a student's courses and assignments
regardless of whether are in CTools or Canvas.  Links to class sites and assignments are provided when possible.

This code is available in a public GitHub repository at: https://github.com/tl-its-umich-edu/StudentDashboard.

# Implementation

This application implements both a user interface  and a REST data API.  The REST api is used
by the UI and is also directly available to Dashboard administrators.  The application 
requires that the user viewing the page has been authenticated and the value of
REMOTE_USER has been set.

The server is implemented  using Ruby and Sinatra.  The application is
packaged into a war file along with JRuby 9.x (implementing 
Ruby 2.2) expects to run within a container
such as Tomcat 7.

The development and build environments assume that the user is setup to use RVM to manage the 
available version of Ruby and uses Bundler to manage GEMS.

For testing purposes an administrative user can impersonate other users 
if the appropriate property has been set *and* the admin user is a member of a LDAP group.

# Running Student Dashboard Locally

Dashboard can be run locally without a build and compile step using the included script
"./tools/runServerBundle.sh"  This will run on port 3000 at the URL: http://localhost:3000/

# Building and deploying

The application can run a number of different environments.

## Web Server
The application is packaged for deployment as a war file and runs under jRuby.  The war is created 
by the script tools/build.sh which configures 
the Ruby environment, assembles the source and required GEM files, runs some unit tests,
and then creates a war file.
The build script is suitable for running a one-button build on a build server.
The application war should be installed into the Tomcat webapps directory as ROOT.war 
so it will run as the root application.

## Local
The script tools/runServerBundle.sh can be used to run the current copy of StudentDashboard 
on localhost.  It will run using a Ruby webserver on port 3000.  This does not require building
the application. 

## Vagrant
See the Rake section below for information on how to run a local vagrant VM which runs
Dashboard in Tomcat.

# Utilities
## tools scripts
The tools directory contains a few useful / necessary scripts.  There are additional scripts
available which may or may not be useful for your particular needs.

- tools/build.sh - Build and package the application into a war file.

- tools/runServerBundle.sh - Run the local copy of the application on localhost at port 3000.

## Ruby Rake
Rake is used as an entry point for some common development tasks.  You can get a complete 
listing of available rake targets with the command: 

    rake -T 
    
### testing
The build script automatically runs some low level unit tests.  More tests are available
through rake.  However these tests make more assumptions about the environment so they
should be run only when specific development questions come up.  For various reasons these
tests are noisier than they should be so they shouldn't be run all the time.
### Vagrant
There are also command to build, provision, and run a Vagrant instance to run Dashboard under tomcat.  
This instance of Dashboard will be available at localhost:9090.

#Application Configuration and Deployment

The application relies on two configuration files. By default they are expected to be in  the directory
**/usr/local/ctools/app/ctools/tl/home**.  If the file isn't there then the application 
will check the directory  **server/local** in the war file.
 
The expected configuration files are described later.

The directory name used for configuration files  can be overridden by an
environment variable.  The variable **LATTE_OPTS** will be checked and it
is not nil then the contents will be parsed as command line options.
Currently all command line values except for **--config_dir** will be ignored.  
The value for **--config_dir** needs to be a directory.
To set environment variables  when running under Tomcat the value needs to be set in the
setenv.sh file.  See the vagrant directory for an example of how to
do that.

## Configuration Files
The file **security.yml** contains the information required to connect to data sources.  
There are no appropriate defaults and it must be 
configured for each installation.  Copy the file **security.yaml.TEMPLATE** and
fill in values appropriate for your installation.  Note that the **security.yml** file 
must have restricted read permissions.

The file **studentdashboard.yml** contains values that may change from instance
to instance but don't contain sensitive information.  The values in it 
that are most likely to change change are the name of the data source application id. 
These need to match values in the security.yml file which provide the connection information
that will be used to connect to the data sources.  

Note while there is still some code in the application to provide stub data it will be easier 
to simply use a mock/stub API provider such as [Mountebank](http://www.mbtest.org/) 
when canned test data is required.

#License#

Copyright (c) 2014, 2015, 2016  University of Michigan

Licensed under the Educational Community License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

[http://www.osedu.org/licenses/ECL-2.0](http://www.osedu.org/licenses/ECL-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

