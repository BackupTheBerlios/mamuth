#!/bin/sh
# logs all stdin/stdout/stderr and exit status. Execution is done by server process
USAGE="USAGE: jgcmdclient ... \n"

# global directory for several requests
read LOG_ROOT <~/.jgcmdlogroot
# this is a fifo, which is read by a server process with sufficient (port) access rights
SERVER_NOTIFICATION_FILE=$LOG_ROOT/serverfifo

# create a directory for this call of this script. jgmktemp uses MKTEMP_DIR
MKTEMP_DIR="$LOG_ROOT"
CLIENT_DIR=$LOG_ROOT/`jgmktemp`
mkdir -p $CLIENT_DIR

# set up directory
CLIENT_NOTIFICATION_FILE=$CLIENT_DIR/finished
echo "$@" > $CLIENT_DIR/cmd
# read input (must be totally read). 
cat > $CLIENT_DIR/stdin
# create a notification fifo
mkfifo $CLIENT_NOTIFICATION_FILE
date >$CLIENT_DIR/scheduled
# notify server
echo "$CLIENT_DIR" >> $SERVER_NOTIFICATION_FILE
# wait for notification
read FINISHEDDATE <$CLIENT_NOTIFICATION_FILE
wc $CLIENT_DIR/exitstatus $CLIENT_DIR/stdout $CLIENT_DIR/stderr
cat $CLIENT_DIR/exitstatus $CLIENT_DIR/stdout $CLIENT_DIR/stderr
