/* JGArrayWithAccessorBlocks.h Copyright (c) 2002 Joerg Garbers. */
/* This software is open source. See the license.        */

#import <Foundation/Foundation.h>
#import "Block.h"

// indexNumberClass: 0: NSNumber 1: Number (default)
#define JGArrayWithAccessorBlocks_COMMON_DATA \
int indexNumberClass;  \
id data; \
Block *countBlock; \
Block *objectAtIndexBlock;

#define JGArrayWithAccessorBlocks_COMMON_METHODS \
+ (id)arrayWithAccessorBlocks:(NSDictionary *)accessorBlocks; \
- (id)initWithAccessorBlocks:(NSDictionary *)accessorBlocks; \
\
- (int)indexNumberClass;\
- (void)setIndexNumberClass:(int)newNumberClass; \
- (id)data; \
- (void)setData:(id)newData; \
\
- (unsigned)count; \
- (id)objectAtIndex:(unsigned)index;

@interface JGArrayWithAccessorBlocks : NSArray
{
  JGArrayWithAccessorBlocks_COMMON_DATA;
}
JGArrayWithAccessorBlocks_COMMON_METHODS;
@end

@interface JGMutableArrayWithAccessorBlocks : NSMutableArray
{
  JGArrayWithAccessorBlocks_COMMON_DATA;
  
  Block *addObjectBlock;
  Block *insertObjectAtIndexBlock;
  Block *removeLastObjectBlock;
  Block *removeObjectAtIndexBlock;
  Block *replaceObjectAtIndexWithObjectBlock;
}
JGArrayWithAccessorBlocks_COMMON_METHODS;

- (void)addObject:(id)anObject;
- (void)insertObject:(id)anObject atIndex:(unsigned)index;
- (void)removeLastObject;
- (void)removeObjectAtIndex:(unsigned)index;
- (void)replaceObjectAtIndex:(unsigned)index withObject:(id)anObject;
@end

/* Testing & HOWTO
a:= JGArrayWithAccessorBlocks arrayWithAccessorBlocks:
(NSDictionary dictionaryWithObjects:{[:a|a data count],[:a :index| a data objectAtIndex:index]} forKeys:{'array:count', 'array:objectAtIndex:'}).
a setData:{1,2,3}.
sys browseKV:a.
a:= JGMutableArrayWithAccessorBlocks arrayWithAccessorBlocks:
(NSDictionary dictionaryWithObjects:{
  [:a|a data count],
  [:a :index| a data objectAtIndex:index],
  [:a :obj| a data addObject:obj],
  [:a :obj :index| a data insertObject:obj atIndex:index],
  [:a|a data removeLastObject],
  [:a :index| a data removeObjectAtIndex:index],
  [:a :index :obj | a data replaceObjectAtIndex:index withObject:obj]
} forKeys:{
  'array:count',
  'array:objectAtIndex:',
  'array:addObject:',
  'array:insertObject:atIndex:',
  'array:removeLastObject',
  'array:removeObjectAtIndex:',
  'array:replaceObjectAtIndex:withObject:'
}).
a setData:{1,2,3}.
sys browseKV:a.
*/
