#!/bin/bash
# Copy bundled artifacts to make them available to the Vagrant VM.
# This script is run on the HOST server before building the VM.
#set -x
set -e
set -u

# Get the configuration information for this instance of Dashboard.
source ./VERSIONS.sh

# remove prior installation artifacts directory.
if [ -e ./ARTIFACTS ]; then
    rm -rf ./ARTIFACTS;
fi

echo "* copy artifacts"

# copy fresh artifacts to the local installation directory.

if [ ! -e $ARTIFACTS_SRC/ARTIFACTS ]; then
    echo "** Can not find source ARTIFACTS directory.  Run a new build."
    exit 1;
fi

cp -rfv $ARTIFACTS_SRC/ARTIFACTS .

# Check that a copy of security.yml will be available to the VM.
# The user must make sure a copy is in the directory.
if [ ! -e ./security.yml ]; then
    echo "** must make the security.yml file available in this directory"
    exit 1;
fi

echo "* artifacts and security file are available"

#end
