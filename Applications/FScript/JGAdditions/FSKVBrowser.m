//  FSKVBrowser.m Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import "FSKVBrowser.h"
#import "FSKVBrowserBase.h"

#define COMPILE_WITH_FSCRIPT

#ifdef COMPILE_WITH_FSCRIPT
#import "System.h"
#import "Compiler.h"
#import "FSInterpreter.h"
#import "ArrayRepId.h"
#import "FScriptFunctions.h"
#import "BigBrowser.h"
#import "FSVoid.h"
#import "BigBrowserView.h"
#import "FSGenericObjectInspector.h"
#endif

#ifdef USE_FSKV_CODING
#import "FSKVCoding.h"
#endif

#include <math.h>

#define BUILD_WITH_APPKIT

@implementation FSKVBrowser
+ (BOOL)loadNibNamed:(NSString *)nibName owner:(id)owner;
{
  id bundle=[NSBundle bundleForClass:self];
  id table=[NSDictionary dictionaryWithObject:owner forKey:@"NSOwner"];
  return [bundle loadNibFile:nibName externalNameTable:table withZone:[self zone]];
}

+(FSKVBrowser *)kvBrowserWithRootObject:(id)object interpreter:(FSKVBROWSER_INTERPRETER_TYPE)newInterpreter
{
  return [[self alloc] initWithRootObject:object interpreter:newInterpreter]; // NO autorelease. The window will be released when closed (in a sense, the window server retains the window).
}
 
-(id)initWithRootObject:(id)object interpreter:(FSKVBROWSER_INTERPRETER_TYPE)newInterpreter;
{
  [super init];
  validColumn=-1;
  useDrawer=NO;
  timer=nil;
  timeInterval=0.0;
  [FSKVBrowser loadNibNamed:@"FSKVBrowser.nib" owner:self];
  [relationshipBrowser setTakesTitleFromPreviousColumn:NO];
  isBrowsingWorkspace=(object==nil)?YES:NO;
  browserBase=[[FSKVBrowserBase alloc] init];
  [browserBase setRootObject:object];
  [browserBase setRelationshipBrowser:relationshipBrowser];
  [self setInterpreter:newInterpreter];
  [window makeKeyAndOrderFront:nil];
  [self setTitle];
//  [attributeTableView reloadData];
  return self;
}

- (void)setTitle;
{
  NSString *title;
  if (isBrowsingWorkspace) {
      title=@"Key Value Browser for Workspace Objects";
  } else {
    title=[NSString stringWithFormat:@"Key Value Browser for Address: %p",[browserBase rootObject]];
    // modified by pm for f-script version 1.2.2 : using %p for printing pointer value. 
  }
  [window setTitle:title];
}

- (void)dealloc;
{
    [browserBase release];
    [timer release];
    [super dealloc];
}
-(void)setInterpreter:(FSKVBROWSER_INTERPRETER_TYPE)theInterpreter
{
  [theInterpreter retain];
  [interpreter release];
  interpreter = theInterpreter;
}

-(void)setRootObject:(id)theRootObject 
{
  [browserBase setRootObject:theRootObject];
  isBrowsingWorkspace = NO;
  [relationshipBrowser loadColumnZero];
  [relationshipBrowser displayColumn:0]; // may be unnecessary
} 

- (void) browseWorkspace
{
  isBrowsingWorkspace = YES;
  [browserBase setRootObject:nil];
  [relationshipBrowser loadColumnZero];
  [relationshipBrowser displayColumn:0]; // may be unnecessary
  [self setTitle];
}

// delegate methods
- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column;
{
  if ((column==0) && isBrowsingWorkspace)
    return [[interpreter identifiers] count];
  return [browserBase browser:sender numberOfRowsInColumn:column];
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column;
{
  id representedObject;
  id theString;
  if ((column==0) && isBrowsingWorkspace) {
    BOOL found;
    theString=[[interpreter identifiers] objectAtIndex:row];
    [cell setStringValue:theString];
    representedObject=[interpreter objectForIdentifier:theString found:&found];
    [cell setRepresentedObject:representedObject];
    [cell setLeaf:(representedObject==nil)];
    [cell setEnabled:YES]; 
  } else {    
    [browserBase browser:sender willDisplayCell:cell atRow:row column:column];
  }
  if (validColumn<column) validColumn=column;
}

- (NSString *)browser:(NSBrowser *)sender titleOfColumn:(int)column;
{
  if ((column==0) && isBrowsingWorkspace) {
    return @"Workspace";
  } else {
    return [browserBase browser:sender titleOfColumn:column];
  }
}
- (BOOL)browser:(NSBrowser *)sender isColumnValid:(int)column;
{
  static int offset=0;
  if (column<=validColumn+offset) 
    return YES;
  else
    return NO;
//  return [browserBase browser:sender isColumnValid:column];
}

- (void)tableKeyP:(NSString **)keyP valueP:(id*)valueP forRow:(int)row;
{
    id browserSelectedObject=[self browserSelectedObject];
    NSArray *attributeKeys=[browserSelectedObject attributeKeys];
    NSString *key=[attributeKeys objectAtIndex:row];
    id value;
#ifdef USE_FSKV_CODING
    if ([browserSelectedObject fskvAllowsToGetValueForKey:key])
        value=[browserSelectedObject fskvValueForKey:key];
    else
        value=[FSKVBrowserBase invalidValue];
#else
    value=[browserSelectedObject valueForKey:key];
#endif
    *keyP=key;
    *valueP=value;
}

// tableView delegate
- (id)tableView:(NSTableView *)aTableView
    objectValueForTableColumn:(NSTableColumn *)aTableColumn
    row:(int)rowIndex
{
  NSString *identifier=[aTableColumn identifier];
  NSString *key;
  id value;
  [self tableKeyP:&key valueP:&value forRow:rowIndex];
  if ([identifier isEqualToString:@"attributeKey"]) 
    return key;
  if ([identifier isEqualToString:@"attributeValue"]) {
    if (value)
      return value;
    else 
      return @"nil";
  }
  return @"error";
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
  return [[[self browserSelectedObject] attributeKeys] count];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    [self setDescriptionIfViewIsVisable];
}

// relationshipBrowser actions

- (void)browserReloadColumns;//:(int)col;
{
  [attributeTableView deselectAll:nil];
  [browserBase cleanCache];
  [relationshipBrowser validateVisibleColumns];
  [attributeTableView reloadData];
//  [relationshipBrowser reloadColumn:col];
//  [relationshipBrowser displayColumn:col];
  [self setDescriptionIfViewIsVisable];
}
// reload table view on new browser selection
- (IBAction)browserSelectAction:(id)sender;
{
  int c=[sender selectedColumn];
  validColumn=c;
  [self browserReloadColumns];//:c+1];
}

- (IBAction)browserSetColumnNumberAction:(id)sender
{
  // use slider value exponentially to size the column
  NSSlider *s=sender;
  double d=[s doubleValue]; // between -1 and +1
  double expFactor=2.3; // approx: e^(-2.3)=0.1, e^2.3=10
  double width=160.0*exp(expFactor*d); 
  [relationshipBrowser setMinColumnWidth:width];
  [relationshipBrowser setMaxVisibleColumns:10];
}

- (IBAction)inspectObjectAction:(id)sender // modified by pm for f-script version 1.2.2
{
  id selectedObject = [self selectedObject];

  NS_DURING
    if ([selectedObject respondsToSelector:@selector(inspect)])
      [selectedObject inspect];
    else
    {
#ifdef COMPILE_WITH_FSCRIPT
      [FSGenericObjectInspector genericObjectInspectorWithObject:selectedObject];
#endif
    }       
  NS_HANDLER
    // An exception may occur if the selectedObject is invalid (e.g. an invalid proxy)
#ifdef COMPILE_WITH_FSCRIPT
    [FSGenericObjectInspector genericObjectInspectorWithObject:selectedObject];
#endif    
  NS_ENDHANDLER  
}

- (IBAction)nameObjectAction:(id)sender
{ // copied and modified from BigBrowserView 'stopNameSheet:'
  
  if (([[newValueTextField stringValue] length] != 0) &&
       [Compiler isValidIndentifier:[newValueTextField stringValue]])
  {
    [interpreter setObject:[self selectedObject] forIdentifier:[newValueTextField stringValue]];
  }
  else
  {
    // don't close the sheet
    NSRunAlertPanel(@"Malformed Name", @"Sorry, an F-Script identifier must start with an alphabetic character or underscore (i.e. \"_\") and must only contains alphanumeric characters and underscores", @"Ok", nil, nil,nil);
  }  
}

static BOOL isEmpty2(NSString *str)
{
    int i = 0;
    int strlen =[str length];
    NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    while (i < strlen && [set characterIsMember:[str characterAtIndex:i]])
        i++;
    return (i == strlen);
}  

- (id)interpreterValueForString:(NSString *)aString isOK:(BOOL *)isOK;
{// highly depends on interpreter and FScript behaviour
#ifdef COMPILE_WITH_FSCRIPT
    FSInterpreterResult *execResult;
    id result=nil;
    execResult = [interpreter execute:aString];
    *isOK=NO;

    if ([execResult isOk]) {
        result = [execResult result];

        if ([result isKindOfClass:[FSVoid class]])
            NSRunAlertPanel(@"Void Value", @"The expression has no return value, so the value is not set. But side effects may have occured!", @"Ok", nil, nil,nil);
        else 
            *isOK=YES;
    } else if ([execResult isSyntaxError]) {
        NSRunAlertPanel(@"Syntax Error", @"A Syntax error has occured. Check the Textfield for nonvalid FScript-Expressions, e.g. enclose strings in '' and check if the referenced variables exist!", @"Ok", nil, nil,nil);
    } else { // [execresult isExecutionError]
        NSRunAlertPanel(@"Execution Error", @"An execution error has occured. Check the Textfield for nonvalid FScript-Expressions, e.g. enclose strings in '' and check if the referenced variables exist!", @"Ok", nil, nil,nil);
    }
    return result;
#else
    // reasonable value without FScript interaction
    *isOK=YES;
    return aString; 
#endif // COMPILE_WITH_FSCRIPT
}

- (IBAction)objectSetValueForKeyAction:(id)sender
{
    id parent=[self parentOfSelectedObject];
    id key=[self selectedKey];
    NSString *aString=[newValueTextField stringValue];
    id result;
    BOOL isOK;

    if (!parent || !key) {
        NSRunAlertPanel(@"Selection missing", @"To set a value, select a key first!", @"Ok", nil, nil,nil);
        return;
    }

    if (isEmpty2(aString)) return;

#ifdef USE_FSKV_CODING
    if (![parent fskvAllowsToTakeValueForKey:key]) {
        NSRunAlertPanel(@"Parent restrictions", @"You may not set values for the selected property", @"Ok", nil, nil,nil);
        return;
    }
#endif
    
    result=[self interpreterValueForString:aString isOK:&isOK];

    if (isOK) {
        static BOOL works=NO;
#ifdef USE_FSKV_CODING
        if (![parent fskvAllowsToTakeValue:result forKey:key]) {
            NSRunAlertPanel(@"Parent restrictions", @"You may not set this value for the selected property", @"Ok", nil, nil,nil);
            return;
        } else {
            [parent fskvTakeValue:result forKey:key];
        }      
#else
        if ([parent isKindOfClass:[NSArray class]]) {
            int idx=[key intValue];
            [parent replaceObjectAtIndex:idx withObject:result];
        } else {
            [parent takeValue:result forKey:key];
        }
#endif
        if (works) {
            int col=[relationshipBrowser selectedColumn];
            int row=[relationshipBrowser selectedRowInColumn:col];
            id cell=[relationshipBrowser selectedCell];
            [browserBase browser:relationshipBrowser willDisplayCell:cell atRow:row column:col];
            [self browserSelectAction:nil];
        } else {
            int selectedCol=[relationshipBrowser selectedColumn];
            validColumn=selectedCol-1;
            [self browserReloadColumns];//:selectedCol];
        }
    }
}


- (IBAction)workspaceAction:(id)sender
{
  [self browseWorkspace];
}

- (IBAction)updateAction:(id)sender
{ // this should try to reconstruct the Browser state for the saved path.
    NSString *path;
    static BOOL doIt=YES;
    static BOOL doItBefore=NO;
    static BOOL doSetPath=YES;
    BOOL success;
    validColumn=-2;
    path=[relationshipBrowser path];
    [browserBase cleanCache];
    [relationshipBrowser loadColumnZero];
    if (doItBefore) {
        validColumn=-2;
        [self browserReloadColumns];       
    }
    if (doSetPath)
      success=[relationshipBrowser setPath:path]; // does the reload already.
    if (doIt) {
//        validColumn=-2; // so this would be unappropriately double the update.
        [self browserReloadColumns];       
    }
}

- (BOOL)descriptionViewIsVisable;
{
    BOOL visable;
    if (useDrawer)
        visable=([descriptionDrawer state]==NSDrawerOpenState);
    else
        visable=([[splitView subviews] indexOfObjectIdenticalTo:descriptionView]!=NSNotFound);
    return visable;
}

- (void)showDescriptionView;
/** call descriptionViewIsVisable before! **/
{
    if (useDrawer) {
        [descriptionDrawer open];
    } else {
        [splitView addSubview:descriptionView];
        [splitView adjustSubviews];        
    }
}
- (void)hideDescriptionView;
/** call descriptionViewIsVisable before! **/
{
    if (useDrawer) {
        [descriptionDrawer close];
    } else {
        [descriptionView removeFromSuperview];
        [splitView adjustSubviews];        
    }
}
- (void)setDescriptionIfViewIsVisable;
{
    BOOL visable=[self descriptionViewIsVisable];
    NSString *str;
    if (visable) {
        str=[[self selectedObject] description];
        if (!str) str=[FSKVBrowserBase invalidValue];
        [descriptionTextView setString:str];
    }
}

- (IBAction)descriptionAction:(id)sender
{
   if ([self descriptionViewIsVisable])
       [self hideDescriptionView];
   else {
        [self showDescriptionView];
   }
   [self setDescriptionIfViewIsVisable];
}

- (IBAction)toggleDescriptionIsInDrawer:(id)sender
{
    BOOL visable=[self descriptionViewIsVisable];
    if (visable) {
        [self hideDescriptionView];
    }
    useDrawer=(BOOL)[sender state];
    if (useDrawer)
        [descriptionDrawer setContentView:descriptionView];
    if (visable)
        [self showDescriptionView];
}

- (IBAction)setIncludeAttributesAction:(id)sender;
{
  [browserBase setIncludeAttributes:(BOOL)[sender intValue]];
}
- (IBAction)showMethodBrowserAction:(id)sender;
{
#ifdef COMPILE_WITH_FSCRIPT
    [BigBrowser bigBrowserWithRootObject:[self selectedObject] interpreter:interpreter];
#endif
}
- (IBAction)newBrowserAction:(id)sender;
{
    [FSKVBrowser kvBrowserWithRootObject:[self selectedObject] interpreter:interpreter];
}

///////////////////////////
// browserSelections
-(id) browserParentOfSelectedObject
{
    int selectedColumn = [relationshipBrowser selectedColumn];
    if (selectedColumn==0) {
        return [browserBase rootObject];
    }
    else return [[relationshipBrowser selectedCellInColumn:selectedColumn-1] representedObject];
}

-(id) browserSelectedObject
{
  int selectedColumn = [relationshipBrowser selectedColumn];
  if (selectedColumn>=0)
    return [[relationshipBrowser selectedCellInColumn:selectedColumn] representedObject];
  else
    return [browserBase rootObject];
}

- (NSString *)browserSelectedKey
{
  int selectedColumn = [relationshipBrowser selectedColumn];
  return [[relationshipBrowser selectedCellInColumn:selectedColumn] stringValue];    
}

// table selection
- (NSString *)tableSelectedKey;
{
  int row=[attributeTableView selectedRow];
  NSString *key;
  id value;
  if (row>-1) {
     [self tableKeyP:&key valueP:&value forRow:row];
      return key;
  } else {
      return nil;
  }
}
- (NSString *)tableSelectedObject;
{
    int row=[attributeTableView selectedRow];
    NSString *key;
    id value;
    if (row>-1) {
        [self tableKeyP:&key valueP:&value forRow:row];
        return value;
    } else {
        return nil;
    }
}

// browser and table selection combined
- (NSString *)selectedKey;
{
    int row=[attributeTableView selectedRow];
    if (row>-1)
        return [self tableSelectedKey];
    else
        return [self browserSelectedKey];
}
- (id) selectedObject;
{
    int row=[attributeTableView selectedRow];
    if (row>-1) 
        return [self tableSelectedObject];
    else 
        return [self browserSelectedObject];
}    
- (id)parentOfSelectedObject;
{
    int row=[attributeTableView selectedRow];
    if (row>-1) 
        return [self browserSelectedObject];
    else
        return [self browserParentOfSelectedObject];

}
- (void)restartTimerWithTimeInterval;
{
    if ([timer isValid])
        [timer invalidate]; // this will release the target==self
    [timer release];
    timer=nil;
    if (timeInterval>0.0) {
      int retainCount1,retainCount2;// does timer retain target? This is to check.
      retainCount1=[self retainCount];
      timer=[[NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(timerAction:) userInfo:nil repeats:NO] retain]; // self is retained
      retainCount2=[self retainCount];
      if (retainCount2>retainCount1) { 
          static BOOL dorelease=NO;
//          NSLog(@"browser retaincount increased by timer:%d",retainCount2);
          if (dorelease)
              [self release];
      }
    }
}
- (void)timerSliderAction:(id)sender;
{ // sender is either timeSlider or timeSliderTextField
    timeInterval=[sender doubleValue]; // between 0(never) and 10
    [timeSlider setDoubleValue:timeInterval];
    [timeSliderTextField setDoubleValue:timeInterval];
    [self restartTimerWithTimeInterval];
}
- (void)timerAction:(id)timer;
{
    [self updateAction:nil];
    [self restartTimerWithTimeInterval];
}
- (void)windowWillClose:(NSNotification *)notification;
{
    timeInterval=0.0;
    [self restartTimerWithTimeInterval]; // removes a timer, that retains self
}
@end

#ifdef COMPILE_WITH_FSCRIPT
@protocol FSKVInterpreterProvider
- (FSKVBROWSER_INTERPRETER_TYPE)interpreter; // this is defined in System.m, but not declared, so we do it here.
@end

@implementation BigBrowserView (KVBrowserAddition)
- (void)browseKVAction:(id)sender;
{
  // self does respond to selectedObject!
  id selectedObject = [(id)self selectedObject];

  // ---- PM added ----
  // We test wether the selectedObject object is valid (an invalid proxy will raise when sent -respondsToSelector:)
  NS_DURING
    [selectedObject respondsToSelector:@selector(self)]; 
  NS_HANDLER
    NSBeep();
    return;
  NS_ENDHANDLER   
  //----------
  
  [FSKVBrowser kvBrowserWithRootObject:selectedObject interpreter:interpreter];
}
@end

@implementation System (KVBrowserAddition)
- (void)browseKV
{
#ifdef BUILD_WITH_APPKIT
//--------------------------------- AppKit version --------------------------------
  
  if (![(id<FSKVInterpreterProvider>)sys interpreter]) 
    FSExecError(@"Sorry, can't open the F-Script object browser because the associated FSInterpreter object no more exists");

  [[FSKVBrowser kvBrowserWithRootObject:nil interpreter:[(id<FSKVInterpreterProvider>)sys interpreter]] browseWorkspace];
 
#else
//-------------------------------- Non AppKit version -----------------------------

  FSExecError(@"The F-Script object browser needs AppKit support. You are running a version of F-Script that does not support AppKit. Sorry...");

#endif  

}

- (void)browseKV:(id)anObject
{
#ifdef BUILD_WITH_APPKIT
//--------------------------------- AppKit version --------------------------------

  if (![(id<FSKVInterpreterProvider>)sys interpreter]) 
    FSExecError(@"Sorry, can't open the F-Script object browser because the associated FSInterpreter object no more exists");


  [FSKVBrowser kvBrowserWithRootObject:anObject interpreter:[(id<FSKVInterpreterProvider>)sys interpreter]];
 
#else
//-------------------------------- Non AppKit version -----------------------------

  FSExecError(@"The F-Script object browser needs AppKit support. You are running a version of F-Script that does not support AppKit. Sorry...");

#endif  
}
@end

#endif //COMPILE_WITH_FSCRIPT

