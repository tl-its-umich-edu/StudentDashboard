Scripts to provision and start a Vagrant server running the UM Dashboard.
The script configuration should all be done in the VERSIONS.sh script.
Those variables are read into the other script files.

SCRIPTS:
getArtifacts.sh - Copy build artifacts to local directory in preparation for installation.
installStudentDashboard.sh - Automatically run from the Vagrant provisioning script to install Dashboard in the VM.
vagrantXterm.sh - Starts an xterm which is logged into the Vagrant VM.

To create the VM:
- check VERSION.sh to make sure it refers to the desired build artifacts.
- run getArtifacts.sh to select and prepare the build for installation.
- run "vagrant up" to build and start the VM.
- Visit http://localhost:9090/StudentDashboard
- (optional) run vagrantXterm.sh to get a shell on the VM.


The command "vagrant halt" will shutdown the VM but will store the system configuration.
The next "vagrant up" should run faster.
