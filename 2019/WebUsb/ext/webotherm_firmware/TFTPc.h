/*********************************************************************
 *
 *                  TFTP Client module for Microchip TCP/IP Stack
 *
 *********************************************************************
 * FileName:        TFTPc.h
 * Dependencies:    StackTsk.h
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
#ifndef TFTPC_H
#define TFTPC_H

#include "StackTsk.h"
#include "UDP.h"

// Number of seconds to wait before declaring TIMEOUT error on Get.
#define TFTP_GET_TIMEOUT_VAL        (3 * TICKS_PER_SECOND)

// Number of seconds to wait before declaring TIMEOUT error on Put
#define TFTP_ARP_TIMEOUT_VAL        (3 * TICKS_PER_SECOND)

// Number of attempts before declaring TIMEOUT error.
#define TFTP_MAX_RETRIES            (3)

// Retry count must be 1 or more.
#if TFTP_MAX_RETRIES <= 0
#error Retry count must at least be 1
#endif

// Enum. of results returned by most of the TFTP functions.
typedef enum _TFTP_RESULT
{
    TFTP_OK = 0,
    TFTP_NOT_READY,
    TFTP_END_OF_FILE,
    TFTP_ERROR,
    TFTP_RETRY,
    TFTP_TIMEOUT
} TFTP_RESULT;

// File open mode as used by TFTPFileOpen().
typedef enum _TFTP_FILE_MODE
{
    TFTP_FILE_MODE_READ = 1,
    TFTP_FILE_MODE_WRITE = 2
} TFTP_FILE_MODE;

// Standard error codes as defined by TFTP spec.
// Use to decode value retuned by TFTPGetError().
typedef enum _TFTP_ACCESS_ERROR
{
    TFTP_ERROR_NOT_DEFINED = 0,
    TFTP_ERROR_FILE_NOT_FOUND,
    TFTP_ERROR_ACCESS_VIOLATION,
    TFTP_ERROR_DISK_FULL,
    TFTP_ERROR_INVALID_OPERATION,
    TFTP_ERROR_UNKNOWN_TID,
    TFTP_ERROR_FILE_EXISTS,
    TFTP_ERROR_NO_SUCH_USE
} TFTP_ACCESS_ERROR;

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
void TFTPOpen(IP_ADDR *host);


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
TFTP_RESULT TFTPIsOpened(void);


/*********************************************************************
 * Macro:           void TFTPClose(void)
 *
 * PreCondition:    TFTPOpen is already called and TFTPIsOpened()
 *                  returned TFTP_OK.
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Closes TFTP client socket.
 *
 * Note:            Once closed, application must do TFTPOpen to
 *                  perform any new TFTP operations.
 *
 *                  If TFTP server does not change during application
 *                  life-time, one may not need to call TFTPClose
 *                  and keep TFTP socket open.
 ********************************************************************/
#define TFTPClose(void)     UDPClose(_tftpSocket)
    extern UDP_SOCKET _tftpSocket;



/*********************************************************************
 * Macro:           BOOL TFTPIsFileOpenReady(void)
 *
 * PreCondition:    TFTPOpen is already called and TFTPIsOpened()
 *                  returned TFTP_OK.
 *
 * Input:           None
 *
 * Output:          TRUE, if it is ok to call TFTPOpenFile()
 *                  FALSE, if otherwise.
 *
 * Side Effects:    None
 *
 * Overview:        Checks to see if it is okay to send TFTP file
 *                  open request to remote server.
 *
 * Note:            None
 ********************************************************************/
#define TFTPIsFileOpenReady()       UDPIsPutReady(_tftpSocket)



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
void TFTPOpenFile(char *fileName, TFTP_FILE_MODE mode);


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
TFTP_RESULT TFTPIsFileOpened(void);

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
void TFTPCloseFile(void);


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
TFTP_RESULT TFTPIsFileClosed(void);



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
TFTP_RESULT TFTPIsGetReady(void);


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
BYTE TFTPGet(void);


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
TFTP_RESULT TFTPIsPutReady(void);


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
void TFTPPut(BYTE c);


/*********************************************************************
 * Macro:           WORD TFTPGetError(void)
 *
 * PreCondition:    One of the TFTP function returned with
 *                  TFTP_ERROR result.
 *
 * Input:           None
 *
 * Output:          Error code as returned by remote server.
 *                  Application may use TFTP_ACCESS_ERROR enum. to
 *                  decode standard error code.
 *
 * Side Effects:    None
 *
 * Overview:        Returns previously saved error code.
 *
 * Note:            None
 ********************************************************************/
#define TFTPGetError()      (_tftpError)
    extern WORD _tftpError;


#endif
