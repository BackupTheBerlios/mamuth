//  FSKVCoding.h Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import "FSKVCoding.h"


@implementation NSObject (FSKVCoding)
- (id)fskvWrapper; // designate a wrapper, that responds to fskv Methods (e.g. for Sets)
{
    return self;
}
- (NSArray *)fskvUnclassifiedRelationshipKeys;
{
    return nil;
}
- (id)fskvValueForKey:(NSString *)key;
    /** may be overridden by subclasses
              default: standard key-value-coding method **/
{
    return [self valueForKey:key];
}
- (void)fskvTakeValue:(id)value forKey:(NSString *)key;
    /** may be overridden by subclasses
              default: standard key-value-coding method **/
{
    [self takeValue:value forKey:key];
}

- (BOOL)fskvIsValidKey:(NSString *)key;
/** Classes, were the valid keys change during time (e.g. NSMutableArray)
might override this. Note: the default method does not check, if key is an element of published Keys for performance reasons.
             default:YES **/
{
    return YES;
}
- (BOOL)fskvAllowsToGetValueForKey:(NSString *)key; 
    /** might disallow getting of properties
        this is rarely needed, if the properties are explicitly published!
                           default: [self fskvIsValidKey:key] **/
{
    return [self fskvIsValidKey:key];
}
- (BOOL)fskvAllowsToTakeValueForKey:(NSString *)key;
    /** might disallow setting for all values
                            default: [self fskvIsValidKey:key] **/
{
    return [self fskvIsValidKey:key];
}
- (BOOL)fskvAllowsToTakeValue:(id)value forKey:(NSString *)key;
    /** might disallow setting of special values
                      default: calls fskvAllowsToTakeValueForKey:key
                          **/
{
    return [self fskvAllowsToTakeValueForKey:key];
}

//NSLog(@"%d",(int)(1<<KEYS)); \
#define addArray(KEYS)  \
if (filter & (1<<KEYS)) { \
    keys=[self KEYS];\
        if (keys) \
            [a addObjectsFromArray:keys];\
}
- (NSMutableArray *)fskvKeysWithFilterBits:(int)filter;
{ // should be faster than fskvKeysWithFilterArray
    NSMutableArray *a=[NSMutableArray array];
    NSArray *keys;
    addArray(attributeKeys);
    addArray(toOneRelationshipKeys);
    addArray(toManyRelationshipKeys);
    addArray(fskvUnclassifiedRelationshipKeys);
    return a;
}

- (NSMutableArray *)fskvKeysWithFilterArray:(NSArray *)filter;
{ // more general than fskvKeysWithFilterBits:(int)
   NSMutableArray *a=[NSMutableArray array];
    NSEnumerator *e=[filter objectEnumerator];
    NSString *s;
    while (s=[e nextObject]) {
        SEL sel=NSSelectorFromString(s);
        NSArray *keys=[self performSelector:sel];
        if (keys) 
            [a addObjectsFromArray:keys];
    }
    return a;
}

@end

@implementation NSArray (FSKVCoding)
// extension of NSClassDescription methods (may be overridden)
- (NSArray *)fskvUnclassifiedRelationshipKeys;
{
    NSMutableArray *a=[NSMutableArray array];
//    NSString *format;
    int i,c;//,digits=0,lessThan=1;
    c=[self count];
/*    while (lessThan<c)
        digits++;
        lessThan*=10;
    }
*/
    for (i=0;i<c;i++)
        [a addObject:[NSString stringWithFormat:@"%7d",i]];
    return a;
}
- (id)fskvValueForKey:(NSString *)key;
{
    int idx=[key intValue];
    id value=[self objectAtIndex:idx];
    return value;
}
    // information regarding the mutability of properties. (may be overridden)
- (BOOL)fskvIsValidKey:(NSString *)key;
{
    int idx=[key intValue];
    return (idx<[self count]);
}
- (BOOL)fskvAllowsToTakeValueForKey:(NSString *)key; // might disallow setting for all values
{
    return NO;
}
@end

@implementation NSMutableArray (FSKVCoding)
// extension of NSClassDescription methods (may be overridden)
- (void)fskvTakeValue:(id)value forKey:(NSString *)key;
{
    int idx=[key intValue];
    [self replaceObjectAtIndex:idx withObject:value];
}
- (BOOL)fskvAllowsToTakeValueForKey:(NSString *)key; // might disallow setting for all values
{
    return [self fskvIsValidKey:(NSString *)key];
}
- (BOOL)fskvAllowsToTakeValue:(id)value forKey:(NSString *)key; // disallow nil values
{
    if (!value) return NO;
    else return [self fskvIsValidKey:key];
}
@end

@implementation NSDictionary (FSKVCoding)
// extension of NSClassDescription methods (may be overridden)
- (NSArray *)fskvUnclassifiedRelationshipKeys;
{
    return [self allKeys];
}
- (id)fskvValueForKey:(NSString *)key;
{
    id value=[self objectForKey:key];
    return value;
}
// information regarding the mutability of properties. (may be overridden)
- (BOOL)fskvIsValidKey:(NSString *)key;
/* any key is valid */
{
    return YES;
}
- (BOOL)fskvAllowsToTakeValueForKey:(NSString *)key; // might disallow setting for all values
{
    return NO;
}
@end

@implementation NSMutableDictionary (FSKVCoding)
// extension of NSClassDescription methods (may be overridden)
- (void)fskvTakeValue:(id)value forKey:(NSString *)key;
{
    [self setObject:value forKey:key];
}
- (BOOL)fskvAllowsToTakeValueForKey:(NSString *)key; // might disallow setting for all values
{
    return YES;
}
- (BOOL)fskvAllowsToTakeValue:(id)value forKey:(NSString *)key; // disallow nil values
{
    if (!value) return NO;
    else return YES;
}
@end


