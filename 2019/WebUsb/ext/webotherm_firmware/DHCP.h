/*********************************************************************
 *
 *                  DHCP Defs for Microchip TCP/IP Stack
 *
 *********************************************************************
 * FileName:        DHCP.h
 * Dependencies:    StackTsk.h
 *                  UDP.h
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
 * Nilesh Rajbharti     3/21/01  Original        (Rev 1.0)
 ********************************************************************/
#ifndef DHCP_H
#define DHCP_H

#include "StackTsk.h"


typedef enum _SM_DHCP
{
    SM_DHCP_INIT,
    SM_DHCP_RESET_WAIT,
    SM_DHCP_BROADCAST,
    SM_DHCP_DISCOVER,
    SM_DHCP_REQUEST,
    SM_DHCP_BIND,
    SM_DHCP_BOUND,
    SM_DHCP_DISABLED,
    SM_DHCP_ABORTED
} SM_DHCP;

#if !defined(THIS_IS_DHCP)
    extern SM_DHCP smDHCPState;
#endif

/*********************************************************************
 * Macro:           void DHCPDisable(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Puts DHCPTask into unhandled state "SM_DHCP_DISABLED"
 *                  and hence DHCP is effictively disabled.
 *
 * Note:            This macro should be called before DHCPTask is called
 *                  or else a UDP port will be kept open and there will
 *                  be no task to process it.
 ********************************************************************/
#define DHCPDisable()       (smDHCPState = SM_DHCP_DISABLED)


/*********************************************************************
 * Function:        void DHCPTask(void)
 *
 * PreCondition:    DHCPInit() is already called AND
 *                  IPGetHeader() is called with
 *                  IPFrameType == IP_PROT_UDP
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Fetches pending UDP packet from MAC receive buffer
 *                  and dispatches it appropriate UDP socket.
 *                  If not UDP socket is matched, UDP packet is
 *                  silently discarded.
 *
 * Note:            Caller must make sure that MAC receive buffer
 *                  access pointer is set to begining of UDP packet.
 *                  Required steps before calling this function is:
 *
 *                  If ( MACIsRxReady() )
 *                  {
 *                      MACGetHeader()
 *                      If MACFrameType == IP
 *                          IPGetHeader()
 *                          if ( IPFrameType == IP_PROT_UDP )
 *                              Call DHCPTask()
 *                  ...
 ********************************************************************/
void DHCPTask(void);


/*********************************************************************
 * Function:        void DHCPAbort(void)
 *
 * PreCondition:    DHCPTask() must have been called at least once.
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Forgets about any previous DHCP attempts and
 *                  closes DHCPSocket.
 *
 * Note:
 ********************************************************************/
void DHCPAbort(void);



/*********************************************************************
 * Macro:           BOOL DHCPIsBound(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          TRUE if DHCP is bound to given configuration
 *                  FALSE if DHCP has yet to be bound.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:
 ********************************************************************/
#define DHCPIsBound()       (DHCPState.bits.bIsBound)

typedef union _DHCP_STATE
{
    struct
    {
        unsigned int bIsBound : 1;
    } bits;
    BYTE Val;
} DHCP_STATE;

#if !defined(THIS_IS_DHCP)
    extern DHCP_STATE DHCPState;
#endif

/*********************************************************************
 * Macro:           void DHCPReset(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Closes any previously opened DHCP socket
 *                  and resets DHCP state machine so that on next
 *                  call to DHCPTask will result in new DHCP request.
 *
 * Note:            None
 ********************************************************************/
void DHCPReset(void);




#endif
