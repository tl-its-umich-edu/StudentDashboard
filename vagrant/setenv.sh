# Environment options for LATTE
# The value of the environment variable LATTE_OPTS will be parsed as if it is Ruby command line parameters.
# This approach allows standard internal processing of startup time parameters for both
# the standalone and webapps versions of Latte.
# As of 2015/07/06 the only supported option is "--config_dir".  This allows specifying the directory
# containing the studentdashboard.yml file.
#export LATTE_OPTS="--config_dir=/tmp"

# add for jmx connection to tomcat
export JAVA_OPTS="$JAVA_OPTS \
       -Dcom.sun.management.jmxremote=true \
       -Dcom.sun.management.jmxremote.ssl=false \
       -Dcom.sun.management.jmxremote.authenticate=false\
       -Djava.rmi.server.hostname=127.0.0.1 \
       "
#       -Djava.rmi.server.hostname=10.0.2.15\
#       -Dcom.sun.management.jmxremote.port=10000 \


#end

