//  JGDOPerformer.m Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import "JGDOPerformer.h"


@implementation JGDOPerformer
- (id)init;
{
  [super init];
  hostName=inputFromCommandLine=nil;
  
  serverName=[@"F-Script" retain];
  serverSelector=@selector(execute:);
  clientSelector=@selector(lineByLineWithNewline);
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

- (void)error:(NSString *)message;
{
  NSData *outputData;
  NSFileHandle *err=[NSFileHandle fileHandleWithStandardError];
  message=[@"jgdo error: " stringByAppendingString:message];
  outputData=[message dataUsingEncoding:NSISOLatin1StringEncoding];
  [err writeData:outputData];
  exit(0);  
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

  input=[[NSFileHandle fileHandleWithStandardInput] retain];
  output=[[NSFileHandle fileHandleWithStandardOutput] retain];

  // to be replaced by meaningfull
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

- (void)all;
{
  NSData *inputData=[input readDataToEndOfFile];
  NSString *inputString=[[NSString alloc] initWithData:inputData encoding:NSISOLatin1StringEncoding];
  [self writeOutputStringForInputString:inputString];
}

- (void)lineByLineWithTerminator:(NSString *)terminator;
{
  char *result;
  size_t length;
  int inpDesc=[input fileDescriptor];
  FILE *inpFile=fdopen(inpDesc,"r");
  while (result=fgetln(inpFile,&length)) {
    if (length>0) {
      NSString *inputString=[NSString stringWithCString:result length:length];
      [self writeOutputStringForInputString:inputString];
      if (terminator) {
        [self writeOutputString:terminator];        
      }
    }
  }
}

- (void)lineByLine;
{
  [self lineByLineWithTerminator:nil];
}
- (void)lineByLineWithNewline;
{
  [self lineByLineWithTerminator:@"\n"];
}

- (void)direct;
{
  if (!inputFromCommandLine)
    [self error:@"direct parameter missing"];
  [self writeOutputStringForInputString:inputFromCommandLine];
}

- (void)closeStreams;
{
  [input closeFile];
  [output closeFile];
}

- (void)writeOutputString:(NSString *)outputString;
{
  NSData *outputData=[outputString dataUsingEncoding:NSISOLatin1StringEncoding];
  [output writeData:outputData];
}
- (void)writeOutputStringForInputString:(NSString *)inputString;
{
  NSString *outputString=[server performSelector:serverSelector withObject:inputString];
  [self writeOutputString:outputString];
}

@end
