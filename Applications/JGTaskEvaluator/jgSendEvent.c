/*
 *  sendEvent.c
 *  sendEvent
 *
 *  Created by Joerg Garbers on Wed Aug 14 2002.
 *  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
 *
 */

#include <Carbon/Carbon.h>


char *sendString(OSType creator, AEEventClass theAEEventClass, AEEventID theAEEventID, const char *text) {
  
  AEAddressDesc target;
  AppleEvent theAppleEvent;
  AppleEvent reply;
  OSErr err=noErr;
  char *resultString=NULL;
      
  // create target descriptor
  if (err==noErr) {
    DescType typeCode=typeApplSignature;
    const void *dataPtr=&creator;  
    Size dataSize = sizeof(creator);  
    
    err= AECreateDesc (
                       typeCode,
                       dataPtr,
                       dataSize,
                       &target
                       );
  }

  // create event frame
  if (err==noErr) {
    AEReturnID returnID=kAutoGenerateReturnID;
    AETransactionID transactionID=kAnyTransactionID;
    
    err= AECreateAppleEvent (
                              theAEEventClass,
                              theAEEventID,
                              &target,
                              returnID,
                              transactionID,
                              &theAppleEvent // resulting apple event
                              );
  }
  
  // Put the string into the direct object parameter
  if (err==noErr) {
    AEKeyword theAEKeyword=keyDirectObject; 
    DescType typeCode=typeChar; // ?
    const void *dataPtr=text;
    Size dataSize=strlen(text);
    
    err = AEPutParamPtr(&theAppleEvent, theAEKeyword, typeCode, dataPtr, dataSize);
  }
  
  // send 
  if (err==noErr) {
    AESendMode sendMode=kAEWaitReply;
    AESendPriority sendPriority=kAENormalPriority;
    SInt32 timeOutInTicks=kNoTimeOut;
    AEIdleUPP idleProc=NULL ; // ? documentation says, it should not be NULL. if kAEWaitReply. But did it forsee command line tools? see AEIdleProcPtr
    AEFilterUPP filterProc=NULL; // no events to receive
    err=AESend (
                      &theAppleEvent,
                      &reply,
                      sendMode,
                      sendPriority,
                      timeOutInTicks,
                      idleProc,
                      filterProc
                      );    
  }

  // Retrieve keyDirectObject parameter from reply structure
  if (err==noErr) {
    AEKeyword theAEKeyword=keyDirectObject;
    DescType desiredType=typeChar;
    DescType typeCode; // actual type, if desiredType is wildcarded.
    char *dataPtr;
    Size maximumSize;
    Size actualSize;

    err = AESizeOfParam(&reply, theAEKeyword, &typeCode, &maximumSize);
    if (err==noErr) {
      dataPtr=malloc(maximumSize);
      err = AEGetParamPtr(&reply, theAEKeyword, desiredType, &typeCode, dataPtr, maximumSize, &actualSize);
      if (err==noErr && (desiredType==typeCode))
        resultString=dataPtr;
    }    
  }
  AEDisposeDesc(&target);
  AEDisposeDesc(&theAppleEvent);
  AEDisposeDesc(&reply);
  return resultString;
}