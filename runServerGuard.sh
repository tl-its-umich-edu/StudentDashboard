#!/bin/bash
set -x
## If there is a xterm use it.
if [ -e /opt/X11/bin/xterm ]; then
    /opt/X11/bin/xterm -e bundle exec guard &
    sleep 5;
    /opt/X11/bin/xterm -e tail -F server/log/sinatra.log &
else
    # otherwise just run guard in current terminal.
    bundle exec guard &
fi

#end
