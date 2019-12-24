/*********************************************************************
 *
 *               Data SPI EEPROM Access Routines
 *
 *********************************************************************
 * FileName:        SPIEEPROM.c
 * Dependencies:    Compiler.h
 *                  XEEPROM.h
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
 * Howard Schlunder		9/01/04		Rewritten for SPI EEPROMs
********************************************************************/
#include "Compiler.h"
#include "XEEPROM.h"
#include "StackTsk.h"
#include "usart.h"

#if !defined(MPFS_USE_EEPROM)
#error MPFS_USE_EEPROM is not defined but spieeprom.c is present
#endif

/* Hardware interface to SPI EEPROM. */
#define EEPROM_CS_TRIS		(TRISB_RB4)
#define EEPROM_CS_IO		(LATB4)
//#define EEPROM_CS_IO		(RB4)
// The following SPI pins are used but are not configurable
//   RC3 is used for the SCK pin and is an output
//   RC4 is used for the SDI pin and is an input
//   RC5 is used for the SDO pin and is an output
// IMPORTANT SPI NOTE: The code in this file expects that the SPI interrupt 
//		flag (PIR1_SSPIF) be clear at all times.  If the SPI is shared with 
//		other hardware, the other code should clear the PIR1_SSPIF when it is 
//		done using the SPI.


/* Psuedo functions */
#define SPISelectEEPROM()	EEPROM_CS_IO = 0
#define SPIUnselectEEPROM()	EEPROM_CS_IO = 1


/* EEPROM opcodes */
#define READ	0b00000011	// Read data from memory array beginning at selected address
#define WRITE	0b00000010	// Write data to memory array beginning at selected address
#define WRDI	0b00000100	// Reset the write enable latch (disable write operations)
#define WREN	0b00000110	// Set the write enable latch (enable write operations)
#define RDSR	0b00000101	// Read Status register
#define WRSR	0b00000001	// Write Status register

void DoWrite(void);

WORD EEPROMAddress;
BYTE EEPROMBuffer[EEPROM_BUFFER_SIZE];
BYTE *EEPROMBufferPtr;

/*********************************************************************
 * Function:        void XEEInit(unsigned char speed)
 *
 * PreCondition:    None
 *
 * Input:           speed - not used (included for compatibility only)
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Initialize SPI module to communicate to serial
 *                  EEPROM.
 *
 * Note:            Code sets SPI clock to Fosc/4.  
 ********************************************************************/
void XEEInit(unsigned char speed)
{
	#define SSPEN 0x20		// SSP Enable bit in SSPCON1

	SPIUnselectEEPROM();
	EEPROM_CS_TRIS = 0;		// Drive SPI EEPROM chip select pin

	TRISC_RC3 = 0;			// Set RC3 (SCK) pin as an output
	TRISC_RC4 = 1;			// Make sure RC4 (SDI) pin is an input
	TRISC_RC5 = 0;			// Set RC5 (SDO) pin as an output
	SSPCON1 = SSPEN;		// SSPEN bit is set, SPI in master mode, 
							//  IDLE state is low level, Fosc/4 clock
	PIR1_SSPIF = 0;
	SSPSTAT_CKE = 1; 		// Transmit data on rising edge of clock
	SSPSTAT_SMP = 0;		// Input sampled at middle of data output time
}


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
XEE_RESULT XEEBeginRead(unsigned char control, XEE_ADDR address )
{
	// Save the address and emptry the contents of our local buffer
	EEPROMAddress = address;
	EEPROMBufferPtr = EEPROMBuffer + EEPROM_BUFFER_SIZE;
	return XEE_SUCCESS;
}


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
unsigned char XEERead(void)
{
	// Check if no more bytes are left in our local buffer
	if( EEPROMBufferPtr == EEPROMBuffer + EEPROM_BUFFER_SIZE )
	{ 
		// Get a new set of bytes
		XEEReadArray(0, EEPROMAddress, EEPROMBuffer, EEPROM_BUFFER_SIZE);
		EEPROMAddress += EEPROM_BUFFER_SIZE;
		EEPROMBufferPtr = EEPROMBuffer;
	}

	// Return a byte from our local buffer
	return *EEPROMBufferPtr++;
}

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
 * Note:            This function ends sequential cycle that was in
 *                  progress.  It releases I2C bus.
 ********************************************************************/
XEE_RESULT XEEEndRead(void)
{
    return XEE_SUCCESS;
}


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
                        unsigned char length)
{
	//unsigned char ch;
	//DBGCMT("XXER<");
	SPISelectEEPROM();

	// Send READ opcode
	SSPBUF = READ;
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;
	
	// Send address
	SSPBUF = 0;
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;

	SSPBUF = ((WORD_VAL*)&address)->v[1];
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;

	SSPBUF = ((WORD_VAL*)&address)->v[0];
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;

	while(length--)
	{
		SSPBUF = 0;
		while(!PIR1_SSPIF);
		PIR1_SSPIF = 0;
		//ch = SSPBUF;
		//*buffer++ = ch;
		//DBGCMD( USARTPut(ch) );
		*buffer++ = SSPBUF;
	};
	SPIUnselectEEPROM();
	//DBGCMT(">");
	return XEE_SUCCESS;
}


/*********************************************************************
 * Function:        XEE_RESULT XEESetAddr(unsigned char control,
 *                                        XEE_ADDR address)
 *
 * PreCondition:    XEEInit() is already called.
 *
 * Input:           control     - data EEPROM control code
 *                  address     - address to be set for writing
 *
 * Output:          XEE_SUCCESS if successful
 *                  other value if failed.
 *
 * Side Effects:    None
 *
 * Overview:        Modifies internal address counter of EEPROM.
 *
 * Note:            Unlike XEESetAddr() in xeeprom.c for I2C EEPROM 
 *					 memories, this function is used only for writing
 *					 to the EEPROM.  Reads must use XEEBeginRead(), 
 *					 XEERead(), and XEEEndRead().
 *					This function does not release the SPI bus.
 *                  User must close XEEClose() after this function
 *                   is called.
 ********************************************************************/
XEE_RESULT XEESetAddr(unsigned char control, XEE_ADDR address)
{
	EEPROMAddress = address;
	EEPROMBufferPtr = EEPROMBuffer;
	return XEE_SUCCESS;
}


/*********************************************************************
 * Function:        XEE_RESULT XEEWrite(unsigned char val)
 *
 * PreCondition:    XEEInit() && XEEBeginWrite() are already called.
 *
 * Input:           val - Byte to be written
 *
 * Output:          XEE_SUCCESS
 *
 * Side Effects:    None
 *
 * Overview:        Adds a byte to the current page to be writen when
 *					XEEEndWrite() is called.
 *
 * Note:            Page boundary cannot be exceeded or the byte 
 *					to be written will be looped back to the 
 *					beginning of the page.
 ********************************************************************/
XEE_RESULT XEEWrite(unsigned char val)
{
	*EEPROMBufferPtr++ = val;
	if( EEPROMBufferPtr == EEPROMBuffer + EEPROM_BUFFER_SIZE )
		DoWrite();

    return XEE_SUCCESS;
}


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
 *                  User must call for XEEIsBusy() to ensure that write
 *                  cycle is finished before calling any other
 *                  routine.
 ********************************************************************/
XEE_RESULT XEEEndWrite(void)
{
	if( EEPROMBufferPtr != EEPROMBuffer )
		DoWrite();

    return XEE_SUCCESS;
}

void DoWrite(void)
{
	BYTE BytesToWrite;
	
	// Set the Write Enable latch
	SPISelectEEPROM();
	SSPBUF = WREN;
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;
	SPIUnselectEEPROM();
	
	// Send WRITE opcode
	SPISelectEEPROM();
	SSPBUF = WRITE;
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;
	
	// Send address
	SSPBUF = 0;
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;

	SSPBUF = ((WORD_VAL*)&EEPROMAddress)->v[1];
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;

	SSPBUF = ((WORD_VAL*)&EEPROMAddress)->v[0];
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;
	
	BytesToWrite = (BYTE)(EEPROMBufferPtr - EEPROMBuffer);
	
	EEPROMAddress += BytesToWrite;
	EEPROMBufferPtr = EEPROMBuffer;

	while(BytesToWrite--)
	{
		// Send the byte to write
		SSPBUF = *EEPROMBufferPtr++;
		while(!PIR1_SSPIF);
		PIR1_SSPIF = 0;
	}

	// Begin the write
	SPIUnselectEEPROM();

	EEPROMBufferPtr = EEPROMBuffer;

	// Wait for write to complete
	while( XEEIsBusy(0) );
}


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
XEE_RESULT XEEIsBusy(unsigned char control)
{
	BYTE result;


	SPISelectEEPROM();
	// Send RDSR - Read Status Register opcode
	SSPBUF = RDSR;
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;
	
	// Get register contents
	SSPBUF = 0;
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;
	result = SSPBUF;
	SPIUnselectEEPROM();

	return (((BYTE_VAL*)&result)->bits.b0) ? XEE_BUSY : XEE_SUCCESS;
}


void FastWriteWord(XEE_ADDR address, unsigned int wData)
{
	BYTE BytesToWrite;
	
	// Set the Write Enable latch
	SPISelectEEPROM();
	SSPBUF = WREN;
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;
	SPIUnselectEEPROM();
	
	// Send WRITE opcode
	SPISelectEEPROM();
	SSPBUF = WRITE;
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;
	
	// Send address
	SSPBUF = 0;
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;

	SSPBUF = ((WORD_VAL*)&address)->v[1];
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;

	SSPBUF = ((WORD_VAL*)&address)->v[0];
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;
	
	BytesToWrite = 2;
	
	SSPBUF = wData >> 8;
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;

	SSPBUF = wData & 255;
	while(!PIR1_SSPIF);
	PIR1_SSPIF = 0;

	// Begin the write
	SPIUnselectEEPROM();

	// Wait for write to complete
	while( XEEIsBusy(0) );
}
