#!/bin/sh
# reads the stdin, writes it as a script to a temporary file,
# executes it with jgdostdio and stopName
# returns the server name.
# The script gets its input from jgdostdio when requests come in.
USAGE="USAGE: jgdoscript stopName [-n]\n"

EXECUTABLE=`jgmktemp`
SERVER="$EXECUTABLE"

# input must be totally read. 
# I tried both open cat processes and fifos as target,
# but they do not work.
cat > $EXECUTABLE
chmod u+x $EXECUTABLE

echo "$SERVER"
# USAGE: jgdostdio serverName executablePath stopName [-n]
jgdostdio $SERVER $EXECUTABLE $@
rm $EXECUTABLE 
