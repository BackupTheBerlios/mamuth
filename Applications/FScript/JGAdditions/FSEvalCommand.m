//  FSEvalScriptCommand.m Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import "FSEvalCommand.h"
#import "FSServicesProvider.h"

@implementation FSEvalCommand
- (id)performDefaultImplementationOld;
{
  NSString *command=[self directParameter];
  id provider;
  NSString *result;
  NSLog(@"evaluating: %@",[command description]);
  provider=[FSServicesProvider globalServicesProvider];
  result=[provider execute:command];
  if (!result) 
    result=[@"FScript error with command: " stringByAppendingString:command];
  NSLog(@"result: %@",result);
  return result;
}
- (id)performDefaultImplementation;
{
/* returns the evaluation of the last command as a string */
  NSString *commandsString=[self directParameter];
  NSString *result;
  NSLog(@"evaluating: %@",[commandsString description]);
  result=[[FSServicesProvider globalServicesProvider] executeText:commandsString];
  NSLog(@"result: %@",result);
  return result;
}
@end
