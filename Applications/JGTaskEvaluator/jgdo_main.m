//  jgdo_main.m Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import <Foundation/Foundation.h>

#import "JGDOPerformer.h"

int main(int argc, const char *argv[])
{
  
  NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
  JGDOPerformer *performer=[[JGDOPerformer alloc] init];

  [performer setWithProcessInfo];
  [performer perform];
  [performer closeStreams];
  
  [pool release];
  exit(0);       // insure the process exit status is 0
  return 0;      // ...and make main fit the ANSI spec.
}
