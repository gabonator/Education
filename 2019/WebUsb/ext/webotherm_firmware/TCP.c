/*********************************************************************
 *
 *                  TCP Module for Microchip TCP/IP Stack
 *
 *********************************************************************
 * FileName:        TCP.C
 * Dependencies:    string.h
 *                  StackTsk.h
 *                  Helpers.h
 *                  IP.h
 *                  MAC.h
 *                  ARP.h
 *                  Tick.h
 *                  TCP.h
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
 * Nilesh Rajbharti     5/8/01  Original        (Rev 1.0)
 * Nilesh Rajbharti     5/22/02 Rev 2.0 (See version.log for detail)
 * Nilesh Rajbharti     11/1/02 Fixed TCPTick() SYN Retry bug.
 * Nilesh Rajbharti     12/5/02	Modified TCPProcess()
 *                              to include localIP as third param.
 *                              This was done to allow this function
 *                              to calculate checksum correctly.
 * Roy Schofield		10/1/04	TCPConnect() startTick bug fix.
 * Howard Schlunder		1/3/05	Fixed HandleTCPSeg() unexpected 
 * 								discard problem identified by Richard
 *				 				Shelquist.
 * Howard Schlunder		1/16/06	Fixed an imporbable RX checksum bug 
 *								when using a Microchip Ethernet controller)
********************************************************************/
#define THIS_IS_TCP

#include <string.h>

#include "StackTsk.h"
#include "Helpers.h"
#include "IP.h"
#include "MAC.h"
#include "Tick.h"
#include "TCP.h"
#include "usart.h"

/*
 * Max TCP data length is MAC_TX_BUFFER_SIZE - sizeof(TCP_HEADER) -
 * sizeof(IP_HEADER) - sizeof(ETHER_HEADER)
 */
#define MAX_TCP_DATA_LEN    (MAC_TX_BUFFER_SIZE - 54)


/*
 * TCP Timeout value to begin with.
 */
#define TCP_START_TIMEOUT_VAL   ((TICK)TICK_SECOND * (TICK)60)

/*
 * TCP Flags as defined by rfc793
 */
#define FIN     (0x01)
#define SYN     (0x02)
#define RST     (0x04)
#define PSH     (0x08)
#define ACK     (0x10)
#define URG     (0x20)


/*
 * TCP Header def. as per rfc 793.
 */

typedef struct _TCP_HEADER
{
    WORD    SourcePort;
    WORD    DestPort;
    DWORD   SeqNumber;
    DWORD   AckNumber;

    struct
    {
        unsigned int Reserved3      : 4;
        unsigned int Val            : 4;
    } DataOffset;


    union
    {
        struct
        {
            unsigned int flagFIN    : 1;
            unsigned int flagSYN    : 1;
            unsigned int flagRST    : 1;
            unsigned int flagPSH    : 1;
            unsigned int flagACK    : 1;
            unsigned int flagURG    : 1;
            unsigned int Reserved2  : 2;
        } bits;
        BYTE byte;
    } Flags;

    WORD    Window;
    WORD    Checksum;
    WORD    UrgentPointer;

} TCP_HEADER;


/*
 * TCP Options as defined by rfc 793
 */
#define TCP_OPTIONS_END_OF_LIST     (0x00)
#define TCP_OPTIONS_NO_OP           (0x01)
#define TCP_OPTIONS_MAX_SEG_SIZE    (0x02)
typedef struct _TCP_OPTIONS
{
    BYTE        Kind;
    BYTE        Length;
    WORD_VAL    MaxSegSize;
} TCP_OPTIONS;

#define SwapPseudoTCPHeader(h)  (h.TCPLength = swaps(h.TCPLength))

/*
 * Pseudo header as defined by rfc 793.
 */
typedef struct _PSEUDO_HEADER
{
    IP_ADDR SourceAddress;
    IP_ADDR DestAddress;
    BYTE Zero;
    BYTE Protocol;
    WORD TCPLength;
} PSEUDO_HEADER;

/*
 * Local temp port numbers.
 */
static WORD _NextPort;

/*
 * Starting segment sequence number for each new connection.
 */
static DWORD ISS;

/*
 * These are all sockets supported by this TCP.
 */
#ifdef MCHP_C18
// Allow the linker to place the next TCB array into a separate 
// memory bank.  This is needed because the TCB array is very 
// large.
#pragma udata SocketMemory	
#endif
SOCKET_INFO TCB[MAX_SOCKETS];


static void HandleTCPSeg(TCP_SOCKET s,
                         NODE_INFO *remote,
                         TCP_HEADER *h,
                         WORD len);

static void TransmitTCP(NODE_INFO *remote,
                        TCP_PORT localPort,
                        TCP_PORT remotePort,
                        DWORD seq,
                        DWORD ack,
                        BYTE flags,
                        BUFFER buffer,
                        WORD len);

static TCP_SOCKET FindMatchingSocket(TCP_HEADER *h,
                                     NODE_INFO *remote);
static void SwapTCPHeader(TCP_HEADER* header);
static void CloseSocket(SOCKET_INFO* ps);

#define SendTCP(remote, localPort, remotePort, seq, ack, flags)     \
        TransmitTCP(remote, localPort, remotePort, seq, ack, flags, \
                    INVALID_BUFFER, 0)

#define LOCAL_PORT_START_NUMBER (1024)
#define LOCAL_PORT_END_NUMBER   (5000)



/*********************************************************************
 * Function:        void TCPInit(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          TCP is initialized.
 *
 * Side Effects:    None
 *
 * Overview:        Initialize all socket info.
 *
 * Note:            This function is called only one during lifetime
 *                  of the application.
 ********************************************************************/
void TCPInit(void)
{
    TCP_SOCKET s;
    SOCKET_INFO* ps;


    // Initialize all sockets.
    for ( s = 0; s < MAX_SOCKETS; s++ )
    {
        ps = &TCB[s];

        ps->smState             = TCP_CLOSED;
        ps->Flags.bServer       = FALSE;
        ps->Flags.bIsPutReady   = TRUE;
        ps->Flags.bFirstRead    = TRUE;
        ps->Flags.bIsTxInProgress = FALSE;
        ps->Flags.bIsGetReady   = FALSE;
        ps->Flags.bACKValid 	= FALSE;
        ps->TxBuffer            = INVALID_BUFFER;
        ps->TimeOut             = TCP_START_TIMEOUT_VAL;
    }

    _NextPort = LOCAL_PORT_START_NUMBER;
    ISS = 0;
}



/*********************************************************************
 * Function:        TCP_SOCKET TCPListen(TCP_PORT port)
 *
 * PreCondition:    TCPInit() is already called.
 *
 * Input:           port    - A TCP port to be opened.
 *
 * Output:          Given port is opened and returned on success
 *                  INVALID_SOCKET if no more sockets left.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
TCP_SOCKET TCPListen(TCP_PORT port)
{
    TCP_SOCKET s;
    SOCKET_INFO* ps;

    for ( s = 0; s < MAX_SOCKETS; s++ )
    {
        ps = &TCB[s];

        if ( ps->smState == TCP_CLOSED )
        {
            /*
             * We have a CLOSED socket.
             * Initialize it with LISTENing state info.
             */
            ps->smState             = TCP_LISTEN;
            ps->localPort           = port;
            ps->remotePort          = 0;

            /*
             * There is no remote node IP address info yet.
             */
            ps->remote.IPAddr.Val   = 0x00;

            /*
             * If a socket is listened on, it is a SERVER.
             */
            ps->Flags.bServer       = TRUE;

            ps->Flags.bIsGetReady   = FALSE;
            ps->TxBuffer            = INVALID_BUFFER;
            ps->Flags.bIsPutReady   = TRUE;

            return s;
        }
    }
    return INVALID_SOCKET;
}



/*********************************************************************
 * Function:        TCP_SOCKET TCPConnect(NODE_INFO* remote,
 *                                      TCP_PORT remotePort)
 *
 * PreCondition:    TCPInit() is already called.
 *
 * Input:           remote      - Remote node address info
 *                  remotePort  - remote port to be connected.
 *
 * Output:          A new socket is created, connection request is
 *                  sent and socket handle is returned.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            By default this function is not included in
 *                  source.  You must define STACK_CLIENT_MODE to
 *                  be able to use this function.
 ********************************************************************/
#ifdef STACK_CLIENT_MODE
TCP_SOCKET TCPConnect(NODE_INFO *remote, TCP_PORT remotePort)
{
    TCP_SOCKET s;
    SOCKET_INFO* ps;
    BOOL lbFound;


    lbFound = FALSE;
    /*
     * Find an available socket
     */
    for ( s = 0; s < MAX_SOCKETS; s++ )
    {
        ps = &TCB[s];
        if ( ps->smState == TCP_CLOSED )
        {
            lbFound = TRUE;
            break;
        }
    }

    /*
     * If there is no socket available, return error.
     */
    if ( lbFound == FALSE )
        return INVALID_SOCKET;

    /*
     * Each new socket that is opened by this node, gets
     * next sequential port number.
     */
    ps->localPort = ++_NextPort;
    if ( _NextPort > LOCAL_PORT_END_NUMBER )
        _NextPort = LOCAL_PORT_START_NUMBER;

    /*
     * This is a client socket.
     */
    ps->Flags.bServer = FALSE;

    /*
     * This is the port, we are trying to connect to.
     */
    ps->remotePort = remotePort;

    /*
     * Each new socket that is opened by this node, will
     * start with next segment seqeuence number.
     */
    ps->SND_SEQ = ++ISS;
    ps->SND_ACK = 0;

    memcpy((BYTE*)&ps->remote, (const void*)remote, sizeof(ps->remote));

    /*
     * Send SYN message.
     */
    SendTCP(&ps->remote,
            ps->localPort,
            ps->remotePort,
            ps->SND_SEQ,
            ps->SND_ACK,
            SYN);

    ps->smState = TCP_SYN_SENT;
    ps->SND_SEQ++;
	
	// Allow TCPTick() to operate properly
	ps->startTick = TickGet(); 	

    return s;
}
#endif



/*********************************************************************
 * Function:        BOOL TCPIsConnected(TCP_SOCKET s)
 *
 * PreCondition:    TCPInit() is already called.
 *
 * Input:           s       - Socket to be checked for connection.
 *
 * Output:          TRUE    if given socket is connected
 *                  FALSE   if given socket is not connected.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            A socket is said to be connected if it is not
 *                  in LISTEN and CLOSED mode.  Socket may be in
 *                  SYN_RCVD or FIN_WAIT_1 and may contain socket
 *                  data.
 ********************************************************************/
BOOL TCPIsConnected(TCP_SOCKET s)
{
    return ( TCB[s].smState == TCP_EST );
}



/*********************************************************************
 * Function:        void TCPDisconnect(TCP_SOCKET s)
 *
 * PreCondition:    TCPInit() is already called     AND
 *                  TCPIsPutReady(s) == TRUE
 *
 * Input:           s       - Socket to be disconnected.
 *
 * Output:          A disconnect request is sent for given socket.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
void TCPDisconnect(TCP_SOCKET s)
{
    SOCKET_INFO *ps;

    ps = &TCB[s];

    /*
     * If socket is not connected, may be it is already closed
     * or in process of closing.  Since user has called this
     * explicitly, close it forcefully.
     */
    if ( ps->smState != TCP_EST )
    {
        CloseSocket(ps);
        return;
    }


    /*
     * Discard any outstanding data that is to be read.
     */
    TCPDiscard(s);

    /*
     * Send FIN message.
     */
    SendTCP(&ps->remote,
            ps->localPort,
            ps->remotePort,
            ps->SND_SEQ,
            ps->SND_ACK,
            FIN | ACK);

        ps->SND_SEQ++;

    ps->smState = TCP_FIN_WAIT_1;

    return;
}

/*********************************************************************
 * Function:        BOOL TCPFlush(TCP_SOCKET s)
 *
 * PreCondition:    TCPInit() is already called.
 *
 * Input:           s       - Socket whose data is to be transmitted.
 *
 * Output:          All and any data associated with this socket
 *                  is marked as ready for transmission.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
BOOL TCPFlush(TCP_SOCKET s)
{
    SOCKET_INFO *ps;

    ps = &TCB[s];

    // Make sure that this already a TxBuffer assigned to this
    // socket.
    if ( ps->TxBuffer == INVALID_BUFFER )
        return FALSE;

    if ( ps->Flags.bIsPutReady == FALSE )
        return FALSE;

    TransmitTCP(&ps->remote,
                ps->localPort,
                ps->remotePort,
                ps->SND_SEQ,
                ps->SND_ACK,
                ACK,
                ps->TxBuffer,
                ps->TxCount);
    ps->SND_SEQ += (DWORD)ps->TxCount;
    ps->Flags.bIsPutReady       = FALSE;
    ps->Flags.bIsTxInProgress   = FALSE;

#ifdef TCP_NO_WAIT_FOR_ACK
    MACDiscardTx(ps->TxBuffer);
    ps->TxBuffer                = INVALID_BUFFER;
    ps->Flags.bIsPutReady       = TRUE;
#endif

    return TRUE;
}



/*********************************************************************
 * Function:        BOOL TCPIsPutReady(TCP_SOCKET s)
 *
 * PreCondition:    TCPInit() is already called.
 *
 * Input:           s       - socket to test
 *
 * Output:          TRUE if socket 's' is free to transmit
 *                  FALSE if socket 's' is not free to transmit.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            Each socket maintains only transmit buffer.
 *                  Hence until a data packet is acknowledeged by
 *                  remote node, socket will not be ready for
 *                  next transmission.
 *                  All control transmission such as Connect,
 *                  Disconnect do not consume/reserve any transmit
 *                  buffer.
 ********************************************************************/
BOOL TCPIsPutReady(TCP_SOCKET s)
{
    if ( TCB[s].TxBuffer == INVALID_BUFFER )
        return IPIsTxReady();
    else
        return TCB[s].Flags.bIsPutReady;
}




/*********************************************************************
 * Function:        BOOL TCPPut(TCP_SOCKET s, BYTE byte)
 *
 * PreCondition:    TCPIsPutReady() == TRUE
 *
 * Input:           s       - socket to use
 *                  byte    - a data byte to send
 *
 * Output:          TRUE if given byte was put in transmit buffer
 *                  FALSE if transmit buffer is full.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
BOOL TCPPut(TCP_SOCKET s, BYTE byte)
{
    WORD tempTxCount;       // This is a fix for HITECH bug
    SOCKET_INFO* ps;

    ps = &TCB[s];

    if ( ps->TxBuffer == INVALID_BUFFER )
    {
        ps->TxBuffer = MACGetTxBuffer();

        // This function is used to transmit data only.  And every data packet
        // must be ack'ed by remote node.  Until this packet is ack'ed by
        // remote node, we must preserve its content so that we can retransmit
        // if we need to.
        MACReserveTxBuffer(ps->TxBuffer);

        ps->TxCount = 0;

        IPSetTxBuffer(ps->TxBuffer, sizeof(TCP_HEADER));
    }

    /*
     * HITECH does not seem to compare ps->TxCount as it is.
     * Copying it to local variable and then comparing seems to work.
     */
    tempTxCount = ps->TxCount;
    if ( tempTxCount >= MAX_TCP_DATA_LEN )
        return FALSE;

    ps->Flags.bIsTxInProgress = TRUE;

    MACPut(byte);

    // REMOVE
    //tempTxCount = ps->TxCount;
    tempTxCount++;
    ps->TxCount = tempTxCount;

    //ps->TxCount++;
    //tempTxCount = ps->TxCount;
    if ( tempTxCount >= MAX_TCP_DATA_LEN )
        TCPFlush(s);
    //if ( TCB[s].TxCount >= MAX_TCP_DATA_LEN )
    //    TCPFlush(s);

    return TRUE;
}



/*********************************************************************
 * Function:        BOOL TCPDiscard(TCP_SOCKET s)
 *
 * PreCondition:    TCPInit() is already called.
 *
 * Input:           s       - socket
 *
 * Output:          TRUE if socket received data was discarded
 *                  FALSE if socket received data was already
 *                          discarded.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
BOOL TCPDiscard(TCP_SOCKET s)
{
    SOCKET_INFO* ps;

    ps = &TCB[s];

    /*
     * This socket must contain data for it to be discarded.
     */
    if ( !ps->Flags.bIsGetReady )
        return FALSE;

    MACDiscardRx();
    ps->Flags.bIsGetReady = FALSE;

    return TRUE;
}




/*********************************************************************
 * Function:        WORD TCPGetArray(TCP_SOCKET s, BYTE *buffer,
 *                                      WORD count)
 *
 * PreCondition:    TCPInit() is already called     AND
 *                  TCPIsGetReady(s) == TRUE
 *
 * Input:           s       - socket
 *                  buffer  - Buffer to hold received data.
 *                  count   - Buffer length
 *
 * Output:          Number of bytes loaded into buffer.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
WORD TCPGetArray(TCP_SOCKET s, BYTE *buffer, WORD count)
{
    SOCKET_INFO *ps;

    ps = &TCB[s];

    if ( ps->Flags.bIsGetReady )
    {
        if ( ps->Flags.bFirstRead )
        {
            // Position read pointer to begining of correct
            // buffer.
            IPSetRxBuffer(sizeof(TCP_HEADER));

            ps->Flags.bFirstRead = FALSE;
        }

        ps->Flags.bIsTxInProgress = TRUE;

        return MACGetArray(buffer, count);
    }
    else
        return 0;
}



/*********************************************************************
 * Function:        BOOL TCPGet(TCP_SOCKET s, BYTE *byte)
 *
 * PreCondition:    TCPInit() is already called     AND
 *                  TCPIsGetReady(s) == TRUE
 *
 * Input:           s       - socket
 *                  byte    - Pointer to a byte.
 *
 * Output:          TRUE if a byte was read.
 *                  FALSE if byte was not read.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
BOOL TCPGet(TCP_SOCKET s, BYTE *byte)
{
    SOCKET_INFO* ps;

    ps = &TCB[s];

    if ( ps->Flags.bIsGetReady )
    {
        if ( ps->Flags.bFirstRead )
        {
            // Position read pointer to begining of correct
            // buffer.
            IPSetRxBuffer(sizeof(TCP_HEADER));

            ps->Flags.bFirstRead = FALSE;

        }

        if ( ps->RxCount == 0 )
        {
            MACDiscardRx();
            ps->Flags.bIsGetReady = FALSE;
            return FALSE;
        }

        ps->RxCount--;
        *byte = MACGet();
        return TRUE;
    }
    return FALSE;
}



/*********************************************************************
 * Function:        BOOL TCPIsGetReady(TCP_SOCKET s)
 *
 * PreCondition:    TCPInit() is already called.
 *
 * Input:           s       - socket to test
 *
 * Output:          TRUE if socket 's' contains any data.
 *                  FALSE if socket 's' does not contain any data.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
BOOL TCPIsGetReady(TCP_SOCKET s)
{
    /*
     * A socket is said to be "Get" ready when it has already
     * received some data.  Sometime, a socket may be closed,
     * but it still may contain data.  Thus in order to ensure
     * reuse of a socket, caller must make sure that it reads
     * a socket, if is ready.
     */
    return (TCB[s].Flags.bIsGetReady );
}



/*********************************************************************
 * Function:        void TCPTick(void)
 *
 * PreCondition:    TCPInit() is already called.
 *
 * Input:           None
 *
 * Output:          Each socket FSM is executed for any timeout
 *                  situation.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
void TCPTick(void)
{
#if 1       //!defined(TCP_NO_WAIT_FOR_ACK)
    TCP_SOCKET s;
    TICK diffTicks;
    TICK tick;
    SOCKET_INFO* ps;
    DWORD seq;
    BYTE flags;

    flags = 0x00;
    /*
     * Periodically all "not closed" sockets must perform timed operation.
     */
    for ( s = 0; s < MAX_SOCKETS; s++ )
    {
        ps = &TCB[s];

        if ( ps->Flags.bIsGetReady || ps->Flags.bIsTxInProgress )
            continue;


        /*
         * Closed or Passively Listening socket do not care
         * about timeout conditions.
         */
        if ( (ps->smState == TCP_CLOSED) ||
             (ps->smState == TCP_LISTEN &&
              ps->Flags.bServer == TRUE) )
            continue;

        tick = TickGet();

        // Calculate timeout value for this socket.
        diffTicks = TickGetDiff(tick, ps->startTick);

        // If timeout has not occured, do not do anything.
        if ( diffTicks <= ps->TimeOut )
            continue;

        /*
         * All states require retransmission, so check for transmitter
         * availability right here - common for all.
         */
        if ( !IPIsTxReady() )
            return;

        // Restart timeout reference.
        ps->startTick = TickGet();

        // Update timeout value if there is need to wait longer.
        ps->TimeOut <<= 1;

        // This will be one more attempt.
        ps->RetryCount++;

        /*
         * A timeout has occured.  Respond to this timeout condition
         * depending on what state this socket is in.
         */
        switch(ps->smState)
        {
        case TCP_SYN_SENT:
            /*
             * Keep sending SYN until we hear from remote node.
             * This may be for infinite time, in that case
             * caller must detect it and do something.
             * Bug Fix: 11/1/02
             */
            flags = SYN;
            break;

        case TCP_SYN_RCVD:
            /*
             * We must receive ACK before timeout expires.
             * If not, resend SYN+ACK.
             * Abort, if maximum attempts counts are reached.
             */
            if ( ps->RetryCount < MAX_RETRY_COUNTS )
            {
                flags = SYN | ACK;
            }
            else
                CloseSocket(ps);
            break;

        case TCP_EST:
#if !defined(TCP_NO_WAIT_FOR_ACK)
            /*
             * Don't let this connection idle for very long time.
             * If we did not receive or send any message before timeout
             * expires, close this connection.
             */
            if ( ps->RetryCount <= MAX_RETRY_COUNTS )
            {
                if ( ps->TxBuffer != INVALID_BUFFER )
                {
                    MACSetTxBuffer(ps->TxBuffer, 0);
                    MACFlush();
                }
                else
                    flags = ACK;
            }
            else
            {
                // Forget about previous transmission.
                if ( ps->TxBuffer != INVALID_BUFFER )
                    MACDiscardTx(ps->TxBuffer);
                ps->TxBuffer = INVALID_BUFFER;

#endif
                // Request closure.
                flags = FIN | ACK;

                ps->smState = TCP_FIN_WAIT_1;
#if !defined(TCP_NO_WAIT_FOR_ACK)
            }
#endif
            break;

        case TCP_FIN_WAIT_1:
        case TCP_LAST_ACK:
            /*
             * If we do not receive any response to out close request,
             * close it outselves.
             */
            if ( ps->RetryCount > MAX_RETRY_COUNTS )
                CloseSocket(ps);
            else
                flags = FIN;
            break;

        case TCP_CLOSING:
        case TCP_TIMED_WAIT:
            /*
             * If we do not receive any response to out close request,
             * close it outselves.
             */
            if ( ps->RetryCount > MAX_RETRY_COUNTS )
                CloseSocket(ps);
            else
                flags = ACK;
            break;
        }

        if ( flags > 0x00 )
        {
            if ( flags != ACK )
                seq = ps->SND_SEQ++;
            else
                seq = ps->SND_SEQ;

            SendTCP(&ps->remote,
                    ps->localPort,
                    ps->remotePort,
                    seq,
                    ps->SND_ACK,
                    flags);
        }
    }
#else
    return;
#endif
}



/*********************************************************************
 * Function:        BOOL TCPProcess(NODE_INFO* remote,
 *                                  IP_ADDR *localIP,
 *                                  WORD len)
 *
 * PreCondition:    TCPInit() is already called     AND
 *                  TCP segment is ready in MAC buffer
 *
 * Input:           remote      - Remote node info
 *                  len         - Total length of TCP semgent.
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
BOOL TCPProcess(NODE_INFO *remote, IP_ADDR *localIP, WORD len)
{
    TCP_HEADER      TCPHeader;
    PSEUDO_HEADER   pseudoHeader;
    TCP_SOCKET      socket;
    WORD_VAL        checksum;
    BYTE            optionsSize;


    // Retrieve TCP header.
    MACGetArray((BYTE*)&TCPHeader, sizeof(TCPHeader));

    SwapTCPHeader(&TCPHeader);

    // Calculate IP pseudoheader checksum.
    pseudoHeader.SourceAddress      = remote->IPAddr;
    pseudoHeader.DestAddress.v[0]   = localIP->v[0];
    pseudoHeader.DestAddress.v[1]   = localIP->v[1];
    pseudoHeader.DestAddress.v[2]   = localIP->v[2];
    pseudoHeader.DestAddress.v[3]   = localIP->v[3];
    pseudoHeader.Zero               = 0x0;
    pseudoHeader.Protocol           = IP_PROT_TCP;
    pseudoHeader.TCPLength          = len;

    SwapPseudoTCPHeader(pseudoHeader);


    checksum.Val = ~CalcIPChecksum((BYTE*)&pseudoHeader,
                                    sizeof(pseudoHeader));


    // Set TCP packet checksum = pseudo header checksum in MAC RAM.
    IPSetRxBuffer(16);
    MACPut(checksum.v[0]);
	// In case if the end of the RX buffer is reached and a wraparound is needed, set the next address to prevent writing to the wrong address.
    IPSetRxBuffer(17);			
    MACPut(checksum.v[1]);
    IPSetRxBuffer(0);

    // Now calculate TCP packet checksum in NIC RAM - including
    // pesudo header.
    checksum.Val = CalcIPBufferChecksum(len);

    if ( checksum.Val != TCPHeader.Checksum )
    {
        MACDiscardRx();
        return TRUE;
    }

    // Skip over options and retrieve all data bytes.
    optionsSize = (BYTE)((TCPHeader.DataOffset.Val << 2)-
                            sizeof(TCPHeader));
    len = len - optionsSize - sizeof(TCPHeader);

    // Position packet read pointer to start of data area.
    IPSetRxBuffer((TCPHeader.DataOffset.Val << 2));

    // Find matching socket.
    socket = FindMatchingSocket(&TCPHeader, remote);
    if ( socket < INVALID_SOCKET )
    {
        HandleTCPSeg(socket, remote, &TCPHeader, len);
    }
    else
    {
        /*
         * If this is an unknown socket, discard it and
         * send RESET to remote node.
         */
        MACDiscardRx();

        if ( socket == UNKNOWN_SOCKET )
        {

            TCPHeader.AckNumber += len;
            if ( TCPHeader.Flags.bits.flagSYN ||
                 TCPHeader.Flags.bits.flagFIN )
                TCPHeader.AckNumber++;

            SendTCP(remote,
                    TCPHeader.DestPort,
                    TCPHeader.SourcePort,
                    TCPHeader.AckNumber,
                    TCPHeader.SeqNumber,
                    RST);
        }

    }

    return TRUE;
}


/*********************************************************************
 * Function:        static void TransmitTCP(NODE_INFO* remote
 *                                          TCP_PORT localPort,
 *                                          TCP_PORT remotePort,
 *                                          DWORD seq,
 *                                          DWORD ack,
 *                                          BYTE flags,
 *                                          BUFFER buffer,
 *                                          WORD len)
 *
 * PreCondition:    TCPInit() is already called     AND
 *                  TCPIsPutReady() == TRUE
 *
 * Input:           remote      - Remote node info
 *                  localPort   - Source port number
 *                  remotePort  - Destination port number
 *                  seq         - Segment sequence number
 *                  ack         - Segment acknowledge number
 *                  flags       - Segment flags
 *                  buffer      - Buffer to which this segment
 *                                is to be transmitted
 *                  len         - Total data length for this segment.
 *
 * Output:          A TCP segment is assembled and put to transmit.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
static void TransmitTCP(NODE_INFO *remote,
                        TCP_PORT localPort,
                        TCP_PORT remotePort,
                        DWORD tseq,
                        DWORD tack,
                        BYTE flags,
                        BUFFER buffer,
                        WORD len)
{
    WORD_VAL        checkSum;
    TCP_HEADER      header;
    TCP_OPTIONS     options;
    PSEUDO_HEADER   pseudoHeader;

    /*
     * When using SLIP (USART), packet transmission takes some time
     * and hence before sending another packet, we must make sure
     * that, last packet is transmitted.
     * When using ethernet controller, transmission occurs very fast
     * and by the time next packet is transmitted, previous is
     * transmitted and we do not need to check for last packet.
     */
    while( !IPIsTxReady() );

    header.SourcePort           = localPort;
    header.DestPort             = remotePort;
    header.SeqNumber            = tseq;
    header.AckNumber            = tack;
    header.Flags.bits.Reserved2 = 0;
    header.DataOffset.Reserved3 = 0;
    header.Flags.byte           = flags;
    // Receive window = MAC Free buffer size - TCP header (20) - IP header (20)
    //                  - ETHERNET header (14 if using NIC) .
    header.Window               = MACGetFreeRxSize();
#if !defined(STACK_USE_SLIP)
    /*
     * Limit one segment at a time from remote host.
     * This limit increases overall throughput as remote host does not
     * flood us with packets and later retry with significant delay.
     */
    if ( header.Window >= MAC_RX_BUFFER_SIZE )
        header.Window = MAC_RX_BUFFER_SIZE;

    else if ( header.Window > 54 )
    {
        header.Window -= 54;
    }
    else
        header.Window = 0;
#else
    if ( header.Window > 40 )
    {
        header.Window -= 40;
    }
    else
        header.Window = 0;
#endif

    header.Checksum             = 0;
    header.UrgentPointer        = 0;

    SwapTCPHeader(&header);

    len += sizeof(header);

    if ( flags & SYN )
    {
        len += sizeof(options);
        options.Kind = TCP_OPTIONS_MAX_SEG_SIZE;
        options.Length = 0x04;

        // Load MSS in already swapped order.
        options.MaxSegSize.v[0]  = (MAC_RX_BUFFER_SIZE >> 8); // 0x05;
        options.MaxSegSize.v[1]  = (MAC_RX_BUFFER_SIZE & 0xff); // 0xb4;

        header.DataOffset.Val   = (sizeof(header) + sizeof(options)) >> 2;
    }
    else
        header.DataOffset.Val   = sizeof(header) >> 2;


    // Calculate IP pseudoheader checksum.
    pseudoHeader.SourceAddress.v[0] = MY_IP_BYTE1;
    pseudoHeader.SourceAddress.v[1] = MY_IP_BYTE2;
    pseudoHeader.SourceAddress.v[2] = MY_IP_BYTE3;
    pseudoHeader.SourceAddress.v[3] = MY_IP_BYTE4;
    pseudoHeader.DestAddress    = remote->IPAddr;
    pseudoHeader.Zero           = 0x0;
    pseudoHeader.Protocol       = IP_PROT_TCP;
    pseudoHeader.TCPLength      = len;

    SwapPseudoTCPHeader(pseudoHeader);

    header.Checksum = ~CalcIPChecksum((BYTE*)&pseudoHeader,
                        sizeof(pseudoHeader));
    checkSum.Val = header.Checksum;

    if ( buffer == INVALID_BUFFER )
        buffer = MACGetTxBuffer();

    IPSetTxBuffer(buffer, 0);

    // Write IP header.
    IPPutHeader(remote, IP_PROT_TCP, len);
    IPPutArray((BYTE*)&header, sizeof(header));

    if ( flags & SYN )
        IPPutArray((BYTE*)&options, sizeof(options));

    IPSetTxBuffer(buffer, 0);

    checkSum.Val = CalcIPBufferChecksum(len);

    // Update the checksum.
    IPSetTxBuffer(buffer, 16);
    MACPut(checkSum.v[1]);
    MACPut(checkSum.v[0]);
    MACSetTxBuffer(buffer, 0);

    MACFlush();
}



/*********************************************************************
 * Function:        static TCP_SOCKET FindMatchingSocket(TCP_HEADER *h,
 *                                      NODE_INFO* remote)
 *
 * PreCondition:    TCPInit() is already called
 *
 * Input:           h           - TCP Header to be matched against.
 *                  remote      - Node who sent this header.
 *
 * Output:          A socket that matches with given header and remote
 *                  node is searched.
 *                  If such socket is found, its index is returned
 *                  else INVALID_SOCKET is returned.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
static TCP_SOCKET FindMatchingSocket(TCP_HEADER *h, NODE_INFO *remote)
{
    SOCKET_INFO *ps;
    TCP_SOCKET s;
    TCP_SOCKET partialMatch;

    partialMatch = INVALID_SOCKET;

    for ( s = 0; s < MAX_SOCKETS; s++ )
    {
        ps = &TCB[s];

        if ( ps->smState != TCP_CLOSED )
        {
            if ( ps->localPort == h->DestPort )
            {
                if ( ps->smState == TCP_LISTEN )
                    partialMatch = s;

                if ( ps->remotePort == h->SourcePort &&
                     ps->remote.IPAddr.Val == remote->IPAddr.Val )
                {
                        return s;
                }
            }
        }
    }

    ps = &TCB[partialMatch];

    if ( partialMatch != INVALID_SOCKET &&
         ps->smState == TCP_LISTEN )
    {
        memcpy((void*)&ps->remote, (void*)remote, sizeof(*remote));
        //ps->remote              = *remote;
        ps->localPort           = h->DestPort;
        ps->remotePort          = h->SourcePort;
        ps->Flags.bIsGetReady   = FALSE;
        ps->TxBuffer            = INVALID_BUFFER;
        ps->Flags.bIsPutReady   = TRUE;

        return partialMatch;
    }

    if ( partialMatch == INVALID_SOCKET )
        return UNKNOWN_SOCKET;
    else
        return INVALID_SOCKET;
}






/*********************************************************************
 * Function:        static void SwapTCPHeader(TCP_HEADER* header)
 *
 * PreCondition:    None
 *
 * Input:           header      - TCP Header to be swapped.
 *
 * Output:          Given header is swapped.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
static void SwapTCPHeader(TCP_HEADER* header)
{
    header->SourcePort      = swaps(header->SourcePort);
    header->DestPort        = swaps(header->DestPort);
    header->SeqNumber       = swapl(header->SeqNumber);
    header->AckNumber       = swapl(header->AckNumber);
    header->Window          = swaps(header->Window);
    header->Checksum        = swaps(header->Checksum);
    header->UrgentPointer   = swaps(header->UrgentPointer);
}



/*********************************************************************
 * Function:        static void CloseSocket(SOCKET_INFO* ps)
 *
 * PreCondition:    TCPInit() is already called
 *
 * Input:           ps  - Pointer to a socket info that is to be
 *                          closed.
 *
 * Output:          Given socket information is reset and any
 *                  buffer held by this socket is discarded.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
static void CloseSocket(SOCKET_INFO* ps)
{
    if ( ps->TxBuffer != INVALID_BUFFER )
    {
        MACDiscardTx(ps->TxBuffer);
        ps->TxBuffer            = INVALID_BUFFER;
        ps->Flags.bIsPutReady   = TRUE;
    }

    ps->remote.IPAddr.Val = 0x00;
    ps->remotePort = 0x00;
    if ( ps->Flags.bIsGetReady )
    {
        MACDiscardRx();
    }
    ps->Flags.bIsGetReady       = FALSE;
    ps->Flags.bACKValid			= FALSE;
    ps->TimeOut                 = TCP_START_TIMEOUT_VAL;

    ps->Flags.bIsTxInProgress   = FALSE;

    if ( ps->Flags.bServer )
    {
        ps->smState = TCP_LISTEN;
    }
    else
    {
        ps->smState = TCP_CLOSED;
    }
    return;
}



/*********************************************************************
 * Function:        static void HandleTCPSeg(TCP_SOCKET s,
 *                                      NODE_INFO *remote,
 *                                      TCP_HEADER* h,
 *                                      WORD len)
 *
 * PreCondition:    TCPInit() is already called     AND
 *                  TCPProcess() is the caller.
 *
 * Input:           s           - Socket that owns this segment
 *                  remote      - Remote node info
 *                  h           - TCP Header
 *                  len         - Total buffer length.
 *
 * Output:          TCP FSM is executed on given socket with
 *                  given TCP segment.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
static void HandleTCPSeg(TCP_SOCKET s,
                        NODE_INFO *remote,
                        TCP_HEADER *h,
                        WORD len)
{
    DWORD ack;
    DWORD seq;
    DWORD prevAck, prevSeq;
    SOCKET_INFO *ps;
    BYTE flags;


    flags = 0x00;
    ps = &TCB[s];

 	// When you use TCPConnect() to connect to a remote socket, the 
 	// SND_ACK socket parameter needs to be initialized to the first 
 	// sequence number returned by the remote node.
    if(!ps->Flags.bACKValid)
    {
    	ps->SND_ACK = h->SeqNumber;
    	ps->Flags.bACKValid = TRUE;
    }

    /*
     * Remember current seq and ack for our connection so that if
     * we have to silently discard this packet, we can go back to
     * previous ack and seq numbers.
     */
    prevAck = ps->SND_ACK;
    prevSeq = ps->SND_SEQ;

    ack = h->SeqNumber;
    ack += (DWORD)len;
    seq = ps->SND_SEQ;

    /*
     * Clear retry counts and timeout tick counter.
     */
    ps->RetryCount  = 0;
    ps->startTick   = TickGet();
    ps->TimeOut = TCP_START_TIMEOUT_VAL;

	// Handle listening condition
    if ( ps->smState == TCP_LISTEN )
    {
        MACDiscardRx();

        ps->SND_SEQ     = ++ISS;
        ps->SND_ACK     = ++ack;
        seq             = ps->SND_SEQ;
        ++ps->SND_SEQ;
        if ( h->Flags.bits.flagSYN )
        {
            /*
             * This socket has received connection request.
             * Remember calling node, assign next segment seq. number
             * for this potential connection.
             */
            memcpy((void*)&ps->remote, (const void*)remote, sizeof(*remote));
            ps->remotePort  = h->SourcePort;

            /*
             * Grant connection request.
             */
            flags           = SYN | ACK;
            ps->smState     = TCP_SYN_RCVD;

        }
        else
        {
            /*
             * Anything other than connection request is ignored in
             * LISTEN state.
             */
            flags               = RST;
            seq                 = ack;
            ack                 = h->SeqNumber;
            ps->remote.IPAddr.Val = 0x00;
        }

    }
    // State is something other than TCP_LISTEN, handle it.
    else
    {
        /*
         * Reset FSM, if RST is received.
         */
        if ( h->Flags.bits.flagRST )
        {
            MACDiscardRx();
            CloseSocket(ps);
            return;

        }
			// Check to see if the incomming sequence number is what 
			// we expect (last transmitted ACK value).  Throw this packet 
			// away if it is wrong.
		else if ( h->SeqNumber == prevAck )
        {
	        // After receiving a SYNchronization request, we expect an 
	        // ACK to our transmitted SYN
            if ( ps->smState == TCP_SYN_RCVD )
            {
                if ( h->Flags.bits.flagACK )
                {
	                // ACK received as expected, this connection is 
	                // now established
                    ps->SND_ACK = ack;
                    ps->RetryCount = 0;
                    ps->startTick = TickGet();
                    ps->smState = TCP_EST;

					// Check if this first packet has application data 
					// in it.  Make it available if so.
                    if ( len > 0 )
                    {
                        ps->Flags.bIsGetReady   = TRUE;
                        ps->RxCount             = len;
                        ps->Flags.bFirstRead    = TRUE;
                    }
                    else
                        MACDiscardRx();
                }
                else	// No ACK to our SYN
                {
                    MACDiscardRx();
                }
            }
#ifdef STACK_CLIENT_MODE
            // The TCP_SYN_SENT state occurs when an application 
            // calls TCPConnect().  After an initial SYN is sent,
            // we expect a SYN + ACK before establishing the 
            // connection.
            else if ( ps->smState == TCP_SYN_SENT )
            {
	            // Check if this is a SYN packet
                if ( h->Flags.bits.flagSYN )
                {
                    ps->SND_ACK = ++ack;
                    // Check if this is a ACK packet, and if so,
                    // establish the connection
                    if ( h->Flags.bits.flagACK )
                    {
                        flags = ACK;
                        ps->smState = TCP_EST;
                    }
                    // No ACK received yet, expect it next time.
                    else
                    {
	                    // Send another SYNchronization request
                        flags = SYN | ACK;
                        ps->smState = TCP_SYN_RCVD;
                        ps->SND_SEQ = ++seq;
                    }

					// Check for application data and make it 
					// available, if present
                    if ( len > 0 )
                    {
                        ps->Flags.bIsGetReady   = TRUE;
                        ps->RxCount             = len;
                        ps->Flags.bFirstRead    = TRUE;
                    }
                    else	// No application data in this packet
                        MACDiscardRx();
                }
                // No use for (unexpected) non-SYN packets, so discard
                else
                {
                    MACDiscardRx();
                }
            }
#endif
            // Connection is established, closing, or otherwise
            else
            {

				// Save the seq+len value of the packet for our future 
				// ACK transmission, and so out of sequence packets 
				// can be detected in the future.
                ps->SND_ACK = ack;

				// Handle packets received while connection established.
                if ( ps->smState == TCP_EST )
                {
	                // If this packet has the ACK set, mark all 
	                // previous TX packets as no longer needed for 
	                // possible retransmission.
                    if ( h->Flags.bits.flagACK )
                    {
                        if ( ps->TxBuffer != INVALID_BUFFER )
                        {
                            MACDiscardTx(ps->TxBuffer);
                            ps->TxBuffer            = INVALID_BUFFER;
                            ps->Flags.bIsPutReady   = TRUE;
                        }
                    }

					// Check if the remote node is closing the connection
                    if ( h->Flags.bits.flagFIN )
                    {
                        flags = FIN | ACK;
                        seq = ps->SND_SEQ++;
                        ack = ++ps->SND_ACK;
                        ps->smState = TCP_LAST_ACK;
                    }

					// Check if there is any application data in 
					// this packet.
                    if ( len > 0 )
                    {
	                    // There is data.  Make it available if we 
	                    // don't already have data available.
                        if ( !ps->Flags.bIsGetReady )
                        {
                            ps->Flags.bIsGetReady   = TRUE;
                            ps->RxCount             = len;
                            ps->Flags.bFirstRead    = TRUE;

                             // 4/1/02
                            flags = ACK;
                       }
                       // There is data, but we cannot handle it at this time.
                       else
                       {
                            /*
                             * Since we cannot accept this packet,
                             * restore to previous seq and ack.
                             * and do not send anything back.
                             * Host has to resend this packet when
                             * we are ready.
                             */
                            flags = 0x00;
                            ps->SND_SEQ = prevSeq;
                            ps->SND_ACK = prevAck;

                            MACDiscardRx();
                        }
                    }
                    // There is no data in this packet, and thus it 
                    // can be thrown away.
                    else
                    {
                        MACDiscardRx();
                    }


                }
                // Connection is not established; check if we've sent 
                // a FIN and expect our last ACK
                else if ( ps->smState == TCP_LAST_ACK )
                {
                    MACDiscardRx();

                    if ( h->Flags.bits.flagACK )
                    {
                        CloseSocket(ps);
                    }
                }
                else if ( ps->smState == TCP_FIN_WAIT_1 )
                {
                    MACDiscardRx();

                    if ( h->Flags.bits.flagFIN )
                    {
                        flags = ACK;
                        ack = ++ps->SND_ACK;
                        if ( h->Flags.bits.flagACK )
                        {
                            CloseSocket(ps);
                        }
                        else
                        {
                            ps->smState = TCP_CLOSING;
                        }
                    }
                }
                else if ( ps->smState == TCP_CLOSING )
                {
                    MACDiscardRx();

                    if ( h->Flags.bits.flagACK )
                    {
                        CloseSocket(ps);
                    }
                }
            }
        }
        // This packet's sequence number does not match what we were 
        // expecting (the last value we ACKed).  Throw this packet 
        // away.  This may happen if packets are delivered out of order.
        // Not enough memory is available on our PIC or Ethernet 
        // controller to implement a robust stream reconstruction 
        // buffer.  As a result, the remote node will just have to 
        // retransmit its packets starting with the proper sequence number.
        else
        {
            MACDiscardRx();

			// Send a new ACK out in case if the previous one was lost 
			// (ACKs aren't ACKed).  This is required to prevent an 
			// unlikely but possible situation which would cause the 
			// connection to time out if the ACK was lost and the 
			// remote node keeps sending us older data than we are 
			// expecting.
			flags = ACK;	
			ack = prevAck;
        }
    }

    if ( flags > 0x00 )
    {
        SendTCP(remote,
                h->DestPort,
                h->SourcePort,
                seq,
                ack,
                flags);
    }
}



