/*********************************************************************
 *
 *                  TFTP Client module for Microchip TCP/IP Stack
 *
 *********************************************************************
 * FileName:        TFTPc.c
 * Dependencies:    TFTPc.h
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
 * Nilesh Rajbharti     8/5/03  Original        (Rev 1.0)
 ********************************************************************/
#if defined(WIN32)
    #include <stdio.h>
    #define TFTP_DEBUG
#endif
    #define TFTP_DEBUG

#include "tftpc.h"
#include "arptsk.h"
#include "tick.h"

#if !defined(STACK_USE_TFTP_CLIENT)
    #error TFTP Client module is not enabled.
    #error If you do not want TFTP Client module, remove this file from your
    #error project to reduce your code size.
    #error If you do want TFTP Client module, make sure that STACK_USE_TFTP_CLIENT
    #error is defined in StackTsk.h file.
#endif


#define TFTP_CLIENT_PORT        65352L       // Some unique port on this
                                            // device.
#define TFTP_SERVER_PORT        (69L)
#define TFTP_BLOCK_SIZE         (0x200L)     // 512 bytes
#define TFTP_BLOCK_SIZE_MSB     (0x02)

typedef enum _TFTP_STATE
{
    SM_TFTP_WAIT = 0,
    SM_TFTP_READY,
    SM_TFTP_WAIT_FOR_DATA,
    SM_TFTP_WAIT_FOR_ACK,
    SM_TFTP_DUPLICATE_ACK,
    SM_TFTP_SEND_ACK,
    SM_TFTP_SEND_LAST_ACK
} TFTP_STATE;

typedef enum _TFTP_OPCODE
{
    TFTP_OPCODE_RRQ = 1,         // Get
    TFTP_OPCODE_WRQ,            // Put
    TFTP_OPCODE_DATA,           // Actual data
    TFTP_OPCODE_ACK,            // Ack for Get/Put
    TFTP_OPCODE_ERROR           // Error
} TFTP_OPCODE;



UDP_SOCKET _tftpSocket;         // TFTP Socket for TFTP server link
WORD _tftpError;

static union _MutExVar
{
    struct
    {
        NODE_INFO _hostInfo;
    } group1;

    struct
    {
        WORD_VAL _tftpBlockNumber;
        WORD_VAL _tftpDuplicateBlock;
        WORD_VAL _tftpBlockLength;
    } group2;
} MutExVar;     // Mutually Exclusive variable groups to conserve RAM.


static TFTP_STATE _tftpState;
static BYTE _tftpRetries;
static TICK _tftpStartTick;
static union
{
    struct
    {
        unsigned int bIsFlushed : 1;
        unsigned int bIsAcked : 1;
        unsigned int bIsClosed : 1;
        unsigned int bIsClosing : 1;
        unsigned int bIsReading : 1;
    } bits;
    BYTE Val;
} _tftpFlags;


// Private helper functions
static void _TFTPSendFileName(TFTP_OPCODE command, char *fileName);
static void _TFTPSendAck(WORD_VAL blockNumber);

// Blank out DEBUG statements if not enabled.
#if defined(TFTP_DEBUG)
    #define DEBUG(a)        a
#else
    #define DEBUG(a)
#endif


/*********************************************************************
 * Function:        void TFTPOpen(IP_ADDR *host)
 *
 * PreCondition:    UDP module is already initialized
 *                  and at least one UDP socket is available.
 *
 * Input:           host        - IP address of remote TFTP server
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Initiates ARP for given host and prepares
 *                  TFTP module for next sequence of function calls.
 *
 * Note:            Use TFTPIsOpened() to check if a connection was
 *                  successfully opened or not.
 *
 ********************************************************************/
void TFTPOpen(IP_ADDR *host)
{
    DEBUG(printf("Opening a connection..."));

    // Remember this address locally.
    MutExVar.group1._hostInfo.IPAddr.Val = host->Val;

    // Initiate ARP resolution.
    ARPResolve(&MutExVar.group1._hostInfo.IPAddr);

    // Wait for ARP to get resolved.
    _tftpState = SM_TFTP_WAIT;

    // Mark this as start tick to detect timeout condition.
    _tftpStartTick = TickGet();

    // Forget about all previous attempts.
    _tftpRetries = 1;

}



/*********************************************************************
 * Function:        TFTP_RESULT TFTPIsOpened(void)
 *
 * PreCondition:    TFTPOpen() is already called.
 *
 * Input:           None
 *
 * Output:          TFTP_OK if previous call to TFTPOpen is complete
 *
 *                  TFTP_TIMEOUT if remote host did not respond to
 *                          previous ARP request.
 *
 *                  TFTP_NOT_READY if remote has still not responded
 *                          and timeout has not expired.
 *
 * Side Effects:    None
 *
 * Overview:        Waits for ARP reply and opens a UDP socket
 *                  to perform further TFTP operations.
 *
 * Note:            Once opened, application may keep TFTP socket
 *                  open and future TFTP operations.
 *                  If TFTPClose() is called to close the connection
 *                  TFTPOpen() must be called again before performing
 *                  any other TFTP operations.
 ********************************************************************/
TFTP_RESULT TFTPIsOpened(void)
{
    switch(_tftpState)
    {
    default:
        DEBUG(printf("Resolving remote IP...\n"));

        // Check to see if adddress is resolved.
        if ( ARPIsResolved(&MutExVar.group1._hostInfo.IPAddr,
                           &MutExVar.group1._hostInfo.MACAddr) )
        {
            _tftpSocket = UDPOpen(TFTP_CLIENT_PORT,
                                  &MutExVar.group1._hostInfo,
                                  TFTP_SERVER_PORT);
            _tftpState = SM_TFTP_READY;
        }
        else
            break;

    case SM_TFTP_READY:
        // Wait for UDP to be ready.  Immediately after this user will
        // may TFTPGetFile or TFTPPutFile and we have to make sure that
        // UDP is read to transmit.  These functions do not check for
        // UDP to get ready.
        if ( UDPIsPutReady(_tftpSocket) )
            return TFTP_OK;
    }

    // Make sure that we do not do this forever.
    if ( TickGetDiff(TickGet(), _tftpStartTick) >= TFTP_ARP_TIMEOUT_VAL )
    {
        _tftpStartTick = TickGet();

        // Forget about all previous attempts.
        _tftpRetries = 1;

        return TFTP_TIMEOUT;
    }

    return TFTP_NOT_READY;
}



/*********************************************************************
 * Function:        void TFTPOpenFile(char *fileName,
 *                                    TFTP_FILE_MODE mode)
 *
 * PreCondition:    TFPTIsFileOpenReady() = TRUE
 *
 * Input:           fileName        - File name that is to be opened.
 *                  mode            - Mode of file access
 *                                    Must be
 *                                      TFTP_FILE_MODE_READ for read
 *                                      TFTP_FILE_MODE_WRITE for write
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Prepares and sends TFTP file name and mode packet.
 *
 * Note:            By default, this funciton uses "octet" or binary
 *                  mode of file transfer.
 *                  Use TFTPIsFileOpened() to check if file is
 *                  ready to be read or written.
 ********************************************************************/
void TFTPOpenFile(char *fileName, TFTP_FILE_MODE mode)
{
    DEBUG(printf("Opening file...\n"));

    // Set TFTP Server port.  If this is the first call, remotePort
    // must have been set by TFTPOpen().  But if caller does not do
    // TFTPOpen for every transfer, we must reset remote port.
    // Most TFTP servers accept connection TFTP port. but once
    // connection is established, they use other temp. port,
    UDPSocketInfo[_tftpSocket].remotePort = TFTP_SERVER_PORT;

    // Tell remote server about our intention.
    _TFTPSendFileName(mode, fileName);

    // Clear all flags.
    _tftpFlags.Val = 0;

    // Remember start tick for this operation.
    _tftpStartTick = TickGet();

    // Depending on mode of operation, remote server will respond with
    // specific block number.
    if ( mode == TFTP_FILE_MODE_READ )
    {
        // Remember that we are reading a file.
        _tftpFlags.bits.bIsReading = TRUE;


        // For read operation, server would respond with data block of 1.
        MutExVar.group2._tftpBlockNumber.Val = 1;

        // Next packet would be the data packet.
        _tftpState = SM_TFTP_WAIT_FOR_DATA;
    }

    else
    {
        // Remember that we are writing a file.
        _tftpFlags.bits.bIsReading = FALSE;

        // For write operation, server would respond with data block of 0.
        MutExVar.group2._tftpBlockNumber.Val = 0;

        // Next packet would be the ACK packet.
        _tftpState = SM_TFTP_WAIT_FOR_ACK;
    }


}




/*********************************************************************
 * Function:        TFTP_RESULT TFTPIsFileOpened(void)
 *
 * PreCondition:    TFTPOpenFile() is called.
 *
 * Input:           None
 *
 * Output:          TFTP_OK if file is ready to be read or written
 *
 *                  TFTP_RETRY if previous attempt was timed out
 *                  needs to be retried.
 *
 *                  TFTP_TIMEOUT if all attempts were exhausted.
 *
 *                  TFTP_NOT_ERROR if remote server responded with
 *                  error
 *
 *                  TFTP_NOT_READY if file is not yet opened.
 *
 * Side Effects:    None
 *
 * Overview:        Waits for remote server response regarding
 *                  previous attempt to open file.
 *                  If no response is received within specified
 *                  timeout, fnction returns with TFTP_RETRY
 *                  and application logic must issue another
 *                  TFTPFileOpen().
 *
 * Note:            None
 ********************************************************************/
TFTP_RESULT TFTPIsFileOpened(void)
{
    if ( _tftpFlags.bits.bIsReading )
        return TFTPIsGetReady();

    else
        return TFTPIsPutReady();
}




/*********************************************************************
 * Function:        TFTP_RESULT TFTPIsGetReady(void)
 *
 * PreCondition:    TFTPOpenFile() is called with TFTP_FILE_MODE_READ
 *                  and TFTPIsFileOpened() returned with TRUE.
 *
 * Input:           None
 *
 * Output:          TFTP_OK if it there is more data byte available
 *                  to read
 *
 *                  TFTP_TIMEOUT if timeout occurred waiting for
 *                  new data.
 *
 *                  TFTP_END_OF_FILE if end of file has reached.
 *
 *                  TFTP_ERROR if remote server returned ERROR.
 *                      Actual error code may be read by calling
 *                      TFTPGetError()
 *
 *                  TFTP_NOT_READY if still waiting for new data.
 *
 * Side Effects:    None
 *
 * Overview:        Waits for data block.  If data block does not
 *                  arrive within specified timeout, it automatically
 *                  sends out ack for previous block to remind
 *                  server to send next data block.
 *                  If all attempts are exhausted, it returns with
 *                  TFTP_TIMEOUT.
 *
 * Note:            By default, this funciton uses "octet" or binary
 *                  mode of file transfer.
 ********************************************************************/
TFTP_RESULT TFTPIsGetReady(void)
{
    WORD_VAL opCode;
    WORD_VAL blockNumber;
    BOOL bTimeOut;


    // Check to see if timeout has occurred.
    bTimeOut = FALSE;
    if ( TickGetDiff(TickGet(), _tftpStartTick) >= TFTP_GET_TIMEOUT_VAL )
    {
        bTimeOut = TRUE;
        _tftpStartTick = TickGet();
    }


    switch(_tftpState)
    {
    case SM_TFTP_WAIT_FOR_DATA:
        // If timeout occurs in this state, it may be because, we have not
        // even received very first data block or some in between block.
        if ( bTimeOut == TRUE )
        {
            bTimeOut = FALSE;

            if ( _tftpRetries++ > (TFTP_MAX_RETRIES-1) )
            {
                DEBUG(printf("TFTPIsGetReady(): Timeout.\n"));

                // Forget about all previous attempts.
                _tftpRetries = 1;

                return TFTP_TIMEOUT;
            }

            // If we have not even received first block, ask application
            // retry.
            if ( MutExVar.group2._tftpBlockNumber.Val == 1 )
            {
                DEBUG(printf("TFTPIsGetReady(): TFTPOpen Retry.\n"));
                return TFTP_RETRY;
            }
            else
            {
                DEBUG(printf("TFTPIsGetReady(): ACK Retry #%d...,\n", _tftpRetries));

                // Block number was already incremented in last ACK attempt,
                // so decrement it.
                MutExVar.group2._tftpBlockNumber.Val--;

                // Do it.
                _tftpState = SM_TFTP_SEND_ACK;
                break;
            }
        }

        // For Read operation, server will respond with data block.
        if ( !UDPIsGetReady(_tftpSocket) )
            break;

        // Get opCode
        UDPGet(&opCode.byte.MSB);
        UDPGet(&opCode.byte.LSB);

        // Get block number.
        UDPGet(&blockNumber.byte.MSB);
        UDPGet(&blockNumber.byte.LSB);

        // In order to read file, this must be data with block number of 0.
        if ( opCode.Val == TFTP_OPCODE_DATA )
        {
            // Make sure that this is not a duplicate block.
            if ( MutExVar.group2._tftpBlockNumber.Val == blockNumber.Val )
            {
                // Mark that we have not acked this block.
                _tftpFlags.bits.bIsAcked = FALSE;

                // Since we have a packet, forget about previous retry count.
                _tftpRetries = 1;

                _tftpState = SM_TFTP_READY;
                return TFTP_OK;
            }

            // If received block has already been received, simply ack it
            // so that Server can "get over" it and send next block.
            else if ( MutExVar.group2._tftpBlockNumber.Val > blockNumber.Val )
            {
                DEBUG(printf("TFTPIsGetReady(): "\
                            "Duplicate block %d received - droping it...\n", \
                            blockNumber.Val));
                MutExVar.group2._tftpDuplicateBlock.Val = blockNumber.Val;
                _tftpState = SM_TFTP_DUPLICATE_ACK;
            }
#if defined(TFTP_DEBUG)
            else
            {
                DEBUG(printf("TFTPIsGetReady(): "\
                             "Unexpected block %d received - droping it...\n", \
                             blockNumber.Val));
            }
#endif
        }
        // Discard all unexpected and error blocks.
        UDPDiscard();

        // If this was an error, remember error code for later delivery.
        if ( opCode.Val == TFTP_OPCODE_ERROR )
        {
            _tftpError = blockNumber.Val;
            return TFTP_ERROR;
        }

        break;

    case SM_TFTP_DUPLICATE_ACK:
        if ( UDPIsPutReady(_tftpSocket) )
        {
            _TFTPSendAck(MutExVar.group2._tftpDuplicateBlock);
            _tftpState = SM_TFTP_WAIT_FOR_DATA;
        }
        break;

    case SM_TFTP_READY:
        if ( UDPIsGetReady(_tftpSocket) )
        {
            _tftpStartTick = TickGet();
            return TFTP_OK;
        }

        // End of file is reached when data block is less than 512 bytes long.
        // To reduce code, only MSB compared against 0x02 (of 0x200 = 512) to
        // determine if block is less than 512 bytes long or not.
        else if ( MutExVar.group2._tftpBlockLength.Val == 0 ||
                  MutExVar.group2._tftpBlockLength.byte.MSB < TFTP_BLOCK_SIZE_MSB )
            _tftpState = SM_TFTP_SEND_LAST_ACK;
        else
            break;


    case SM_TFTP_SEND_LAST_ACK:
    case SM_TFTP_SEND_ACK:
        if ( UDPIsPutReady(_tftpSocket) )
        {
            _TFTPSendAck(MutExVar.group2._tftpBlockNumber);

            // This is the next block we are expecting.
            MutExVar.group2._tftpBlockNumber.Val++;

            // Remember that we have already acked current block.
            _tftpFlags.bits.bIsAcked = TRUE;

            if ( _tftpState == SM_TFTP_SEND_LAST_ACK )
                return TFTP_END_OF_FILE;

            _tftpState = SM_TFTP_WAIT_FOR_DATA;
        }
        break;
    }



    return TFTP_NOT_READY;
}



/*********************************************************************
 * Function:        BYTE TFTPGet(void)
 *
 * PreCondition:    TFTPOpenFile() is called with TFTP_FILE_MODE_READ
 *                  and TFTPIsGetReady() = TRUE
 *
 * Input:           None
 *
 * Output:          data byte as received from remote server.
 *
 * Side Effects:    None
 *
 * Overview:        Fetches next data byte from TFTP socket.
 *                  If end of data block is reached, it issues
 *                  ack to server so that next data block can be
 *                  received.
 *
 * Note:            Use this function to read file from server.
 ********************************************************************/
BYTE TFTPGet(void)
{
    BYTE v;

    // Read byte from UDP
    UDPGet(&v);

    // Update block length
    MutExVar.group2._tftpBlockLength.Val++;

    // Check to see if entire data block is fetched.
    // To reduce code, MSB is compared for 0x02 (of 0x200 = 512).
    if ( MutExVar.group2._tftpBlockLength.byte.MSB == TFTP_BLOCK_SIZE_MSB )
    {
        // Entire block was fetched.  Discard everything else.
        UDPDiscard();

        // Remember that we have flushed this block.
        _tftpFlags.bits.bIsFlushed = TRUE;

        // Reset block length.
        MutExVar.group2._tftpBlockLength.Val = 0;

        // Must send ACK to receive next block.
        _tftpState = SM_TFTP_SEND_ACK;
    }

    return v;
}




/*********************************************************************
 * Function:        void TFTPCloseFile(void)
 *
 * PreCondition:    TFTPOpenFile() was called and TFTPIsFileOpened()
 *                  had returned with TFTP_OK.
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        If file is opened in read mode, it makes sure
 *                  that last ACK is sent to server
 *                  If file is opened in write mode, it makes sure
 *                  that last block is sent out to server and
 *                  waits for server to respond with ACK.
 *
 * Note:            TFTPIsFileClosed() must be called to confirm
 *                  if file was really closed.
 ********************************************************************/
void TFTPCloseFile(void)
{
    // If a file was opened for read, we can close it immediately.
    if ( _tftpFlags.bits.bIsReading )
    {
        // If this was premature close, make sure that we discard
        // current block.
        if ( !_tftpFlags.bits.bIsFlushed )
        {
            _tftpFlags.bits.bIsFlushed = TRUE;
            UDPDiscard();
        }

        if ( _tftpFlags.bits.bIsAcked )
        {
            _tftpFlags.bits.bIsClosed = TRUE;
            _tftpFlags.bits.bIsClosing = FALSE;
            return;
        }

        else
        {
            _tftpState = SM_TFTP_SEND_LAST_ACK;
            _tftpFlags.bits.bIsClosing = TRUE;
        }
        return;
    }

    // For write mode, if we have not flushed last block, do it now.
    if ( !_tftpFlags.bits.bIsFlushed )
    {
        _tftpFlags.bits.bIsFlushed = TRUE;
        UDPFlush();
    }

    // For write mode, if our last block was ack'ed by remote server,
    // file is said to be closed.
    if ( _tftpFlags.bits.bIsAcked )
    {
        _tftpFlags.bits.bIsClosed = TRUE;
        _tftpFlags.bits.bIsClosing = FALSE;
        return;
    }

    _tftpState = SM_TFTP_WAIT_FOR_ACK;
    _tftpFlags.bits.bIsClosing =  TRUE;

}



/*********************************************************************
 * Function:        TFTP_RESULT TFPTIsFileClosed(void)
 *
 * PreCondition:    TFTPCloseFile() is already called.
 *
 * Input:           None
 *
 * Output:          TFTP_OK if file was successfully closdd
 *
 *                  TFTP_RETRY if file mode was Write and remote
 *                  server did not receive last packet.
 *                  Application must retry with last block.
 *
 *                  TFTP_TIMEOUT if all attempts were exhausted
 *                  in closing file.
 *
 *                  TFTP_ERROR if remote server sent an error
 *                  in response to last block.
 *                  Actual error code may be read by calling
 *                  TFTPGetError()
 *
 *                  TFTP_NOT_READY if file is not closed yet.
 *
 * Side Effects:    None
 *
 * Overview:        If file mode is Read, it simply makes that
 *                  last block is acknowledged.
 *                  If file mode is Write, it waits for server ack.
 *                  If no ack was received within specified timeout
 *                  instructs appliaction to resend last block.
 *                  It keeps track of retries and declares timeout
 *                  all attempts were exhausted.
 *
 * Note:            None
 ********************************************************************/
TFTP_RESULT TFTPIsFileClosed(void)
{
    if ( _tftpFlags.bits.bIsReading )
        return TFTPIsGetReady();

    else
        return TFTPIsPutReady();
}




/*********************************************************************
 * Function:        TFTP_RESULT TFTPIsPutReady(void)
 *
 * PreCondition:    TFTPOpenFile() is called with TFTP_FILE_MODE_WRITE
 *                  and TFTPIsFileOpened() returned with TRUE.
 *
 * Input:           None
 *
 * Output:          TFTP_OK if it is okay to write more data byte.
 *
 *                  TFTP_TIMEOUT if timeout occurred waiting for
 *                  ack from server
 *
 *                  TFTP_RETRY if all server did not send ack
 *                  on time and application needs to resend
 *                  last block.
 *
 *                  TFTP_ERROR if remote server returned ERROR.
 *                  Actual error code may be read by calling
 *                  TFTPGetError()
 *
 *                  TFTP_NOT_READY if still waiting...
 *
 * Side Effects:    None
 *
 * Overview:        Waits for ack from server.  If ack does not
 *                  arrive within specified timeout, it it instructs
 *                  application to retry last block by returning
 *                  TFTP_RETRY.
 *
 *                  If all attempts are exhausted, it returns with
 *                  TFTP_TIMEOUT.
 *
 * Note:            None
 ********************************************************************/
TFTP_RESULT TFTPIsPutReady(void)
{
    WORD_VAL opCode;
    WORD_VAL blockNumber;
    BOOL bTimeOut;

    // Check to see if timeout has occurred.
    bTimeOut = FALSE;
    if ( TickGetDiff(TickGet(), _tftpStartTick) >= TFTP_GET_TIMEOUT_VAL )
    {
        bTimeOut = TRUE;
        _tftpStartTick = TickGet();
    }

    switch(_tftpState)
    {
    case SM_TFTP_WAIT_FOR_ACK:
        // When timeout occurs in this state, application must retry.
        if ( bTimeOut )
        {
            if ( _tftpRetries++ > (TFTP_MAX_RETRIES-1) )
            {
                DEBUG(printf("TFTPIsPutReady(): Timeout.\n"));

                // Forget about all previous attempts.
                _tftpRetries = 1;

                return TFTP_TIMEOUT;
            }

            else
            {
                DEBUG(printf("TFTPIsPutReady(): Retry.\n"));
                return TFTP_RETRY;
            }
        }

        // Must wait for ACK from server before we transmit next block.
        if ( !UDPIsGetReady(_tftpSocket) )
            break;

        // Get opCode.
        UDPGet(&opCode.byte.MSB);
        UDPGet(&opCode.byte.LSB);

        // Get block number.
        UDPGet(&blockNumber.byte.MSB);
        UDPGet(&blockNumber.byte.LSB);

        // Discard everything else.
        UDPDiscard();

        // This must be ACK or else there is a problem.
        if ( opCode.Val == TFTP_OPCODE_ACK )
        {
            // Also the block number must match with what we are expecting.
            if ( MutExVar.group2._tftpBlockNumber.Val == blockNumber.Val )
            {
                // Mark that block we sent previously has been ack'ed.
                _tftpFlags.bits.bIsAcked = TRUE;

                // Since we have ack, forget about previous retry count.
                _tftpRetries = 1;

                // If this file is being closed, this must be last ack.
                // Declare it as closed.
                if ( _tftpFlags.bits.bIsClosing )
                {
                    _tftpFlags.bits.bIsClosed = TRUE;
                    return TFTP_OK;
                }

                // Or else, wait for put to become ready so that caller
                // can transfer more data blocks.
                _tftpState = SM_TFTP_WAIT;
            }

            else
            {
                DEBUG(printf("TFTPIsPutReady(): "\
                    "Unexpected block %d received - droping it...\n", \
                    blockNumber.Val));
                return TFTP_NOT_READY;
            }
        }

        else if ( opCode.Val == TFTP_OPCODE_ERROR )
        {
            // For error opCode, remember error code so that application
            // can read it later.
            _tftpError = blockNumber.Val;

            // Declare error.
            return TFTP_ERROR;
        }
        else
            break;


    case SM_TFTP_WAIT:
        // Wait for UDP is to be ready to transmit.
        if ( UDPIsPutReady(_tftpSocket) )
        {
            // Put next block of data.
            MutExVar.group2._tftpBlockNumber.Val++;
            UDPPut(0);
            UDPPut(TFTP_OPCODE_DATA);

            UDPPut(MutExVar.group2._tftpBlockNumber.byte.MSB);
            UDPPut(MutExVar.group2._tftpBlockNumber.byte.LSB);

            // Remember that this block is not yet flushed.
            _tftpFlags.bits.bIsFlushed = FALSE;

            // Remember that this block is not acknowledged.
            _tftpFlags.bits.bIsAcked = FALSE;

            // Now, TFTP module is ready to put more data.
            _tftpState = SM_TFTP_READY;

            return TFTP_OK;
        }
        break;

    case SM_TFTP_READY:
        // TFTP module is said to be ready only when underlying UDP
        // is ready to transmit.
        if ( UDPIsPutReady(_tftpSocket) )
            return TFTP_OK;
    }

    return TFTP_NOT_READY;
}



/*********************************************************************
 * Function:        void TFTPPut(BYTE c)
 *
 * PreCondition:    TFTPOpenFile() is called with TFTP_FILE_MODE_WRITE
 *                  and TFTPIsPutReady() = TRUE
 *
 * Input:           c       - Data byte that is to be written
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Puts given data byte into TFTP socket.
 *                  If end of data block is reached, it
 *                  transmits entire block.
 *
 * Note:            Use this function to write file to server.
 ********************************************************************/
void TFTPPut(BYTE c)
{
    // Put given byte directly to UDP
    UDPPut(c);

    // One more byte in data block.
    ++MutExVar.group2._tftpBlockLength.Val;

    // Check to see if data block is full.
    if ( MutExVar.group2._tftpBlockLength.byte.MSB == TFTP_BLOCK_SIZE_MSB )
    {
        // If it is, then transmit this block.
        UDPFlush();

        // Remember that current block is already flushed.
        _tftpFlags.bits.bIsFlushed = TRUE;

        // Prepare for next block.
        MutExVar.group2._tftpBlockLength.Val = 0;

        // Need to wait for ACK from server before putting
        // next block of data.
        _tftpState = SM_TFTP_WAIT_FOR_ACK;
    }
}




static void _TFTPSendFileName(TFTP_OPCODE opcode, char *fileName)
{
    BYTE c;

    // Write opCode
    UDPPut(0);
    UDPPut(opcode);

    // write file name, including NULL.
    do
    {
        c = *fileName++;
        UDPPut(c);
    } while ( c != '\0' );

    // Write mode - always use octet or binay mode to transmit files.
    UDPPut('o');
    UDPPut('c');
    UDPPut('t');
    UDPPut('e');
    UDPPut('t');
    UDPPut(0);

    // Transmit it.
    UDPFlush();

    // Reset data block length.
    MutExVar.group2._tftpBlockLength.Val = 0;

}

static void _TFTPSendAck(WORD_VAL blockNumber)
{
    // Write opCode.
    UDPPut(0);
    UDPPut(TFTP_OPCODE_ACK);

    // Write block number for this ack.
    UDPPut(blockNumber.byte.MSB);
    UDPPut(blockNumber.byte.LSB);

    // Transmit it.
    UDPFlush();
}
