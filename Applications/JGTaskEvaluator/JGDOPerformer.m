//  JGDOPerformer.m Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import "JGDOPerformer.h"


@implementation JGDOPerformer
- (id)init;
{
  [super init];
  hostName=nil;
  
  serverName=[@"F-Script" retain];
  serverSelector=@selector(execute:);
  errorFormatter=[@"jgdo error:%@" retain];
  return self;
}
- (void)dealloc;
{
  [serverName release];
  [hostName release];
  [super dealloc];
}

- (NSString *)usage;
{
return @"\
USAGE: jgdo [DO-Server-Name [Serve-Method [Slice-Method [Direct-Parameter]]]]\n\
  DO-Server-Name: Name of the DO-Server (default: F-Script) \n\
          Format: Name[@host]. Use \"Process-Name@\" if Process-Name contains a @. \n\
  Serve-Method: Name of the Method called on the DO-Server (default: execute) (appends colon if necessary)\n\
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
  int serverNamePos=0;
  int serverSelectorPos=1;
  int clientSelectorPos=2;
  int inputFromCommandLinePos=3;

  if (argc>firstArg+serverNamePos) {
    NSString *serverNameString=[args objectAtIndex:firstArg+serverNamePos];
    NSArray *components=[serverNameString componentsSeparatedByString:@"@"];
    if ([serverNameString isEqualToString:@"-h"]) {
      [self writeOutputString:[self usage]];
      exit(0);
    }
    if ([components count]>1) {
      hostName=[[components lastObject] retain];
      components=[components subarrayWithRange:NSMakeRange(0,[components count]-1)];
      serverName=[[components componentsJoinedByString:@"@"] retain];
    } else {
      hostName=nil;
      serverName=[serverNameString retain];
    }
  }
  if (argc>firstArg+serverSelectorPos) {
    NSString *serverSelectorString=[args objectAtIndex:firstArg+serverSelectorPos];
    NSArray *components=[serverSelectorString componentsSeparatedByString:@":"];
    switch ([components count]) {
      case 1:serverSelectorString=[serverSelectorString stringByAppendingString:@":"]; break;
      case 2: break;
      default: [self error:@"invalid server method selector"];
    }
    serverSelector=NSSelectorFromString(serverSelectorString);
    if (!serverSelector) // maybe Cocoa prevents from making selectors from empty strings
      [self error:@"invalid server method selector"]; // that begin with : or contain spaces.
  }
  if (argc>firstArg+clientSelectorPos)
    clientSelector=NSSelectorFromString([args objectAtIndex:firstArg+clientSelectorPos]);
  if (argc>firstArg+inputFromCommandLinePos)
    inputFromCommandLine=[[args objectAtIndex:firstArg+inputFromCommandLinePos] retain];
}

- (void)perform;
  /*"Establishes and checks the connection and performs the selector given on command line"*/
{
  if (!serverName || !serverSelector) {
    [self error:@"serverName and server method selector may not be empty"];
  }
  // hostname may be nil (look only on same host)
  server=[NSConnection rootProxyForConnectionWithRegisteredName:serverName host:hostName];
  if (!server)
    [self error:@"could not connect server"];
  [self performSelector:clientSelector];
}

- (NSString *)outputStringForInputString:(NSString *)inputStr;
{
  NSString *outputString=[server performSelector:serverSelector withObject:inputStr];
  return outputString;
}

@end
