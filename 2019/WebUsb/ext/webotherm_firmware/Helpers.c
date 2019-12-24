/*********************************************************************
 *
 *                  Helper Functions for Microchip TCP/IP Stack
 *
 *********************************************************************
 * FileName:        Helpers.C
 * Dependencies:    Compiler.h
 *                  Helpers.h
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
 * Nilesh Rajbharti     5/17/01 Original        (Rev 1.0)
 * Nilesh Rajbharti     2/9/02  Cleanup
 * Nilesh Rajbharti     6/25/02 Rewritten CalcIPChecksum() to avoid
 *                              multi-byte shift operation.
 * Howard Schlunder		2/9/05	Added hexatob(), btohexa_high(), and
 *								btohexa_low()
 ********************************************************************/

#include "Compiler.h"
#include "Helpers.h"
#include "MAC.h"


/*********************************************************************
 * Function:        BYTE hexatob(WORD_VAL AsciiChars)
 *
 * PreCondition:    None
 *
 * Input:           Two ascii bytes; each ranged '0'-'9', 'A'-'F', or
 *						'a'-'f'
 *
 * Output:          The resulting packed byte: 0x00-0xFF
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:			None
 ********************************************************************/
BYTE hexatob(WORD_VAL AsciiChars)
{
	// Convert lowercase to uppercase
	if(AsciiChars.byte.MSB > 'F')
		AsciiChars.byte.MSB -= 'a'-'A';
	if(AsciiChars.byte.LSB > 'F')
		AsciiChars.byte.LSB -= 'a'-'A';
	
	// Convert 0-9, A-F to 0x0-0xF
	if(AsciiChars.byte.MSB > '9')
		AsciiChars.byte.MSB -= 'A' - 10;
	else
		AsciiChars.byte.MSB -= '0';
		
	if(AsciiChars.byte.LSB > '9')
		AsciiChars.byte.LSB -= 'A' - 10;
	else
		AsciiChars.byte.LSB -= '0';
	
	// Concatenate
	return (AsciiChars.byte.MSB<<4) |  AsciiChars.byte.LSB;
}

/*********************************************************************
 * Function:        BYTE btohexa_high(BYTE b)
 *
 * PreCondition:    None
 *
 * Input:           One byte ranged 0x00-0xFF
 *
 * Output:          An ascii byte (always uppercase) between '0'-'9' 
 *					or 'A'-'F' that corresponds to the upper 4 bits of
 *					the input byte.
 *					ex: b = 0xAE, btohexa_high() returns 'A'
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:			None
 ********************************************************************/
BYTE btohexa_high(BYTE b)
{
	b >>= 4;
	return (b>0x9) ? b+'A'-10:b+'0';
}

/*********************************************************************
 * Function:        BYTE btohexa_low(BYTE b)
 *
 * PreCondition:    None
 *
 * Input:           One byte ranged 0x00-0xFF
 *
 * Output:          An ascii byte (always uppercase) between '0'-'9' 
 *					or 'A'-'F' that corresponds to the lower 4 bits of
 *					the input byte.
 *					ex: b = 0xAE, btohexa_low() returns 'E'
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:			None
 ********************************************************************/
BYTE btohexa_low(BYTE b)
{
	b &= 0x0F;
	return (b>9) ? b+'A'-10:b+'0';
}


WORD swaps(WORD v)
{
    WORD_VAL t;
    BYTE b;

    t.Val   = v;
    b       = t.v[1];
    t.v[1]  = t.v[0];
    t.v[0]  = b;

    return t.Val;
}


DWORD swapl(DWORD v)
{
    BYTE b;
    DWORD myV;
    DWORD_VAL *myP;

    myV     = v;
    myP     = (DWORD_VAL*)&myV;

    b       = myP->v[3];
    myP->v[3] = myP->v[0];
    myP->v[0] = b;

    b       = myP->v[2];
    myP->v[2] = myP->v[1];
    myP->v[1] = b;

    return myV;

}


WORD CalcIPChecksum(BYTE* buffer, WORD count)
{
    WORD i;
    WORD *val;

    union
    {
        DWORD Val;
        struct
        {
            WORD_VAL LSB;
            WORD_VAL MSB;
        } words;
    } tempSum, sum;

    sum.Val = 0;

    i = count >> 1;
    val = (WORD *)buffer;

    while( i-- )
        sum.Val += *val++;

    if ( count & 1 )
        sum.Val += *(BYTE *)val;

    tempSum.Val = sum.Val;

    while( (i = tempSum.words.MSB.Val) != 0u )
    {
        sum.words.MSB.Val = 0;
        sum.Val = (DWORD)sum.words.LSB.Val + (DWORD)i;
        tempSum.Val = sum.Val;
    }

    return (~sum.words.LSB.Val);
}


/*********************************************************************
 * Function:        WORD CalcIPBufferChecksum(WORD len)
 *
 * PreCondition:    TCPInit() is already called     AND
 *                  MAC buffer pointer set to starting of buffer
 *
 * Input:           len     - Total number of bytes to calculate
 *                          checksum for.
 *
 * Output:          16-bit checksum as defined by rfc 793.
 *
 * Side Effects:    None
 *
 * Overview:        This function performs checksum calculation in
 *                  MAC buffer itself.
 *
 * Note:            None
 ********************************************************************/
#if !defined(MCHP_MAC)
WORD CalcIPBufferChecksum(WORD len)
{
    BOOL lbMSB;
    WORD_VAL checkSum;
    BYTE Checkbyte;

    lbMSB = TRUE;
    checkSum.Val = 0;

    while( len-- )
    {
        Checkbyte = MACGet();

        if ( !lbMSB )
        {
            if ( (checkSum.v[0] = Checkbyte+checkSum.v[0]) < Checkbyte)
            {
                if ( ++checkSum.v[1] == 0 )
                    checkSum.v[0]++;
            }
        }
        else
        {
            if ( (checkSum.v[1] = Checkbyte+checkSum.v[1]) < Checkbyte)
            {
                if ( ++checkSum.v[0] == 0 )
                    checkSum.v[1]++;
            }
        }

        lbMSB = !lbMSB;
    }

    checkSum.v[1] = ~checkSum.v[1];
    checkSum.v[0] = ~checkSum.v[0];
    return checkSum.Val;
}
#endif


#if defined(HITECH_C18)
char *strupr (char *s)
{
    char c;
    char *t;

    t = s;
    while( (c = *t) )
    {
        if ( (c >= 'a' && c <= 'z') )
            *t -= ('a' - 'A');
    t++;
    }
    return s;
}
#endif


#if defined(HITECH_C18)
void *mymemcpy(void * d1, const void * s1, register unsigned char n)
{

    register char *     d;
    register const char *   s;

    s = s1;
    d = d1;
    while(n--)
        *d++ = *s++;
    return d1;
}
#endif
