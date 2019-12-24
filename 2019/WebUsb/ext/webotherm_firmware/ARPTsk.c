/*********************************************************************
 *
 *                  ARP Server Module for Microchip TCP/IP Stack
 *
 *********************************************************************
 * FileName:        ARPTsk.c
 * Dependencies:    Compiler.h
 *                  string.h
 *                  ARP.h
 *                  ARPTsk.h
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
 * Nilesh Rajbharti     8/20/01 Original        (Rev 1.0)
 * Nilesh Rajbharti     2/9/02  Cleanup
 * Nilesh Rajbharti     5/22/02 Rev 2.0 (See version.log for detail)
 ********************************************************************/

#include "Compiler.h"
#include <string.h>

#include "ARP.h"
#include "ARPTsk.h"

/*
 * ARP Task FSM States
 */
typedef enum _ARP_STATE
{
    SM_ARP_IDLE,
    SM_ARP_REPLY
} ARP_STATE;


/*
 * This ARP task caches one ARP response.
 */
static ARP_STATE smARP;

#ifdef STACK_CLIENT_MODE
static NODE_INFO Cache;
#endif


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
void ARPInit(void)
{
    smARP = SM_ARP_IDLE;

#ifdef STACK_CLIENT_MODE
    Cache.MACAddr.v[0] = 0xff;
    Cache.MACAddr.v[1] = 0xff;
    Cache.MACAddr.v[2] = 0xff;
    Cache.MACAddr.v[3] = 0xff;
    Cache.MACAddr.v[4] = 0xff;
    Cache.MACAddr.v[5] = 0xff;

	Cache.IPAddr.Val = 0x0;
#endif
}



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
BOOL ARPProcess(void)
{
    NODE_INFO remoteNode;
    BYTE opCode;

    switch(smARP)
    {
    case SM_ARP_IDLE:
        if ( !ARPGet(&remoteNode, &opCode) )
            break;

        if ( opCode == ARP_REPLY )
        {
#ifdef STACK_CLIENT_MODE
            Cache.MACAddr.v[0] = remoteNode.MACAddr.v[0];
            Cache.MACAddr.v[1] = remoteNode.MACAddr.v[1];
            Cache.MACAddr.v[2] = remoteNode.MACAddr.v[2];
            Cache.MACAddr.v[3] = remoteNode.MACAddr.v[3];
            Cache.MACAddr.v[4] = remoteNode.MACAddr.v[4];
            Cache.MACAddr.v[5] = remoteNode.MACAddr.v[5];

            Cache.IPAddr.Val = remoteNode.IPAddr.Val;
#endif
            break;
        }
        else
            smARP = SM_ARP_REPLY;

    default:
        if ( ARPIsTxReady() )
        {
            ARPPut(&remoteNode, ARP_REPLY);
            smARP = SM_ARP_IDLE;
        }
        else
            return FALSE;
        break;
    }
    return TRUE;
}


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
 * Note:            This function is available only when
 *                  STACK_CLIENT_MODE is defined.
 ********************************************************************/
#ifdef STACK_CLIENT_MODE
void ARPResolve(IP_ADDR *IPAddr)
{
    NODE_INFO remoteNode;

    remoteNode.IPAddr = *IPAddr;

    ARPPut(&remoteNode, ARP_REQUEST);
}
#endif



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
#ifdef STACK_CLIENT_MODE
BOOL ARPIsResolved(IP_ADDR *IPAddr, MAC_ADDR *MACAddr)
{
    if ( (Cache.IPAddr.Val == IPAddr->Val) ||
         (Cache.IPAddr.v[0] == MY_GATE_BYTE1 &&
          Cache.IPAddr.v[1] == MY_GATE_BYTE2 &&
          Cache.IPAddr.v[2] == MY_GATE_BYTE3 &&
          Cache.IPAddr.v[3] == MY_GATE_BYTE4) )
    {
        *MACAddr = Cache.MACAddr;
        return TRUE;
    }
    return FALSE;
}
#endif

