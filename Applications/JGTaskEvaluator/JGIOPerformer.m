//  JGIOPerformer.m Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import "JGIOPerformer.h"


@implementation JGIOPerformer
- (id)init;
{
  [super init];
  input=[[NSFileHandle fileHandleWithStandardInput] retain];
  output=[[NSFileHandle fileHandleWithStandardOutput] retain];
  inputFromCommandLine=nil;
  clientSelector=@selector(lineByLineWithNewline);
  errorFormatter=nil;
  return self;
}
- (void)dealloc;
{
  [inputFromCommandLine release];
  [errorFormatter release];
  [super dealloc];
}

- (void)error:(NSString *)message;
{
  if (errorFormatter) {
    NSData *outputData;
    NSFileHandle *err=[NSFileHandle fileHandleWithStandardError];
    message=[NSString stringWithFormat:errorFormatter,message];
    outputData=[message dataUsingEncoding:NSISOLatin1StringEncoding];
    [err writeData:outputData];
  }
  exit(0);  
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
  NSString *outputString=[self outputStringForInputString:inputString];
  [self writeOutputString:outputString];
}
- (void)perform;
{
  [self performSelector:clientSelector];
}
- (NSString *)outputStringForInputString:(NSString *)inputStr; // abstract
{
  return nil;
}
@end
