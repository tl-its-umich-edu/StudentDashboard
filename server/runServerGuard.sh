#!/bin/bash
#set -x
## If there is a xterm use it.
if [ -e /opt/X11/bin/xterm ]; then
    /opt/X11/bin/xterm -e guard &
    sleep 10;
    /opt/X11/bin/xterm -e tail -F log/sinatra.log &
else
    # otherwise just run guard in current terminal.
    guard &
fi

#end
