
# UMich Student Dashboard Repository

This code is kept in github and will be public for the whole world to see forever.

# Implementation

This server implements both a single page UI and a Rest API.  The Rest api can be used
independenly if that is appropriate.  It assumes that authentication has
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

and then 

	warble

To create the war file. This is easiest if you have rvm installed. 

#Organization

The UI and backend Server are kept in corresponding directories.  The
top level directory contains the configuration required to build the
war file.

# Configuration

The ESB connection information must be supplied in the file 
server/spec/security.yaml.  Copy the file server/spec/security.yaml.TEMPLATE and
fill in the appropriate values.

The authn shortcut needs to be configured in the file server/local/local.yml.

---
This readme file is written with Markdown.
See this link for information on Markdown: https://help.github.com/articles/markdown-basics
