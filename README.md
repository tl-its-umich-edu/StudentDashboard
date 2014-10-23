
# UMich Student Dashboard Repository

This code is kept in github and will be public for the whole world to see forever.

# Implementation

This server implements both a single page UI and a Rest API.  The Rest api can be used
independently if that is appropriate.  It assumes that authentication has
already been done and the request object has a valid value for REMOTE_USER.

The server is implemented using Ruby Sinatra.

It is packaged into a war file along with
JRuby 1.7 (implementing Ruby 1.9.3).  It is expected to run within
Tomcat 7.  Tomcat must be configured to supply the REMOTE_USER 
environment variable value in the request.  An example server.xml file
is included.

# Building the project

In the top level directory run to get dependencies:

	bundle install

and then create the war file with the command:

	warble

#Organization

The UI and backend Server are kept in the obvious directories.  The
top level source directory contains the configuration files required to build the
war file.  Delivery of the configuration files is handled separately.

# Configuration

There are two configuration files for StudentDashboard.   The configuration
files will be read from the directory
*/usr/local/ctools/app/ctools/tl/home* or, if a file isn't there,
from the *server/local* directory in the expanded war file directory.

The file
*security.yml* contains the ESB connection information.  There are no appropriate defaults and it must be 
setup for each installation.  Copy the file *security.yaml.TEMPLATE* and
fill in values appropriate for your installation.

The file *studentdashboard.yml* contains values that may change from instance
to instance but don't contain sensitive information.  The values in it 
that are most likely to change change are: the ESB application id and the
authn settings.  The first identifies the information in the security file that
will be used to connect to the ESB.  The other values are for load testing
and allow using a stub authentication service.  See the yml file for details.

---
This readme file is written with Markdown.
See this link for information on Markdown: https://help.github.com/articles/markdown-basics
