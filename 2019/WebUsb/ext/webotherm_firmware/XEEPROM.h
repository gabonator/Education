/*********************************************************************
 *
 *               External serial data EEPROM Access Defs.
 *
 *********************************************************************
 * FileName:        XEEPROM.h
 * Dependencies:    None
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
 *
 * Author               Date        Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Nilesh Rajbharti     5/20/02     Original (Rev. 1.0)
********************************************************************/
#ifndef XEEPROM_H
#define XEEPROM_H

#define EE_BAUD(CLOCK, BAUD)      ( ((CLOCK / BAUD) / 4) - 1 )


typedef enum _XEE_RESULT
{
    XEE_SUCCESS = 0,
    XEE_READY = 0,
    XEE_BUS_COLLISION,
    XEE_NAK,
    XEE_VERIFY_ERR,
    XEE_BUSY
} XEE_RESULT;

typedef unsigned int XEE_ADDR;


/*********************************************************************
 * Function:        void XEEInit(unsigned char baud)
 *
 * PreCondition:    None
 *
 * Input:           baud    - SSPADD value for bit rate.
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Initialize I2C module to communicate to serial
 *                  EEPROM.
 *
 * Note:            None
 ********************************************************************/
void XEEInit(unsigned char baud);



/*********************************************************************
 * Function:        XEE_RESULT XEESetAddr(unsigned char control,
 *                                        XEE_ADDR address)
 *
 * PreCondition:    XEEInit() is already called.
 *
 * Input:           control     - data EEPROM control code
 *                  address     - address to be set
 *
 * Output:          XEE_SUCCESS if successful
 *                  other value if failed.
 *
 * Side Effects:    None
 *
 * Overview:        Modifies internal address counter of EEPROM.
 *
 * Note:            This function does not release the I2C bus.
 *                  User must close XEEClose() after this function
 *                  is called.
 ********************************************************************/
XEE_RESULT XEESetAddr(unsigned char control, XEE_ADDR address);



/*********************************************************************
 * Macro:           XEE_RESULT XEEBeginWrite(unsigned char control,
 *                                           XEE_ADDR address)
 *
 * PreCondition:    XEEInit() is already called.
 *
 * Input:           control     - data EEPROM control code
 *                  address     - address to where to write
 *
 * Output:          XEE_SUCCESS if successful
 *                  other value if failed.
 *
 * Side Effects:    None
 *
 * Overview:        Sets up internal address counter of EEPROM.
 *
 * Note:            This function does not release the I2C bus.
 *                  User must close XEEEndWrite() after this function
 *                  is called to relase the I2C bus.
 ********************************************************************/
#define XEEBeginWrite(control, address)     XEESetAddr(control, address)



/*********************************************************************
 * Function:        XEE_RESULT XEEWrite(unsigned char val)
 *
 * PreCondition:    XEEInit() && XEEBeginWrite() are already called.
 *
 * Input:           val to be written
 *
 * Output:          XEE_SUCCESS if successful
 *                  other value if failed.
 *
 * Side Effects:    None
 *
 * Overview:        Writes given value 'val' at current address.
 *                  Current address is set by XEEBeginWrite()
 *                  and is incremented by every XEEWrite().
 *
 * Note:            This function does not initiate the write cycle;
 *                  it simply loads given value into internal page buffer.
 *                  This function does not release the I2C bus.
 *                  User must close XEEEndWrite() after this function
 *                  is called to relase the I2C bus.
 ********************************************************************/
XEE_RESULT XEEWrite(unsigned char val);



/*********************************************************************
 * Function:        XEE_RESULT XEEEndWrite(void)
 *
 * PreCondition:    XEEInit() && XEEBeginWrite() are already called.
 *
 * Input:           None
 *
 * Output:          XEE_SUCCESS if successful
 *                  other value if failed.
 *
 * Side Effects:    None
 *
 * Overview:        Instructs EEPROM to begin write cycle.
 *
 * Note:            Call this function after either page full of bytes
 *                  written or no more bytes are left to load.
 *                  This function initiates the write cycle.
 *                  User must call for XEEWait() to ensure that write
 *                  cycle is finished before calling any other
 *                  routine.
 ********************************************************************/
XEE_RESULT XEEEndWrite(void);


/*********************************************************************
 * Function:        XEE_RESULT XEEBeginRead(unsigned char control,
 *                                          XEE_ADDR address)
 *
 * PreCondition:    XEEInit() is already called.
 *
 * Input:           control - EEPROM control and address code.
 *                  address - Address at which read is to be performed.
 *
 * Output:          XEE_SUCCESS if successful
 *                  other value if failed.
 *
 * Side Effects:    None
 *
 * Overview:        Sets internal address counter to given address.
 *                  Puts EEPROM in sequential read mode.
 *
 * Note:            This function does not release I2C bus.
 *                  User must call XEEEndRead() when read is not longer
 *                  needed; I2C bus will released after XEEEndRead()
 *                  is called.
 ********************************************************************/
XEE_RESULT XEEBeginRead(unsigned char control, XEE_ADDR address);



/*********************************************************************
 * Function:        XEE_RESULT XEERead(void)
 *
 * PreCondition:    XEEInit() && XEEBeginRead() are already called.
 *
 * Input:           None
 *
 * Output:          XEE_SUCCESS if successful
 *                  other value if failed.
 *
 * Side Effects:    None
 *
 * Overview:        Reads next byte from EEPROM; internal address
 *                  is incremented by one.
 *
 * Note:            This function does not release I2C bus.
 *                  User must call XEEEndRead() when read is not longer
 *                  needed; I2C bus will released after XEEEndRead()
 *                  is called.
 ********************************************************************/
unsigned char XEERead(void);


/*********************************************************************
 * Function:        XEE_RESULT XEEEndRead(void)
 *
 * PreCondition:    XEEInit() && XEEBeginRead() are already called.
 *
 * Input:           None
 *
 * Output:          XEE_SUCCESS if successful
 *                  other value if failed.
 *
 * Side Effects:    None
 *
 * Overview:        Ends sequential read cycle.
 *
 * Note:            This function ends seuential cycle that was in
 *                  progress.  It releases I2C bus.
 ********************************************************************/
XEE_RESULT XEEEndRead(void);


/*********************************************************************
 * Function:        XEE_RESULT XEEReadArray(unsigned char control,
 *                                          XEE_ADDR address,
 *                                          unsigned char *buffer,
 *                                          unsigned char length)
 *
 * PreCondition:    XEEInit() is already called.
 *
 * Input:           control     - EEPROM control and address code.
 *                  address     - Address from where array is to be read
 *                  buffer      - Caller supplied buffer to hold the data
 *                  length      - Number of bytes to read.
 *
 * Output:          XEE_SUCCESS if successful
 *                  other value if failed.
 *
 * Side Effects:    None
 *
 * Overview:        Reads desired number of bytes in sequential mode.
 *                  This function performs all necessary steps
 *                  and releases the bus when finished.
 *
 * Note:            None
 ********************************************************************/
XEE_RESULT XEEReadArray(unsigned char control,
                        XEE_ADDR address,
                        unsigned char *buffer,
                        unsigned char length);



/*********************************************************************
 * Function:        XEE_RESULT XEEIsBusy(unsigned char control)
 *
 * PreCondition:    XEEInit() is already called.
 *
 * Input:           control     - EEPROM control and address code.
 *
 * Output:          XEE_READY if EEPROM is not busy
 *                  XEE_BUSY if EEPROM is busy
 *                  other value if failed.
 *
 * Side Effects:    None
 *
 * Overview:        Requests ack from EEPROM.
 *
 * Note:            None
 ********************************************************************/
XEE_RESULT XEEIsBusy(unsigned char control);


void FastWriteWord(XEE_ADDR address, unsigned int wData);

#endif
