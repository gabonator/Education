/*********************************************************************
 *
 *                  ARP Server Defs for Microchip TCP/IP Stack
 *
 *********************************************************************
 * FileName:        ARPTsk.h
 * Dependencies:    StackTsk.h
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
 * Nilesh Rajbharti     8/20/01 Original        (Rev 1.0)
 * Nilesh Rajbharti     2/9/02  Cleanup
 * Nilesh Rajbharti     5/22/02 Rev 2.0 (See version.log for detail)
 ********************************************************************/

#ifndef ARP_TSK_H
#define ARP_TSK_H

#include "StackTsk.h"
#include "MAC.h"


/*********************************************************************
 * Function:        void ARPInit(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          ARP Cache is initialized.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
void ARPInit(void);


/*********************************************************************
 * Function:        BOOL ARPProcess(void)
 *
 * PreCondition:    ARP packet is ready in MAC buffer.
 *
 * Input:           None
 *
 * Output:          ARP FSM is executed.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
BOOL ARPProcess(void);


/*********************************************************************
 * Function:        void ARPResolve(IP_ADDR* IPAddr)
 *
 * PreCondition:    None
 *
 * Input:           IPAddr  - IP Address to be resolved.
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        An ARP request is sent.
 *
 * Note:
 ********************************************************************/
void ARPResolve(IP_ADDR *IPAddr);


/*********************************************************************
 * Function:        BOOL ARPIsResolved(IP_ADDR* IPAddr,
 *                                      MAC_ADDR *MACAddr)
 *
 * PreCondition:    None
 *
 * Input:           IPAddr      - IPAddress to be resolved.
 *                  MACAddr     - Buffer to hold corresponding
 *                                MAC Address.
 *
 * Output:          TRUE if given IP Address has been resolved.
 *                  FALSE otherwise.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            This function is available only when
 *                  STACK_CLIENT_MODE is defined.
 ********************************************************************/
BOOL ARPIsResolved(IP_ADDR *IPAddr, MAC_ADDR *MACAddr);



#endif
