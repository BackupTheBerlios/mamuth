//  jgdostdio_main.m Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import <Foundation/Foundation.h>

@interface JGSTDIOServiceProvider : NSObject 
{
  NSString *serverName;
  NSString *executablePath;
  NSString *stopWord;
  NSTask *aTask;
  BOOL doRelaunch;  
  int launchCount;
}
- (id)initWithServerName:(NSString *)serverNameI executablePath:(NSString *)executablePathI stopWord:(NSString *)stopWordI;
- (void)registerServerConnection;
- (void)registerServerConnection:(NSString *)connectionName;
- (NSString *)execute:(NSString *)inputString;
@end

@implementation JGSTDIOServiceProvider 
- (id)initWithServerName:(NSString *)serverNameI executablePath:(NSString *)executablePathI stopWord:(NSString *)stopWordI;
{
  [super init];
  serverName=[serverNameI copy];
  executablePath=[executablePathI stringByExpandingTildeInPath];
  stopWord=[stopWordI copy];
  aTask=nil;
  doRelaunch=NO;
  launchCount=0;
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

- (void)setupTask;
{
    NSArray *args = [NSArray array];
    NSPipe *outPipe = [NSPipe pipe];
    NSPipe *inPipe = [NSPipe pipe];
    NSPipe *errPipe = [NSPipe pipe];
    [aTask release];
    aTask = [[NSTask alloc] init];
    [aTask setLaunchPath:executablePath];
    [aTask setArguments:args];
    [aTask setStandardOutput:inPipe]; 
    [aTask setStandardInput:outPipe]; 
    [aTask setStandardError:errPipe]; 
}

- (void)launchTask;
{
  [aTask launch];
  launchCount++;
}

- (void)setupAndLaunchTask;
{
  [self setupTask];
  [self launchTask];
}
- (NSString *)execute:(NSString *)inputString;
{
  if (![aTask isRunning]) {
    if (!launchCount || doRelaunch) {
      [self setupAndLaunchTask];
    }
  }
  if (![aTask isRunning]) {
    return [NSString stringWithFormat:@"jgdostdio error: task %@ is not running",executablePath];
  } else {
    NSString *outStr=inputString;
    NSMutableString *inCollectStr=[NSMutableString string];
    NSData *outData = [outStr dataUsingEncoding:NSISOLatin1StringEncoding];
    NSData *inData=nil;
    NSFileHandle *writeHandle = [[aTask standardInput] fileHandleForWriting];
    NSFileHandle *readHandle = [[aTask standardOutput]  fileHandleForReading];
//    NSFileHandle *errHandle = [[aTask standardError] fileHandleForReading];
    BOOL stopWordFound=NO;

    [writeHandle writeData:outData];
//    [writeHandle synchronizeFile];
    inData=[readHandle availableData]; // waits for output resp. data of lenght 0 if EOF
    while (!stopWordFound && [inData length]) {
          NSString *s=[[NSString alloc] initWithData:inData encoding:NSISOLatin1StringEncoding];
          [inCollectStr appendString:s];
          stopWordFound=[inCollectStr hasSuffix:stopWord];
          if (!stopWordFound) 
            inData=[readHandle availableData];
          [s release];
    }
    if (!stopWordFound) 
      return [NSString stringWithFormat:@"jgdostdio error: unexpected end of file. Stopword %@ not found.",stopWord];
    else 
      return [inCollectStr substringToIndex:[inCollectStr length]-[stopWord length]];
  }
}

- (void)checkTaskWithTimer:(NSTimer *)timer;
{
  if (![aTask isRunning]) {
    if (!launchCount || doRelaunch) {
      // o.K, continue
    } else {
      [timer invalidate];
      exit(0);
    }
  }
}

- (void)run;
{
//  NSTimer *timer=[NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(checkTaskWithTimer:) userInfo:nil repeats:YES];
  NSRunLoop *runLoop=[NSRunLoop currentRunLoop];
  [runLoop configureAsServer];
  while (!launchCount || doRelaunch || [aTask isRunning]) 
    [runLoop runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
}
@end 


int main(int argc, const char *argv[])
{
  JGSTDIOServiceProvider *provider;
  NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
  NSArray *args=[[NSProcessInfo processInfo] arguments];
  if ((argc!=4) || ((argc==5) && (![[args objectAtIndex:4] isEqualToString:@"-n"]))){
    puts("USAGE: jgdostdio serverName executablePath stopName [-n]");
    puts("  -n: if given, does not append \\n to stopName (like echo command)");
    exit(1);
  } else {
    NSString *serverName=[args objectAtIndex:1];
    NSString *executablePath=[args objectAtIndex:2];
    NSString *stopWord=[args objectAtIndex:3];
    if (argc==4)
      stopWord=[stopWord stringByAppendingString:@"\n"];
    provider=[[JGSTDIOServiceProvider alloc] initWithServerName:serverName executablePath:executablePath stopWord:stopWord];
    [provider setupAndLaunchTask];
    [provider registerServerConnection];
  }
  [provider run];
  
  [pool release];
  exit(0);       // insure the process exit status is 0
  return 0;      // ...and make main fit the ANSI spec.
}
