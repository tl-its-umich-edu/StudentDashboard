#!/bin/bash
# copy bundled artifacts.
set -x
source ./VERSIONS.sh
#SRC=/Users/dlhaines/dev/GITHUB/dlh-umich.edu/FORKS/StudentDashboard
#if [ -e ./ARTIFACTS.TXT ]; then
#    source ./ARTIFACTS.TXT
#fi

#if [ "" -eq "$ARTIFACTS_SRC" ]; then
#    echo "  Need to specify a value for ARTIFACTS_SRC. Use ARTIFACTS.TXT file or command line"
#    exit 1;
#fi

# save the last requested artifacts.
#echo "\$ARTIFACTS_SRC=$ARTIFACTS_SRC" >| ./ARTIFACTS.TXT

# remove prior artifacts.
if [ -e ./ARTIFACTS ]; then
    rm -rf ./ARTIFACTS;
fi

cp -rf $ARTIFACTS_SRC/ARTIFACTS .

if [ ! -e ./security.yml ]; then
    echo "** must make the security.yml file available in this directory"
    exit 1;
fi

#end
