//  jgsendevent_main.c Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#include <stdio.h>
#include <Carbon/Carbon.h>
#import "JGAEPerformer.h"

char *sendString(OSType creator, AEEventClass theAEEventClass, AEEventID theAEEventID, const char *text, Size *returnStringSize);

// appleevent-toolkit.lisp and eval-server.lisp must be loaded
// it automatically installs a handler (install-appleevent-handler :|misc| :|eval| #'eval-handler)
// loading needs the existence of the MCL Library. (Standard OM version does not work)

char *sendOM(char *text) {
  OSType creator='CCL2';
  AEEventClass theAEEventClass='misc';
  AEEventID theAEEventID='eval';
  return sendString(creator,theAEEventClass,theAEEventID, text,NULL);
}

void testSendEvent() {
  char *text="(list 'a 'b \"c\")";
  char *result=sendOM(text);
  if (!result) {
    puts("error");
    exit(1);
  } else 
    puts(result);
}

int main(int argc, const char *argv[])
{
  NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
  JGAEPerformer *performer=[[JGAEPerformer alloc] init];

  [performer setWithProcessInfo];
  [performer perform];
  [performer closeStreams];
  
  [pool release];
  exit(0);       // insure the process exit status is 0
  return 0;      // ...and make main fit the ANSI spec.
}
