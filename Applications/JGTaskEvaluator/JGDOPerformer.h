//  JGDOPerformer.h Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import <Foundation/Foundation.h>
#import "JGIOPerformer.h"


@interface JGDOPerformer : JGIOPerformer
{
  NSString *serverName;
  NSString *hostName;
  SEL serverSelector; // jgdoPerformer is the client, the foreign process server object is the server.
  id server;
}
- (NSString *)usage;
- (void)setWithProcessInfo;

// overridden
- (void)perform;
- (NSString *)outputStringForInputString:(NSString *)inputStr;
@end
