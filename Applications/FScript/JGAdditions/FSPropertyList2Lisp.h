//  FSPropertyList2Lisp.h Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import <Foundation/Foundation.h>

#define FSPROPERTYLIST_MAXPLISTTYPE 10

@interface FSPropertyList2Lisp : NSObject {
  NSMutableSet *addresses;
  NSMutableSet *duplicates[FSPROPERTYLIST_MAXPLISTTYPE];
  int varNumber[FSPROPERTYLIST_MAXPLISTTYPE];
  NSString *varPrefix[FSPROPERTYLIST_MAXPLISTTYPE];
  unsigned int objectCount[FSPROPERTYLIST_MAXPLISTTYPE];
  NSMutableSet *begunAddresses,*cycleAddresses;
  NSMutableDictionary *names;
  NSMutableString *letDefs;
  BOOL defineCycles;
  int needDictDef,needArrayDef;
  NSString *vectorString; // if nil, use value form.
  NSString *newLine; //  used in macroStringForArrays. set global variable to switch to mcl-encoding: (FSPropertyList2Lisp setNewLine:'\r').
}
+ (void)setNewLine:(NSString *)newStr; // used for initialization of [self newLine] 
+ (void)initializeLispStrings;
+ (NSString *)lisp_defines;
+ (NSString *)stringFromPropertyList:(id)plist;
+ (NSString *)stringFromPropertyList:(id)plist vectorString:(NSString *)v;
+ (void)setUseLocalFunctions:(BOOL)yn;
- init;
- (void)setVectorString:(NSString *)newStr;
- (NSString *)vectorString;
- (NSString *)newLine;
- (void)setNewLine:(NSString *)newStr;
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

@interface FSPropertyList2Lisp (NestedListData)
- (void)addToString:(NSMutableString *)lispString lispStringForString:(NSString *)str;
- (void)addToMacroString:(NSMutableString *)lispString fromArrayOrString:(id)plist level:(int)level;
+ (BOOL)macroStringForArraysUsesReferences;
+ (void)setMacroStringForArraysUsesReferences:(BOOL)newVal;
+ (NSMutableString *)macroStringForArrays:(id) plist;
@end
