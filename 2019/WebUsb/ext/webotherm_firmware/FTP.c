/*********************************************************************
 *
 *                  FTP ServerModule for Microchip TCP/IP Stack
 *
 *********************************************************************
 * FileName:        ftp.c
 * Dependencies:    StackTsk.h
 *                  tcp.h
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
 * Nilesh Rajbharti     4/23/01  Original        (Rev 1.0)
 * Nilesh Rajbharti     11/13/02 Fixed FTPServer()
  ********************************************************************/
#define THIS_IS_FTP

#include <string.h>
#include <stdlib.h>
#include "FTP.h"
#include "TCP.h"
#include "Tick.h"
#include "usart.h"

#include "MPFS.h"

#if !defined(STACK_USE_FTP_SERVER)
    #error FTP SERVER module is not enabled.
    #error If you do not want FTP module, remove this file from your
    #error project to reduce your code size.
    #error If you do want FTP module, make sure that STACK_USE_FTP_SERVER
    #error is defined in StackTsk.h file.
#endif


#define FTP_COMMAND_PORT                (21)
#define FTP_DATA_PORT                   (20)
#define FTP_TIMEOUT                     (TICK)((TICK)180 * TICK_SECOND)
#define MAX_FTP_ARGS                    (7)
#define MAX_FTP_CMD_STRING_LEN          (31)

typedef enum _SM_FTP
{
    SM_FTP_NOT_CONNECTED,
    SM_FTP_CONNECTED,
    SM_FTP_USER_NAME,
    SM_FTP_USER_PASS,
    SM_FTP_RESPOND
} SM_FTP;

typedef enum _SM_FTP_CMD
{
    SM_FTP_CMD_IDLE,
    SM_FTP_CMD_WAIT,
    SM_FTP_CMD_RECEIVE,
    SM_FTP_CMD_WAIT_FOR_DISCONNECT
} SM_FTP_CMD;

typedef enum _FTP_COMMAND
{
    FTP_CMD_USER,
    FTP_CMD_PASS,
    FTP_CMD_QUIT,
    FTP_CMD_STOR,
    FTP_CMD_PORT,
    FTP_CMD_ABORT,
	// g {{{
	FTP_CMD_SYST,
	FTP_CMD_PWD,
//	FTP_CMD_TYPE,
//	FTP_CMD_LIST,
	// }}}

    FTP_CMD_UNKNOWN,
    FTP_CMD_NONE,
} FTP_COMMAND;

/*
 * Each entry in following table must match with that of FTP_COMMAND enum.
 */
ROM char *FTPCommandString[] =
{
    { "USER" },                         // FTP_CMD_USER
    { "PASS" },                         // FTP_CMD_PASS
    { "QUIT" },                         // FTP_CMD_QUIT
    { "STOR" },                         // FTP_CMD_STOR
    { "PORT" },                         // FTP_CMD_PORT
    { "ABOR" },                          // FTP_CMD_ABORT

    { "SYST" },
    { "PWD" }
 //   { "TYPE" },
 //   { "LIST" }

};
#define FTP_COMMAND_TABLE_SIZE  ( sizeof(FTPCommandString)/sizeof(FTPCommandString[0]) )


typedef enum _FTP_RESPONSE
{
    FTP_RESP_BANNER,
    FTP_RESP_USER_OK,
    FTP_RESP_PASS_OK,
    FTP_RESP_QUIT_OK,
    FTP_RESP_STOR_OK,
    FTP_RESP_UNKNOWN,
    FTP_RESP_LOGIN,
    FTP_RESP_DATA_OPEN,
    FTP_RESP_DATA_READY,
    FTP_RESP_DATA_CLOSE,
    FTP_RESP_OK,

	FTP_RESP_SYST,
	FTP_RESP_PWD,
//	FTP_RESP_LIST,

    FTP_RESP_NONE                       // This must always be the last
                                        // There is no corresponding string.
} FTP_RESPONSE;

/*
 * Each entry in following table must match with FTP_RESPONE enum
 */
ROM char *FTPResponseString[] =
{
    "220 Ready\r\n",                    // FTP_RESP_BANNER
    "331 Password required\r\n",        // FTP_RESP_USER_OK
    "230 Logged in\r\n",                // FTP_RESP_PASS_OK
    "221 Bye\r\n",                      // FTP_RESP_QUIT_OK
    "500 \r\n",                         // FTP_RESP_STOR_OK
    "502 Not implemented\r\n",          // FTP_RESP_UNKNOWN
    "530 Login required\r\n",           // FTP_RESP_LOGIN
    "150 Transferring data...\r\n",     // FTP_RESP_DATA_OPEN
    "125 Done.\r\n",                    // FTP_RESP_DATA_READY
    "226 Transfer Complete\r\n",        // FTP_RESP_DATA_CLOSE
    "200 ok\r\n",                       // FTP_RESP_OK
    "ENC28J60 Type: L8\r\n",
    "257 \"/\"\r\n"
//    "ENC28J60 Type: L8\r\n",
//    "257 \"/\"\r\n"
};


static union
{
    struct
    {
        unsigned int bUserSupplied : 1;
        unsigned int bLoggedIn: 1;
    } Bits;
    BYTE Val;
} FTPFlags;


static TCP_SOCKET       FTPSocket;      // Main ftp command socket.
static TCP_SOCKET       FTPDataSocket;  // ftp data socket.
static WORD_VAL         FTPDataPort;    // ftp data port number as supplied by client

static SM_FTP           smFTP;          // ftp server FSM state
static SM_FTP_CMD       smFTPCommand;   // ftp command FSM state

static FTP_COMMAND      FTPCommand;
static FTP_RESPONSE     FTPResponse;

static char             FTPUser[FTP_USER_NAME_LEN];
static char             FTPString[MAX_FTP_CMD_STRING_LEN+2];
static BYTE             FTPStringLen;
static char             *FTP_argv[MAX_FTP_ARGS];    // Parameters for a ftp command
static BYTE             FTP_argc;       // Total number of params for a ftp command
static TICK             lastActivity;   // Timeout keeper.


static MPFS             FTPFileHandle;

/*
 * Private helper functions.
 */
static void ParseFTPString(void);
static FTP_COMMAND ParseFTPCommand(char *cmd);
static void ParseFTPString(void);
static BOOL ExecuteFTPCommand(FTP_COMMAND cmd);
static BOOL PutFile(void);
static BOOL Quit(void);

/*
 * Uncomment following line if ftp transactions are to be displayed on
 * RS-232 - for debug purpose only.
 */
#define FTP_SERVER_DEBUG_MODE
#define FTP_PUT_ENABLED


/*********************************************************************
 * Function:        void FTPInit(void)
 *
 * PreCondition:    TCP module is already initialized.
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Initializes internal variables of FTP
 *
 * Note:
 ********************************************************************/
void FTPInit(void)
{
    FTPSocket       = TCPListen(FTP_COMMAND_PORT);
    smFTP           = SM_FTP_NOT_CONNECTED;
    FTPStringLen    = 0;
    FTPFlags.Val    = 0;
    FTPDataPort.Val = FTP_DATA_PORT;
}


/*********************************************************************
 * Function:        void FTPServer(void)
 *
 * PreCondition:    FTPInit() must already be called.
 *
 * Input:           None
 *
 * Output:          Opened FTP connections are served.
 *
 * Side Effects:    None
 *
 * Overview:
 *
 * Note:            This function acts as a task (similar to one in
 *                  RTOS).  This function performs its task in
 *                  co-operative manner.  Main application must call
 *                  this function repeatdly to ensure all open
 *                  or new connections are served on time.
 ********************************************************************/
BOOL FTPServer(void)
{
    BYTE v;
    TICK currentTick;

    if ( !TCPIsConnected(FTPSocket) )
    {
        FTPStringLen    = 0;
        FTPCommand      = FTP_CMD_NONE;
        smFTP           = SM_FTP_NOT_CONNECTED;
        FTPFlags.Val    = 0;
        smFTPCommand    = SM_FTP_CMD_IDLE;
        return TRUE;
    }

    if ( TCPIsGetReady(FTPSocket) )
    {
        lastActivity    = TickGet();

        while( TCPGet(FTPSocket, &v ) )
        {
            USARTPut(v);
            FTPString[FTPStringLen++]   = v;
            if ( FTPStringLen == MAX_FTP_CMD_STRING_LEN )
                FTPStringLen            = 0;
        }
        TCPDiscard(FTPSocket);


        if ( v == '\n' )
        {
            FTPString[FTPStringLen]     = '\0';
            FTPStringLen                = 0;
            ParseFTPString();
            FTPCommand                  = ParseFTPCommand(FTP_argv[0]);
        }
    }
    else if ( smFTP != SM_FTP_NOT_CONNECTED )
    {
        currentTick = TickGet();
        currentTick = TickGetDiff(currentTick, lastActivity);
        if ( currentTick >= FTP_TIMEOUT )
        {
            lastActivity                = TickGet();
            FTPCommand                  = FTP_CMD_QUIT;
            smFTP                       = SM_FTP_CONNECTED;
        }
    }

    switch(smFTP)
    {
    case SM_FTP_NOT_CONNECTED:
        FTPResponse = FTP_RESP_BANNER;
        lastActivity = TickGet();
        /* No break - Continue... */

    case SM_FTP_RESPOND:
SM_FTP_RESPOND_Label:
        while( !TCPIsPutReady(FTPSocket) );
        if ( TCPIsPutReady(FTPSocket) )
        {
            ROM char* pMsg;

            pMsg = FTPResponseString[FTPResponse];

            while( (v = *pMsg++) )
            {
                USARTPut(v);
                TCPPut(FTPSocket, v);
            }
            TCPFlush(FTPSocket);
            FTPResponse = FTP_RESP_NONE;
            smFTP = SM_FTP_CONNECTED;
        }
        /* No break - this will speed up little bit */

    case SM_FTP_CONNECTED:
        if ( FTPCommand != FTP_CMD_NONE )
        {
            if ( ExecuteFTPCommand(FTPCommand) )
            {
                if ( FTPResponse != FTP_RESP_NONE )
                    smFTP = SM_FTP_RESPOND;
                else if ( FTPCommand == FTP_CMD_QUIT )
                    smFTP = SM_FTP_NOT_CONNECTED;

                FTPCommand = FTP_CMD_NONE;
                smFTPCommand = SM_FTP_CMD_IDLE;
            }
            else if ( FTPResponse != FTP_RESP_NONE )
            {
                smFTP = SM_FTP_RESPOND;
                goto SM_FTP_RESPOND_Label;
            }
        }
        break;


    }

    return TRUE;
}

static BOOL ExecuteFTPCommand(FTP_COMMAND cmd)
{
    switch(cmd)
    {
	// gabo {{{
	case FTP_CMD_SYST:
        FTPResponse = FTP_RESP_SYST;
		break;
	case FTP_CMD_PWD:
        FTPResponse = FTP_RESP_PWD;
		break;
	// }}}
    case FTP_CMD_USER:
        FTPFlags.Bits.bUserSupplied = TRUE;
        FTPFlags.Bits.bLoggedIn = FALSE;
        FTPResponse = FTP_RESP_USER_OK;
        strncpy(FTPUser, FTP_argv[1], sizeof(FTPUser));
        break;

    case FTP_CMD_PASS:
        if ( !FTPFlags.Bits.bUserSupplied )
            FTPResponse = FTP_RESP_LOGIN;
        else
        {
            if ( FTPVerify(FTPUser, FTP_argv[1]) )
            {
                FTPFlags.Bits.bLoggedIn = TRUE;
                FTPResponse = FTP_RESP_PASS_OK;
            }
            else
                FTPResponse = FTP_RESP_LOGIN;
        }
        break;

    case FTP_CMD_QUIT:
        return Quit();

    case FTP_CMD_PORT:
        FTPDataPort.v[1] = (BYTE)atoi(FTP_argv[5]);
        FTPDataPort.v[0] = (BYTE)atoi(FTP_argv[6]);
        FTPResponse = FTP_RESP_OK;
        break;

    case FTP_CMD_STOR:
        return PutFile();

    case FTP_CMD_ABORT:
        FTPResponse = FTP_RESP_OK;
        if ( FTPDataSocket != INVALID_SOCKET )
            TCPDisconnect(FTPDataSocket);
        break;

    default:
        FTPResponse = FTP_RESP_UNKNOWN;
        break;
    }
    return TRUE;
}

static BOOL Quit(void)
{
    switch(smFTPCommand)
    {
    case SM_FTP_CMD_IDLE:
#if defined(FTP_PUT_ENABLED)
        if ( smFTPCommand == SM_FTP_CMD_RECEIVE )
            MPFSClose();
#endif

        if ( FTPDataSocket != INVALID_SOCKET )
        {
#if defined(FTP_PUT_ENABLED)
            MPFSClose();
#endif
            TCPDisconnect(FTPDataSocket);
            smFTPCommand = SM_FTP_CMD_WAIT;
        }
        else
            goto Quit_Done;
        break;

    case SM_FTP_CMD_WAIT:
        if ( !TCPIsConnected(FTPDataSocket) )
        {
Quit_Done:
            FTPResponse = FTP_RESP_QUIT_OK;
            smFTPCommand = SM_FTP_CMD_WAIT_FOR_DISCONNECT;
        }
        break;

    case SM_FTP_CMD_WAIT_FOR_DISCONNECT:
        if ( TCPIsPutReady(FTPSocket) )
        {
            if ( TCPIsConnected(FTPSocket) )
                TCPDisconnect(FTPSocket);
        }
        break;

    }
    return FALSE;
}


static BOOL PutFile(void)
{
    BYTE v;


    switch(smFTPCommand)
    {
    case SM_FTP_CMD_IDLE:
        if ( !FTPFlags.Bits.bLoggedIn )
        {
            FTPResponse     = FTP_RESP_LOGIN;
            return TRUE;
        }
        else
        {
            FTPResponse     = FTP_RESP_DATA_OPEN;
            FTPDataSocket   = TCPConnect(&REMOTE_HOST(FTPSocket), FTPDataPort.Val);
            smFTPCommand    = SM_FTP_CMD_WAIT;
        }
        break;

    case SM_FTP_CMD_WAIT:
        if ( TCPIsConnected(FTPDataSocket) )
        {
#if defined(FTP_PUT_ENABLED)
            if ( !MPFSIsInUse() )
#endif
            {
#if defined(FTP_PUT_ENABLED)
                FTPFileHandle   = MPFSFormat();
#endif

                smFTPCommand    = SM_FTP_CMD_RECEIVE;
            }
        }
        break;

    case SM_FTP_CMD_RECEIVE:
        if ( TCPIsGetReady(FTPDataSocket) )
        {
            /*
             * Reload timeout timer.
             */
            lastActivity    = TickGet();
            MPFSPutBegin(FTPFileHandle);
            while( TCPGet(FTPDataSocket, &v) )
            {
                USARTPut(v);

#if defined(FTP_PUT_ENABLED)
                MPFSPut(v);
#endif
            }
            FTPFileHandle = MPFSPutEnd();
            TCPDiscard(FTPDataSocket);
        }
        else if ( !TCPIsConnected(FTPDataSocket) )
        {
#if defined(FTP_PUT_ENABLED)
            MPFSPutEnd();
            MPFSClose();
#endif
            TCPDisconnect(FTPDataSocket);
            FTPDataSocket   = INVALID_SOCKET;
            FTPResponse     = FTP_RESP_DATA_CLOSE;
            return TRUE;
        }
    }
    return FALSE;
}



static FTP_COMMAND ParseFTPCommand(char *cmd)
{
    FTP_COMMAND i;

    for ( i = 0; i < (FTP_COMMAND)FTP_COMMAND_TABLE_SIZE; i++ )
    {
    if ( !memcmppgm2ram((void*)cmd, (ROM void*)FTPCommandString[i], 4) )
            return i;
    }

    return FTP_CMD_UNKNOWN;
}

static void ParseFTPString(void)
{
    BYTE *p;
    BYTE v;
    enum { SM_FTP_PARSE_PARAM, SM_FTP_PARSE_SPACE } smParseFTP;

    smParseFTP  = SM_FTP_PARSE_PARAM;
    p           = (BYTE*)&FTPString[0];

    /*
     * Skip white blanks
     */
    while( *p == ' ' )
        p++;

    FTP_argv[0]  = (char*)p;
    FTP_argc     = 1;

    while( (v = *p) )
    {
        switch(smParseFTP)
        {
        case SM_FTP_PARSE_PARAM:
            if ( v == ' ' || v == ',' )
            {
                *p = '\0';
                smParseFTP = SM_FTP_PARSE_SPACE;
            }
            else if ( v == '\r' || v == '\n' )
                *p = '\0';
            break;

        case SM_FTP_PARSE_SPACE:
            if ( v != ' ' )
            {
                FTP_argv[FTP_argc++] = (char*)p;
                smParseFTP = SM_FTP_PARSE_PARAM;
            }
            break;
        }
        p++;
    }
}

