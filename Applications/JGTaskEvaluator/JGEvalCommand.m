//  JGEvalCommand.m Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import "JGEvalCommand.h"
#import "JGTaskServicesProvider.h"
#import <Foundation/NSDebug.h>

@implementation JGEvalCommand
- (id)performDefaultImplementation;
{
  NSString *command=[self directParameter];
  id provider;
  NSString *result;
  static BOOL debug;
  static BOOL initDebug=YES;
    if (initDebug) {
      debug=NSDebugEnabled;
      initDebug=NO;
    }
  if (debug) NSLog(@"evaluating: %@",[command description]);
  provider=[JGTaskServicesProvider globalServicesProvider];
  result=[provider execute:command];
  if (!result) 
    result=[@"FScript error with command: " stringByAppendingString:command];
  if (debug) NSLog(@"result: %@",result);
  return result;
}
@end
