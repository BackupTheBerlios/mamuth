//  FSLisp2PropertyList.h Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import <Foundation/Foundation.h>


@interface FSLisp2PropertyList : NSObject {
  BOOL decodeCyclicMacro;
  NSMutableDictionary *cyclicStructs;
}
+ (id)plistForCyclicLispString:(NSString *)lispString;
+ (id)plistForLispString:(NSString *)lispString;

- (BOOL)decodeCyclicMacro;
- (void)setDecodeCyclicMacro:(BOOL)newVal;
- (id)plistForLispString:(NSString *)lispString;
@end
