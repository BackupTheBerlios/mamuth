//  JGTask.h Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import <Foundation/Foundation.h>


@interface JGTask : NSObject {
}
+ (void)setOutputTextView:(id)tv; // showing the progress of output

+ (void)setInputEncoding:(NSStringEncoding)enc;
+ (void)setOutputEncoding:(NSStringEncoding)enc;
+ (void)setReportErrorOnNotZero:(BOOL)yn;
+ (void)setMaxInterval:(NSTimeInterval)interv;

+ (NSString *)outputOfProgram:(NSString *)program;
+ (NSString *)outputOfProgram:(NSString *)program withArguments:(NSArray *)args;
+ (NSString *)outputOfProgram:(NSString *)program withInput:(NSString *)inputString;
+ (NSString *)outputOfProgram:(NSString *)program withArguments:(NSArray *)args withInput:(NSString *)inputString;
+ (NSString *)outputOfProgram:(NSString *)program withArguments:(NSArray *)args withInput:(NSString *)inputString inputEncoding:(NSStringEncoding)inputEncoding outputEncoding:(NSStringEncoding)outputEncoding;
@end

/* Examples:
JGTask outputOfProgram:'/tmp/x'

JGTask outputOfProgram:'/bin/bash' withInput:'ls
echo done
'
(send-eval "JGTask outputOfProgram:'/bin/bash' withInput:'ls
echo done
' "fs")

*/
