#!/bin/sh

# global directory for several requests
#LOG_ROOT=$TMPDIR/$USER/jgcmdlog
LOG_ROOT=/User/$USER/tmp/jgcmdlog

# this is a fifo, which is read by a server process with sufficient (port) access rights
SERVER_NOTIFICATION_FILE=$LOG_ROOT/serverfifo
rm -f $SERVER_NOTIFICATION_FILE
mkdir -p $LOG_ROOT
mkfifo $SERVER_NOTIFICATION_FILE
if test -e $SERVER_NOTIFICATION_FILE;
then 
  chmod go-rwx $SERVER_NOTIFICATION_FILE; # security
  echo $SERVER_NOTIFICATION_FILE;
else
  exit 1;
fi
# this is where the next jgcmdlient looks for the directory information
echo $LOG_ROOT >~/.jgcmdlogroot

# endless loop
while test -z "";
do 
  read CLIENT_DIR <$SERVER_NOTIFICATION_FILE
  # give chance to redraw schedule by setting forgetit
  if test -z "$CLIENT_DIR"; 
  then echo "warning: read empty line" # this occurs both in bash and sh
  elif test "$LAST_CLIENT_DIR" == "$CLIENT_DIR"
  then echo "warning $CLIENT_DIR read twice" # this occurs often in bash, no time in sh.
  elif ! test -d $CLIENT_DIR;
  then echo "error (not a directory): $CLIENT_DIR"
  elif test -e $CLIENT_DIR/forgetit
  then date > $CLIENT_DIR/forgot
  else
      read COMMAND <$CLIENT_DIR/cmd
      echo "$CLIENT_DIR:$COMMAND"
      date >$CLIENT_DIR/started
      # $? is the exit status of the last foreground pipeline
      (($COMMAND) <$CLIENT_DIR/stdin >$CLIENT_DIR/stdout 2>$CLIENT_DIR/stderr ; echo $? >$CLIENT_DIR/exitstatus; date >>$CLIENT_DIR/finished; echo "finished: $CLIENT_DIR:$COMMAND") &
      LAST_CLIENT_DIR="$CLIENT_DIR"
  fi
done

echo "please clean up $LOG_ROOT"
