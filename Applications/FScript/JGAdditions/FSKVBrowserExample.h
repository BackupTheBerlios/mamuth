//  FSKVBrowserExample.h Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import <Foundation/Foundation.h>
#import "Airplane.h"
#import "Pilot.h"
#import "Flight.h"

@interface Airplane (KVCoding)
- (NSArray *)attributeKeys;
@end
@interface Pilot (KVCoding)
- (NSArray *)attributeKeys;
@end
@interface Flight (KVCoding)
- (NSArray *)attributeKeys;
- (NSArray *)toOneRelationshipKeys;
@end
