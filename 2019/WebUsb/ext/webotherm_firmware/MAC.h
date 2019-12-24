/*********************************************************************
 *
 *                  MAC Module Defs for Microchip Stack
 *
 *********************************************************************
 * FileName:        MAC.h
 * Dependencies:    StackTsk.h
 * Processor:       PIC18C
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
 * Author               Date        Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Nilesh Rajbharti     4/27/01     Original        (Rev 1.0)
 * Nilesh Rajbharti     11/27/01    Added SLIP
 * Nilesh Rajbharti     2/9/02      Cleanup
 * Nilesh Rajbharti     5/22/02     Rev 2.0 (See version.log for detail)
 * Howard Schlunder     6/28/04     Added ENC28J60 specific features
 * Howard Schlunder		11/29/04	Added Get/SetLEDConfig macros
 ********************************************************************/

#ifndef MAC_H
#define MAC_H

#include "StackTsk.h"

#define MAC_IP      (0u)
#define MAC_ARP     (0x6u)
#define MAC_UNKNOWN (0x0ffu)

#define INVALID_BUFFER  (0xffu)

/*
 * Microchip Ethernet controller specific MAC items
 */
#if defined(MCHP_MAC)
#include "ENC28J60.h"

// Duplex configuration options
typedef enum _DUPLEX {
	HALF = 0, 
	FULL = 1, 
	USE_PHY = 2
} DUPLEX;

typedef enum _CLK_CONFIG {
	Divide1,
	Divide2,
	Divide3,
	Divide4,
	Divide8
} CLK_CONFIG;
void	MACSetDuplex(DUPLEX DuplexState);
WORD 	CalcIPBufferChecksum(WORD len);

void	MACPowerDown(void);
void 	MACPowerUp(void);
WORD	MACCalcRxChecksum(WORD offset, WORD len);
WORD	MACCalcTxChecksum(WORD offset, WORD len);
void	MACCopyRxToTx(WORD RxOffset, WORD TxOffset, WORD len);
void	WritePHYReg(BYTE Register, WORD Data);
PHYREG	ReadPHYReg(BYTE Register);


/******************************************************************************
 * Macro:        	void SetLEDConfig(WORD NewConfig)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 *
 * Input:           NewConfig - xxx0: Pulse stretching disabled
 *								xxx2: Pulse stretch to 40ms (default)
 *								xxx6: Pulse stretch to 73ms
 *								xxxA: Pulse stretch to 139ms
 *								
 *								xx1x: LEDB - TX
 *								xx2x: LEDB - RX (default)
 *								xx3x: LEDB - collisions
 *								xx4x: LEDB - link
 *								xx5x: LEDB - duplex
 *								xx7x: LEDB - TX and RX
 *								xx8x: LEDB - on
 *								xx9x: LEDB - off
 *								xxAx: LEDB - blink fast
 *								xxBx: LEDB - blink slow
 *								xxCx: LEDB - link and RX
 *								xxDx: LEDB - link and TX and RX
 *								xxEx: LEDB - duplex and collisions
 *
 *								x1xx: LEDA - TX
 *								x2xx: LEDA - RX
 *								x3xx: LEDA - collisions
 *								x4xx: LEDA - link (default)
 *								x5xx: LEDA - duplex
 *								x7xx: LEDA - TX and RX
 *								x8xx: LEDA - on
 *								x9xx: LEDA - off
 *								xAxx: LEDA - blink fast
 *								xBxx: LEDA - blink slow
 *								xCxx: LEDA - link and RX
 *								xDxx: LEDA - link and TX and RX
 *								xExx: LEDA - duplex and collisions
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Writes the value of NewConfig into the PHLCON PHY register.  
 *					The LED pins will beginning outputting the new 
 *					configuration immediately.
 *
 * Note:            
 *****************************************************************************/
#define SetLEDConfig(NewConfig)		WritePHYReg(PHLCON, NewConfig)


/******************************************************************************
 * Macro:        	WORD GetLEDConfig(void)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 *
 * Input:           None
 *
 * Output:          WORD -	xxx0: Pulse stretching disabled
 *							xxx2: Pulse stretch to 40ms (default)
 *							xxx6: Pulse stretch to 73ms
 *							xxxA: Pulse stretch to 139ms
 *								
 *							xx1x: LEDB - TX
 *							xx2x: LEDB - RX (default)
 *							xx3x: LEDB - collisions
 *							xx4x: LEDB - link
 *							xx5x: LEDB - duplex
 *							xx7x: LEDB - TX and RX
 *							xx8x: LEDB - on
 *							xx9x: LEDB - off
 *							xxAx: LEDB - blink fast
 *							xxBx: LEDB - blink slow
 *							xxCx: LEDB - link and RX
 *							xxDx: LEDB - link and TX and RX
 *							xxEx: LEDB - duplex and collisions
 *
 * 							x1xx: LEDA - TX
 *							x2xx: LEDA - RX
 *							x3xx: LEDA - collisions
 *							x4xx: LEDA - link (default)
 *							x5xx: LEDA - duplex
 *							x7xx: LEDA - TX and RX
 *							x8xx: LEDA - on
 *							x9xx: LEDA - off
 *							xAxx: LEDA - blink fast
 *							xBxx: LEDA - blink slow
 *							xCxx: LEDA - link and RX
 *							xDxx: LEDA - link and TX and RX
 *							xExx: LEDA - duplex and collisions
 *
 * Side Effects:    None
 *
 * Overview:        Returns the current value of the PHLCON register.
 *
 * Note:            None
 *****************************************************************************/
#define GetLEDConfig()		ReadPHYReg(PHLCON).Val

#endif


void    MACInit(void);
BOOL    MACIsTxReady(void);

BOOL    MACGetHeader(MAC_ADDR *remote, BYTE* type);
BYTE    MACGet(void);
WORD    MACGetArray(BYTE *val, WORD len);
void    MACDiscardRx(void);

void    MACPutHeader(MAC_ADDR *remote,
                     BYTE type,
                     WORD dataLen);
void    MACPut(BYTE val);
void    MACPutArray(BYTE *val, WORD len);
void    MACFlush(void);
void    MACDiscardTx(BUFFER buffer);

void    MACSetRxBuffer(WORD offset);
void    MACSetTxBuffer(BUFFER buffer, WORD offset);
void    MACReserveTxBuffer(BUFFER buffer);

WORD    MACGetOffset(void);

WORD    MACGetFreeRxSize(void);

#if defined(MCHP_MAC)
#define MACGetRxBuffer()        (0)
#define MACGetTxBuffer()        (0)
#else
#define MACGetRxBuffer()        (NICCurrentRdPtr)
#define MACGetTxBuffer()        (NICCurrentTxBuffer)
#endif

#if     !defined(THIS_IS_MAC_LAYER)
#if     !defined(STACK_USE_SLIP)
extern  BYTE NICCurrentTxBuffer;
extern  BYTE NICCurrentRdPtr;
#else
#define NICCurrentTxBuffer      (0)
#define NICCurrentRdPtr         (0)
#endif
#endif

BOOL	MACIsLinked(void);


#endif
