//  FSKVBrowser.h Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import <Cocoa/Cocoa.h>

#define COMPILE_WITH_FSCRIPT

#ifndef COMPILE_WITH_FSCRIPT
#define FSKVBROWSER_INTERPRETER_TYPE id
// to compile without errors
@protocol FSKVWorkspaceInterpreter
- (NSArray *)identifiers;
- (id)   objectForIdentifier:(NSString *)identifier found:(BOOL *)found;
- (void) setObject:(id)object forIdentifier:(NSString *)identifier;
@end
#else
#define FSKVBROWSER_INTERPRETER_TYPE FSInterpreter *
#import "System.h"
#import "Array.h"
#import "FSInterpreter.h"
@interface System (KVBrowserAddition)
- (void)browseKV;
- (void)browseKV:(id)anObject;
@end
#endif

@protocol FSKVBrowserObjectInspect
- (void) inspect;
@end

@interface FSKVBrowser : NSObject
{
  id browserBase;

  IBOutlet NSWindow *window;
  IBOutlet NSBrowser *relationshipBrowser;
  IBOutlet NSTableView *attributeTableView;
  int validColumn;

  FSKVBROWSER_INTERPRETER_TYPE interpreter;
  BOOL isBrowsingWorkspace;

    IBOutlet NSButton *confirmSwitch;
    IBOutlet NSTextField *newValueTextField;

    // two modes of displaying descriptionView with window:
    // within splitView or within Drawer.
    BOOL useDrawer; 
    IBOutlet NSSplitView *splitView;
    IBOutlet NSView *descriptionView; // contains descriptionTextView
    IBOutlet NSTextView *descriptionTextView;
    IBOutlet NSDrawer *descriptionDrawer;

    IBOutlet NSSlider *timeSlider;
    IBOutlet NSTextField *timeSliderTextField;
    NSTimer *timer;
    NSTimeInterval timeInterval;
}
- (void)setTitle;
// delegate methods
- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column;
- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column;
- (NSString *)browser:(NSBrowser *)sender titleOfColumn:(int)column;

- (IBAction)browserSetColumnNumberAction:(id)sender;
- (IBAction)inspectObjectAction:(id)sender;
- (IBAction)nameObjectAction:(id)sender;
- (IBAction)objectSetValueForKeyAction:(id)sender;
- (IBAction)workspaceAction:(id)sender;
- (IBAction)updateAction:(id)sender;
- (IBAction)setIncludeAttributesAction:(id)sender;
- (IBAction)showMethodBrowserAction:(id)sender;
- (IBAction)newBrowserAction:(id)sender;

- (void)setDescriptionIfViewIsVisable;
- (IBAction)descriptionAction:(id)sender;
- (IBAction)toggleDescriptionIsInDrawer:(id)sender;

- (id)browserParentOfSelectedObject;
- (NSString *)browserSelectedKey;
- (id)browserSelectedObject;
- (NSString *)tableSelectedKey;
- (id)tableSelectedObject;
- (id)parentOfSelectedObject;
- (NSString *)selectedKey;
- (id)selectedObject;

+ (FSKVBrowser *)kvBrowserWithRootObject:(id)object interpreter:(FSKVBROWSER_INTERPRETER_TYPE)interpreter;
- (id)initWithRootObject:(id)object interpreter:(FSKVBROWSER_INTERPRETER_TYPE)interpreter;
- (void)setInterpreter:(FSKVBROWSER_INTERPRETER_TYPE)theInterpreter;
- (void)setRootObject:(id)theRootObject;
- (void) browseWorkspace;

- (void)restartTimerWithTimeInterval;
- (IBAction)timerSliderAction:(id)sender;
- (void)timerAction:(id)timer;
@end
