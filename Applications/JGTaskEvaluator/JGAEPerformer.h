//  JGAEPerformer.h Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import <Foundation/Foundation.h>
#import "JGIOPerformer.h"
#import <Carbon/Carbon.h>

@interface JGAEPerformer : JGIOPerformer
{
  OSType creator;
  AEEventClass theAEEventClass;
  AEEventID theAEEventID;
}
- (NSString *)usage;
- (void)setWithProcessInfo;

// helpers
- (OSType)osType:(NSString *)str;
- (OSType)convertString:(NSString *)str errorVarName:(NSString *)varName;

// overridden
- (void)perform;
- (NSString *)outputStringForInputString:(NSString *)inputStr;
@end
