/*********************************************************************
 *
 *                  UDP Module for Microchip TCP/IP Stack
 *
 *********************************************************************
 * FileName:        UDP.c
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
 *
 * Author               Date    Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Nilesh Rajbharti     3/19/01  Original        (Rev 1.0)
 * Nilesh Rajbharti     2/26/03  Fixed UDPGet and UDPProcess bugs
 *                               as discovered and fixed by John Owen
 *                               of Powerwave.
 *                               1. UDPGet would return FALSE on last good byte
 *                               2. UDPProcess was incorrectly calculating length.
 * Nilesh Rajbharti     5/19/03  Added bFirstRead flag similar to TCP
 *                               to detect very first UDPGet and
 *                               reset MAC Rx pointer to begining of
 *                               UDP data area.  This would ensure that
 *                               if UDP socket has pending Rx data and
 *                               another module resets MAC Rx pointer,
 *                               next UDP socket Get would get correct
 *                               data.
 * Robert Sloan (RSS)    5/29/03 Improved FindMatchingSocket()
 * Nilesh Rajbharti     12/2/03  Added UDPChecksum logic in UDPProcess()
 * Nilesh Rajbharti     12/5/03  Modified UDPProcess() and FindMatchingSocket()
 *                               to include localIP as new parameter.
 *                               This corrects pseudo header checksum
 *                               logic in UDPProcess().
 *                               It also corrects broadcast packet
 *                               matching correct in FindMatchingSocket().
 * Howard Schlunder		1/16/06	 Fixed an imporbable RX checksum bug 
 *								 when using a Microchip Ethernet controller)
 ********************************************************************/

#define THIS_IS_UDP_MODULE

#include <string.h>

#include "StackTsk.h"
#include "Helpers.h"
#include "MAC.h"
#include "IP.h"
#include "UDP.h"

#if !defined(STACK_USE_UDP)
    #error UDP module is not enabled.
    #error If you do not want UDP module, remove this file from your
    #error project to reduce your code size.
    #error If you do want UDP module, make sure that STACK_USE_UDP
    #error is defined in StackTsk.h file.
#endif

UDP_SOCKET_INFO  UDPSocketInfo[MAX_UDP_SOCKETS];
UDP_SOCKET activeUDPSocket;

static UDP_SOCKET FindMatchingSocket(UDP_HEADER *h, NODE_INFO *remoteNode,
                                    IP_ADDR *localIP);

/*********************************************************************
 * Function:        void UDPInit(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Initializes internal variables.
 *
 * Note:
 ********************************************************************/
void        UDPInit(void)
{
    UDP_SOCKET s;

    for ( s = 0; s < MAX_UDP_SOCKETS; s++ )
    {
        UDPSocketInfo[s].localPort  = INVALID_UDP_PORT;
        UDPSocketInfo[s].Flags.bFirstRead = FALSE;
    }
}

/*********************************************************************
 * Function:        UDP_SOCKET UDPOpen(UDP_PORT localPort,
 *                                     NODE_INFO *remoteNode,
 *                                     UDP_PORT remotePort)
 *
 * PreCondition:    UDPInit() is already called
 *
 * Input:           remoteNode - Remote Node info such as MAC and IP
 *                               address
 *                               If NULL, broadcast node address is set.
 *                  remotePort - Remote Port to which to talk to
 *                               If INVALID_UDP_SOCKET, localPort is
 *                               opened for Listen.
 *                  localPort  - A valid port number.
 *
 * Output:          A valid UDP socket that is to be used for
 *                  subsequent UDP communications.
 *
 * Side Effects:    None
 *
 * Overview:        A UDP packet header is assembled and loaded into
 *                  UDP transmit buffer.
 *
 * Note:            This call must always have valid localPort
 *                  value.
  ********************************************************************/
UDP_SOCKET UDPOpen(UDP_PORT localPort,
                   NODE_INFO *remoteNode,
                   UDP_PORT remotePort)
{
    UDP_SOCKET s;
    UDP_SOCKET_INFO *p;


    p = UDPSocketInfo;
    for ( s = 0; s < MAX_UDP_SOCKETS; s++ )
    {
        if ( p->localPort == INVALID_UDP_PORT )
        {
            p->localPort    = localPort;

            /*
             * If remoteNode is supplied, remember it.
             */
            if ( remoteNode )
            {
                memcpy((void*)&p->remoteNode,
                        (const void*)remoteNode,
                        sizeof(p->remoteNode));
            }
            /* else Set broadcast address - TO BE DONE */


            p->remotePort   = remotePort;
            p->TxCount      = 0;
            p->RxCount      = 0;

            /*
             * Mark this socket as active.
             * Once an active socket is set, subsequent operation can be
             * done without explicitely supply socket identifier.
             */
            activeUDPSocket = s;
            return s;
        }
        p++;
    }

    return (UDP_SOCKET)INVALID_UDP_SOCKET;
}




/*********************************************************************
 * Function:        void UDPClose(UDP_SOCKET s)
 *
 * PreCondition:    UDPOpen() is already called
 *
 * Input:           s       - Socket that is to be closed.
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Given socket is marked as available for future
 *                  new communcations.
 *
 * Note:            This function does not affect previous
 *                  active UDP socket designation.
  ********************************************************************/
void UDPClose(UDP_SOCKET s)
{
    UDPSocketInfo[s].localPort = INVALID_UDP_PORT;
}


/*********************************************************************
 * Function:        BOOL UDPPut(BYTE v)
 *
 * PreCondition:    UDPIsPutReady() == TRUE with desired UDP socket
 *                  that is to be loaded.
 *
 * Input:           v       - Data byte to loaded into transmit buffer
 *
 * Output:          TRUE if transmit buffer is still ready to accept
 *                  more data bytes
 *
 *                  FALSE if transmit buffer can no longer accept
 *                  any more data byte.
 *
 * Side Effects:    None
 *
 * Overview:        Given data byte is put into UDP transmit buffer
 *                  and active UDP socket buffer length is incremented
 *                  by one.
 *                  If buffer has become full, FALSE is returned.
 *                  Or else TRUE is returned.
 *
 * Note:            This function loads data into an active UDP socket
 *                  as determined by previous call to UDPIsPutReady()
 ********************************************************************/
BOOL UDPPut(BYTE v)
{
    UDP_SOCKET_INFO *p;
    WORD temp;

    p = &UDPSocketInfo[activeUDPSocket];

    if ( p->TxCount == 0 )
    {
        /*
         * This is the very first byte that is loaded in UDP buffer.
         * Remember what transmit buffer we are loading, and
         * start loading this and next bytes in data area of UDP
         * packet.
         */
        p->TxBuffer = MACGetTxBuffer();

        IPSetTxBuffer(p->TxBuffer, sizeof(UDP_HEADER));

        p->TxOffset = 0;
    }

    /*
     * Load it.
     */
    MACPut(v);

    if ( p->TxOffset++ >= p->TxCount )
        p->TxCount++;

#if 0
    /*
     * Keep track of number of bytes loaded.
     * If total bytes fill up buffer, transmit it.
     */
    p->TxCount++;
#endif

#define SIZEOF_MAC_HEADER       (14)

    /*
     * Depending on what communication media is used, allowable UDP
     * data length will vary.
     */
#if !defined(STACK_USE_SLIP)
#define MAX_UDP_DATA  (MAC_TX_BUFFER_SIZE - SIZEOF_MAC_HEADER - sizeof(IP_HEADER) - sizeof(UDP_HEADER))
#else
#define MAX_UDP_DATA  (MAC_TX_BUFFER_SIZE - sizeof(IP_HEADER) - sizeof(UDP_HEADER) )
#endif

    temp = p->TxCount;
    if ( temp >= MAX_UDP_DATA )
    {
        UDPFlush();
    }
#undef MAX_UDP_DATA

    return TRUE;
}


/*********************************************************************
 * Function:        BOOL UDPFlush(void)
 *
 * PreCondition:    UDPPut() is already called and desired UDP socket
 *                  is set as an active socket by calling
 *                  UDPIsPutReady().
 *
 * Input:           None
 *
 * Output:          All and any data associated with active UDP socket
 *                  buffer is marked as ready for transmission.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            This function transmit all data from
 *                  an active UDP socket.
 ********************************************************************/
void UDPFlush(void)
{
    UDP_HEADER      h;
    UDP_SOCKET_INFO *p;

    // Wait for TX hardware to become available (finish transmitting 
    // any previous packet)
    while( !IPIsTxReady() );

    p = &UDPSocketInfo[activeUDPSocket];

    h.SourcePort        = swaps(p->localPort);
    h.DestinationPort   = swaps(p->remotePort);
    h.Length            = (WORD)((WORD)p->TxCount + (WORD)sizeof(UDP_HEADER));
    // Do not swap h.Length yet.  It is needed in IPPutHeader.
    h.Checksum          = 0x00;

    IPSetTxBuffer(p->TxBuffer, 0);

    /*
     * Load IP header.
     */
    IPPutHeader( &p->remoteNode,
                 IP_PROT_UDP,
                 h.Length );


    // Now swap h.Length.
    h.Length            = swaps(h.Length);

    /*
     * Now load UDP header.
     */
    IPPutArray((BYTE*)&h, sizeof(h));

    /*
     * Update checksum.
     * TO BE IMPLEMENTED
     */

    MACFlush();

    p->TxBuffer         = INVALID_BUFFER;
    p->TxCount          = 0;

}



/*********************************************************************
 * Function:        BOOL UDPIsGetReady(UDP_SOCKET s)
 *
 * PreCondition:    UDPInit() is already called.
 *
 * Input:           A valid UDP socket that is already "Listen"ed on
 *                  or opened.
 *
 * Output:          TRUE if given port contains any data.
 *                  FALSE if given port does not contain any data.
 *
 * Side Effects:    Given socket is set as an active UDP Socket.
 *
 * Overview:        None
 *
 * Note:            This function automatically sets supplied socket
 *                  as an active socket.  Caller need not call
 *                  explicit function UDPSetActiveSocket().  All
 *                  subsequent calls will us this socket as an
 *                  active socket.
 ********************************************************************/
BOOL UDPIsGetReady(UDP_SOCKET s)
{
    activeUDPSocket = s;
    return ( UDPSocketInfo[activeUDPSocket].RxCount > 0 );
}

/*********************************************************************
 * Function:        BOOL UDPGet(BYTE *v)
 *
 * PreCondition:    UDPInit() is already called     AND
 *                  UDPIsGetReady(s) == TRUE
 *
 * Input:           v       - Buffer to receive UDP data byte
 *
 * Output:          TRUE    if a data byte was read
 *                  FALSE   if no data byte was read or available
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            This function fetches data from an active UDP
 *                  socket as set by UDPIsGetReady() call.
 ********************************************************************/
BOOL UDPGet(BYTE *v)
{
    /*
     * CALLER MUST MAKE SURE THAT THERE IS ENOUGH DATA BYTE IN BUFFER
     * BEFORE CALLING THIS FUNCTION.
     * USE UDPIsGetReady() TO CONFIRM.
     */
    if ( UDPSocketInfo[activeUDPSocket].RxCount == 0 )
        return FALSE;

    // If if this very first read to packet, set MAC Rx Pointer to
    // beginig of UDP data area.
    if ( UDPSocketInfo[activeUDPSocket].Flags.bFirstRead )
    {
        UDPSocketInfo[activeUDPSocket].Flags.bFirstRead = FALSE;
        UDPSetRxBuffer(0);
    }

    *v = MACGet();

    UDPSocketInfo[activeUDPSocket].RxCount--;

    if ( UDPSocketInfo[activeUDPSocket].RxCount == 0 )
    {
        MACDiscardRx();
    }

    return TRUE;
}


/*********************************************************************
 * Function:        void UDPDiscard(void)
 *
 * PreCondition:    UDPInit() is already called    AND
 *                  UDPIsGetReady() == TRUE with desired UDP socket.
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            This function discards an active UDP socket content.
 ********************************************************************/
void UDPDiscard(void)
{
    if ( UDPSocketInfo[activeUDPSocket].RxCount )
        MACDiscardRx();

    UDPSocketInfo[activeUDPSocket].RxCount = 0;
}



/*********************************************************************
 * Function:        BOOL UDPProcess(NODE_INFO* remoteNode,
 *                                  IP_ADDR *localIP,
 *                                  WORD len)
 *
 * PreCondition:    UDPInit() is already called     AND
 *                  UDP segment is ready in MAC buffer
 *
 * Input:           remoteNode      - Remote node info
 *                  len             - Total length of UDP semgent.
 *
 * Output:          TRUE if this function has completed its task
 *                  FALSE otherwise
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
/*
 * Pseudo header as defined by rfc 793.
 */
typedef struct _PSEUDO_HEADER
{
    IP_ADDR SourceAddress;
    IP_ADDR DestAddress;
    BYTE Zero;
    BYTE Protocol;
    WORD Length;
} PSEUDO_HEADER;

#define SwapPseudoHeader(h)  (h.Length = swaps(h.Length))

BOOL UDPProcess(NODE_INFO *remoteNode, IP_ADDR *localIP, WORD len)
{
    UDP_HEADER h;
    UDP_SOCKET s;
    PSEUDO_HEADER   pseudoHeader;
    WORD_VAL        checksum;

    /*
     * Retrieve UDP header.
     */
    MACGetArray((BYTE*)&h, sizeof(h));

    h.SourcePort        = swaps(h.SourcePort);
    h.DestinationPort   = swaps(h.DestinationPort);
    h.Length            = swaps(h.Length) - sizeof(UDP_HEADER);;
    h.Checksum          = swaps(h.Checksum);

    // Calculate IP pseudoheader checksum.
    pseudoHeader.SourceAddress      = remoteNode->IPAddr;
    pseudoHeader.DestAddress.v[0]   = localIP->v[0];
    pseudoHeader.DestAddress.v[1]   = localIP->v[1];
    pseudoHeader.DestAddress.v[2]   = localIP->v[2];
    pseudoHeader.DestAddress.v[3]   = localIP->v[3];
    pseudoHeader.Zero               = 0x0;
    pseudoHeader.Protocol           = IP_PROT_UDP;
    pseudoHeader.Length             = len;

    SwapPseudoHeader(pseudoHeader);

    checksum.Val = ~CalcIPChecksum((BYTE*)&pseudoHeader,
                                    sizeof(pseudoHeader));


    // Set UDP packet checksum = pseudo header checksum in MAC RAM.
    IPSetRxBuffer(6);
    MACPut(checksum.v[0]);
	// In case if the end of the RX buffer is reached and a wraparound is needed, set the next address to prevent writing to the wrong address.
    IPSetRxBuffer(7);
    MACPut(checksum.v[1]);
    IPSetRxBuffer(0);

    // Now calculate UDP packet checksum in NIC RAM - including
    // pesudo header.
    checksum.Val = CalcIPBufferChecksum(len);

    if ( checksum.Val != h.Checksum )
    {
        MACDiscardRx();
        return TRUE;
    }


    s = FindMatchingSocket(&h, remoteNode, localIP);
    if ( s == INVALID_UDP_SOCKET )
    {
        /*
         * If there is no matching socket, There is no one to handle
         * this data.  Discard it.
         */
        MACDiscardRx();
    }
    else
    {
        UDPSocketInfo[s].RxCount = h.Length;
        UDPSocketInfo[s].Flags.bFirstRead = TRUE;
    }


    return TRUE;
}


/*********************************************************************
 * Function:        UDP_SOCKET FindMatchingSocket(UDP_HEADER *h,
 *                                NODE_INFO *remoteNode,
 *                                IP_ADDR *localIP)
 *
 * PreCondition:    UDP Segment header has been retrieved from buffer
 *                  The IP header has also been retrieved
 *
 * Input:           remoteNode      - Remote node info from IP header
 *                  h               - header of UDP semgent.
 *
 * Output:          matching UDP socket or INVALID_UDP_SOCKET
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
#define BROADCAST_ADDRESS   (0xffffffffL)
static UDP_SOCKET FindMatchingSocket(UDP_HEADER *h,
                                     NODE_INFO *remoteNode,
                                     IP_ADDR *localIP)
{
    UDP_SOCKET s;
    UDP_SOCKET partialMatch;
    UDP_SOCKET_INFO *p;

    partialMatch = INVALID_UDP_SOCKET;

    p = UDPSocketInfo;
    for ( s = 0; s < MAX_UDP_SOCKETS; s++ )
    {
        /*
         * This packet is said to be matching with current socket
         * 1. If its destination port matches with our local port.
         * 2. This socket does not have any data pending.
         * 3. Packet source IP address matches with socket remote IP address.
         *    OR this socket had transmitted packet with destination address
         *       as broadcast.
         */
        if ( p->localPort == h->DestinationPort )
        {
            if ( (p->remotePort == h->SourcePort) && (p->RxCount == 0L) )
            {
                if ( (p->remoteNode.IPAddr.Val == remoteNode->IPAddr.Val) ||
                     (localIP->Val == BROADCAST_ADDRESS) )
                {
                    return s;
                }
            }

            partialMatch = s;
        }
        p++;
    }

    if ( partialMatch != INVALID_UDP_SOCKET )
    {
        p = &UDPSocketInfo[partialMatch];

        memcpy((void*)&p->remoteNode,
                (const void*)remoteNode, sizeof(p->remoteNode) );

        p->remotePort = h->SourcePort;
    }
    return partialMatch;
}



