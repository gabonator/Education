/*********************************************************************
 *
 *                  ICMP Module for Microchip TCP/IP Stack
 *
 *********************************************************************
 * FileName:        ICMP.C
 * Dependencies:    ICMP.h
 *                  string.h
 *                  StackTsk.h
 *                  Helpers.h
 *                  IP.h
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
 *
 * Author               Date    Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Nilesh Rajbharti     4/30/01 Original        (Rev 1.0)
 * Nilesh Rajbharti     2/9/02  Cleanup
 * Nilesh Rajbharti     5/22/02 Rev 2.0 (See version.log for detail)
 * Howard Schlunder		9/9/04	Added ENC28J60 DMA checksum support
 * Howard Schlunder		1/5/06	Increased DMA checksum efficiency
 ********************************************************************/

#include <string.h>
#include "StackTsk.h"
#include "Helpers.h"
#include "ICMP.h"
#include "IP.h"
#include "MAC.h"

#if !defined(STACK_USE_ICMP)
#error You have selected to not include ICMP.  Remove this file from \
       your project to reduce code size.
#endif



/*
 * ICMP packet definition
 */
typedef struct _ICMP_PACKET
{
    BYTE    Type;
    BYTE    Code;
    WORD    Checksum;
    WORD    Identifier;
    WORD    SequenceNumber;
    BYTE    Data[MAX_ICMP_DATA];
} ICMP_PACKET;
#define ICMP_HEADER_SIZE    (sizeof(ICMP_PACKET) - MAX_ICMP_DATA)

static void SwapICMPPacket(ICMP_PACKET* p);


/*********************************************************************
 * Function:        BOOL ICMPGet(ICMP_CODE *code,
 *                              BYTE *data,
 *                              BYTE *len,
 *                              WORD *id,
 *                              WORD *seq)
 *
 * PreCondition:    MAC buffer contains ICMP type packet.
 *
 * Input:           code    - Buffer to hold ICMP code value
 *                  data    - Buffer to hold ICMP data
 *                  len     - Buffer to hold ICMP data length
 *                  id      - Buffer to hold ICMP id
 *                  seq     - Buffer to hold ICMP seq
 *
 * Output:          TRUE if valid ICMP packet was received
 *                  FALSE otherwise.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
BOOL ICMPGet(ICMP_CODE *code,
             BYTE *data,
             BYTE *len,
             WORD *id,
             WORD *seq)
{
    ICMP_PACKET packet;
    WORD CalcChecksum;
    WORD ReceivedChecksum;
#if !defined(MCHP_MAC)
    WORD checksums[2];
#endif

    // Obtain the ICMP Header
    MACGetArray((BYTE*)&packet, ICMP_HEADER_SIZE);


#if defined(MCHP_MAC)
	// Calculate the checksum using the Microchip MAC's DMA module
	// The checksum data includes the precomputed checksum in the 
	// header, so a valid packet will always have a checksum of 
	// 0x0000 if the packet is not disturbed.
	ReceivedChecksum = 0x0000;
	CalcChecksum = MACCalcRxChecksum(0+sizeof(IP_HEADER), *len);
#endif

	// Obtain the ICMP data payload
    *len -= ICMP_HEADER_SIZE;
    MACGetArray(data, *len);

#if !defined(MCHP_MAC)
	// Calculte the checksum in local memory without hardware help
    ReceivedChecksum = packet.Checksum;
    packet.Checksum = 0;

    checksums[0] = ~CalcIPChecksum((BYTE*)&packet, ICMP_HEADER_SIZE);
    checksums[1] = ~CalcIPChecksum(data, *len);
    
    CalcChecksum = CalcIPChecksum((BYTE*)checksums, 2 * sizeof(WORD));
#endif


    SwapICMPPacket(&packet);

    *code = packet.Type;
    *id = packet.Identifier;
    *seq = packet.SequenceNumber;

    return ( CalcChecksum == ReceivedChecksum );
}

/*********************************************************************
 * Function:        void ICMPPut(NODE_INFO *remote,
 *                               ICMP_CODE code,
 *                               BYTE *data,
 *                               BYTE len,
 *                               WORD id,
 *                               WORD seq)
 *
 * PreCondition:    ICMPIsTxReady() == TRUE
 *
 * Input:           remote      - Remote node info
 *                  code        - ICMP_ECHO_REPLY or ICMP_ECHO_REQUEST
 *                  data        - Data bytes
 *                  len         - Number of bytes to send
 *                  id          - ICMP identifier
 *                  seq         - ICMP sequence number
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Note:            A ICMP packet is created and put on MAC.
 *
 ********************************************************************/
void ICMPPut(NODE_INFO *remote,
             ICMP_CODE code,
             BYTE *data,
             BYTE len,
             WORD id,
             WORD seq)
{
    ICMP_PACKET	packet;
    WORD ICMPLen;
	
	ICMPLen = ICMP_HEADER_SIZE + (WORD)len;

    packet.Code             = 0;
    packet.Type             = code;
    packet.Checksum         = 0;
    packet.Identifier       = id;
    packet.SequenceNumber   = seq;

    memcpy((void*)packet.Data, (void*)data, len);

    SwapICMPPacket(&packet);

#if !defined(MCHP_MAC)
    packet.Checksum         = CalcIPChecksum((BYTE*)&packet,
                                    ICMPLen);
#endif

    IPPutHeader(remote,
                IP_PROT_ICMP,
                (WORD)(ICMP_HEADER_SIZE + len));

    IPPutArray((BYTE*)&packet, ICMPLen);

#if defined(MCHP_MAC)
    // Calculate and write the ICMP checksum using the Microchip MAC's DMA
	packet.Checksum = MACCalcTxChecksum(sizeof(IP_HEADER), ICMPLen);
	IPSetTxBuffer(0, 2);
	MACPutArray((BYTE*)&packet.Checksum, 2);
#endif


    MACFlush();
}

/*********************************************************************
 * Function:        void SwapICMPPacket(ICMP_PACKET* p)
 *
 * PreCondition:    None
 *
 * Input:           p - ICMP packet header
 *
 * Output:          ICMP packet is swapped
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
static void SwapICMPPacket(ICMP_PACKET* p)
{
    p->Identifier           = swaps(p->Identifier);
    p->SequenceNumber       = swaps(p->SequenceNumber);
    p->Checksum             = swaps(p->Checksum);
}
