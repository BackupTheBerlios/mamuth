//  JGDOPerformer.h Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import <Foundation/Foundation.h>



@interface JGDOPerformer : NSObject
{
  NSString *serverName;
  NSString *hostName;
  SEL serverSelector,clientSelector; // jgdoPerformer is the client, the foreign process server object is the server.

  NSFileHandle *input,*output;
  id server;
  NSString *inputFromCommandLine;
}
- (NSString *)usage;
- (void)setWithProcessInfo;

- (void)perform;
// valid clientSelectors
- (void)all;
- (void)lineByLine;
- (void)lineByLineWithNewline; // good for interactive mode
- (void)direct;

// helpers
- (void)lineByLineWithTerminator:(NSString *)terminator;

- (void)writeOutputString:(NSString *)outputString;
- (void)writeOutputStringForInputString:(NSString *)inputString;
- (void)closeStreams;

@end
