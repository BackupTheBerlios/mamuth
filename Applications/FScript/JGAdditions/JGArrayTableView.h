/* JGArrayTableView.h Copyright (c) 1998-2001 Philippe Mougin, Joerg Garbers. */
/* This software is open source. See the license.        */

#import <Foundation/Foundation.h>
#import "Array.h"

@class NSTableView;
@class NSTableColumn;
@protocol SDMovingRowsProtocol;

#define USE_SD_TABLE_VIEW

/* identifierMappings is a Dictionary of Mappings between identifier and other TableView relevant information. Keys in this dictionary are the identifiers.
Value is a dictionary with keys such as: "title" "getBlock" "setBlock".
Missing setBlocks result in non editable columns.
Missing titles result will be replaced by (getBlock printString) 
e.g.:
identifiers:={'Name', 'Address'}
mappings:=NSDictionary dictionaryWithObjects:{
(NSDictionary dictionaryWithObjects:{'Pilot',#name} forKeys:{'title', 'getBlock'}) 
(NSDictionary dictionaryWithObjects:{'Wohnhaft',#address,#address:} forKeys:{'title', 'getBlock', 'setBlock'}) } forKeys:identifiers.

JGArrayTableView arrayOfDictionariesForKeys:{'title','getBlock','setBlock'} valueArrays:{{'Pilot','Wohnhaft'},{'#name',#address},{nil,#address:}}
JGArrayTableView arrayTableViewWithArray:P identifiers: {'Meta-Index1'}++(2 iota)  titles:{'Nr','Pilot','Wohnhaft'} getBlocks:{[:arr :ind | ind+1],#name,#address} setBlocks:{nil,nil,#address:}

Identifiers, that are Strings, that start with 'Meta', must be coupled with Blocks, that accept the model array as a first parameter and the row number (Number) as a second parameter.
Other Blocks get just one element of the model object as parameter.
Set-Blocks get an Object as an additional parameter.
*/

@interface JGArrayTableView : NSObject
{
  NSTableView *tableView; // outlet
  NSArray *model;
  NSDictionary *mappings;
}
+ (NSMutableArray *)arrayOfDictionariesForKeys:(NSArray *)keys valueArrays:(NSArray *)valueArrays;
+ (NSDictionary *)mappingsForIdentifiers:(NSArray *)identifiers titles:(NSArray *)titles getBlocks:(NSArray *)getBlocks setBlocks:(NSArray *)setBlocks;
+ (JGArrayTableView *)arrayTableViewWithArray:(NSArray*)modelArray identifiers:(NSArray *)identifiers  titles:(NSArray *)titles getBlocks:(NSArray *)getBlocks setBlocks:(NSArray *)setBlocks;
+ (JGArrayTableView *)arrayTableViewWithArray:(NSArray*)modelArray identifiers:(NSArray *)identifiers mappings:(NSDictionary *)mappings;

- (JGArrayTableView *)initWithArray:(NSArray*)modelArray identifiers:(NSArray *)identifiers mappings:(NSDictionary *)mappings;
@end

#ifdef USE_SD_TABLE_VIEW
// for drag and drop see JGTableDataViewController (SDTableViewDelegate) <SDMovingRowsProtocol>
@interface JGArrayTableView (SDTableViewDelegate) <SDMovingRowsProtocol>
- (unsigned int)dragReorderingMask:(int)forColumn;
- (BOOL)tableView:(NSTableView *)tv didDepositRow:(int)rowToMove at:(int)newPosition;
- (BOOL) tableView:(/*SDTableView */NSTableView *)tableView draggingRow:(int)draggedRow overRow:(int) targetRow;
@end
#endif
