//  FSKVBrowserExample.m Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import "FSKVBrowserExample.h"
#import "Airplane.h"
#import "Pilot.h"
#import "Flight.h"


@implementation Airplane (KVCoding)
- (NSArray *)attributeKeys;
{
  return [NSArray arrayWithObjects:@"capacity",@"model",@"location",nil];
}
@end

@implementation Pilot (KVCoding)
- (NSArray *)attributeKeys;
{
  return [NSArray arrayWithObjects:@"name",@"address",@"salary",nil];
}
@end

@implementation Flight (KVCoding)
- (NSArray *)attributeKeys;
{
  return [NSArray arrayWithObjects:@"arrivalDate",@"arrivalLocation",@"departureDate",@"departureLocation",nil];
}
- (NSArray *)toOneRelationshipKeys;
{
  return [NSArray arrayWithObjects:@"pilot",@"airplane",nil];
}
@end
