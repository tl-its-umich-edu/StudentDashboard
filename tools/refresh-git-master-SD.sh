#!/bin/bash
# refresh local branch (master) from upstream.
# Assumes that want the origin branch is to be put in sync with the upstream branch.
# TODO: why did pull find things that fetch did not?
set +x
set -e
# Variables allow for remotes with descriptive names.
UPSTREAM=tl-its-umich-edu
ORIGIN=dlhaines
BRANCH=master
echo "+++ updating local $ORIGIN/$BRANCH from $UPSTREAM/$BRANCH"
git checkout $BRANCH
git fetch $UPSTREAM
git rebase $UPSTREAM/$BRANCH
git fetch $ORIGIN
git rebase $ORIGIN/$BRANCH
echo "+++ local $BRANCH synced but not pushed."
#end
