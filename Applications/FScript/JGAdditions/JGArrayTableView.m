/* ArrayTableView.m Copyright (c) 1998-2001 Philippe Mougin. Joerg Garbers  */
/*   This software is open source. See the license.  */  

#import "build_config.h"
#import "JGArrayTableView.h"
#import "Block.h" 
#import "Number.h" 

#ifdef BUILD_WITH_APPKIT
//--------------------------------- AppKit version --------------------------------

#import <AppKit/AppKit.h>

NSString *TitleString=@"title";
NSString *GetBlockString=@"getBlock";
NSString *SetBlockString=@"setBlock";

@implementation JGArrayTableView

//mappingsForIdentifiers:{'title','getBlock','setBlock'} //arrays:{{'Pilot','Wohnhaft'},{'#name',#address},{nil,#address:}}

+ (NSMutableArray *)arrayOfDictionariesForKeys:(NSArray *)keys valueArrays:(NSArray *)valueArrays;
{
  NSMutableArray *a=[NSMutableArray array];
  id nilObj=[NSNull null];
  int idx=-1;
  BOOL cont=YES; 
  NSParameterAssert([keys count]==[valueArrays count]);
  while (cont) {
    NSMutableDictionary *d=[NSMutableDictionary dictionary];
    NSEnumerator *vE=[valueArrays objectEnumerator];
    NSEnumerator *kE=[keys objectEnumerator];
    id key;
    idx++;
    cont=NO;
    while (key=[kE nextObject]) {
      NSArray *valueArray=[vE nextObject];
      if (idx<[valueArray count]) {
        id obj=[valueArray objectAtIndex:idx];
        cont=YES;
        if (obj && (obj!=nilObj))
          [d setObject:obj forKey:key];
      }
    }
    if (cont)
      [a addObject:d];
  }
  return a;
}

+ (NSDictionary *)mappingsForIdentifiers:(NSArray *)theIdentifiers titles:(NSArray *)titles getBlocks:(NSArray *)getBlocks setBlocks:(NSArray *)setBlocks;
{
  NSMutableArray *valueArrays=[NSMutableArray array];
  NSMutableArray *keyArray=[NSMutableArray array];
  NSArray *values;
  if (titles) {
    [keyArray addObject:TitleString];
    [valueArrays addObject:titles];
  }
  if (getBlocks) {
      [keyArray addObject:GetBlockString];
      [valueArrays addObject:getBlocks];
  }
  if (setBlocks) {
      [keyArray addObject:SetBlockString];
      [valueArrays addObject:setBlocks];
  }  
  values=[self arrayOfDictionariesForKeys:keyArray valueArrays:valueArrays];
  if([theIdentifiers count]==[values count])
    return [NSDictionary dictionaryWithObjects:values forKeys:theIdentifiers];
  else
    return nil;
}

+ (JGArrayTableView *)arrayTableViewWithArray:(NSArray*)modelArray identifiers:(NSArray *)theIdentifiers  titles:(NSArray *)titles getBlocks:(NSArray *)getBlocks setBlocks:(NSArray *)setBlocks;
{
  id mappingsValue=[self mappingsForIdentifiers:theIdentifiers titles:titles getBlocks:getBlocks setBlocks:setBlocks];
  if (mappingsValue)
    return [self arrayTableViewWithArray:modelArray identifiers:theIdentifiers mappings:mappingsValue];
  else
    return nil;
}

+ (JGArrayTableView *)arrayTableViewWithArray:(NSArray*)modelArray identifiers:(NSArray *)theIdentifiers mappings:(NSDictionary *)mappingsValue;
{
  JGArrayTableView *inst= [[self alloc] init];
  [inst setArray:modelArray identifiers:theIdentifiers mappings:mappingsValue];

  [NSBundle loadNibNamed:@"ArrayTableView.nib" owner:inst];
  [inst setupTableViewAsWindowDelegate:YES];
  return [inst autorelease];
}

- (JGArrayTableView *)init;
{
  if (self = [super init])
  {
    model = [[NSArray alloc] init];
    identifiers=[[NSArray alloc] init];
    mappings=nil;
    return self;
  }
  return nil;
}

-(void)dealloc
{
  //  NSLog(@"JGArrayTableView dealloc");
  [model release];
  [identifiers release];
  [mappings release];
  [super dealloc];
}


- (void)setArray:(NSArray*)modelArray identifiers:(NSArray *)theIdentifiers mappings:(NSDictionary *)mappingsValue;
{
  [modelArray retain];
  [theIdentifiers retain];
  [mappingsValue retain];
  [model release];
  [identifiers release];
  [mappings release];
  model = modelArray;
  identifiers=theIdentifiers;  
  mappings=mappingsValue;
  if (tableView)
    [self setupTableViewAsWindowDelegate:NO];
}

- (void)setupTableViewAsWindowDelegate:(BOOL)isWindowDelegate;
{
  int i, nb;

  if (isWindowDelegate) {
    [self retain]; // we must stay alive while our window exist cause we are its delegate (and delegate produces a weak reference).

    [[tableView window] setMenu:nil];
    [[tableView window] setDelegate:self];    
  }

  while([[tableView tableColumns] count] > 0)
    [tableView removeTableColumn:[[tableView tableColumns] objectAtIndex:0]];

  for (i = 0, nb = [identifiers count]; i < nb; i++) { 
    id identifier=[identifiers objectAtIndex:i];
    NSDictionary *mapping=[mappings objectForKey:identifier];
    Block *getBlock=[mapping objectForKey:GetBlockString];
    Block *setBlock=[mapping objectForKey:SetBlockString];
    NSString *title=[mapping objectForKey:TitleString];
    if (getBlock) {
      NSTableColumn *column = [[[NSTableColumn alloc] initWithIdentifier:identifier] autorelease];
      [[column headerCell] setStringValue:
        (title? title: [getBlock printString]) ];
      [column setEditable:(setBlock!=nil)];
      [tableView addTableColumn:column];
    }
  }
  [tableView tile];  
}

- (NSTableView *)tableView;
{
  return tableView;
}

//////////////////// NSTableView callbacks

- (BOOL)classifyAsMetaIdentifier:(id)identifier;
{
  if ([identifier isKindOfClass:[NSString class]] && [identifier hasPrefix:@"Meta"])
    return YES;
  else
    return NO;
}
- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex 
{
  id identifier=[tableColumn identifier];
  NSDictionary *mapping=[mappings objectForKey:identifier];
  Block *getBlock=[mapping objectForKey:GetBlockString];
  if ([self classifyAsMetaIdentifier:identifier])
    return [getBlock value:model value:[Number numberWithDouble:(double)rowIndex]];
  else
    return [getBlock value:[model objectAtIndex:rowIndex]];
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(int)rowIndex;
{
  id identifier=[tableColumn identifier];
  NSDictionary *mapping=[mappings objectForKey:identifier];
  Block *setBlock=[mapping objectForKey:SetBlockString];
  if ([self classifyAsMetaIdentifier:identifier])
    [setBlock value:model value:[Number numberWithDouble:(double)rowIndex] value:object];
  else   
    [setBlock value:[model objectAtIndex:rowIndex] value:object];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
  return [model count];
}

/////////////////// Window delegate callbacks

- (void)windowWillClose:(NSNotification *)aNotification
{
  // is not called, if it is not the delegate. see -setupTableViewAsWindowDelegate:
  [self autorelease];
} 

// jg test
- (BOOL)tableView:(NSTableView *)tv writeRows:(NSArray*)rows toPasteboard:(NSPasteboard*)pboard;
{
  static int doNr=2;
  NSString *type=nil;
  if (doNr==1) 
    type=NSTabularTextPboardType;
  else if (doNr==2)
    type=NSStringPboardType;
  if (type) {
    [pboard declareTypes:[NSArray arrayWithObject:type] owner:nil];
    return [pboard setString:@"11\t12\n21\t22\n" forType:type];    
  } else
    return NO;
}
- (void)copy:(id)sender;
{
  NSPasteboard *pboard=[NSPasteboard generalPasteboard];
  [self tableView:nil writeRows:nil toPasteboard:pboard];

}
@end

#ifdef USE_SD_TABLE_VIEW
@implementation JGArrayTableView (SDTableViewDelegate)
- (unsigned int)dragReorderingMask:(int)forColumn;
{
    return NSShiftKeyMask;
}
// Delegate called after the reordering of cells, you must reorder your data.
// Returning YES will cause the table to be reloaded.
- (BOOL)tableView:(NSTableView *)tv didDepositRow:(int)rowToMove at:(int)newPosition;
{
  BOOL smaller=(rowToMove<=newPosition);
  if ([model isKindOfClass:[NSMutableArray class]]) {
    id obj=[model objectAtIndex:rowToMove];
    if (newPosition==[model count]) {
      [(NSMutableArray *)model addObject:obj];
    } else {
      [(NSMutableArray *)model insertObject:obj atIndex:newPosition];
    } 
    if (smaller)
      [(NSMutableArray *)model removeObjectAtIndex:rowToMove];
    else
      [(NSMutableArray *)model removeObjectAtIndex:rowToMove+1];
  }
  return YES;
}
// This gives you a chance to decline to drop particular rows on other particular
// row. Return YES if you don't care
- (BOOL) tableView:(/*SDTableView */NSTableView *)tableView draggingRow:(int)draggedRow overRow:(int) targetRow;
{
    return [model isKindOfClass:[NSMutableArray class]];
}
@end
#endif

#else
//--------------------------------- Non AppKit version --------------------------------

@implementation ArrayTableView

+ (ArrayTableView *)arrayTableViewWithArray:(Array*)modelArray blocks:(Array *)blocks
{
  return [[[self alloc] initWithArray:modelArray blocks:blocks] autorelease];
}

- (ArrayTableView *)initWithArray:(Array*)modelArray blocks:(Array *)blocks;
{
  return (self = [super init]);
}

@end

#endif
