/* JGArrayWithBlockAccessorsCommonImpl.m Copyright (c) 2002 Joerg Garbers. */
/* This software is open source. See the license.        */

+ (id)arrayWithAccessorBlocks:(NSDictionary *)newAccessorBlocks;
{
  return [[[self alloc] initWithAccessorBlocks:newAccessorBlocks] autorelease];
}

// Helper Methods
- (unsigned)indexWithNumber:(id)number;
{
  if (indexNumberClass==0)
    return [number intValue];
  else if (indexNumberClass==1)
    return (int)[number doubleValue];
  else
    return NSNotFound;
}
- (id)numberWithIndex:(unsigned)index;
{
  if (indexNumberClass==0)
    return [NSNumber numberWithInt:index];
  else if (indexNumberClass==1)
    return [Number numberWithDouble:(double)index];
  else
    return nil;
}

// ivar accessors
- (int)indexNumberClass;
{
  return indexNumberClass;
}
- (void)setIndexNumberClass:(int)newNumberClass;
{
  indexNumberClass=newNumberClass;
}

- (id)data;
{
  return data;
}
- (void)setData:(id)newData;
{
  [newData retain];
  [data release];
  data=newData;
}

// primitive Methods
- (unsigned)count;
{
  id blockValue=[countBlock value:self];
  return [self indexWithNumber:blockValue];
}
- (id)objectAtIndex:(unsigned)index;
{
  return [objectAtIndexBlock value:self value:[self numberWithIndex:index]];
}
