
# UMich Student Dashboard Repository

This application will provide a single page that provides a link to a student's
current courses regardless of whether are in CTools or Canvas.

This code is kept in github and will be public for the whole world to see forever.

# Implementation

This server implements both a single page UI and a Rest API.  The Rest api can be used
independently if that is appropriate.  It assumes that authentication has
already been done and the request object has a valid value for REMOTE_USER.

The server is implemented  using Ruby and Sinatra.  The application is
packaged into a war file along with JRuby 1.7 (implementing
Ruby 1.9.3). It expects to run within a container, such as Tomcat 7,
that will provide authentication.  The container must be configured to
supply the REMOTE_USER environment variable value in the request.  An
example server.xml file for Tomcat is included.

# Building the project

The application runs under Ruby 1.9.3.  After checking out the source
use RVM to get the proper Ruby environment (1.9.3) and then  run the
bundle command to update dependencies.

    bundle install

The server can then be run locally using common Ruby web servers.
There are some script files included that make it easy to run a Ruby
server directly on port 3000. 

To build the war file for installation under Tomcat use the command

    warble

The
top level directory contains the Ruby configuration files required to build the
war file.  Delivery of the application configuration files is handled separately.


Note that the urls for a server run locally with a default Ruby server
will not require a context name but when running the war package in a container the
URLS will require including the StudentDashboard context element.

#Application  Configuration and Deployment#

The application has default configuration values suitable for
development testing but for any installation that is not simply for
local testing two yaml configuration files should be provided.  See
copies of those files in the application source for detailed
information on the contents. 
There are two configuration files for StudentDashboard.   The configuration
files will be read from the directory
*/usr/local/ctools/app/ctools/tl/home* or, if a file isn't there,
from the *server/local* directory in the expanded war file directory.

The file
*security.yml* contains the ESB connection information.  There are no appropriate defaults and it must be 
configured for each installation.  Copy the file *security.yaml.TEMPLATE* and
fill in values appropriate for your installation.  Note that the *security.yml* file must have restricted read permissions.

The file *studentdashboard.yml* contains values that may change from instanceo
to instance but don't contain sensitive information.  The values in it 
that are most likely to change change are: the ESB application id and the
authn settings.  The first identifies the information in the security file that
will be used to connect to the ESB.  The other values are for load testing
and allow using a stub authentication service. See the sample file for details.

---

This readme file is written with Markdown.
See this link for information on [Markdown basics](https://help.github.com/articles/markdown-basics)
