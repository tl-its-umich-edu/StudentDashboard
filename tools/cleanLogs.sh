#!/bin/bash
LOG_BASE=../server/log
if [ -e ${LOG_BASE}/sinatra.log ]; then
    rm ${LOG_BASE}/sinatra.log
fi
#end
