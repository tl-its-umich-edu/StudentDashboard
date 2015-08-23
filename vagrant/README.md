# UMIch Student Dashboard Vagrant VM

This directory contains scripts that will build and launch a Vagrant
VM running a StudentDashboard build using Tomcat.  The scripts are invoked by
the 'rake' command run from the StudentDashboard directory above.  Run
'rake -T' to see a list of commands.

The scripts expect the artifacts to be created locally by running
./build.sh in the StudentDashboard directory.  If that is not the
correct location for the artifacts you can explicitly update the
variables set in VERSIONS.sh to specify different locations.

Custom scripts are described below.  The scripts should provide clear
error messages if they encounter a problem.  If they don't let's fix them.

The standard Vagrant configuration scripts are not described here.

## USER SCRIPTS:
* VERSIONS.sh - define where to get and put the build artifacts.  The
default values should usually work.
* getArtifacts.sh - Run to stage the application build artifacts to be
used when building the VM.
* vagrantXterm.sh - Starts an xterm which is logged into the Vagrant
VM.
* installStudentDashboard.sh - Provisioning script to install
Dashboard into the VM. It is automatically run from the Vagrant scripts.
* setenv.sh - If this file is present will be copied to /var/lib/tomcat7/bin.  This is used 
to make environment variables available to a tomcat war file.

Note: The tomcat setup is split between the files shared by all tomcat instances,
in /usr/share/tomcat7, and the files may be customized for different running tomcats.
For the default installation the customizable files are in /var/lib/tomcat7/bin.

##To create the VM:
- check VERSION.sh to make sure it refers to the desired build artifacts.
- run "rake vagrant:get_artifacts" to gather the artifacts to install.
- run "rake vagrant:up" to build and start the VM.
- Visit http://localhost:9090/StudentDashboard to check it out.
- run 'rake vagrant:destroy' or 'rake vagrant:halt' to bring the VM down.
- Optional: run "rake vagrant:xterm" to start an VM xterm if you need
to look into the VM.

