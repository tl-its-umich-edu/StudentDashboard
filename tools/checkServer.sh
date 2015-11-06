#!/usr/bin/env bash
# check if the development server is running.
echo "checking port 3000"
set -x
lsof -i TCP:3000
echo "should check for guard server also"
#end
