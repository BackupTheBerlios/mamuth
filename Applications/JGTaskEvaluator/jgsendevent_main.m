//
//  jgsendevent.m
//  JGTaskEvaluator
//
//  Created by Joerg Garbers on Wed Aug 14 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#include <stdio.h>
#include <Carbon/Carbon.h>

char *sendString(OSType creator, AEEventClass theAEEventClass, AEEventID theAEEventID, const char *text);

// appleevent-toolkit.lisp and eval-server.lisp must be loaded
// it automatically installs a handler (install-appleevent-handler :|misc| :|eval| #'eval-handler)
// loading needs the existence of the MCL Library. (Standard OM version does not work)

char *sendOM(char *text) {
  OSType creator='CCL2';
  AEEventClass theAEEventClass='misc';
  AEEventID theAEEventID='eval';
  return sendString(creator,theAEEventClass,theAEEventID, text);
}

int main(int argc, const char *argv[])
{
  char *text="(list 'a 'b \"c\")";
  char *result=sendOM(text);
  if (!result) {
    puts("error");
    exit(1);
  } else 
    puts(result);
  exit(0);       // insure the process exit status is 0
  return 0;      // ...and make main fit the ANSI spec.
}
