
# UMich Student Dashboard Repository

This application will provide a single page that provides a link to a student's
current courses regardless of whether are in CTools or Canvas.

This code is kept in github and will be public for the whole world to see forever.

# Implementation

This server implements both a single page UI and a Rest API that
provides services to the UI.

The implementation is done using Ruby and Sinatra.  The application is
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

For server deployment create a self contained war file with the
command: 

	warble

Note that the urls for a server run locally with a default Ruby server
will not require a context name but when running in a container the
war version the URLS will require including the StudentDashboard context element.

#Application Organization

The UI and backend Server are kept in corresponding directories.  The
top level directory contains the Ruby configuration files required to build the
war file. 

#Application  Configuration and Deployment

The application has default configuration values suitable for
development testing but for any installation that is not simply for
local testing two yaml configuration files should be provided.  See
copies of those files in the application source for detailed
information on the contents. The file *studentdashboard.yml* contains
non-sensitive information that may be customized on an instance by
instance basis.  The file security.yml contains information required
to connect to a WSO2 ESB in order to get the information consumed by
the dashboard.  A template of the required format is available in the
file security.yml.TEMPLATE in the source directory.

The application will look for these files first under the directory 
*/usr/local/studentdashboard*. It will try to find the 
*studentdashboard.yml* file there.  The *security.yml* file must be in the 
same directory with restricted read permissions..

---
This readme file is written with Markdown.
See this link for information on [Markdown basics](https://help.github.com/articles/markdown-basics)
