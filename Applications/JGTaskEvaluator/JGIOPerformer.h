//  JGIOPerformer.h Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import <Foundation/Foundation.h>


@interface JGIOPerformer : NSObject 
{
  SEL clientSelector;
  NSFileHandle *input,*output;
  NSString *inputFromCommandLine;  
  NSString *errorFormatter;
}

// valid clientSelectors
- (void)all;
- (void)lineByLine;
- (void)lineByLineWithNewline; // good for interactive mode
- (void)direct;

// helpers
- (void)lineByLineWithTerminator:(NSString *)terminator;

- (void)writeOutputString:(NSString *)outputString;
- (void)writeOutputStringForInputString:(NSString *)inputString;
- (void)closeStreams;
- (void)error:(NSString *)message;

// could use some checking, if connection can be established. Probably overridden in subclasses
- (void)perform; // calls [self clientSelector]

// abstract methods (must be implemented in subclasses)
- (NSString *)outputStringForInputString:(NSString *)inputStr; // abstract
@end
