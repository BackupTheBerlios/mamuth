//  FSKVBrowserBase.h Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import <Cocoa/Cocoa.h>

#define USE_FSKV_CODING

#ifdef USE_FSKV_CODING
#import "FSKVCoding.h"
#endif


@interface FSKVBrowserBase : NSObject
{
  id rootObject;
  IBOutlet NSBrowser *relationshipBrowser; // this one should not change!
  BOOL includeAttributes;

  // helper vars to make it fast.
  int cachedForColumn; // number gives 
#ifdef USE_FSKV_CODING
  NSMutableArray *relationshipKeys;
  int relationshipCount;
#else
  NSMutableArray *attributeKeys,*toOneRelationshipKeys,*toManyRelationshipKeys,*relationshipKeys;
  int attributeCount,toOneRelationshipCount,toManyRelationshipCount,relationshipCount;
  BOOL objectForColumnIsArray;
#endif
  id objectForColumn;  
}
+ (NSString *)invalidValue;
- (id)rootObject;
- (void)setRootObject:(id)newRoot;
- (void)setRelationshipBrowser:(NSBrowser *)newBrowser;
- (void)setIncludeAttributes:(BOOL)yn;

// caching
- (void)cleanCache;
- (void)setKeysForObject:(id)obj;
- (void)setObjectForColumn:(int)column;

- (id)objectForColumn:(int)column; // rootObject or previously representedObject in browser
- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column;
- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column;
- (NSString *)browser:(NSBrowser *)sender titleOfColumn:(int)column;
@end
