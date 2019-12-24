/*********************************************************************
 *
 *                  ARP Module for Microchip TCP/IP Stack
 *
 *********************************************************************
 * FileName:        ARP.c
 * Dependencies:    string.h
 *                  stacktsk.h
 *                  helpers.h
 *                  arp.h
 *                  mac.h
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
 * Nilesh Rajbharti     5/1/01  Original        (Rev 1.0)
 * Nilesh Rajbharti     2/9/02  Cleanup
 * Nilesh Rajbharti     5/22/02 Rev 2.0 (See version.log for detail)
 ********************************************************************/
#include <string.h>

#include "StackTsk.h"
#include "Helpers.h"
#include "ARP.h"
#include "MAC.h"

/*
 * ARP Operation codes.
 */
#define ARP_OPERATION_REQ       0x01u
#define ARP_OPERATION_RESP      0x02u

/*
 * ETHERNET packet type as defined by IEEE 802.3
 */
#define HW_ETHERNET             (0x0001u)
#define ARP_IP                  (0x0800u)


/*
 * ARP packet
 */
typedef struct _ARP_PACKET
{
    WORD        HardwareType;
    WORD        Protocol;
    BYTE        MACAddrLen;
    BYTE        ProtocolLen;
    WORD        Operation;
    MAC_ADDR    SenderMACAddr;
    IP_ADDR     SenderIPAddr;
    MAC_ADDR    TargetMACAddr;
    IP_ADDR     TargetIPAddr;
} ARP_PACKET;

static void SwapARPPacket(ARP_PACKET *p);



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
BOOL ARPGet(NODE_INFO *remote, BYTE *opCode)
{
    ARP_PACKET packet;

    MACGetArray((BYTE*)&packet, sizeof(packet));

    MACDiscardRx();

    SwapARPPacket(&packet);

    if ( packet.HardwareType != HW_ETHERNET     ||
         packet.MACAddrLen != sizeof(MAC_ADDR)  ||
         packet.ProtocolLen != sizeof(IP_ADDR) )
         return FALSE;

    if ( packet.Operation == ARP_OPERATION_RESP )
        *opCode = ARP_REPLY;
    else if ( packet.Operation == ARP_OPERATION_REQ )
        *opCode = ARP_REQUEST;
    else
    {
        *opCode = ARP_UNKNOWN;
        return FALSE;
    }

    if ( (packet.TargetIPAddr.v[0] == MY_IP_BYTE1) &&
         (packet.TargetIPAddr.v[1] == MY_IP_BYTE2) &&
         (packet.TargetIPAddr.v[2] == MY_IP_BYTE3) &&
         (packet.TargetIPAddr.v[3] == MY_IP_BYTE4) )
    {
        remote->MACAddr     = packet.SenderMACAddr;
        remote->IPAddr      = packet.SenderIPAddr;
        return TRUE;
    }
    else
        return FALSE;
}


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
void ARPPut(NODE_INFO *remote,
            BYTE opCode)
{
    ARP_PACKET packet;

    packet.HardwareType             = HW_ETHERNET;
    packet.Protocol                 = ARP_IP;
    packet.MACAddrLen               = sizeof(MAC_ADDR);
    packet.ProtocolLen              = sizeof(IP_ADDR);

    if ( opCode == ARP_REQUEST )
    {
        packet.Operation            = ARP_OPERATION_REQ;
        packet.TargetMACAddr.v[0]   = 0xff;
        packet.TargetMACAddr.v[1]   = 0xff;
        packet.TargetMACAddr.v[2]   = 0xff;
        packet.TargetMACAddr.v[3]   = 0xff;
        packet.TargetMACAddr.v[4]   = 0xff;
        packet.TargetMACAddr.v[5]   = 0xff;
    }
    else
    {
        packet.Operation            = ARP_OPERATION_RESP;
        packet.TargetMACAddr        = remote->MACAddr;
    }

    packet.SenderMACAddr.v[0]       = MY_MAC_BYTE1;
    packet.SenderMACAddr.v[1]       = MY_MAC_BYTE2;
    packet.SenderMACAddr.v[2]       = MY_MAC_BYTE3;
    packet.SenderMACAddr.v[3]       = MY_MAC_BYTE4;
    packet.SenderMACAddr.v[4]       = MY_MAC_BYTE5;
    packet.SenderMACAddr.v[5]       = MY_MAC_BYTE6;

    packet.SenderIPAddr.v[0]        = MY_IP_BYTE1;
    packet.SenderIPAddr.v[1]        = MY_IP_BYTE2;
    packet.SenderIPAddr.v[2]        = MY_IP_BYTE3;
    packet.SenderIPAddr.v[3]        = MY_IP_BYTE4;


    /*
     * Check to see if target is on same subnet, if not, find
     * Gateway MAC.
     * Once we get Gateway MAC, all access to remote host will
     * go through Gateway.
     */
    if (((packet.SenderIPAddr.v[0] ^ remote->IPAddr.v[0]) &
                                                MY_MASK_BYTE1) ||
        ((packet.SenderIPAddr.v[1] ^ remote->IPAddr.v[1]) &
                                                MY_MASK_BYTE2) ||
        ((packet.SenderIPAddr.v[2] ^ remote->IPAddr.v[2]) &
                                                MY_MASK_BYTE3) ||
        ((packet.SenderIPAddr.v[3] ^ remote->IPAddr.v[3]) &
                                                MY_MASK_BYTE4) )
    {
        packet.TargetIPAddr.v[0] = MY_GATE_BYTE1;
        packet.TargetIPAddr.v[1] = MY_GATE_BYTE2;
        packet.TargetIPAddr.v[2] = MY_GATE_BYTE3;
        packet.TargetIPAddr.v[3] = MY_GATE_BYTE4;
    }
    else
        packet.TargetIPAddr             = remote->IPAddr;

    SwapARPPacket(&packet);

    MACPutHeader(&packet.TargetMACAddr, MAC_ARP, sizeof(packet));

    MACPutArray((BYTE*)&packet, sizeof(packet));

    MACFlush();
}


/*********************************************************************
 * Function:        static void SwapARPPacket(ARP_PACKET* p)
 *
 * PreCondition:    None
 *
 * Input:           p   - ARP packet to be swapped.
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
static void SwapARPPacket(ARP_PACKET *p)
{
    p->HardwareType     = swaps(p->HardwareType);
    p->Protocol         = swaps(p->Protocol);
    p->Operation        = swaps(p->Operation);
}
