/*********************************************************************
 *
 *                  External LCD access routines
 *
 *********************************************************************
 * FileName:        XLCD.c
 * Dependencies:    xlcd.h
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
 * Author               Date    Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Nilesh Rajbharti     5/8/02  Original        (Rev 1.0)
 * Nilesh Rajbharti     7/10/02 Optimized
 ********************************************************************/
#include "xlcd.h"

/*********************************************************************
 * Function:        void XLCDInit(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        LCD is intialized
 *
 * Note:            This function will work with all Hitachi HD447780
 *                  LCD controller.
 ********************************************************************/
void XLCDInit(void)
{
    // The data bits must be either a 8-bit port or the upper or
    // lower 4-bits of a port. These pins are made into inputs
#ifdef BIT8                 // 8-bit mode, use whole port
    DATA_PORT       = 0;
    TRIS_DATA_PORT  = 0xff;
#else                       // 4-bit mode
#ifdef UPPER                // Upper 4-bits of the port
    DATA_PORT       &= 0x0f;
    TRIS_DATA_PORT  |= 0xf0;
#else                       // Lower 4-bits of the port
    DATA_PORT       &= 0xf0;
    TRIS_DATA_PORT  |= 0x0f;
#endif
#endif
    TRIS_RW         = 0;    // All control signals made outputs
    TRIS_RS         = 0;
    TRIS_E          = 0;
    RW_PIN          = 0;    // R/W pin made low
    RS_PIN          = 0;    // Register select pin made low
    E_PIN           = 0;    // Clock pin made low

    // Delay for 15ms to allow for LCD Power on reset
    XLCDDelay15ms();

    // Setup interface to LCD
#ifdef BIT8     // 8-bit mode interface
    TRIS_DATA_PORT  = 0;    // Data port output
    DATA_PORT       = 0b00110000;     // Function set cmd(8-bit interface)
#else           // 4-bit mode interface
#ifdef UPPER    // Upper nibble interface
    TRIS_DATA_PORT  &= 0x0f;
    DATA_PORT       &= 0x0f;
    DATA_PORT       |= 0b00100000;    // Function set cmd(4-bit interface)
#else   // Lower nibble interface
    TRIS_DATA_PORT  &= 0xf0;
    DATA_PORT       &= 0xf0;
    DATA_PORT       |= 0b00000010;    // Function set cmd(4-bit interface)

#endif
#endif
    E_PIN = 1;                      // Clock the cmd in
    XLCDDelay500ns();
    E_PIN = 0;


    // Delay for at least 4.1ms
    XLCDDelay4ms();


        // Setup interface to LCD
#ifdef BIT8                             // 8-bit interface
        DATA_PORT = 0b00110000;         // Function set cmd(8-bit interface)
#else                                   // 4-bit interface
#ifdef UPPER                            // Upper nibble interface
        DATA_PORT &= 0x0f;              // Function set cmd(4-bit interface)
        DATA_PORT |= 0b00100000;
#else                                   // Lower nibble interface
        DATA_PORT &= 0xf0;              // Function set cmd(4-bit interface)
        DATA_PORT |= 0b00000010;
#endif
#endif
        E_PIN = 1;                      // Clock the cmd in
        XLCDDelay500ns();
        E_PIN = 0;

        // Delay for at least 100us
        XLCDDelay100us();

#if 1

#ifdef BIT8
    DATA_PORT = 0b00110000;         // Function set cmd(8-bit interface)
#else
#ifndef BIT8
#ifdef UPPER    // Upper nibble interface
    DATA_PORT       &= 0x0f;      // Function set cmd(4-bit interface)
    DATA_PORT       |= 0b00100000;
#else           // Lower nibble interface
    DATA_PORT       &= 0xf0;      // Function set cmd(4-bit interface)
    DATA_PORT       |= 0b00000010;
#endif
    E_PIN           = 1;          // Clock cmd in
    XLCDDelay500ns();
    E_PIN           = 0;
#endif
#endif

#endif


#ifdef BIT8             // 8-bit interface
    TRIS_DATA_PORT  = 0xff;      // Make data port input
#else                   // 4-bit interface
#ifdef UPPER                // Upper nibble interface
    TRIS_DATA_PORT  |= 0xf0;     // Make data nibble input
#else                   // Lower nibble interface
    TRIS_DATA_PORT  |= 0x0f;     // Make data nibble input
#endif
#endif

    // Set data interface width, # lines, font
#if !defined(XLCD_IS_BLOCKING)
    while(XLCDIsBusy());      // Wait if LCD busy
#endif
    XLCDCommand(XCLD_TYPE);      // Function set cmd


    // Set DD Ram address to 0
#if !defined(XLCD_IS_BLOCKING)
    while(XLCDIsBusy());      // Wait if LCD busy
#endif
    XLCDCommand(XCLD_TYPE);


#if !defined(XLCD_IS_BLOCKING)
    while(XLCDIsBusy());      // Wait if LCD busy
#endif
    XLCDCommand(DOFF&XLCD_DISPLAY_SETUP);

#if !defined(XLCD_IS_BLOCKING)
    while(XLCDIsBusy());      // Wait if LCD busy
#endif
    XLCDCommand(DON&XLCD_DISPLAY_SETUP);

    // Clear display
#if !defined(XLCD_IS_BLOCKING)
    while(XLCDIsBusy());      // Wait if LCD busy
#endif
    XLCDCommand(0x01);     // Clear display

    // Set entry mode inc, no shift
#if !defined(XLCD_IS_BLOCKING)
    while(XLCDIsBusy());      // Wait if LCD busy
#endif
    XLCDCommand(SHIFT_CUR_LEFT);       // Entry Mode

    // Set DD Ram address to 0
#if !defined(XLCD_IS_BLOCKING)
    while(XLCDIsBusy());      // Wait if LCD busy
#endif
    XLCDCommand(0x80);

    return;
}

/*********************************************************************
 * Function:        void XLCDCommand(unsigned char cmd)
 *
 * PreCondition:    XLCDIsBusy() == FALSE if !defined(XLCD_IS_BLOCKING)
 *
 * Input:           cmd - Command to be set to LCD.
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
void XLCDCommand(unsigned char cmd)
{
#if defined(XLCD_IS_BLOCKING)
    while(XLCDIsBusy());      // Wait if LCD busy
#endif

    TRIS_RW         = 0;    // All control signals made outputs
    TRIS_RS         = 0;

#ifdef BIT8             // 8-bit interface
    TRIS_DATA_PORT = 0;     // Data port output
    DATA_PORT = cmd;        // Write command to data port
    RW_PIN = 0;         // Set the control signals
    RS_PIN = 0;         // for sending a command

    XLCDDelay500ns();

    E_PIN = 1;          // Clock the command in
    XLCDDelay500ns();
    E_PIN = 0;
    XLCDDelay500ns();
    TRIS_DATA_PORT = 0xff;      // Data port input
#else                   // 4-bit interface
#ifdef UPPER                // Upper nibble interface
    TRIS_DATA_PORT &= 0x0f;
    DATA_PORT &= 0x0f;
    DATA_PORT |= cmd&0xf0;
#else                   // Lower nibble interface
    TRIS_DATA_PORT &= 0xf0;
    DATA_PORT &= 0xf0;
    DATA_PORT |= (cmd>>4);
#endif

    RW_PIN = 0;         // Set control signals for command
    RS_PIN = 0;
    XLCDDelay500ns();
    E_PIN = 1;          // Clock command in
    XLCDDelay500ns();
    E_PIN = 0;
#ifdef UPPER                // Upper nibble interface
    DATA_PORT &= 0x0f;
    DATA_PORT |= (cmd<<4)&0xf0;
#else                   // Lower nibble interface
    DATA_PORT &= 0xf0;
    DATA_PORT |= cmd&0x0f;
#endif
    XLCDDelay500ns();
    E_PIN = 1;          // Clock command in
    XLCDDelay500ns();
    E_PIN = 0;
#ifdef UPPER                // Make data nibble input
    TRIS_DATA_PORT |= 0xf0;
#else
    TRIS_DATA_PORT |= 0x0f;
#endif
#endif
    return;
}

/*********************************************************************
 * Function:        char XLCDIsBusy(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          non-zero if LCD controller is ready to accept new
 *                      data or command
 *                  zero otherwise.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
char XLCDIsBusy(void)
{
#if !defined(XLCD_READ_BACK)
    int i = 0;

    for ( i = 0; i < 500; i++ )
        ;
    return 0;
#endif

    RW_PIN = 1;         // Set the control bits for read
    RS_PIN = 0;

    TRIS_RW         = 0;    // All control signals made outputs
    TRIS_RS         = 0;

    XLCDDelay500ns();
    E_PIN = 1;          // Clock in the command
    XLCDDelay500ns();
#ifdef BIT8             // 8-bit interface
    if(DATA_PORT&0x80)  // Read bit 7 (busy bit)
    {               // If high
        E_PIN = 0;      // Reset clock line
        RW_PIN = 0;     // Reset control line
        return 1;       // Return TRUE
    }
    else                // Bit 7 low
    {
        E_PIN = 0;      // Reset clock line
        RW_PIN = 0;     // Reset control line
        return 0;       // Return FALSE
    }
#else                   // 4-bit interface
#ifdef UPPER                // Upper nibble interface
    if(DATA_PORT&0x80)
#else                   // Lower nibble interface
    if(DATA_PORT&0x08)
#endif
    {
        E_PIN = 0;      // Reset clock line
        XLCDDelay500ns();
        E_PIN = 1;      // Clock out other nibble
        XLCDDelay500ns();
        E_PIN = 0;
        RW_PIN = 0;     // Reset control line
        return 1;       // Return TRUE
    }
    else                // Busy bit is low
    {
        E_PIN = 0;      // Reset clock line
        XLCDDelay500ns();
        E_PIN = 1;      // Clock out other nibble
        XLCDDelay500ns();
        E_PIN = 0;
        RW_PIN = 0;     // Reset control line
        return 0;       // Return FALSE
    }
#endif
}

/*********************************************************************
 * Function:        unsigned char XLCDGetAddr(void)
 *
 * PreCondition:    XLCDIsBusy() == FALSE && !defined(XLCD_IS_BLOCKING)
 *
 * Input:           None
 *
 * Output:          Current address byte from LCD
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            The address is read from the character generator
 *                  RAM or display RAM depending on current setup.
 ********************************************************************/
#if defined(XLCD_ENABLE_LCD_READS)
unsigned char XLCDGetAddr(void)
{
    char data;          // Holds the data retrieved from the LCD

    TRIS_RW         = 0;    // All control signals made outputs
    TRIS_RS         = 0;

#if defined(XLCD_IS_BLOCKING)
    while(XLCDIsBusy());      // Wait if LCD busy
#endif


#ifdef BIT8             // 8-bit interface
    RW_PIN = 1;         // Set control bits for the read
    RS_PIN = 0;
    XLCDDelay500ns();
    E_PIN = 1;          // Clock data out of the LCD controller
    XLCDDelay500ns();
    data = DATA_PORT;       // Save the data in the register
    E_PIN = 0;
    RW_PIN = 0;         // Reset the control bits
#else                   // 4-bit interface
    RW_PIN = 1;         // Set control bits for the read
    RS_PIN = 0;
    XLCDDelay500ns();
    E_PIN = 1;          // Clock data out of the LCD controller
    XLCDDelay500ns();
#ifdef UPPER                // Upper nibble interface
    data = DATA_PORT&0xf0;      // Read the nibble into the upper nibble of data
#else                   // Lower nibble interface
    data = (DATA_PORT<<4)&0xf0; // Read the nibble into the upper nibble of data
#endif
    E_PIN = 0;          // Reset the clock
    XLCDDelay500ns();
    E_PIN = 1;          // Clock out the lower nibble
    XLCDDelay500ns();
#ifdef UPPER                // Upper nibble interface
    data |= (DATA_PORT>>4)&0x0f;    // Read the nibble into the lower nibble of data
#else                   // Lower nibble interface
    data |= DATA_PORT&0x0f;     // Read the nibble into the lower nibble of data
#endif
    E_PIN = 0;
    RW_PIN = 0;         // Reset the control lines
#endif
    return (data&0x7f);     // Return the address, Mask off the busy bit
}
#endif

/*********************************************************************
 * Function:        char XLCDGet(void)
 *
 * PreCondition:    XLCDIsBusy() == FALSE && !defined(XLCD_IS_BLOCKING)
 *
 * Input:           None
 *
 * Output:          Current data byte from LCD
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            The data is read from the character generator
 *                  RAM or display RAM depending on current setup.
 ********************************************************************/
#if defined(XLCD_ENABLE_LCD_READS)
char XLCDGet(void)
{
    char data;

    TRIS_RW         = 0;    // All control signals made outputs
    TRIS_RS         = 0;

#if defined(XLCD_IS_BLOCKING)
    while(XLCDIsBusy());      // Wait if LCD busy
#endif

#ifdef BIT8             // 8-bit interface
    RS_PIN = 1;         // Set the control bits
    RW_PIN = 1;
    XLCDDelay500ns();
    E_PIN = 1;          // Clock the data out of the LCD
    XLCDDelay500ns();
    data = DATA_PORT;       // Read the data
    E_PIN = 0;
    RS_PIN = 0;         // Reset the control bits
    RW_PIN = 0;
#else                   // 4-bit interface
    RW_PIN = 1;
    RS_PIN = 1;
    XLCDDelay500ns();
    E_PIN = 1;          // Clock the data out of the LCD
    XLCDDelay500ns();
#ifdef UPPER                // Upper nibble interface
    data = DATA_PORT&0xf0;      // Read the upper nibble of data
#else                   // Lower nibble interface
    data = (DATA_PORT<<4)&0xf0; // read the upper nibble of data
#endif
    E_PIN = 0;          // Reset the clock line
    XLCDDelay500ns();
    E_PIN = 1;          // Clock the next nibble out of the LCD
    XLCDDelay500ns();
#ifdef UPPER                // Upper nibble interface
    data |= (DATA_PORT>>4)&0x0f;    // Read the lower nibble of data
#else                   // Lower nibble interface
    data |= DATA_PORT&0x0f;     // Read the lower nibble of data
#endif
    E_PIN = 0;
    RS_PIN = 0;         // Reset the control bits
    RW_PIN = 0;
#endif
    return(data);           // Return the data byte
}
#endif


void XLCDPutString(char *string)
{
    char v;

    while( v = *string )
    {
#if !defined(XLCD_IS_BLOCKING)
        while(XLCDIsBusy());      // Wait if LCD busy
#endif
        XLCDPut(v);
        string++;
    }
}

void XLCDPutROMString(ROM char *string)
{
    char v;

    while( v = *string )
    {
#if !defined(XLCD_IS_BLOCKING)
        while(XLCDIsBusy());      // Wait if LCD busy
#endif
        XLCDPut(v);
        string++;
    }
}


/*********************************************************************
 * Function:        void XLCDPut(char data)
 *
 * PreCondition:    XLCDInit() is already called AND
 *                  (XLCDIsBusy() == FALSE AND !defined(XLCD_IS_BLOCKING)
 *
 * Input:           data    - Data to be written
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            Data is written to character generator RAM or
 *                  display data RAM depending on how the access is
 *                  setup.
 ********************************************************************/
void XLCDPut(char data)
{
#if defined(XLCD_IS_BLOCKING)
    while(XLCDIsBusy());      // Wait if LCD busy
#endif

    TRIS_RW         = 0;    // All control signals made outputs
    TRIS_RS         = 0;

#ifdef BIT8             // 8-bit interface
    TRIS_DATA_PORT = 0;     // Make port output
    DATA_PORT = data;       // Write data to port
    RS_PIN = 1;         // Set control bits
    RW_PIN = 0;
    XLCDDelay500ns();
    E_PIN = 1;          // Clock data into LCD
    XLCDDelay500ns();
    E_PIN = 0;
    RS_PIN = 0;         // Reset control bits
    TRIS_DATA_PORT = 0xff;      // Make port input
#else                   // 4-bit interface
#ifdef UPPER                // Upper nibble interface
    TRIS_DATA_PORT &= 0x0f;
    DATA_PORT &= 0x0f;
    DATA_PORT |= data&0xf0;
#else                   // Lower nibble interface
    TRIS_DATA_PORT &= 0xf0;
    DATA_PORT &= 0xf0;
    DATA_PORT |= ((data>>4)&0x0f);
#endif
    RS_PIN = 1;         // Set control bits
    RW_PIN = 0;
    XLCDDelay500ns();
    E_PIN = 1;          // Clock nibble into LCD
    XLCDDelay500ns();
    E_PIN = 0;
#ifdef UPPER                // Upper nibble interface
    DATA_PORT &= 0x0f;
    DATA_PORT |= ((data<<4)&0xf0);
#else                   // Lower nibble interface
    DATA_PORT &= 0xf0;
    DATA_PORT |= (data&0x0f);
#endif
    XLCDDelay500ns();
    E_PIN = 1;          // Clock nibble into LCD
    XLCDDelay500ns();
    E_PIN = 0;
#ifdef UPPER                // Upper nibble interface
    TRIS_DATA_PORT |= 0xf0;
#else                   // Lower nibble interface
    TRIS_DATA_PORT |= 0x0f;
#endif
#endif
    return;
}

