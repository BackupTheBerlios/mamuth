//  FSPropertyList2Lisp.h Copyright (c) 2002 Joerg Garbers.
//  This software is open source. See the license.

#import "FSPropertyList2Lisp.h"

enum plist_type {ERROR=0,TEMP,STRING,ARRAY,DICTIONARY,DATA} ; 

@interface FSPropertyList2Lisp(FSPropertyList2LispPrivate)
+ (void)setDefines;
- (void)appendItem:(NSString *)str;
- (void)let:(enum plist_type)type address:(NSValue *)address definition:(NSString *)definition prePrefix:(NSString *)prePrefix;
@end

@implementation FSPropertyList2Lisp

static id lisp_arraySetElementsRec,lisp_arraySetElements,lisp_arrayWithElements;
static id lispDef_arraySetElementsRec,lispDef_arraySetElements,lispDef_arrayWithElements;

static id lisp_hashTableSetKeyValuesRec,lisp_hashTableSetKeyValues,lisp_hashTableWithKeyValues;
static id lispDef_hashTableSetKeyValuesRec,lispDef_hashTableSetKeyValues,lispDef_hashTableWithKeyValues;

static id lispPrintCircle;
static BOOL useLocalFunctions=YES;

+ (void)initializeLispStrings;
{
  static BOOL done=NO;
  if (done) return;
  done=YES;
  lisp_arraySetElementsRec=[@"array-set-elements-rec" retain];
  lisp_arraySetElements=[@"array-set-elements" retain];
  lisp_arrayWithElements=[@"array-with-elements" retain];
  
  // elems== (((quote k1) v1) ((quote k2) v2) ...)
  lisp_hashTableSetKeyValuesRec=[@"hash-table-set-key-values-rec" retain];
  lisp_hashTableSetKeyValues=[@"hash-table-set-key-values" retain];
  lisp_hashTableWithKeyValues=[@"hash-table-with-key-values" retain];
  
  [self setDefines];
}

+ (void)setUseLocalFunctions:(BOOL)yn;
{
  useLocalFunctions=yn;
}
+ (NSString *)lisp_defines;
{
// include lispPrintCircle
  return [NSString stringWithFormat:@"%@\n(defun %@)\n(defun %@)\n(defun %@)\n(defun %@)\n(defun %@)\n(defun %@)\n",lispPrintCircle,lispDef_arraySetElementsRec,lispDef_arraySetElements,lispDef_arrayWithElements,lispDef_hashTableSetKeyValuesRec,lispDef_hashTableSetKeyValues,lispDef_hashTableWithKeyValues];
}

+ (void)setDefines;
{
  lispDef_arraySetElementsRec=[[NSString alloc] initWithFormat:@"%@ (vect pos elems) (if elems (prog () (setf (svref vect pos) (first elems)) (%@ vect (+ pos 1) (rest elems))))",lisp_arraySetElementsRec,lisp_arraySetElementsRec];
  lispDef_arraySetElements=[[NSString alloc] initWithFormat:@"%@ (vect elems) (%@ vect 0 elems)",lisp_arraySetElements,lisp_arraySetElementsRec];
  lispDef_arrayWithElements=[[NSString alloc] initWithFormat:@"%@ (elems) (let ((a (make-array (length elems)))) (%@ a elems) a)",lisp_arrayWithElements,lisp_arraySetElements];

  lispDef_hashTableSetKeyValuesRec=[[NSString alloc] initWithFormat:@"%@ (ht elems) (if elems (prog () (setf (gethash (first (first elems)) ht) (second (first elems))) (%@ ht (rest elems))))",lisp_hashTableSetKeyValuesRec,lisp_hashTableSetKeyValuesRec];
  lispDef_hashTableSetKeyValues=[[NSString alloc] initWithFormat:@"%@ (ht elems) (%@ ht elems)",lisp_hashTableSetKeyValues,lisp_hashTableSetKeyValuesRec];
  lispDef_hashTableWithKeyValues=[[NSString alloc] initWithFormat:@"%@ (elems) (let ((ht (make-hash-table))) (%@ ht elems) ht)",lisp_hashTableWithKeyValues,lisp_hashTableSetKeyValues];
  
  lispPrintCircle=[@"(setf *print-circle* t)" retain];
}

+ (NSString *)stringFromPropertyList:(id)plist;
{
  FSPropertyList2Lisp *inst=[[[self class] alloc] init];
  [[self class] initializeLispStrings];
  [inst checkRefs:plist];
  return [inst stringFromPropertyList:plist];
}

- (NSString *)stringFromPropertyList:(id)plist;
{  
  NSString *functionLabels,*dataExpression;
  dataExpression=[self dataExpressionForPlist:plist];
  functionLabels=[self labelDefinitions];
  if (useLocalFunctions && [functionLabels length]) 
    return [NSString stringWithFormat:@"(labels (\n%@\n  )\n%@)",functionLabels,dataExpression];
  else 
    return dataExpression;
}

- (NSString *)dataExpressionForPlist:(id)plist;
{
  NSString *def,*cycleDefs,*lets;
  [self declareAddresses];
  def=[self varOrDefinitionForPlist:plist];
  [self setDefineCylce:YES];
  cycleDefs=[self cycleDefinitions];
  lets=[self letDefinitions];
  if ([lets length]==0)
    return def;
  else 
    return [NSString stringWithFormat:@"(let* (\n%@)\n%@%@)",lets,cycleDefs,def];
}

- init;
{
  int i;
  [super init];
  //checkRefs variables
  addresses=[[NSMutableSet alloc] init];
  for (i=0;i<=DATA; i++) {
    varNumber[i]=0;
    duplicates[i]=[[NSMutableSet alloc] init];
  }
  varPrefix[STRING]=@"s";
  varPrefix[ARRAY]=@"a";
  varPrefix[DICTIONARY]=@"h";
  varPrefix[DATA]=@"d";
  
  begunAddresses=[[NSMutableSet alloc] init];
  cycleAddresses=[[NSMutableSet alloc] init];

  // lisp
  names=[[NSMutableDictionary alloc] init]; // of strings
  letDefs=[[NSMutableString alloc] init];
  needDictDef=needArrayDef=0;
  defineCycles=NO; // set YES, when declared vars must be defined (in case of cyclic objects)
  vectorString=[@"list" retain];
  return self;
}

- (void)setDefineCylce:(BOOL)yn;
{ 
  defineCycles=yn;
}

- (enum plist_type)typeOfObject:(id)obj;
{
  if ([obj isKindOfClass:[NSString class]])
    return STRING;
  if ([obj isKindOfClass:[NSArray class]])
    return ARRAY;
  if ([obj isKindOfClass:[NSDictionary class]])
    return DICTIONARY;
  if ([obj isKindOfClass:[NSData class]])
    return DATA;
  return ERROR;
}

- (void)checkRefs:(id)plist;
{
// This method finds all duplicates of objects in plist.
// Also cycles are detected and the first node in a cycle is added to the set of cycleAddresses. 
  id address=[NSValue valueWithNonretainedObject:plist];
  enum plist_type type=[self typeOfObject:plist];
  NSEnumerator *e;
  if ([addresses containsObject:address]) {
    [duplicates[type] addObject:address];
    if ([begunAddresses containsObject:address])
      [cycleAddresses addObject:address];
    return;
  }
  [addresses addObject:address];
  switch (type) {
    case ARRAY:
    case DICTIONARY: e=[plist objectEnumerator]; break;
    default: e=nil;
  }
  if (e) {
    id obj;
    [begunAddresses addObject:address];
    while (obj=[e nextObject])
      [self checkRefs:obj];
    [begunAddresses removeObject:address];
  }
}

- (void)declareAddresses;
{
// This method declares all objects, that are necessary to break cycles.
  NSEnumerator *e=[cycleAddresses objectEnumerator];
  NSValue *address;
  while (address=[e nextObject]) {
    id plist=[address nonretainedObjectValue];
    enum plist_type type=[self typeOfObject:plist];
    NSString *definition;
    switch (type) {
      case ARRAY:definition=[NSString stringWithFormat:@"(make-array %d)",[plist count]]; break;
      case DICTIONARY:definition=[NSString stringWithFormat:@"(make-hash-table :size %d)",[plist count]]; break;
      default:definition=@"error";
    }
    [self let:type address:address definition:definition prePrefix:@"c"];
  }
}

- (NSString *)labelDefinitions;
{
    NSMutableString *str=[NSMutableString string];
    NSArray *a;
    int i;
    a=[NSArray arrayWithObjects:lispDef_arraySetElementsRec,lispDef_arraySetElements,lispDef_arrayWithElements,nil];
    for (i=0;i<needArrayDef;i++)
        [str appendFormat:@"  (%@)\n",[a objectAtIndex:i]];
    a=[NSArray arrayWithObjects:lispDef_hashTableSetKeyValuesRec,lispDef_hashTableSetKeyValues,lispDef_hashTableWithKeyValues,nil];
    for (i=0;i<needDictDef;i++)
        [str appendFormat:@"  (%@)\n",[a objectAtIndex:i]];
    return str;
}

- (NSString *)letDefinitions;
{ 
    return letDefs;
}
- (NSString *)cycleDefinitions;
{
  NSEnumerator *e=[cycleAddresses objectEnumerator];
  NSMutableString *resultString=[NSMutableString string];
  NSValue *address;
  while (address=[e nextObject]) {
    NSString *def=[self defineAddress:address];
    [resultString appendFormat:@"%@\n",def];
  }
  return resultString;
}

- (NSString *)varOrDefinitionForPlist:(id)plist;
{
  return [self varOrDefinitionForAddress:[NSValue valueWithNonretainedObject:plist]];
}
- (NSString *)varOrDefinitionForAddress:(NSValue *)address;
{
// This method returns the lisp definition for an object.
// If the object is used multiple times, that means, if it is already declared or if there is a
// begun-cycle, an identifier of the let-Block is returned. In that case there is a side effect.
  NSString *returnString;
  returnString=[names objectForKey:address];
  if (!returnString)
    returnString=[self defineAddress:address];
  return returnString;
}

- (NSString *)defineAddress:(NSValue *)address;
{
// Gets a definition depending on type of object.
// Forms a let definition, if used more than one time.
  id plist=[address nonretainedObjectValue];
  enum plist_type type=[self typeOfObject:plist];
  NSString *definition;
  switch (type) {
    case ARRAY:definition=[self defineArray:plist address:address];break;
    case DICTIONARY:definition=[self defineDictionary:plist address:address];break;
    case STRING:definition=[self defineString:plist address:address]; break;
    default: definition=nil;
  }
  if (!defineCycles && [duplicates[type] containsObject:address]) {
    [self let:type address:address definition:definition prePrefix:@""];
    return [names objectForKey:address];
  } else
    return definition;
}

- (NSString *)newNameForType:(enum plist_type)type prePrefix:(NSString *)prePrefix;
{
  NSString *varName;
  varNumber[type]++;
  varName=[NSString stringWithFormat:@"%@%@%d",prePrefix,varPrefix[type],varNumber[type]];
  return varName;
}

- (void)let:(enum plist_type)type address:(NSValue *)address definition:(NSString *)definition prePrefix:(NSString *)prePrefix;
{
// This method appends a let entry to the let definition.
// (let* (entry1 entry2 ...))
  NSString *varName=[self newNameForType:type prePrefix:prePrefix];
  NSString *letDef;
  NSParameterAssert([names objectForKey:varName]==nil);
  [names setObject:varName forKey:address];
  letDef=[NSString stringWithFormat:@"(%@ %@)",varName,definition];
  [self appendItem:letDef];
}

- (NSString *)defineString:(NSString *)str address:(NSValue *)address;
{
  NSArray *a=[str componentsSeparatedByString:@"\""];
  NSString *ret=[a componentsJoinedByString:@"\\\""];
  return [NSString stringWithFormat:@"\"%@\"",ret];
}

- (NSString *)defineArray:(NSArray *)a address:(NSValue *)address;
{
// This method gives the lisp definition of an array.
// We have to watch the case, that there is an object graph cycle.
// In this case the object is declared before with make-array and filled here.
  NSEnumerator *e=[a objectEnumerator];
  NSMutableArray *results=[NSMutableArray array];
  id obj;
  NSString *componentsString;
  while (obj=[e nextObject]) {
    NSString *result=[self varOrDefinitionForPlist:obj];
    [results addObject:result];
  }
  componentsString=[results componentsJoinedByString:@" "];
  if (!defineCycles) {
    // the usual case
    if (vectorString==lisp_arrayWithElements) 
      needArrayDef=3;
    return [NSString stringWithFormat:@"(%@ %@)",vectorString,componentsString];
  } else {
    NSString *name=[names objectForKey:address];
    if (needArrayDef<2)
      needArrayDef=2;
    return [NSString stringWithFormat:@"(%@ %@ (list %@))",lisp_arraySetElements,name,componentsString];
/*
    // set of (setf (svref arrName index) value)
    NSMutableString *returnString=[NSMutableString string];
    int c=[results count];
    int i;
    for (i=0;i<c;i++) {
      [returnString appendFormat:@"(setf (svref %@ %d) %@)",name,i,[results objectAtIndex:i]];
    }
    return returnString;
*/
  }
}

- (NSString *)defineDictionary:(NSDictionary *)d address:(NSValue *)address;
{
// This method gives the lisp definition of an dictionary.
// We have to watch the case, that there is an object graph cycle.
// In this case the object is declared before with make-array and filled here.
  NSEnumerator *e=[d keyEnumerator];
  id obj;
  NSString *key;
  NSMutableString *declarations=[NSMutableString string];
  while (key=[e nextObject]) {
    NSString *declaration;
    obj=[d objectForKey:key];
    declaration=[self varOrDefinitionForPlist:obj];
    [declarations appendFormat:@"(list '%@ %@)",key,declaration];
  }
  if (!defineCycles) {
    // the usual case:
    needDictDef=3;
    return [NSString stringWithFormat:@"(%@ (list %@))",lisp_hashTableWithKeyValues,declarations];
  } else {
    NSString *name=[names objectForKey:address];
    if (needDictDef<2) 
      needDictDef=2;
    return [NSString stringWithFormat:@"(%@ %@ (list %@))",lisp_hashTableSetKeyValues,name,declarations];
  }
}

- (void)appendItem:(NSString *)str;
{
  [letDefs appendFormat:@"  %@\n",str];
}

/*
- (void)duplicateStrings;
{
  NSEnumerator *e=[duplicates[STRING] objectEnumerator];
  NSValue *v;
  int i=0;
  while (v=[e nextObject]) {
    NSString *name;
    NSString *value=[v nonretainedObjectValue];
    i++;
    name=[NSString stringWithFormat:@"s%d",i];
    [names setObject:name forKey:v];
    [self appendItem:[NSString stringWithFormat:@"(%@ \"%@\")",name,value]];
  }
}

- (void)duplicateArrays;
{
  NSEnumerator *e=[duplicates[ARRAY] objectEnumerator];
  NSValue *v;
  int i=0;
  while (v=[e nextObject]) {
    NSString *name;
    NSArray *value=[v nonretainedObjectValue];
    i++;
    name=[NSString stringWithFormat:@"a%d",i];
    [names setObject:name forKey:v];
    [self appendItem:[NSString stringWithFormat:@"(%@ (make-array %d))",name,[value count]]];
  }  
}

- (void)duplicateDictionarys;
{
  NSEnumerator *e=[duplicates[DICTIONARY] objectEnumerator];
  NSValue *v;
  int i=0;
  while (v=[e nextObject]) {
    NSString *name;
//    NSArray *value=[v nonretainedObjectValue];
    i++;
    name=[NSString stringWithFormat:@"h%d",i];
    [names setObject:name forKey:v];
    [self appendItem:[NSString stringWithFormat:@"(%@ (make-hash-table))",name]];
  }  
}
*/
@end
