#!/bin/bash

# global directory for several requests
LOG_ROOT=$TMPDIR/$USER/jgcmdlog
# this is a fifo, which is read by a server process with sufficient (port) access rights
SERVER_NOTIFICATION_FILE=$LOG_ROOT/serverfifo
rm -f $SERVER_NOTIFICATION_FILE
mkdir -p $LOG_ROOT
mkfifo $SERVER_NOTIFICATION_FILE
if test -e $SERVER_NOTIFICATION_FILE;
then 
  echo $SERVER_NOTIFICATION_FILE;
else
  exit 1;
fi
# this is where the next jgcmdlient looks for the directory information
echo $LOG_ROOT >~/.jgcmdlogroot

# endless loop
while read CLIENT_DIR <$SERVER_NOTIFICATION_FILE;
do 
  # give chance to redraw schedule by setting forgetit
  if test -e $CLIENT_DIR/forgetit
  then
    date > $CLIENT_DIR/forgot
  else
    read COMMAND <$CLIENT_DIR/cmd
    echo $CLIENT_DIR: $COMMAND
    date >$CLIENT_DIR/started
    (($COMMAND) <$CLIENT_DIR/stdin >$CLIENT_DIR/stdout 2>$CLIENT_DIR/stderr ; echo $PIPESTATUS >$CLIENT_DIR/exitstatus; date >>$CLIENT_DIR/finished) &
  fi
done

echo "please clean up $LOG_ROOT"
