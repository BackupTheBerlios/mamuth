//  FSPropertyList2Lisp.h Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import <Foundation/Foundation.h>


@interface FSPropertyList2Lisp : NSObject {
  NSMutableSet *addresses;
  NSMutableSet *duplicates[10];
  int varNumber[10];
  NSString *varPrefix[10];
  NSMutableSet *begunAddresses,*cycleAddresses;
  NSMutableDictionary *names;
  NSMutableString *letDefs;
  BOOL defineCycles;
  int needDictDef,needArrayDef;
  NSString *vectorString; // if nil, use value form.
}
+ (void)initializeLispStrings;
+ (NSString *)lisp_defines;
+ (NSString *)stringFromPropertyList:(id)plist;
+ (NSString *)stringFromPropertyList:(id)plist vectorString:(NSString *)v;
+ (void)setUseLocalFunctions:(BOOL)yn;
- init;
- (void)setVectorString:(NSString *)newStr;
- (NSString *)vectorString;
- (NSString *)stringFromPropertyList:(id)plist;
- (NSString *)dataExpressionForPlist:(id)plist;
- (void)setDefineCylce:(BOOL)yn;
- (void)checkRefs:(id)plist;
- (void)declareAddresses;
- (NSString *)labelDefinitions;
- (NSString *)letDefinitions;
- (NSString *)cycleDefinitions;
- (NSString *)varOrDefinitionForPlist:(id)plist;
- (NSString *)varOrDefinitionForAddress:(NSValue *)address;
- (NSString *)defineAddress:(NSValue *)address;
//- (void)let:type address:(NSValue *)address definition:(NSString *)definition prePrefix:(NSString *)prePrefix;
- (NSString *)defineString:(NSString *)str address:(NSValue *)address;
- (NSString *)defineArray:(NSArray *)a address:(NSValue *)address;
- (NSString *)defineDictionary:(NSDictionary *)d address:(NSValue *)address;
@end
