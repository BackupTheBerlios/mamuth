//  FSLisp2PropertyList.m Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import "FSLisp2PropertyList.h"
#include "sexp.h"


@implementation FSLisp2PropertyList
+ (id)globalConverter;
{
  static id converter=nil;
  if (!converter)
    converter=[[self alloc] init];
  return converter;
}
+ (id)plistForLispString:(NSString *)lispString;
{
  return [[self globalConverter] plistForLispString:lispString];
}
+ (id)plistForCyclicLispString:(NSString *)lispString;
{
  id plist;
  id converter=[self globalConverter];
  BOOL prev=[converter decodeCyclicMacro];
  [converter setDecodeCyclicMacro:YES];
  plist=[converter plistForLispString:lispString];
  [converter setDecodeCyclicMacro:prev];
  return plist;
}

- (id)init;
{
  [super init];
  decodeCyclicMacro=NO;
  cyclicStructs=[[NSMutableDictionary alloc] init];
  return self;
}
- (void)dealloc;
{
  [cyclicStructs release];
  [super dealloc];
}

- (void)setDecodeCyclicMacro:(BOOL)newVal;
{
  decodeCyclicMacro=newVal;
}
- (BOOL)decodeCyclicMacro;
{
  return decodeCyclicMacro;
}

- (id)plistFromSExp:(sexp_t *)sx;
{
  NSMutableArray *a=[NSMutableArray array];
  id item;
  sexp_t *next;
  BOOL isMacroDef=NO;

  NSString *key=nil;
  if (sx) 
    next=sx->next;
  while (sx) {
    if (sx->ty==SEXP_VALUE) {
      char *str=sx->val;
      if (decodeCyclicMacro && (sx->aty==SEXP_BASIC) && (str[0]=='#')) {
        int len=strlen(str);
        if (key) {
          fprintf(stderr,"Wrong Macro after Macro.\n");
          return nil;
        }
        if (len>=3) {
          key=[NSString stringWithCString:str+1 length:len-2]; // from #1= skip first # and last =
          switch (str[len-1]) {
            case '=': isMacroDef=YES; break; 
            case '#': item=[cyclicStructs objectForKey:key];
              if (!item) {
                fprintf(stderr,"Wrong Macro (not yet defined): %s\n",str);
                return nil;
              }
              key=nil; break;
            default: fprintf(stderr,"Wrong Macro does not end in '#' or '=': %s.\n",str); return nil;
          }
        } else {
          fprintf(stderr,"Wrong Macro: %s\n",str);
          return nil;
        }          
      } else {
        item=[NSString stringWithCString:str];
      }
    } else if (sx->ty == SEXP_LIST) {
      item=[self plistFromSExp:sx->list];
    } else {
      fprintf(stderr,"No sexp.  bad bad bad.\n");
      return nil;
    }
    if (decodeCyclicMacro) {
      if (!isMacroDef) {
        [a addObject:item];
        if (key) {
          [cyclicStructs setObject:item forKey:key];
          key=nil;
        }
      } else {
        isMacroDef=NO;        
      }
    } else {
      [a addObject:item];
    }
      
    if (next) {
      sx=next;
      next=sx->next;
    } else {
      sx=NULL;
    }
  }
  return a;
}

- (id)plistForLispString:(NSString *)lispString;
{
  id plist=nil;
  sexp_t *sx;

  if (decodeCyclicMacro) {
    [cyclicStructs removeAllObjects];
  }
  
  sx = parse_sexp([lispString cString],[lispString length]); // is qualifier ok?
  if (sx)
    plist=[self plistFromSExp:sx->list];
  destroy_sexp(sx);
  return plist;
}

/*
 - (NSString *)plistStringForLispString:(NSString *)lispString;
{
  BOOL quoted=NO;
  NSMutableString *result=[NSMutableString string];
  NSString *str;
  NSScanner *scanner=[NSScanner scannerWithString:lispString];
  NSCharacterSet *white=[NSCharacterSet whitespaceAndNewlineCharacterSet];
  NSCharacterSet *escape=[NSCharacterSet characterSetWithCharactersInString:@"\\"];
  NSCharacterSet *quote=[NSCharacterSet characterSetWithCharactersInString:@"\""];
  NSCharacterSet *quoteOrEscape=[NSCharacterSet characterSetWithCharactersInString:@"\"\\"];
  NSMutableCharacterSet *whiteOrQuote=[white mutableCopy];
  [whiteOrQuote addCharactersInString:@"\""];

  while (![s isAtEnd]) {
    [scanner scanUpToCharactersFromSet:white intoString:&str];
    ...
  }
  // hmm. better implement this in LISP. Because it is easier to produce text than to scan,
  // and because it might be useful to use that routine from lisp for producing property lists for other Programs also.
}
- (NSArray *)arrayForLispString:(NSString *)lispString;
{
}
*/
@end
