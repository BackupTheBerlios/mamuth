/* JGArrayWithAccessorBlocks.m Copyright (c) 2002 Joerg Garbers. */
/* This software is open source. See the license.        */

#import "JGArrayWithAccessorBlocks.h"
#import "Number.h"

#define JGArrayWithAccessorBlocks_COMMON_init \
data=nil; \
indexNumberClass=1; \
countBlock=[[newAccessorBlocks objectForKey:@"array:count"] retain]; \
objectAtIndexBlock=[[newAccessorBlocks objectForKey:@"array:objectAtIndex:"] retain]; \
if (!(countBlock && objectAtIndexBlock)) {\
  [self release]; \
  return nil; \
}

#define JGArrayWithAccessorBlocks_COMMON_dealloc \
[countBlock release]; \
[objectAtIndexBlock release]; \
[data release];

@implementation JGArrayWithAccessorBlocks


- (id)initWithAccessorBlocks:(NSDictionary *)newAccessorBlocks;
{
  [super init];
  JGArrayWithAccessorBlocks_COMMON_init;
  return self;
}
- (void)dealloc;
{
  JGArrayWithAccessorBlocks_COMMON_dealloc;
  [super dealloc];
}

#include "JGArrayWithAccessorBlocksCommonImpl.m"
@end

@implementation JGMutableArrayWithAccessorBlocks
#include "JGArrayWithAccessorBlocksCommonImpl.m"

- (id)initWithAccessorBlocks:(NSDictionary *)newAccessorBlocks;
{
  self=[super init];
  if (!self)
    return nil;
  JGArrayWithAccessorBlocks_COMMON_init;
  addObjectBlock=[[newAccessorBlocks objectForKey:@"array:addObject:"] retain];
  insertObjectAtIndexBlock=[[newAccessorBlocks objectForKey:@"array:insertObject:atIndex:"] retain];
  removeLastObjectBlock=[[newAccessorBlocks objectForKey:@"array:removeLastObject"] retain];
  removeObjectAtIndexBlock=[[newAccessorBlocks objectForKey:@"array:removeObjectAtIndex:"] retain];
  replaceObjectAtIndexWithObjectBlock=[[newAccessorBlocks objectForKey:@"array:replaceObjectAtIndex:withObject:"] retain];
  if (addObjectBlock && insertObjectAtIndexBlock && removeLastObjectBlock && removeObjectAtIndexBlock && replaceObjectAtIndexWithObjectBlock)
    return self;
  else {
    [self release];
    return nil;
  }  
}
- (void)dealloc;
{
  [addObjectBlock release];
  [insertObjectAtIndexBlock release];
  [removeLastObjectBlock release];
  [removeObjectAtIndexBlock release];
  [replaceObjectAtIndexWithObjectBlock release];
  JGArrayWithAccessorBlocks_COMMON_dealloc;
  [super dealloc];
}


- (void)addObject:(id)anObject;
{
  [addObjectBlock value:self value:anObject];
}
- (void)insertObject:(id)anObject atIndex:(unsigned)index;
{
  [insertObjectAtIndexBlock value:self value:anObject value:[self numberWithIndex:index]];
}
- (void)removeLastObject;
{
  [removeLastObjectBlock value:self];
}
- (void)removeObjectAtIndex:(unsigned)index;
{
  [removeObjectAtIndexBlock value:self value:[self numberWithIndex:index]];
}
- (void)replaceObjectAtIndex:(unsigned)index withObject:(id)anObject;
{
  [replaceObjectAtIndexWithObjectBlock value:self value:[self numberWithIndex:index] value:anObject];  
}
@end
