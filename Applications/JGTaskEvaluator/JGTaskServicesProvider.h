//  JGTaskServicesProvider.h Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

@class NSPasteboard;

@interface JGTaskServicesProvider : NSObject 
{
  IBOutlet NSWindow *window;
  IBOutlet NSTextView *inputTextView; 
  IBOutlet NSTextView *outputTextView;
  IBOutlet NSComboBox *commandComboBox; // absolute path

  IBOutlet NSButton *echoServicesAndEventsInputSwitch;
  IBOutlet NSButton *echoServicesAndEventsOutputSwitch;
  IBOutlet NSButton *useCommandInInputCommentSwitch;
}
+ (id)globalServicesProvider;
- (id)init;
- (void)awakeFromNib;
// convenience for registering distributed objects and Services
- (void)registerExports;
// distributed objects
- (void)registerServerConnection:(NSString *)connectionName;
- (NSString *)outputOfProgramWithInput:(NSString *)inputString;
- (NSString *)execute:(NSString *)inputString; // also used by JGEvalCommand Semantic changed from FScript class
- (IBAction)executeInputTextView:(id)sender;

// services
- (void)registerServicesProvider;
- (void)putCommand:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;
- (void)execute:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;
@end
