//  JGAEPerformer.m Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import "JGAEPerformer.h"

// see jgSendEvent.c
char *sendString(OSType creator, AEEventClass theAEEventClass, AEEventID theAEEventID, const char *text, Size *returnStringSize);

@implementation JGAEPerformer
- (id)init;
{
  [super init];
  errorFormatter=[@"jgae error:%@" retain];
  creator='CCL2';
  theAEEventClass='misc';
  theAEEventID='eval';
  return self;
}
- (void)dealloc;
{
  [super dealloc];
}

- (NSString *)usage;
{
return @"\
USAGE: jgae [Creator-Name [Class-Name [Id-Name [Slice-Method [Direct-Parameter]]]]]\n\
  Creator-Name: Creator-Name of the AE-Server (default: 'CCL2') \n\
  Class-Name: Class-Name of the AE-Server (default: 'misc') \n\
  Id-Name: Id-Name of the AE-Server (default: 'eval') \n\
  Slice-Method: lineByLineWithNewline (default), lineByLine, all, direct\n\
    defines what (stdin or Direct-Parameter) is sent to the server and for stdin, in what portions. \n\
  Direct-Parameter: used instead of stdin. \n\
";
}

- (OSType)osType:(NSString *)str;
{
  static BOOL tested=NO;
  static int idxs[4];
  const char *cStr=[str cString];
  char castStr[4];
  int i;
  
  if (!tested) {
     // char castStr2[4]='abcd';
      OSType ostype=(OSType)'abcd';
      char *asStr=(char *)&ostype;
      for (i=0;i<4;i++) 
        idxs[i]=asStr[i]-'a';
  }
  for (i=0;i<4;i++)
    castStr[idxs[i]]=cStr[i];
  return *(OSType *)castStr;
}

- (OSType)convertString:(NSString *)str errorVarName:(NSString *)varName;
{
  if ([str length]!=4) {
    if (varName) {
      NSString *errorStr=[NSString stringWithFormat:@"parameter %@ is not a four letter code"];
      [self error:errorStr];
    }
    return (OSType)0;
  } else
    return [self osType:str];
}

- (void)setWithProcessInfo;
{
  NSProcessInfo *processInfo=[NSProcessInfo processInfo];
  NSArray *args=[processInfo arguments];
  int argc=[args count];

  // constants
  int firstArg=1; // 0 is this tasks executable
  int creatorNamePos=0;
  int classNamePos=1;
  int idNamePos=2;
  int clientSelectorPos=3;
  int inputFromCommandLinePos=4;

  if (argc>firstArg+creatorNamePos) {
    NSString *creatorNameString=[args objectAtIndex:firstArg+creatorNamePos];
    if ([creatorNameString isEqualToString:@"-h"]) {
      [self writeOutputString:[self usage]];
      exit(0);
    }
    creator=[self convertString:creatorNameString errorVarName:@"Creator-Name"];
  }
  if (argc>firstArg+classNamePos) {
    NSString *classNameString=[args objectAtIndex:firstArg+classNamePos];
    theAEEventClass=[self convertString:classNameString errorVarName:@"Class-Name"];
  }
  if (argc>firstArg+idNamePos) {
    NSString *idNameString=[args objectAtIndex:firstArg+idNamePos];
    theAEEventID=[self convertString:idNameString errorVarName:@"Id-Name"];
  }
  if (argc>firstArg+clientSelectorPos)
    clientSelector=NSSelectorFromString([args objectAtIndex:firstArg+clientSelectorPos]);
  if (argc>firstArg+inputFromCommandLinePos)
    inputFromCommandLine=[[args objectAtIndex:firstArg+inputFromCommandLinePos] retain];
}

- (void)perform;
  /*"Establishes and checks the connection and performs the selector given on command line"*/
{
  // to do: should check, if Application is running.
  [self performSelector:clientSelector];
}

- (NSString *)outputStringForInputString:(NSString *)inputStr;
{
  const char *inStr=[inputStr cString];
  Size outSize;
  char *outStr=sendString(creator, theAEEventClass, theAEEventID, inStr, &outSize);
  NSString *outputString=(outStr ? [[[NSString alloc] initWithCStringNoCopy:outStr length:outSize freeWhenDone:YES] autorelease] : nil);
  return outputString ;
}

@end
