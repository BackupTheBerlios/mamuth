#!/bin/sh
# This is probably obsolete, because in bash there is the <(command) and >(command) notation
#
# A script that allows to pipe stdin to a command, that only accepts input from a file.
# Works for commands that do read from start till end-of-file only once.
USAGE="jgrunwithfifo command [fifofilename [arg2 ... ]]"
COMMANDNAME="$1"
FILENAME="$2"
#echo "command: $COMMANDNAME"
#echo "file: $FILENAME"
if [ "x$COMMANDNAME" = "x" ]
then
  echo $USAGE
  exit 1
fi

# 1. choose a file name
#    if it is given, use it, otherwise use jgmktemp
if [ "x$FILENAME" = "x" ]
then
  FILENAMEGIVEN="NO"
  FILENAME=`jgmktemp`
else
  FILENAMEGIVEN="YES"
fi

# 2. create a fifo if file does not exists 
if test -e "$FILENAME"; then
  #echo "file $FILENAME exists"
  if test -p;
  then FIFOEXISTED="YES";
  else
    echo "file exists but is not a fifo";
    exit 2;
  fi;
else
  FIFOEXISTED="NO";
  if /usr/bin/mkfifo "$FILENAME"; 
  then
    #echo "created fifo"
    CREATEDFIFO="YES"
  else
    echo "could not create fifo $FILENAME"
    exit 3;
  fi
fi

# 3. run command in background, reading from fifo
if [ "$FILENAMEGIVEN" = "YES" ]
then
  "$@" &
else
  "$COMMANDNAME" $FILENAME &
fi

# 4. echo the shell script stdin to the pipe
cat >>$FILENAME;
# the command will read from the pipe and produce stdout.

# 5. cleanup
# when EOF is reached and there are no more threads, command will terminate.
# so we only need to remove the file.
if [ "$FIFOEXISTED" = "YES" ]; then
  FIFOEXISTED="dummy";
else
  rm $FILENAME;
fi
