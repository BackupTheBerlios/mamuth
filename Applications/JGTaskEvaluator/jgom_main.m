//  jgom_main.c Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import "JGAEPerformer.h"

// appleevent-toolkit.lisp and eval-server.lisp must be loaded
// it automatically installs a handler (install-appleevent-handler :|misc| :|eval| #'eval-handler)
// loading needs the existence of the MCL Library. (Standard OM version does not work)

@interface JGOMPerformer : JGAEPerformer
{
}
@end

@implementation JGOMPerformer
- (NSString *)usage;
{
return @"\
USAGE: jgom [Slice-Method [Direct-Parameter]]\n\
  Slice-Method: lineByLineWithNewline (default), lineByLine, all, direct\n\
    defines what (stdin or Direct-Parameter) is sent to the server and for stdin, in what portions. \n\
  Direct-Parameter: used instead of stdin. \n\
";
}
- (void)setWithProcessInfo;
{
  NSProcessInfo *processInfo=[NSProcessInfo processInfo];
  NSArray *args=[processInfo arguments];
  int argc=[args count];

  // constants
  int firstArg=1; // 0 is this tasks executable
  int clientSelectorPos=0;
  int inputFromCommandLinePos=1;

  if (argc>firstArg+clientSelectorPos)
    clientSelector=NSSelectorFromString([args objectAtIndex:firstArg+clientSelectorPos]);
  if (argc>firstArg+inputFromCommandLinePos)
    inputFromCommandLine=[[args objectAtIndex:firstArg+inputFromCommandLinePos] retain];
}

@end

int main(int argc, const char *argv[])
{
  NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
  JGOMPerformer *performer=[[JGOMPerformer alloc] init];

  [performer setWithProcessInfo];
  [performer perform];
  [performer closeStreams];
  
  [pool release];
  exit(0);       // insure the process exit status is 0
  return 0;      // ...and make main fit the ANSI spec.
}
