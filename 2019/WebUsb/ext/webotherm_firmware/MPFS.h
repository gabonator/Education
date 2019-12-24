/*********************************************************************
 *
 *               Microchip File System on PIC18
 *
 *********************************************************************
 * FileName:        MPFS.h
 * Dependencies:    StackTsk.H
 * Processor:       PIC18
 * Complier:        MCC18 v1.00.50 or higher
 *                  HITECH PICC-18 V8.10PL1 or higher
 * Company:         Microchip Technology, Inc.
 *
 * Software License Agreement
 *
 * This software is owned by Microchip Technology Inc. ("Microchip") 
 * and is supplied to you for use exclusively as described in the 
 * associated software agreement.  This software is protected by 
 * software and other intellectual property laws.  Any use in 
 * violation of the software license may subject the user to criminal 
 * sanctions as well as civil liability.  Copyright 2006 Microchip
 * Technology Inc.  All rights reserved.
 *
 * This software is provided "AS IS."  MICROCHIP DISCLAIMS ALL 
 * WARRANTIES, EXPRESS, IMPLIED, STATUTORY OR OTHERWISE, NOT LIMITED 
 * TO MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND 
 * INFRINGEMENT.  Microchip shall in no event be liable for special, 
 * incidental, or consequential damages.
 *
 * This file provides Microchip File System access calls.
 *
 * Author               Date        Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Nilesh Rajbharti     8/14/01     Original (Rev. 1.0)
 * Nilesh Rajbharti     2/9/02      Cleanup
 * Nilesh Rajbharti     5/22/02     Rev 2.0 (See version.log for detail)
********************************************************************/

#ifndef MPFS_H
#define MPFS_H

#include "StackTsk.h"

#if defined(MPFS_USE_PGRM)
    typedef ROM BYTE* MPFS;
    #define MPFS_INVALID                (MPFS)(0xffffff)
	typedef WORD MPFS_OFFSET;

#else
    typedef WORD MPFS;
    #define MPFS_INVALID                (0xffff)
    typedef WORD MPFS_OFFSET;

#endif

#define MPFS_NOT_AVAILABLE              (0x0)

#if defined(MPFS_USE_EEPROM)
#define MPFS_WRITE_PAGE_SIZE            (64)
#elif defined(MPFS_USE_PRGMR)
#define MPFS_WRITE_PAGE_SIZE            (8)
#endif



/*********************************************************************
 * Function:        BOOL MPFSInit(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          TRUE, if MPFS Storage access is initialized and
 *                          MPFS is is ready to be used.
 *                  FALSE otherwise
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
BOOL MPFSInit(void);


/*********************************************************************
 * Function:        MPFS MPFSOpen(BYTE* name)
 *
 * PreCondition:    None
 *
 * Input:           name    - NULL terminate file name.
 *
 * Output:          MPFS_INVALID if not found
 *                  != MPFS_INVALID if found ok.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
MPFS   MPFSOpen(BYTE* name);



/*********************************************************************
 * Function:        void MPFSClose(void)
 *
 * PreCondition:    None
 *
 * Input:           handle      - File handle to be closed
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
void MPFSClose(void);


/*********************************************************************
 * Function:        BOOL MPFSGetBegin(MPFS handle)
 *
 * PreCondition:    MPFSOpen() != MPFS_INVALID &&
 *
 * Input:           handle      - handle of file that is to be read
 *
 * Output:          TRUE if successful
 *                  !TRUE otherwise
 *
 * Side Effects:    None
 *
 * Overview:        Prepares MPFS storage media for subsequent reads.
 *
 * Note:            None
 ********************************************************************/
#if defined(MPFS_USE_EEPROM)
    BOOL MPFSGetBegin(MPFS handle);
#else
    #define MPFSGetBegin(handle)    (_currentHandle = handle)
#endif


/*********************************************************************
 * Function:        BYTE MPFSGet(void)
 *
 * PreCondition:    MPFSOpen() != MPFS_INVALID &&
 *                  MPFSGetBegin() == TRUE
 *
 * Input:           None
 *
 * Output:          Data byte from current address.
 *
 * Side Effects:    None
 *
 * Overview:        Reads a byte from current address.
 *
 * Note:            Caller must call MPFSIsEOF() to check for end of
 *                  file condition
 ********************************************************************/
BYTE MPFSGet(void);


/*********************************************************************
 * Function:        MPFS MPFSGetEnd(void)
 *
 * PreCondition:    MPFSOpen() != MPFS_INVALID &&
 *                  MPFSGetBegin() = TRUE
 *
 * Input:           None
 *
 * Output:          Current mpfs handle.
 *
 * Side Effects:    None
 *
 * Overview:        Ends on-going read cycle.
 *                  MPFS handle that is returned must be used
 *                  for subsequent begin gets..
 *
 * Note:            None
 ********************************************************************/
#if defined(MPFS_USE_EEPROM)
    MPFS MPFSGetEnd(void);
#else
    #define MPFSGetEnd()        _currentHandle
#endif


/*********************************************************************
 * Macro:           BOOL MPFSIsEOF(void)
 *
 * PreCondition:    MPFSGetBegin() must be called.
 *
 * Input:           None
 *
 * Output:          TRUE if current file read has reached end of file.
 *                  FALSE if otherwise.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
#define MPFSIsEOF()     (_currentHandle == MPFS_INVALID)


/*********************************************************************
 * Function:        MPFS MPFSFormat(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          A valid MPFS handle that can be used for MPFSPut
 *
 * Side Effects:    None
 *
 * Overview:        Prepares MPFS image to get re-written
 *                  Declares MPFS as in use.
 *
 * Note:            MPFS will be unaccessible until MPFSClose is
 *                  called.
 ********************************************************************/
MPFS MPFSFormat(void);



/*********************************************************************
 * Function:        BOOL MPFSPutBegin(MPFS handle)
 *
 * PreCondition:    MPFSInit() and MPFSFormat() are already called.
 *
 * Input:           handle  - handle to where put to begin
 *
 * Output:          TRUE if successful
 *                  !TRUE otherwise
 *
 * Side Effects:    None
 *
 * Overview:        Prepares MPFS image to get re-written
 *
 * Note:            MPFS will be unaccessible until MPFSClose is
 *                  called.
 ********************************************************************/
#if defined(MPFS_USE_EEPROM)
    BOOL MPFSPutBegin(MPFS handle);
#else
    #define MPFSPutBegin(handle)        (_currentHandle = handle)
#endif


/*********************************************************************
 * Function:        BOOL MPFSPut(BYTE b)
 *
 * PreCondition:    MPFSFormat() or MPFSCreate() must be called
 *
 * Input:           b       - byte to be written
 *
 * Output:          TRUE if successful
 *                  !TRUE if otherwise
 *
 * Side Effects:    MPFS handle is updated.
 *
 * Overview:        None
 *
 * Note:            Since this function updates internal MPFS handle
 *                  caller must call MPFSPutEnd() to obtain
 *                  up-to-date handle.
 ********************************************************************/
BOOL MPFSPut(BYTE b);


/*********************************************************************
 * Function:        MPFS MPFSPutEnd(void)
 *
 * PreCondition:    MPFSPutBegin() is already called.
 *
 * Input:           None
 *
 * Output:          Up-to-date MPFS handle
 *
 * Side Effects:    Original MPFS handle is no longer valid.
 *                  Updated MPFS handle must be obtained by calling
 *                  MPFSPutEnd().
 *
 * Overview:        None
 *
 * Note:            Actual write may not get started until internal
 *                  write page is full.  To ensure that previously
 *                  data gets written, caller must call MPFSPutEnd()
 *                  after last call to MPFSPut().
 ********************************************************************/
MPFS MPFSPutEnd(void);


/*********************************************************************
 * Macro:           BYTE MPFSInUse(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          No. of file currently open.
 *                  If == 0, MPFS is not in use.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
#if !defined(THIS_IS_MPFS)
extern BYTE mpfsOpenCount;
#endif

/*********************************************************************
 * Function:        MPFS MPFSSeek(MPFS_OFFSET offset)
 *
 * PreCondition:    MPFSGetBegin() is already called.
 *
 * Input:           offset      - Offset from current pointer
 *
 * Output:          New MPFS handle located to given offset
 *
 * Side Effects:    None.
 *
 * Overview:        None
 *
 * Note:            None.
 ********************************************************************/
MPFS MPFSSeek(MPFS_OFFSET offset);


/*********************************************************************
 * Function:        MPFS MPFSTell(void)
 *
 * PreCondition:    MPFSOpen() is already called.
 *
 * Input:           None
 *
 * Output:          current MPFS file pointer
 *
 * Side Effects:    None.
 *
 * Overview:        None
 *
 * Note:            None.
 ********************************************************************/
#define MPFSTell()      (_currentHandle)


#define MPFSIsInUse()       (mpfsOpenCount)

#if !defined(THIS_IS_MPFS)
    extern MPFS _currentHandle;
    extern BYTE _currentCount;
#endif


#endif
