//  FSKVBrowserBase.m Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import "FSKVBrowserBase.h"


@implementation FSKVBrowserBase
+ (NSString *)invalidValue;
{
    static NSString *str=nil;
    if (!str)
        str=[[NSString stringWithCString:"invalidValue"] retain];
    return str;
}
- (id)init;
{
  [super init];
  rootObject=nil;
  relationshipBrowser=nil;
#ifdef USE_FSKV_CODING
  relationshipKeys=nil;
#else
  attributeKeys=toOneRelationshipKeys=toManyRelationshipKeys=relationshipKeys=nil;
#endif
  cachedForColumn=-2; // impossible value, so cache is not valid.
  return self;
}

- (void)dealoc;
{
  [rootObject release];
  [relationshipBrowser release];
  
#ifndef USE_FSKV_CODING
  [attributeKeys release];
  [toOneRelationshipKeys release];
  [toManyRelationshipKeys release];
#endif
  [relationshipKeys release];
  [super dealloc];
}
- (id)rootObject;
{
    return rootObject;
}
- (void)setRootObject:(id)newRoot; 
{
  [newRoot retain];
  [rootObject release];
  rootObject=newRoot;
  [self cleanCache];
}
- (void)setRelationshipBrowser:(NSBrowser *)newBrowser;
{
  [newBrowser retain];
  [relationshipBrowser release];
  relationshipBrowser=newBrowser;
  [self cleanCache];
}
- (void)setIncludeAttributes:(BOOL)yn;
{
  includeAttributes=yn;
  [self cleanCache];
}

- (void)cleanCache;
{
  cachedForColumn=-2;
}

- (void)setKeysForObject:(id)obj;
{
#ifdef USE_FSKV_CODING
  int bits=0;
  [relationshipKeys release];
  if (includeAttributes)
      bits+=1<<attributeKeys;
  bits+=1<<toOneRelationshipKeys;
  bits+=1<<toManyRelationshipKeys;
  bits+=1<<fskvUnclassifiedRelationshipKeys;
  relationshipKeys=[[obj fskvKeysWithFilterBits:bits] retain];
  [relationshipKeys sortUsingSelector:@selector(compare:)];
  relationshipCount=[relationshipKeys count];
#else
  [attributeKeys release];
  [toOneRelationshipKeys release];
  [toManyRelationshipKeys release];
  [relationshipKeys release];
  
  attributeKeys=[[obj attributeKeys] mutableCopy];
  toOneRelationshipKeys=[[obj toOneRelationshipKeys] mutableCopy];
  toManyRelationshipKeys=[[obj toManyRelationshipKeys] mutableCopy]; 
  
  if (!attributeKeys)
    attributeKeys=[[NSMutableArray alloc] init];
  if (!toOneRelationshipKeys)
    toOneRelationshipKeys=[[NSMutableArray alloc] init];
  if (!toManyRelationshipKeys)
    toManyRelationshipKeys=[[NSMutableArray alloc] init];

  relationshipKeys=[toOneRelationshipKeys mutableCopy];
  [relationshipKeys addObjectsFromArray:toManyRelationshipKeys];
  if (includeAttributes)
    [relationshipKeys addObjectsFromArray:attributeKeys];

  [attributeKeys sortUsingSelector:@selector(compare:)];
  [toOneRelationshipKeys sortUsingSelector:@selector(compare:)];
  [toManyRelationshipKeys sortUsingSelector:@selector(compare:)];
  [relationshipKeys sortUsingSelector:@selector(compare:)];

  attributeCount=[attributeKeys count];
  toOneRelationshipCount=[toOneRelationshipKeys count];
  toManyRelationshipCount=[toManyRelationshipKeys count]; 
  relationshipCount=[relationshipKeys count];
#endif
}

- (void)setObjectForColumn:(int)column;
{
  if (cachedForColumn==column)
    return;
  cachedForColumn=column;

  [objectForColumn autorelease];
  objectForColumn=[[self objectForColumn:column] retain];
#ifdef USE_FSKV_CODING
      [self setKeysForObject:objectForColumn];
#else
  if ([objectForColumn isKindOfClass:[NSArray class]]) {
    objectForColumnIsArray=YES;
    relationshipCount=[objectForColumn count];
  } else {
    objectForColumnIsArray=NO;
      [self setKeysForObject:objectForColumn];
  }
#endif
}

- (id)objectForColumn:(int)column;
{
  id obj;
  if (column==0)
    return rootObject;
  obj=[[relationshipBrowser selectedCellInColumn:column-1] representedObject];
  return obj;
}

- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column;
{
  [self setObjectForColumn:column];
  return relationshipCount;
}

- (void)invalidateCell:(id)cell;
{
    [cell setStringValue:[FSKVBrowserBase invalidValue]];
    [cell setRepresentedObject:nil];
    [cell setLeaf:YES];
    [cell setEnabled:YES];
}
// jg watchout: this is not called for all cells at once, but also later, when the user scrolls!
// but at that time, the represented object (an array) might have changed its count in fscript.
// two solutions:
// 1. insert an array copy instead of a user array for represented object
// 2. check index and return @"invalid"
- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column;
{
  id representedObject=nil;
  id theString;
  [self setObjectForColumn:column];
#ifdef USE_FSKV_CODING
  if (row>=[relationshipKeys count]) {
      [self invalidateCell:cell];
      return;
  } else {
      theString=[relationshipKeys objectAtIndex:row];
      if ([objectForColumn fskvAllowsToGetValueForKey:theString]) {
          representedObject=[[objectForColumn fskvValueForKey:theString] fskvWrapper];
      } else {
        [self invalidateCell:cell];
        return;          
      }
  }  
#else
  if (objectForColumnIsArray) {
      if (row>=[objectForColumn count]) {
          [self invalidateCell:cell];
          return;
      } else {
          theString=[NSString stringWithFormat:@"%d",row];
          representedObject=[objectForColumn objectAtIndex:row];          
      }
  } else {
      if (row>=[relationshipKeys count]) {
          [self invalidateCell:cell];
          return;
      } else {
          theString=[relationshipKeys objectAtIndex:row];
          representedObject=[objectForColumn valueForKey:theString];
      }
  }
#endif
  [cell setStringValue:theString];
  [cell setRepresentedObject:representedObject];
  [cell setLeaf:(representedObject==nil)];
  [cell setEnabled:YES]; 
}
- (NSString *)browser:(NSBrowser *)sender titleOfColumn:(int)column;
{
  return NSStringFromClass([[self objectForColumn:column] class]);
}
- (BOOL)browser:(NSBrowser *)sender isColumnValid:(int)column;
{
  static BOOL v=NO;
  return v;
}
@end
