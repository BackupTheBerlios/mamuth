//  jgdofifo_main.m Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import <Foundation/Foundation.h>

@interface JGFIFOServiceProvider : NSObject 
{
  NSString *serverName;
  NSString *fileIn;
  NSString *fileOut;
}
- (id)initWithServerName:(NSString *)serverNameI fileIn:(NSString *)fileInI fileOut:(NSString *)fileOutI;
- (void)registerServerConnection;
- (void)registerServerConnection:(NSString *)connectionName;
- (NSString *)execute:(NSString *)inputString;
@end

@implementation JGFIFOServiceProvider 
- (id)initWithServerName:(NSString *)serverNameI fileIn:(NSString *)fileInI fileOut:(NSString *)fileOutI;
{
  [super init];
  serverName=[serverNameI copy];
  fileIn=[fileInI copy];
  fileOut=[fileOutI copy];
  return self;
}
- (void)registerServerConnection;
{
  [self registerServerConnection:serverName];
}
- (void)registerServerConnection:(NSString *)connectionName;
{
  NSConnection *theConnection = [NSConnection defaultConnection]; // in current Thread
  [theConnection setRootObject:self];
  if ([theConnection registerName:connectionName] == NO) {
    NSLog(@"Handle error.");
  }
}
- (NSString *)execute:(NSString *)inputString;
{
  NSString *result;
  // opening fifo file descriptors blocks until there is the corresponding partner opening on the other line.
  // this is not the same as from the shell, where imediately input can be entered.
#if 0
  [inputString writeToFile:fileIn atomically:NO]; // YES overrides status of 
  result=[NSString stringWithContentsOfFile:fileOut]; // wrong: does not wait until producer writes EOF.
#elif 0
  NSString *helpfile=@"/tmp/jgdofifo.help";
  NSString *command=[NSString stringWithFormat:@"cat %@ >%@",helpfile,fileIn];
  [inputString writeToFile:helpfile atomically:YES];
  system([command cString]); //  launchedTaskWithLaunchPath // this blocks, until there is a reader.
  if (1) {
    NSMutableString *collector=[NSMutableString string];
    char *line;
    size_t length;
    FILE *fout=fopen([fileOut cString],"r");
    while (line=fgetln(fout,&length)) {
      if (length>0) {
        NSString *lineString=[NSString stringWithCString:line length:length];
        [collector appendString:lineString];
      }
    }
    result=collector;
  }
#elif 1
  // most elegant version (1)
  NSFileHandle *fout;
  NSData *outData;
  if (1) {
    [inputString writeToFile:fileIn atomically:NO]; // YES overrides status of 
  } else {
    NSFileHandle *fin=[NSFileHandle fileHandleForWritingAtPath:fileIn];
    NSData *inData = [inputString dataUsingEncoding:[NSString defaultCStringEncoding]];
    [fin writeData:inData];
    [fin closeFile];
  }
  fout=[NSFileHandle fileHandleForReadingAtPath:fileOut];
  outData=[fout readDataToEndOfFile];
  result=[[[NSString alloc] initWithData:outData encoding:[NSString defaultCStringEncoding]] autorelease];
#elif 0
  NSMutableString *collector=[NSMutableString string];
  char *line;
  size_t length;
  FILE *fin=fopen([fileIn cString], "w");
  FILE *fout=fopen([fileOut cString],"r");
  fputs([inputString cString],fin);
  fclose(fin);
  while (line=fgetln(fout,&length)) {
    if (length>0) {
      NSString *lineString=[NSString stringWithCString:line length:length];
      [collector appendString:lineString];
    }
  }
  result=collector;
#endif
  return result;
}
@end 


int main(int argc, const char *argv[])
{
  NSRunLoop *runLoop;
  JGFIFOServiceProvider *provider;
  NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
  if (argc!=4) {
    puts("USAGE: jgdofifo serverName fifoInputName fifoOutputName");
    exit(1);
  } else {
    NSArray *args=[[NSProcessInfo processInfo] arguments];
    NSString *serverName=[args objectAtIndex:1];
    NSString *fileIn=[args objectAtIndex:2];
    NSString *fileOut=[args objectAtIndex:3];
    provider=[[JGFIFOServiceProvider alloc] initWithServerName:serverName fileIn:fileIn fileOut:fileOut];
    [provider registerServerConnection];
  }
  runLoop=[NSRunLoop currentRunLoop];
  [runLoop configureAsServer];
  [runLoop run];
  
  [pool release];
  exit(0);       // insure the process exit status is 0
  return 0;      // ...and make main fit the ANSI spec.
}
