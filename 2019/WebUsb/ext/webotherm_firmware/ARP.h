/*********************************************************************
 *
 *                  ARP Module Defs for Microchip TCP/IP Stack
 *
 *********************************************************************
 * FileName:        ARP.h
 * Dependencies:    Stacktsk.h
 *                  MAC.h
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
 * Author               Date    Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Nilesh Rajbharti     5/1/01  Original        (Rev 1.0)
 * Nilesh Rajbharti     2/9/02  Cleanup
 * Nilesh Rajbharti     5/22/02 Rev 2.0 (See version.log for detail)
 ********************************************************************/
#ifndef ARP_H
#define ARP_H

#include "StackTsk.h"
#include "MAC.h"

/*
 * Following codes are must be used with ARPGet/Put functions.
 */
#define ARP_REPLY       (0x00)
#define ARP_REQUEST     (0x01)
#define ARP_UNKNOWN     (0x02)


/*********************************************************************
 * Function:        BOOL ARPGet(NODE_INFO* remote, BYTE* opCode)
 *
 * PreCondition:    ARP packet is ready in MAC buffer.
 *
 * Input:           remote  - Remote node info
 *                  opCode  - Buffer to hold ARP op code.
 *
 * Output:          TRUE if a valid ARP packet was received.
 *                  FALSE otherwise.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
BOOL    ARPGet(NODE_INFO *remote, BYTE *opCode);


/*********************************************************************
 * Macro:           ARPIsRxReady()
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          TRUE if ARP receive buffer is full.
 *                  FALSE otherwise.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
#define ARPIsTxReady()      MACIsTxReady()



/*********************************************************************
 * Function:        void ARPPut(NODE_INFO* more, BYTE opCode)
 *
 * PreCondition:    MACIsTxReady() == TRUE
 *
 * Input:           remote  - Remote node info
 *                  opCode  - ARP op code to send
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
void    ARPPut(NODE_INFO *remode, BYTE opCode);

#endif


