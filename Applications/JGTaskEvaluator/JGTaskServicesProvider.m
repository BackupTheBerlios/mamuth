//  JGTaskServicesProvider.m Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import <AppKit/AppKit.h>
#import "JGTaskServicesProvider.h"
#import "JGTask.h"

@implementation JGTaskServicesProvider

static id globalServicesProvider;

+ (id)globalServicesProvider;
{
  return globalServicesProvider;
}
- (id)init;
{
  [super init];
  if (!globalServicesProvider) {
    globalServicesProvider=[self retain];
    [self registerExports];    
  }
  return self;
}
- (void)awakeFromNib;
{
  NSArray *values=[[NSUserDefaults standardUserDefaults] stringArrayForKey:@"ComboBoxValues"];
  if (!values) {
    values=[NSArray arrayWithObjects:
      @"/usr/bin/osascript",
      @"/bin/bash",
      @"/bin/sh",
      @"/bin/csh",
      @"/bin/cat",
      nil];
    [[NSUserDefaults standardUserDefaults] setObject:values forKey:@"ComboBoxValues"];
  }

  [commandComboBox addItemsWithObjectValues:values];
  [commandComboBox selectItemAtIndex:0];
//  [JGTask setOutputTextView:outputTextView];
}
- (void)registerExports;
{
  [self registerServicesProvider];
//  [self registerServerConnection:@"JGTaskEvaluator"];
}
- (void)registerServerConnection:(NSString *)connectionName;
{
  NSConnection *theConnection = [NSConnection defaultConnection]; // in current Thread
  [theConnection setRootObject:self];
  if ([theConnection registerName:connectionName] == NO) {
    NSLog(@"Handle error.");
  }
}

- (BOOL)validProgramName:(NSString *)path;
{
  return [[NSFileManager defaultManager] isExecutableFileAtPath:path];
}

- (NSString *)outputOfProgramWithInput:(NSString *)inputString;
{// always returns a string
  NSString *command=nil;
  if (!inputString)
    return @"Error: input must not be nil!";
  if ([useCommandInInputCommentSwitch state]) {
    // get the first line
    NSString *start=[inputString substringToIndex:2];
    if ([start isEqualToString:@"#!"]) { // if first line is special
      unsigned startIndex,lineEndIndex,contentsEndIndex;
      [inputString getLineStart:&startIndex end:&lineEndIndex contentsEnd:&contentsEndIndex
                       forRange:NSMakeRange(0,1)];
      command=[inputString substringWithRange:NSMakeRange(2,contentsEndIndex-2)];
      inputString=[inputString substringFromIndex:lineEndIndex];
    }
  }
  if (command==nil)
    command=[commandComboBox stringValue];
  if ([command length]==0)
    return inputString; // perform the identity
  else {
    NSString *msg;
    if (![self validProgramName:command]) {
      msg=[NSString stringWithFormat:@"\"%@\" is not a valid executable",command];
      NSBeginAlertSheet(@"Error", @"OK", nil, nil, window, nil, NULL, NULL, NULL, msg);
      return msg;
    } else {
      NSString *result;
      static BOOL usefilein=YES; // jg set input field as filename or use switch
      if (usefilein) {
        NSString *filename=@"/tmp/JGTaskEvaluatorInput";
        [inputString writeToFile:filename atomically:YES];
        result=[JGTask outputOfProgram:command withArguments:[NSArray arrayWithObjects:filename,nil]];
      } else 
        result=[JGTask outputOfProgram:command withInput:inputString];
      if (!result) {
        msg=[NSString stringWithFormat:@"Error: JGTask outputOfProgram:@\"%@\" withInput:... returned nil",command];
        NSBeginAlertSheet(@"Error", @"OK", nil, nil, window, nil, NULL, NULL, NULL, msg);
        return msg;
      }
      else {
        return result;              
      }
    }    
  }
}

- (NSString *)execute:(NSString *)inputString;
{
  NSString *result;
  if ([echoServicesAndEventsInputSwitch state])
    [inputTextView setString:inputString];
  result=[self outputOfProgramWithInput:inputString];
  if ([echoServicesAndEventsOutputSwitch state])
    [outputTextView setString:result];
  return result;
}

- (IBAction)executeInputTextView:(id)sender;
{
  NSString *inputString=[inputTextView string];
  NSString *result=[self outputOfProgramWithInput:inputString];
  [outputTextView setString:result];
}

// services section
- (void)registerServicesProvider;
{
  NSApplication *app=[NSApplication sharedApplication];
  [app setServicesProvider:self];
}

- (void)putCommand:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;
{
  NSString *pboardString=[pboard stringForType:NSStringPboardType];
  if (pboardString)
    [inputTextView setString:pboardString];
}

- (void)execute:(NSPasteboard *)pboard userData:(NSString *)userData error:(NSString **)error;
/* check userData for parserMode */
{
//    NSArray *types=[pboard types];
  NSString *command=[pboard stringForType:NSStringPboardType];
  NSString *ret=[self execute:command];
  if (ret) {
    NSArray *newTypes=[NSArray arrayWithObject:NSStringPboardType];
    [pboard declareTypes:newTypes owner:nil];
    [pboard setString:ret forType:NSStringPboardType];
  } else {
    *error=[@"Error with command: " stringByAppendingString:command];
  }
}
@end
