/*********************************************************************
 *
 *                  SNMP Module for Microchip TCP/IP Stack
 *
 *********************************************************************
 * FileName:        SNMP.c
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
 *
 * Author               Date    Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Nilesh Rajbharti     1/9/03  Original        (Rev 1.0)
 * Dan Cohen            12/11/03  Removed trap support by #define if not
 *                                required to lower code space requirements
 *
 ********************************************************************/
#define THIS_IS_SNMP_SERVER

#include <string.h>

#include "snmp.h"
#include "stacktsk.h"
#ifndef _WIN32
#include "udp.h"
#include "tick.h"
#include "arptsk.h"
#endif
#include "mpfs.h"

#if _WIN32
#include <windows.h>
#endif

#if !defined(STACK_USE_SNMP_SERVER)
    #error SNMP module is not enabled.
    #error If you do not want SNMP module, remove this file from your
    #error project to reduce your code size.
    #error If you do want SNMP module, make sure that STACK_USE_SNMP_SERVER
    #error is defined in StackTsk.h file.
#endif

#define SNMP_V1                 (0)


#define STRUCTURE               (0x30)
#define ASN_INT                 (0x02)
#define OCTET_STRING            (0x04)
#define ASN_NULL                (0x05)
#define ASN_OID                 (0x06)

// SNMP specific variables
#define SNMP_IP_ADDR            (0x40)
#define SNMP_COUNTER32          (0x41)
#define SNMP_GAUGE32            (0x42)
#define SNMP_TIME_TICKS         (0x43)
#define SNMP_OPAQUE             (0x44)
#define SNMP_NSAP_ADDR          (0x45)


#define GET_REQUEST             (0xa0)
#define GET_NEXT_REQUEST        (0xa1)
#define GET_RESPONSE            (0xa2)
#define SET_REQUEST             (0xa3)
#define TRAP                    (0xa4)

#define IS_STRUCTURE(a)         (a==STRUCTURE)
#define IS_ASN_INT(a)           (a==ASN_INT)
#define IS_OCTET_STRING(a)      (a==OCTET_STRING)
#define IS_OID(a)               (a==ASN_OID)
#define IS_ASN_NULL(a)          (a==ASN_NULL)
#define IS_GET_REQUEST(a)       (a==GET_REQUEST)
#define IS_GET_NEXT_REQUEST(a)  (a==GET_NEXT_REQUEST)
#define IS_GET_RESPONSE(a)      (a==GET_RESPONSE)
#define IS_SET_REQUEST(a)       (a==SET_REQUEST)
#define IS_TRAP(a)              (a==TRAP)
#define IS_AGENT_PDU(a)         (a==GET_REQUEST || \
                                 a==GET_NEXT_REQUEST || \
                                 a==SET_REQUEST)

typedef enum _SNMP_ERR_STATUS
{
    SNMP_NO_ERR = 0,
    SNMP_TOO_BIG,
    SNMP_NO_SUCH_NAME,
    SNMP_BAD_VALUE,
    SNMP_READ_ONLY,
    SNMP_GEN_ERR
} SNMP_ERR_STATUS;

typedef union _SNMP_STATUS
{
    struct
    {
        unsigned int bIsFileOpen : 1;
    } Flags;
    BYTE Val;
} SNMP_STATUS;



#define SNMP_AGENT_PORT     (161)
#define SNMP_NMS_PORT       (162)
#define AGENT_NOTIFY_PORT   (0xfffe)

#ifdef _WIN32
    #define ROM
    extern int _RxIndex;
    extern int _TxIndex;
    extern int _TxLength;
    extern BYTE _TxPacket[1000];
    extern BYTE _RxPacket[1000];

    #define INVALID_UDP_SOCKET  (0XFFFF)

    #define UDPGet(a)           _UDPGet(a)
    #define UDPFlush()
    #define UDPClose(a)
    #define ARPResolve(a)
    #define ARPIsResolved(a, b) (TRUE)
    static void _UDPGet(BYTE *v)
    {
        *v = _RxPacket[_RxIndex++];
    }

    #define UDP_SOCKET              int
    #define BUFFER                  int

    #define UDPOpen(a, b, c)            (0)
    #define UDPDiscard()            (_TxLength = 0)
    #define UDPPut(a)               \
    {                               \
        if ( _TxIndex >= _TxLength ) \
            _TxLength = _TxIndex+1; \
        _TxPacket[_TxIndex++] = a;  \
    }
    #define UDPIsGetReady(a)        TRUE
    #define UDPIsPutReady(a)        TRUE
    #define MACGetRxBuffer()        0
    #define MACGetTxBuffer()         0
    #define UDPSetRxBuffer(a)       (_RxIndex = a)
    #define UDPSetTxBuffer(a, b)    (_TxIndex = a+b)
    #define SNMPValidate(a, b)      TRUE

    #undef MY_IP_BYTE1
    #undef MY_IP_BYTE2
    #undef MY_IP_BYTE3
    #undef MY_IP_BYTE4
    #define MY_IP_BYTE1             (10)
    #define MY_IP_BYTE2             (10)
    #define MY_IP_BYTE3             (5)
    #define MY_IP_BYTE4             (15)

#endif

UDP_SOCKET SNMPAgentSocket;

typedef struct _SNMP_NOTIFY_INFO
{
    char community[NOTIFY_COMMUNITY_LEN];
    BYTE communityLen;
    SNMP_ID agentIDVar;
    BYTE notificationCode;
    UDP_SOCKET socket;
    DWORD_VAL timestamp;
} SNMP_NOTIFY_INFO;

// SNMPNotifyInfo is not required if TRAP is disabled
#if !defined(SNMP_TRAP_DISABED)
static SNMP_NOTIFY_INFO SNMPNotifyInfo;
#endif


typedef enum _DATA_TYPE
{
    INT8_VAL        = 0x00,
    INT16_VAL       = 0x01,
    INT32_VAL       = 0x02,
    BYTE_ARRAY      = 0x03,
    ASCII_STRING    = 0x04,
    IP_ADDRESS      = 0x05,
    COUNTER32       = 0x06,
    TIME_TICKS_VAL  = 0x07,
    GAUGE32         = 0x08,
    OID_VAL         = 0x09,

    DATA_TYPE_UNKNOWN
} DATA_TYPE;

typedef union _INDEX_INFO
{
    struct
    {
        unsigned int bIsOID:1;
    } Flags;
    BYTE Val;
} INDEX_INFO;


typedef struct _DATA_TYPE_INFO
{
    BYTE asnType;
    BYTE asnLen;
} DATA_TYPE_INFO;

ROM DATA_TYPE_INFO dataTypeTable[] =
{
    /* INT8_VAL         */ { ASN_INT,           1       },
    /* INT16_VAL        */ { ASN_INT,           2       },
    /* INT32_VAL        */ { ASN_INT,           4       },
    /* BYTE_ARRAY       */ { OCTET_STRING,      0xff    },
    /* ASCII_ARRAY      */ { OCTET_STRING,      0xff    },
    /* IP_ADDRESS       */ { SNMP_IP_ADDR,      4       },
    /* COUNTER32        */ { SNMP_COUNTER32,    4       },
    /* TIME_TICKS_VAL   */ { SNMP_TIME_TICKS,   4       },
    /* GAUTE32          */ { SNMP_GAUGE32,      4       },
    /* OID_VAL          */ { ASN_OID,           0xff    }
};
#define DATA_TYPE_TABLE_SIZE    (sizeof(dataTypeTable)/sizeof(dataTypeTable[0]))



typedef union _MIB_INFO
{
    struct
    {
        unsigned int bIsDistantSibling : 1;
        unsigned int bIsConstant : 1;
        unsigned int bIsSequence : 1;
        unsigned int bIsSibling : 1;

        unsigned int bIsParent : 1;
        unsigned int bIsEditable : 1;
        unsigned int bIsAgentID : 1;
        unsigned int bIsIDPresent : 1;
    } Flags;
    BYTE Val;
} MIB_INFO;


typedef struct _OID_INFO
{
    MPFS            hNode;

    BYTE            oid;
    MIB_INFO        nodeInfo;
    DATA_TYPE       dataType;
    SNMP_ID         id;

    WORD_VAL        dataLen;
    MPFS            hData;
    MPFS            hSibling;
    MPFS            hChild;
    BYTE            index;
    BYTE            indexLen;
} OID_INFO;

static WORD SNMPTxOffset;
static WORD SNMPRxOffset;

static BUFFER SNMPRxBuffer;
static BUFFER SNMPTxBuffer;

static SNMP_STATUS SNMPStatus;

#define _SNMPSetTxOffset(o)     (SNMPTxOffset = o)
#define _SNMPGetTxOffset()      SNMPTxOffset


static SNMP_ACTION ProcessHeader(char *community, BYTE *len);
static BOOL ProcessGetSetHeader(DWORD *requestID);
static BOOL ProcessVariables(char *community,
                            BYTE len,
                            DWORD_VAL *request,
                            BYTE pduType);

static BOOL OIDLookup(BYTE *oid, BYTE oidLen, OID_INFO *rec);
static BOOL IsValidCommunity(char* community, BYTE *len);
static BOOL IsValidInt(DWORD *val);
static BOOL IsValidPDU(SNMP_ACTION *pdu);
static BYTE IsValidLength(WORD *len);
static BOOL IsASNNull(void);
static BOOL IsValidOID(BYTE *oid, BYTE *len);
static BYTE IsValidStructure(WORD *dataLen);
static void _SNMPDuplexInit(UDP_SOCKET socket);
static void _SNMPPut(BYTE v);
static BYTE _SNMPGet(void);
static BOOL GetNextLeaf(OID_INFO *n);
static void ReadMIBRecord(MPFS h, OID_INFO *rec);
static BOOL GetDataTypeInfo(DATA_TYPE dataType, DATA_TYPE_INFO *info);
static BYTE ProcessGetVar(OID_INFO *rec, BOOL bAsOID);
static BYTE ProcessGetNextVar(OID_INFO *rec);
static BOOL GetOIDStringByAddr(OID_INFO *rec, BYTE *oidString, BYTE *len);
static BYTE ProcessSetVar(OID_INFO *rec, SNMP_ERR_STATUS *errorStatus);
static void SetErrorStatus(WORD errorStatusOffset,
                           WORD errorIndexOffset,
                           SNMP_ERR_STATUS errorStatus,
                           BYTE errorIndex);

// This function is used only when TRAP is enabled.
#if !defined(SNMP_TRAP_DISABED)
static BOOL GetOIDStringByID(SNMP_ID id, OID_INFO *info, BYTE *oidString, BYTE *len);
#endif


/*********************************************************************
 * Function:        void SNMPInit(void)
 *
 * PreCondition:    At least one UDP socket must be available.
 *                  UDPInit() is already called.
 *
 * Input:           None
 *
 * Output:          SNMP agent module is initialized.
 *
 * Side Effects:    One UDP socket will be used.
 *
 * Overview:        Initialize SNMP module internals
 *
 * Note:            This function is called only once during lifetime
 *                  of the application.
 ********************************************************************/
void SNMPInit(void)
{
    // Start with no error or flag set.
    SNMPStatus.Val = 0;

    SNMPAgentSocket = UDPOpen(SNMP_AGENT_PORT, 0, INVALID_UDP_SOCKET);
    // SNMPAgentSocket must not be INVALID_UDP_SOCKET.
    // If it is, compile time value of UDP Socket numbers must be increased.

    return;
}


/*********************************************************************
 * Function:        BOOL SNMPTask(void)
 *
 * PreCondition:    SNMPInit is already called.
 *
 * Input:           None
 *
 * Output:          TRUE if SNMP module has finished with a state
 *                  FALSE if a state has not been finished.
 *
 *
 * Side Effects:    None
 *
 * Overview:        Handle incoming SNMP requests as well as any
 *                  outgoing SNMP responses and timeout conditions
 *
 * Note:            None.
 ********************************************************************/
BOOL SNMPTask(void)
{
    char community[SNMP_COMMUNITY_MAX_LEN];
    BYTE communityLen;
    DWORD_VAL requestID;
    BYTE pdu;
    MPFS hMIBFile;
    BOOL lbReturn;

    char snmpBIBFile[] = SNMP_BIB_FILE_NAME;

    // Check to see if there is any packet on SNMP Agent socket.
    if ( !UDPIsGetReady(SNMPAgentSocket) )
        return TRUE;

    // As we process SNMP variables, we will prepare response on-the-fly
    // creating full duplex transfer.
    // Current MAC layer does not support full duplex transfer, so
    // SNMP needs to manage its own full duplex connection.
    // Prepare for full duplex transfer.
    _SNMPDuplexInit(SNMPAgentSocket);


    pdu = ProcessHeader(community, &communityLen);
    if ( pdu == SNMP_ACTION_UNKNOWN )
        goto _SNMPDiscard;

    if ( !ProcessGetSetHeader(&requestID.Val) )
        goto _SNMPDiscard;

    // Open MIB file.
    SNMPStatus.Flags.bIsFileOpen = FALSE;
    hMIBFile = MPFSOpen((BYTE*)snmpBIBFile);
    if ( hMIBFile != MPFS_INVALID )
    {
        SNMPStatus.Flags.bIsFileOpen = TRUE;
    }

    lbReturn = ProcessVariables(community, communityLen, &requestID, pdu);
    if ( SNMPStatus.Flags.bIsFileOpen )
    {
        MPFSClose();
    }

    if ( lbReturn == FALSE )
        goto _SNMPDiscard;

    UDPFlush();

    return TRUE;

_SNMPDiscard:
    UDPDiscard();

    return TRUE;
}


#if !defined(SNMP_TRAP_DISABED)
/*********************************************************************
 * Function:        void SNMPNotifyPrepare(IP_ADDR *remoteHost,
 *                                         char *community,
 *                                         BYTE communityLen,
 *                                         SNMP_ID agentIDVar,
 *                                         BYTE notificationCode,
 *                                         DWORD timestamp)
 *
 * PreCondition:    SNMPInit is already called.
 *
 * Input:           remoteHost  - pointer to remote Host IP address
 *                  community   - Community string to use to notify
 *                  communityLen- Community string length
 *                  agentIDVar  - System ID to use identify this agent
 *                  notificaitonCode - Notification Code to use
 *                  timestamp   - Notification timestamp in 100th
 *                                of second.
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        This function prepares SNMP module to send SNMP
 *                  trap (notification) to remote host.
 *
 * Note:            This is first of series of functions to complete
 *                  SNMP notification.
 ********************************************************************/
void SNMPNotifyPrepare(IP_ADDR *remoteHost,
                        char *community,
                        BYTE communityLen,
                        SNMP_ID agentIDVar,
                        BYTE notificationCode,
                        DWORD timestamp )
{
    strcpy(SNMPNotifyInfo.community, community);
    SNMPNotifyInfo.communityLen = communityLen;

    SNMPNotifyInfo.agentIDVar = agentIDVar;
    SNMPNotifyInfo.notificationCode = notificationCode;

    SNMPNotifyInfo.timestamp.Val = timestamp;

    ARPResolve(remoteHost);
}



/*********************************************************************
 * Function:        BOOL SNMPIsNotifyReady(IP_ADDR *remoteHost)
 *
 * PreCondition:    SNMPNotifyPrepare is already called and returned
 *                  TRUE.
 *
 * Input:           remoteHost  - pointer to remote Host IP address
 *
 * Output:          TRUE if remoteHost IP address is resolved and
 *                         SNMPNotify may be called.
 *                  FALSE otherwise.
 *                      This would fail if there were not UDP socket
 *                      to open.
 *
 * Side Effects:    None
 *
 * Overview:        This function resolves given remoteHost IP address
 *                  into MAC address using ARP module.
 *                  If remoteHost is not aviailable, this function
 *                  would never return TRUE.
 *                  Application must implement timeout logic to
 *                  handle "remoteHost not avialable" situation.
 *
 * Note:            None
 ********************************************************************/
BOOL SNMPIsNotifyReady(IP_ADDR *remoteHost)
{
    NODE_INFO remoteNode;

    if ( ARPIsResolved(remoteHost, &remoteNode.MACAddr) )
    {
        remoteNode.IPAddr.Val = remoteHost->Val;

        SNMPNotifyInfo.socket = UDPOpen(AGENT_NOTIFY_PORT, &remoteNode, SNMP_NMS_PORT);

        return (SNMPNotifyInfo.socket != INVALID_UDP_SOCKET);
    }

    return FALSE;
}



/*********************************************************************
 * Function:        BOOL SNMPNotify(SNMP_ID var,
 *                                  SNMP_VAL val,
 *                                  SNMP_INDEX index)
 *
 * PreCondition:    SNMPIsNotified is already called and returned
 *                  TRUE.
 *
 * Input:           var     - SNMP var ID that is to be used in
 *                            notification
 *                  val     - Value of var. Only value of
 *                            BYTE, WORD or DWORD can be sent.
 *                  index   - Index of var. If this var is a single,
 *                            index would be 0, or else if this var
 *                            is a sequence, index could be any
 *                            value from 0 to 127.
 *
 * Output:          TRUE if SNMP notification was successful sent.
 *                      This does not guarantee that remoteHost recieved
 *                      it.
 *                  FALSE otherwise.
 *                      This would fail under following contions:
 *                      1) Given SNMP_BIB_FILE does not exist in MPFS
 *                      2) Given var does not exist.
 *                      3) Previously given agentID does not exist
 *                      4) Data type of given var is unknown - only
 *                              possible if MPFS itself was corrupted.
 *
 * Side Effects:    None
 *
 * Overview:        This function creates SNMP trap PDU and sends it
 *                  to previously specified remoteHost.
 *
 * Note:            None
 ********************************************************************/
BOOL SNMPNotify(SNMP_ID var,
               SNMP_VAL val,
               SNMP_INDEX index)
{
    BYTE len;
    BYTE OIDValue[OID_MAX_LEN];
    BYTE OIDLen;
    BYTE agentIDLen;
    BYTE *pOIDValue;
    OID_INFO rec;
    DATA_TYPE_INFO dataTypeInfo;
    WORD packetStructLenOffset;
    WORD pduStructLenOffset;
    WORD varBindStructLenOffset;
    WORD varPairStructLenOffset;
    WORD prevOffset;
    char *pCommunity;
    MPFS hMIBFile;

    char snmpBIBFile[] = SNMP_BIB_FILE_NAME;

    hMIBFile = MPFSOpen((BYTE*)snmpBIBFile);
    if ( hMIBFile == MPFS_INVALID )
    {
        UDPClose(SNMPNotifyInfo.socket);
        return FALSE;
    }

    _SNMPDuplexInit(SNMPNotifyInfo.socket);

    len = SNMPNotifyInfo.communityLen;
    pCommunity = SNMPNotifyInfo.community;

    _SNMPPut(STRUCTURE);            // First item is packet structure
    packetStructLenOffset = SNMPTxOffset;
    _SNMPPut(0);

    // Put SNMP version info - only v1.0 is supported.
    _SNMPPut(ASN_INT);              // Int type.
    _SNMPPut(1);                    // One byte long value.
    _SNMPPut(SNMP_V1);              // v1.0.

    //len = strlen(community);  // Save community length for later use.
    _SNMPPut(OCTET_STRING);         // Octet string type.
    _SNMPPut(len);                  // community string length
    while( len-- )                  // Copy entire string.
        _SNMPPut(*(pCommunity++));

    // Put PDU type.  SNMP agent's response is always GET RESPONSE
    _SNMPPut(TRAP);
    pduStructLenOffset = SNMPTxOffset;
    _SNMPPut(0);

    // Get complete OID string from MPFS.
    if ( !GetOIDStringByID(SNMPNotifyInfo.agentIDVar,
                           &rec, OIDValue, &agentIDLen) )
    {
        MPFSClose();
        UDPClose(SNMPNotifyInfo.socket);
        return FALSE;
    }

    if ( !rec.nodeInfo.Flags.bIsAgentID )
    {
        MPFSClose();
        UDPClose(SNMPNotifyInfo.socket);
        return FALSE;
    }

    MPFSGetBegin(rec.hData);

    _SNMPPut(ASN_OID);
    len = MPFSGet();
    agentIDLen = len;
    _SNMPPut(len);
    while( len-- )
        _SNMPPut(MPFSGet());

    MPFSGetEnd();

    // This agent's IP address.
    _SNMPPut(SNMP_IP_ADDR);
    _SNMPPut(4);
    _SNMPPut(MY_IP_BYTE1);
    _SNMPPut(MY_IP_BYTE2);
    _SNMPPut(MY_IP_BYTE3);
    _SNMPPut(MY_IP_BYTE4);

    // Trap code
    _SNMPPut(ASN_INT);
    _SNMPPut(1);
    _SNMPPut(6);            // Enterprisespecific trap code

    _SNMPPut(ASN_INT);
    _SNMPPut(1);
    _SNMPPut(SNMPNotifyInfo.notificationCode);

    // Time stamp
    _SNMPPut(SNMP_TIME_TICKS);
    _SNMPPut(4);
    _SNMPPut(SNMPNotifyInfo.timestamp.v[3]);
    _SNMPPut(SNMPNotifyInfo.timestamp.v[2]);
    _SNMPPut(SNMPNotifyInfo.timestamp.v[1]);
    _SNMPPut(SNMPNotifyInfo.timestamp.v[0]);

    // Variable binding structure header
    _SNMPPut(0x30);
    varBindStructLenOffset = SNMPTxOffset;
    _SNMPPut(0);

    // Create variable name-pair structure
    _SNMPPut(0x30);
    varPairStructLenOffset = SNMPTxOffset;
    _SNMPPut(0);

    // Get complete notification variable OID string.
    if ( !GetOIDStringByID(var, &rec, OIDValue, &OIDLen) )
    {
        MPFSClose();
        UDPClose(SNMPNotifyInfo.socket);
        return FALSE;
    }

    // Copy OID string into packet.
    _SNMPPut(ASN_OID);
    _SNMPPut((BYTE)(OIDLen+1));
    len = OIDLen;
    pOIDValue = OIDValue;
    while( len-- )
        _SNMPPut(*pOIDValue++);
    _SNMPPut(index);

    // Encode and Copy actual data bytes
    if ( !GetDataTypeInfo(rec.dataType, &dataTypeInfo) )
    {
        MPFSClose();
        UDPClose(SNMPNotifyInfo.socket);
        return FALSE;
    }

    _SNMPPut(dataTypeInfo.asnType);
    // In this version, only data type of 4 bytes or less long can be
    // notification variable.
    if ( dataTypeInfo.asnLen == 0xff )
    {
        MPFSClose();
        UDPClose(SNMPNotifyInfo.socket);
        return FALSE;
    }

    len = dataTypeInfo.asnLen;
    _SNMPPut(len);
    while( len-- )
        _SNMPPut(val.v[len]);

    len = dataTypeInfo.asnLen           // data bytes count
         + 1                            // Length byte
         + 1                            // Data type byte
         + OIDLen                       // OID bytes
         + 2                            // OID header bytes
         + 1;                           // index byte

    prevOffset = _SNMPGetTxOffset();
    _SNMPSetTxOffset(varPairStructLenOffset);
    _SNMPPut(len);

    len += 2;                           // Variable Binding structure header
    _SNMPSetTxOffset(varBindStructLenOffset);
    _SNMPPut(len);

    len = len
        + 2                             // Var bind struct header
        + 6                             // 6 bytes of timestamp
        + 3                             // 3 bytes of trap code
        + 3                             // 3 bytes of notification code
        + 6                             // 6 bytes of agnent IP address
        + agentIDLen                    // Agent ID bytes
        + 2;                                // Agent ID header bytes
    _SNMPSetTxOffset(pduStructLenOffset);
    _SNMPPut(len);

    len = len                           // PDU struct length
        + 2                             // PDU header
        + SNMPNotifyInfo.communityLen            // Community string bytes
        + 2                             // Community header bytes
        + 3;                            // SNMP version bytes
    _SNMPSetTxOffset(packetStructLenOffset);
    _SNMPPut(len);

    _SNMPSetTxOffset(prevOffset);

    MPFSClose();
    UDPFlush();
    UDPClose(SNMPNotifyInfo.socket);

    return TRUE;
}
#endif // Code removed when SNMP_TRAP_DISABLED

static SNMP_ACTION ProcessHeader(char *community, BYTE *len)
{
    DWORD_VAL tempLen;
    SNMP_ACTION pdu;

    // Very first item must be a structure
    if ( !IsValidStructure((WORD*)&tempLen) )
        return SNMP_ACTION_UNKNOWN;

    // Only SNMP v1.0 is supported.
    if ( !IsValidInt(&tempLen.Val) )
        return SNMP_ACTION_UNKNOWN;

    if ( tempLen.v[0] != SNMP_V1 )
        return SNMP_ACTION_UNKNOWN;

    // This function populates response as it processes community string.
    if ( !IsValidCommunity(community, len) )
        return SNMP_ACTION_UNKNOWN;

    // Fetch and validate pdu type.  Only "Get" and "Get Next" are expected.
    if ( !IsValidPDU(&pdu) )
        return SNMP_ACTION_UNKNOWN;

    // Ask main application to verify community name against requested
    // pdu type.
    if ( !SNMPValidate(pdu, community) )
        return SNMP_ACTION_UNKNOWN;

    return pdu;
}

static BOOL ProcessGetSetHeader(DWORD *requestID)
{
    DWORD_VAL tempData;

    // Fetch and save request ID.
    if ( IsValidInt(&tempData.Val) )
        *requestID = tempData.Val;
    else
        return FALSE;

    // Fetch and discard error status
    if ( !IsValidInt(&tempData.Val) )
        return FALSE;

    // Fetch and disacard error index
    return IsValidInt(&tempData.Val);
}


static BOOL ProcessVariables(char *community, BYTE len, DWORD_VAL *request, BYTE pduType)
{
    BYTE temp;
    WORD_VAL varBindingLen;
    WORD_VAL tempLen;
    BYTE errorIndex;
    SNMP_ERR_STATUS errorStatus;
    BYTE varIndex;
    WORD packetStructLenOffset;
    WORD pduLenOffset;
    WORD errorStatusOffset;
    WORD errorIndexOffset;
    WORD varBindStructOffset;
    WORD varStructLenOffset;
    BYTE OIDValue[OID_MAX_LEN];
    BYTE OIDLen;
    BYTE *ptemp;
    OID_INFO OIDInfo;
    WORD_VAL varPairLen;
    WORD_VAL varBindLen;
    BYTE communityLen;
    WORD oidOffset;
    WORD prevOffset;


    // Before each variables are processed, prepare necessary header.
    _SNMPPut(STRUCTURE);            // First item is packet structure
    // Since we do not know length of structure at this point, use
    // placeholder bytes that will be replaced with actual value.
    _SNMPPut(0x82);
    packetStructLenOffset = SNMPTxOffset;
    _SNMPPut(0);
    _SNMPPut(0);

    // Put SNMP version info - only v1.0 is supported.
    _SNMPPut(ASN_INT);              // Int type.
    _SNMPPut(1);                    // One byte long value.
    _SNMPPut(SNMP_V1);              // v1.0.

    // Put community string
    communityLen = len;             // Save community length for later use.
    _SNMPPut(OCTET_STRING);         // Octet string type.
    _SNMPPut(len);                  // community string length
    while( len-- )                  // Copy entire string.
        _SNMPPut(*community++);

    // Put PDU type.  SNMP agent's response is always GET RESPONSE
    _SNMPPut(GET_RESPONSE);
    // Since we don't know length of this response, use placeholders until
    // we know for sure...
    _SNMPPut(0x82);                    // Be prepared for 2 byte-long length
    pduLenOffset = SNMPTxOffset;
    _SNMPPut(0);
    _SNMPPut(0);

    // Put original request back.
    _SNMPPut(ASN_INT);              // Int type.
    _SNMPPut(4);                    // To simplify logic, always use 4 byte long requestID
    _SNMPPut(request->v[3]);         // Start MSB
    _SNMPPut(request->v[2]);
    _SNMPPut(request->v[1]);
    _SNMPPut(request->v[0]);

    // Put error status.
    // Since we do not know error status, put place holder until we know it...
    _SNMPPut(ASN_INT);              // Int type
    _SNMPPut(1);                    // One byte long.
    errorStatusOffset = SNMPTxOffset;
    _SNMPPut(0);                    // Placeholder.

    // Similarly put error index.
    _SNMPPut(ASN_INT);              // Int type
    _SNMPPut(1);                    // One byte long
    errorIndexOffset = SNMPTxOffset;
    _SNMPPut(0);                    // Placeholder.

    varIndex    = 0;
    errorIndex  = 0;
    errorStatus = SNMP_NO_ERR;

    // Decode variable binding structure
    if ( !IsValidStructure(&varBindingLen.Val) )
        return FALSE;

    // Put variable binding response structure
    _SNMPPut(STRUCTURE);
    _SNMPPut(0x82);
    varBindStructOffset = SNMPTxOffset;
    _SNMPPut(0);
    _SNMPPut(0);

    varBindLen.Val = 0;

    while( varBindingLen.Val )
    {
        // Need to know what variable we are processing, so that in case
        // if there is problem for that varaible, we can put it in
        // errorIndex location of SNMP packet.
        varIndex++;

        // Decode variable length structure
        temp = IsValidStructure(&tempLen.Val);
        if ( !temp )
            return FALSE;

        varBindingLen.Val -= tempLen.Val;
        varBindingLen.Val -= temp;


        // Prepare variable response structure.
        _SNMPPut(STRUCTURE);
        _SNMPPut(0x82);
        varStructLenOffset = SNMPTxOffset;
        _SNMPPut(0);
        _SNMPPut(0);

        // Decode next object
        if ( !IsValidOID(OIDValue, &OIDLen) )
            return FALSE;

        // For Get & Get-Next, value must be NULL.
        if ( pduType != (BYTE)SET_REQUEST )
        {
            if ( !IsASNNull() )
                return FALSE;
        }

        // Prepare response - original variable
        _SNMPPut(ASN_OID);
        oidOffset = SNMPTxOffset;
        _SNMPPut(OIDLen);
        ptemp = OIDValue;
        temp = OIDLen;
        while( temp-- )
            _SNMPPut(*ptemp++);

        // Lookup current OID into our compiled database.
        if ( !OIDLookup(OIDValue, OIDLen, &OIDInfo) )
        {

            errorStatus = SNMP_NO_SUCH_NAME;

            SetErrorStatus(errorStatusOffset,
                            errorIndexOffset,
                            SNMP_NO_SUCH_NAME,
                            varIndex);

            if ( pduType != SNMP_SET )
            {
                _SNMPPut(ASN_NULL);
                _SNMPPut(0);
                varPairLen.Val = OIDLen + 4;
            }
            else
            {
                // Copy original value as it is and goto next variable.
                // Copy data type
                _SNMPPut(_SNMPGet());

                // Get data length.
                temp = _SNMPGet();
                _SNMPPut(temp);

                // Start counting total number of bytes in this structure.
                varPairLen.Val = OIDLen         // OID name bytes
                                + 2             // OID header bytes
                                + 2;            // Value header bytes

                // Copy entire data bytes as it is.
                while( temp-- )
                {
                    varPairLen.Val++;
                    _SNMPPut(_SNMPGet());
                }
            }

        }

        else
        {
            // Now handle specific pduType request...
            if ( pduType == SNMP_GET )
            {
                // Start counting total number of bytes in this structure.
                varPairLen.Val = OIDLen + 2;

                prevOffset = _SNMPGetTxOffset();
                temp = ProcessGetVar(&OIDInfo, FALSE);
                if ( temp == 0 )
                {
                    _SNMPSetTxOffset(prevOffset);
                    errorStatus = SNMP_NO_SUCH_NAME;

                    SetErrorStatus(errorStatusOffset,
                                   errorIndexOffset,
                                   SNMP_NO_SUCH_NAME,
                                   varIndex);

                    _SNMPPut(ASN_NULL);
                    _SNMPPut(0);
                    temp = 2;
                }
                varPairLen.Val += temp;
            }

            else if ( pduType == SNMP_GET_NEXT )
            {
                prevOffset = _SNMPGetTxOffset();
                _SNMPSetTxOffset(oidOffset);
                temp = ProcessGetNextVar(&OIDInfo);
                if ( temp == 0 )
                {
                    _SNMPSetTxOffset(prevOffset);

                    SetErrorStatus(errorStatusOffset,
                                   errorIndexOffset,
                                   SNMP_NO_SUCH_NAME,
                                   varIndex);


                    _SNMPPut(ASN_NULL);
                    _SNMPPut(0);

                    // Start counting total number of bytes in this structure.
                    varPairLen.Val = OIDLen             // as put by GetNextVar()
                                     + 2                // OID header
                                     + 2;               // ASN_NULL bytes

                }
                else
                    varPairLen.Val = (temp + 2);        // + OID headerbytes
            }

            else if ( pduType == SNMP_SET )
            {
                temp = ProcessSetVar(&OIDInfo, &errorStatus);
                if ( errorStatus != SNMP_NO_ERR )
                {
                    SetErrorStatus(errorStatusOffset,
                                   errorIndexOffset,
                                   errorStatus,
                                   varIndex);
                }
                varPairLen.Val = OIDLen +2              // OID name + header bytes
                                + temp;                 // value bytes as put by SetVar
            }

        }
        prevOffset = _SNMPGetTxOffset();

        _SNMPSetTxOffset(varStructLenOffset);
        _SNMPPut(varPairLen.byte.MSB);
        _SNMPPut(varPairLen.byte.LSB);


        varBindLen.Val += 4                 // Variable Pair STRUCTURE byte + 1 length byte.
                        + varPairLen.Val;

        _SNMPSetTxOffset(prevOffset);
    }


    //MACSetTxBuffer(SNMPTxBuffer, varBindStructOffset);
    _SNMPSetTxOffset(varBindStructOffset);
    _SNMPPut(varBindLen.byte.MSB);
    _SNMPPut(varBindLen.byte.LSB);

    // varBindLen is reused as "pduLen"
    varBindLen.Val = varBindLen.Val+4           // Variable Binding Strucure length
                + 6                         // Request ID bytes
                + 3                         // Error status
                + 3;                        // Error index

    //MACSetTxBuffer(SNMPTxBuffer, pduLenOffset);
    _SNMPSetTxOffset(pduLenOffset);
    _SNMPPut(varBindLen.byte.MSB);
    _SNMPPut(varBindLen.byte.LSB);

    // varBindLen is reused as "packetLen".
    varBindLen.Val = 3                      // SNMP Version bytes
                    + 2 + communityLen      // community string bytes
                    + 4                     // PDU structure header bytes.
                    + varBindLen.Val;

    //MACSetTxBuffer(SNMPTxBuffer, packetStructLenOffset);
    _SNMPSetTxOffset(packetStructLenOffset);
    _SNMPPut(varBindLen.byte.MSB);
    _SNMPPut(varBindLen.byte.LSB);


    return TRUE;
}




static BYTE ProcessGetNextVar(OID_INFO *rec)
{
    WORD_VAL temp;
    BYTE putBytes;
    OID_INFO indexRec;
    BYTE *pOIDValue;
    BYTE OIDValue[51];
    BYTE OIDLen;
    INDEX_INFO indexInfo;
    MIB_INFO varNodeInfo;
    SNMP_ID varID;
    WORD OIDValOffset;
    WORD prevOffset;
    BOOL lbNextLeaf;
    BYTE ref;
    SNMP_VAL v;
    BYTE varDataType;
    BYTE indexBytes;

    lbNextLeaf = FALSE;
    temp.byte.LSB = 0;

    // Get next leaf only if this OID is a parent or a simple leaf
    // node.
    if ( rec->nodeInfo.Flags.bIsParent ||
        (!rec->nodeInfo.Flags.bIsParent && !rec->nodeInfo.Flags.bIsSequence) )
    {
_GetNextLeaf:
        lbNextLeaf = TRUE;
        if ( !GetNextLeaf(rec) )
            return 0;
    }

    // Get complete OID string from oid record.
    if ( !GetOIDStringByAddr(rec, OIDValue, &OIDLen) )
        return 0;

    // Copy complete OID string to create response packet.
    pOIDValue = OIDValue;
    OIDValOffset = _SNMPGetTxOffset();
    temp.byte.LSB = OIDLen;
    _SNMPSetTxOffset(OIDValOffset+1);
    while( temp.byte.LSB-- )
        _SNMPPut(*pOIDValue++);

    // Start counting number of bytes put - OIDLen is already counted.
    temp.byte.LSB = OIDLen;


    varDataType = rec->dataType;
    varID = rec->id;


    // If this is a simple OID, handle it as a GetVar command.
    if ( !rec->nodeInfo.Flags.bIsSequence )
    {
        // This is an addition to previously copied OID string.
        // This is index value of '0'.
        _SNMPPut(0);
        temp.byte.LSB++;

        // Since we added one more byte to previously copied OID
        // string, we need to update OIDLen value.
        prevOffset = _SNMPGetTxOffset();
        _SNMPSetTxOffset(OIDValOffset);
        _SNMPPut(++OIDLen);
        _SNMPSetTxOffset(prevOffset);

        // Now do Get on this simple variable.
        prevOffset = _SNMPGetTxOffset();
        putBytes = ProcessGetVar(rec, FALSE);
        if ( putBytes == 0 )
        {
            _SNMPSetTxOffset(prevOffset);
            _SNMPPut(ASN_NULL);
            _SNMPPut(0);
            putBytes = 2;
        }

        temp.byte.LSB += putBytes; // ProcessGetVar(rec, FALSE);

        // Return with total number of bytes copied to response packet.
        return temp.byte.LSB;
    }

    // This is a sequence variable.

    // First of all make sure that there is a next index after this
    // index.  We also need to make sure that we do not do this foerever.
    // So make sure that this is not a repeat test.
    ref = 0;
    if ( lbNextLeaf == TRUE )
    {
        // Let application tell us whether this is a valid index or not.
        if ( !SNMPGetVar(rec->id, rec->index, &ref, &v) )
        {
            // If not, then we need to get next leaf in line.
            // Remember that we have already did this once, so that we do not
            // do this forever.
            //lbNextSequence = TRUE;

            // Reset the response packet pointer to begining of OID.
            _SNMPSetTxOffset(OIDValOffset);

            // Jump to this label within this function - Not a good SW engineering
            // practice, but this will reuse code at much lower expense.
            goto _GetNextLeaf;
        }
    }

    // Need to fetch index information from MIB and prepare complete OID+
    // index response.

    varNodeInfo.Val = rec->nodeInfo.Val;

    MPFSGetBegin(MPFSTell());

    // In this version, only 7-bit index is supported.
    MPFSGet();

    indexBytes = 0;

    indexInfo.Val = MPFSGet();

    // Fetch index ID.
    indexRec.id = MPFSGet();
    // Fetch index data type.
    indexRec.dataType = MPFSGet();

    indexRec.index = rec->index;

    MPFSGetEnd();

    // Check with application to see if there exists next index
    // for this index id.
    if ( !lbNextLeaf && !SNMPGetNextIndex(indexRec.id, &indexRec.index) )
    {
        //lbNextSeqeuence = TRUE;

        // Reset the response packet pointer to begining of OID.
        _SNMPSetTxOffset(OIDValOffset);

        // Jump to this label.  Not a good practice, but once-in-a-while
        // it should be acceptable !
        goto _GetNextLeaf;
    }

    // Index is assumed to be dynamic, and leaf node.
    // mib2bib has already ensured that this was the case.
    indexRec.nodeInfo.Flags.bIsConstant = 0;
    indexRec.nodeInfo.Flags.bIsParent = 0;
    indexRec.nodeInfo.Flags.bIsSequence = 1;

    // Now handle this as simple GetVar.
    // Keep track of number of bytes added to OID.
    indexBytes += ProcessGetVar(&indexRec, TRUE);

    rec->index = indexRec.index;

    // These are the total number of bytes put so far as a result of this function.
    temp.byte.LSB += indexBytes;

    // These are the total number of bytes in OID string including index bytes.
    OIDLen += indexBytes;

    // Since we added index bytes to previously copied OID
    // string, we need to update OIDLen value.
    prevOffset = _SNMPGetTxOffset();
    _SNMPSetTxOffset(OIDValOffset);
    _SNMPPut(OIDLen);
    _SNMPSetTxOffset(prevOffset);


    // Fetch actual value itself.
    // Need to restore original OID value.
    rec->nodeInfo.Val = varNodeInfo.Val;
    rec->id = varID;
    rec->dataType = varDataType;

    temp.byte.LSB += ProcessGetVar(rec, FALSE);

    return temp.byte.LSB;
}




// This is the binary mib format:
// <oid, nodeInfo, [id], [SiblingOffset], [DistantSibling], [dataType], [dataLen], [data], [{IndexCount, <IndexType>, <Index>, ...>]}, ChildNode
static BOOL OIDLookup(BYTE *oid, BYTE oidLen, OID_INFO *rec)
{
    WORD_VAL tempData;
    BYTE tempOID;
    MPFS hNode;
    BYTE matchedCount;

    if ( !SNMPStatus.Flags.bIsFileOpen )
        return FALSE;


    hNode = MPFSSeek(0);
    matchedCount = oidLen;

    // Begin reading the data...
    //MPFSGetBegin(hNode);

    while( 1 )
    {
        MPFSGetBegin(hNode);

        // Remember offset of this node so that we can find its sibling
        // and child data.
        rec->hNode = MPFSTell(); // hNode;

        // Read OID byte.
        tempOID = MPFSGet();

        // Read Node Info
        rec->nodeInfo.Val = MPFSGet();

        // Next byte will be node id, if this is a leaf node with variable data.
        if ( rec->nodeInfo.Flags.bIsIDPresent )
            rec->id = MPFSGet();

        // Read sibling offset, if there is any.
        if ( rec->nodeInfo.Flags.bIsSibling )
        {
            tempData.v[0] = MPFSGet();
            tempData.v[1] = MPFSGet();
            rec->hSibling = (MPFS)tempData.Val;
        }

        if ( tempOID != *oid )
        {
            // If very first OID byte does not match, it may be because it is
            // 0, 1 or 2.  In that case declare that there is a match.
            // The command processor would detect OID type and continue or reject
            // this OID as a valid argument.
            if ( matchedCount == oidLen )
                goto FoundIt;

            if ( rec->nodeInfo.Flags.bIsSibling )
            {
                MPFSGetEnd();
                hNode = MPFSSeek((MPFS)tempData.Val);
            }
            else
                goto DidNotFindIt;
        }
        else
        {
            // One more oid byte matched.
            matchedCount--;
            oid++;

            // A node is said to be matched if last matched node is a leaf node
            // or all but last OID string is matched and last byte of OID is '0'.
            // i.e. single index.
            if ( !rec->nodeInfo.Flags.bIsParent )
            {
                // Read and discard Distant Sibling info if there is any.
                if ( rec->nodeInfo.Flags.bIsDistantSibling )
                {
                    tempData.v[0] = MPFSGet();
                    tempData.v[1] = MPFSGet();
                    rec->hSibling = (MPFS)tempData.Val;
                }


                rec->dataType = MPFSGet();
                rec->hData = MPFSTell();

                goto FoundIt;
            }

            else if ( matchedCount == 1 && *oid == 0x00 )
            {
                goto FoundIt;
            }

            else if ( matchedCount == 0 )
            {
                goto FoundIt;
            }

            else
            {
                //hNode = rec->hChild;
                hNode = MPFSTell();
                MPFSGetEnd();
                // Try to match following child node.
                continue;
            }
        }
    }

FoundIt:
    MPFSGetEnd();
    // Convert index info from OID to regular value format.
    tempOID = *oid;
    rec->index = tempOID;

    // In this version, we only support 7-bit index.
    if ( matchedCount == 0 )
    {
        rec->index = SNMP_INDEX_INVALID;
        rec->indexLen = 0;
    }

    else if ( matchedCount > 1 || tempOID & 0x80 )
    {
        // Current instnace spans across more than 7-bit.
        rec->indexLen = 0xff;
        return FALSE;
    }
    else
        rec->indexLen = 1;



    return TRUE;

DidNotFindIt:
    MPFSGetEnd();
    return FALSE;
}


static BOOL GetNextLeaf(OID_INFO *n)
{
    WORD_VAL temp;

    // If current node is leaf, its next sibling (near or distant) is the next leaf.
    if ( !n->nodeInfo.Flags.bIsParent )
    {
        // Since this is a leaf node, it must have at least one distant or near
        // sibling to get next sibling.
        if ( n->nodeInfo.Flags.bIsSibling ||
             n->nodeInfo.Flags.bIsDistantSibling )
        {
            // Reposition at sibling.
            MPFSSeek(n->hSibling);

            // Fetch node related information
        }
        // There is no sibling to this leaf.  This must be the very last node on the tree.
        else
        {
            //--MPFSClose();
            return FALSE;
        }
    }

    while( 1 )
    {
        // Remember current MPFS position for this node.
        n->hNode = MPFSTell();

        MPFSGetBegin(n->hNode);


        // Read OID byte.
        n->oid = MPFSGet();

        // Read Node Info
        n->nodeInfo.Val = MPFSGet();

        // Next byte will be node id, if this is a leaf node with variable data.
        if ( n->nodeInfo.Flags.bIsIDPresent )
            n->id = MPFSGet();

        // Fetch sibling offset, if there is any.
        if ( n->nodeInfo.Flags.bIsSibling ||
             n->nodeInfo.Flags.bIsDistantSibling )
        {
            temp.byte.LSB = MPFSGet();
            temp.byte.MSB = MPFSGet();
            n->hSibling = temp.Val;
        }

        // If we have not reached a leaf yet, continue fetching next child in line.
        if ( n->nodeInfo.Flags.bIsParent )
        {
            MPFSGetEnd();
            continue;
        }

        // Fetch data type.
        n->dataType = MPFSGet();

        n->hData = MPFSTell();

        // Since we just found next leaf in line, it will always have zero index
        // to it.
        n->indexLen = 1;
        n->index = 0;

        MPFSGetEnd();

        return TRUE;
    }

    return FALSE;
}





static BOOL IsValidCommunity(char* community, BYTE *len)
{
    BYTE tempData;
    BYTE tempLen;

    tempData = _SNMPGet();
    if ( !IS_OCTET_STRING(tempData) )
        return FALSE;

    tempLen = _SNMPGet();
    *len    = tempLen;
    if ( tempLen > SNMP_COMMUNITY_MAX_LEN )
        return FALSE;

    while( tempLen-- )
    {
        tempData = _SNMPGet();
        *community++ = tempData;
    }
    *community = '\0';

    return TRUE;
}


static BOOL IsValidInt(DWORD *val)
{
    DWORD_VAL tempData;
    DWORD_VAL tempLen;

    tempLen.Val = 0;

    // Get variable type
    if ( !IS_ASN_INT(_SNMPGet()) )
        return FALSE;

    if ( !IsValidLength(&tempLen.word.LSW) )
        return FALSE;

    // Integer length of more than 32-bit is not supported.
    if ( tempLen.Val > 4 )
        return FALSE;

    tempData.Val = 0;
    while( tempLen.v[0]-- )
        tempData.v[tempLen.v[0]] = _SNMPGet();

    *val = tempData.Val;

    return TRUE;
}

static BOOL IsValidPDU(SNMP_ACTION *pdu)
{
    BYTE tempData;
    WORD tempLen;


    // Fetch pdu data type
    tempData = _SNMPGet();
    if ( !IS_AGENT_PDU(tempData) )
        return FALSE;

    *pdu = tempData;

    // Now fetch pdu length.  We don't need to remember pdu length.
    return IsValidLength(&tempLen);
}

// Checks current packet and returns total length value
// as well as actual length bytes.
static BYTE IsValidLength(WORD *len)
{
    BYTE tempData;
    WORD_VAL tempLen;
    BYTE lengthBytes;

    // Initialize length value.
    tempLen.Val = 0;
    lengthBytes = 0;

    tempData = _SNMPGet();
    tempLen.v[0] = tempData;
    if ( tempData & 0x80 )
    {
        tempData &= 0x7F;

        // We do not support any length byte count of more than 2
        // i.e. total length value must not be more than 16-bit.
        if ( tempData > 2 )
            return FALSE;

        // Total length bytes are 0x80 itself plus tempData.
        lengthBytes = tempData + 1;

        // Get upto 2 bytes of length value.
        while( tempData-- )
            tempLen.v[tempData] = _SNMPGet();
    }
    else
        lengthBytes = 1;

    *len = tempLen.Val;

    return lengthBytes;
}

static BOOL IsASNNull(void)
{
    // Fetch and verify that this is NULL data type.
    if ( !IS_ASN_NULL(_SNMPGet()) )
        return FALSE;

    // Fetch and verify that length value is zero.
    return (_SNMPGet() == 0 );
}

static BOOL IsValidOID(BYTE *oid, BYTE *len)
{
    DWORD_VAL tempLen;

    // Fetch and verify that this is OID.
    if ( !IS_OID(_SNMPGet()) )
        return FALSE;

    // Retrieve OID length
    if ( !IsValidLength(&tempLen.word.LSW) )
        return FALSE;

    // Make sure that OID length is within our capability.
    if ( tempLen.word.LSW > OID_MAX_LEN )
        return FALSE;

    *len = tempLen.v[0];

    while( tempLen.v[0]-- )
        *oid++ = _SNMPGet();


    return TRUE;
}


static BYTE IsValidStructure(WORD *dataLen)
{
    DWORD_VAL tempLen;
    BYTE headerBytes;


    if ( !IS_STRUCTURE(_SNMPGet()) )
        return FALSE;

    // Retrieve structure length
    headerBytes = IsValidLength(&tempLen.word.LSW);
    if ( !headerBytes )
        return FALSE;

    headerBytes++;


    // Since we are using UDP as our transport and UDP are not fragmented,
    // this structure length cannot be more than 1500 bytes.
    // As a result, we will only use lower WORD of length value.
    *dataLen = tempLen.word.LSW;

    return headerBytes;
}




static void _SNMPDuplexInit(UDP_SOCKET socket)
{
    // In full duplex transfer, transport protocol must be ready to
    // accept new transmit packet.
    while( !UDPIsPutReady(socket) ) ;

    // Fetch and remember current tx and rx buffer id.
    SNMPRxBuffer = MACGetRxBuffer();
    SNMPTxBuffer = MACGetTxBuffer();

    // Initialize buffer offsets.
    SNMPRxOffset = 0;
    SNMPTxOffset = 0;
}


static void _SNMPPut(BYTE v)
{
    UDPSetTxBuffer(SNMPTxBuffer, SNMPTxOffset);

    UDPPut(v);

    SNMPTxOffset++;
}


static BYTE _SNMPGet(void)
{
    BYTE v;

    UDPSetRxBuffer(SNMPRxOffset++);
    UDPGet(&v);
    return v;
}


#if !defined(SNMP_TRAP_DISABED)
static BOOL GetOIDStringByID(SNMP_ID id, OID_INFO *info, BYTE *oidString, BYTE *len)
{
    MPFS hCurrent;

    hCurrent = MPFSSeek(0);

    while (1)
    {
        ReadMIBRecord(hCurrent, info);

        if ( !info->nodeInfo.Flags.bIsParent )
        {
            if ( info->nodeInfo.Flags.bIsIDPresent )
            {
                if ( info->id == id )
                    return GetOIDStringByAddr(info, oidString, len);
            }

            if ( info->nodeInfo.Flags.bIsSibling ||
                 info->nodeInfo.Flags.bIsDistantSibling )
                MPFSSeek(info->hSibling);

            else
                break;

        }
        hCurrent = MPFSTell();
    }
    return FALSE;
}
#endif




static BOOL GetOIDStringByAddr(OID_INFO *rec, BYTE *oidString, BYTE *len)
{
    MPFS hTarget;
    MPFS hCurrent;
    MPFS hNext;
    OID_INFO currentMIB;
    BYTE index;
    enum { SM_PROBE_SIBLING, SM_PROBE_CHILD } state;

    hCurrent = MPFSSeek(0);


    hTarget = rec->hNode;
    state = SM_PROBE_SIBLING;
    index = 0;

    while( 1 )
    {
        ReadMIBRecord(hCurrent, &currentMIB);

        oidString[index] = currentMIB.oid;

        if ( hTarget == hCurrent )
        {
            *len = ++index;

            return TRUE;
        }


        switch(state)
        {
        case SM_PROBE_SIBLING:
            if ( !currentMIB.nodeInfo.Flags.bIsSibling )
                state = SM_PROBE_CHILD;

            else
            {
                hNext = currentMIB.hSibling;
                MPFSSeek(hNext);
                hNext = MPFSTell();
                if ( hTarget >= hNext )
                {
                    hCurrent = hNext;
                    break;
                }
                else
                    state = SM_PROBE_CHILD;
            }

        case SM_PROBE_CHILD:
            if ( !currentMIB.nodeInfo.Flags.bIsParent )
                return FALSE;

            index++;

            hCurrent = currentMIB.hChild;
            state = SM_PROBE_SIBLING;
            break;
        }
    }
    return FALSE;
}

static void ReadMIBRecord(MPFS h, OID_INFO *rec)
{
    MIB_INFO nodeInfo;
    WORD_VAL tempVal;

    MPFSGetBegin(h);

    // Remember location of this record.
    rec->hNode = h;

    // Read OID
    rec->oid = MPFSGet();

    // Read nodeInfo
    rec->nodeInfo.Val = MPFSGet();
    nodeInfo = rec->nodeInfo;

    // Read id, if there is any: Only leaf node with dynamic data will have id.
    if ( nodeInfo.Flags.bIsIDPresent )
        rec->id = MPFSGet();

    // Read Sibling offset if there is any - any node may have sibling
    if ( nodeInfo.Flags.bIsSibling )
    {
        tempVal.byte.LSB = MPFSGet();
        tempVal.byte.MSB = MPFSGet();
        rec->hSibling = (MPFS)tempVal.Val;
    }

    // All rest of the parameters are applicable to leaf node only.
    if ( nodeInfo.Flags.bIsParent )
        rec->hChild = MPFSTell();
    else
    {
        if ( nodeInfo.Flags.bIsDistantSibling )
        {
            // Read Distant Sibling if there is any - only leaf node will have distant sibling
            tempVal.byte.LSB = MPFSGet();
            tempVal.byte.MSB = MPFSGet();
            rec->hSibling = (MPFS)tempVal.Val;
        }

        // Save data type for this node.
        rec->dataType = MPFSGet();

        rec->hData = MPFSTell();

    }

    MPFSGetEnd();
}


static BOOL GetDataTypeInfo(DATA_TYPE dataType, DATA_TYPE_INFO *info )
{
    if ( dataType >= DATA_TYPE_UNKNOWN )
        return FALSE;

    info->asnType   = dataTypeTable[dataType].asnType;
    info->asnLen    = dataTypeTable[dataType].asnLen;

    return TRUE;
}

static BYTE ProcessSetVar(OID_INFO *rec, SNMP_ERR_STATUS *errorStatus)
{
    SNMP_ERR_STATUS errorCode;
    DATA_TYPE_INFO actualDataTypeInfo;
    BYTE dataType;
    BYTE dataLen;
    SNMP_VAL dataValue;
    BYTE ref;
    BYTE temp;
    BYTE copiedBytes;

    // Start with no error.
    errorCode = SNMP_NO_ERR;
    copiedBytes = 0;

    // Non-leaf, Constant and ReadOnly node cannot be modified
    if ( rec->nodeInfo.Flags.bIsParent    ||
         rec->nodeInfo.Flags.bIsConstant  ||
         !rec->nodeInfo.Flags.bIsEditable )
        errorCode = SNMP_NO_SUCH_NAME;

    dataType = _SNMPGet();
    _SNMPPut(dataType);
    copiedBytes++;

    // Get data type for this node.
    //actualDataType = MPFSGet();

    if ( !GetDataTypeInfo(rec->dataType, &actualDataTypeInfo) )
        errorCode = SNMP_BAD_VALUE;

    // Make sure that received data type is same as what is declared
    // for this node.
    if ( dataType != actualDataTypeInfo.asnType )
        errorCode = SNMP_BAD_VALUE;

    // Make sure that received data length is within our capability.
    dataLen = _SNMPGet();
    _SNMPPut(dataLen);
    copiedBytes++;

    // Only max data length of 127 is supported.
    if ( dataLen > 0x7f )
        errorCode = SNMP_BAD_VALUE;

    // If this is a Simple variable and given index is other than '0',
    // it is considered bad value
    if ( !rec->nodeInfo.Flags.bIsSequence && rec->index != 0x00 )
        errorCode = SNMP_NO_SUCH_NAME;

    dataValue.dword = 0;
    ref = 0;

    // If data length is within 4 bytes, fetch all at once and pass it
    // to application.
    if ( actualDataTypeInfo.asnLen != 0xff )
    {
        // According to mib def., this data length for this data type/
        // must be less or equal to 4, if not, we don't know what this
        // is.
        if ( dataLen <= 4 )
        {
            // Now that we have verified data length, fetch them all
            // at once and save it in correct place.
            //dataLen--;

            while( dataLen-- )
            {
                temp = _SNMPGet();
                dataValue.v[dataLen] = temp;

                // Copy same byte back to create response...
                _SNMPPut(temp);
                copiedBytes++;
            }


            // Pass it to application.
            if ( errorCode == SNMP_NO_ERR )
            {
                if ( !SNMPSetVar(rec->id, rec->index, ref, dataValue) )
                    errorCode = SNMP_BAD_VALUE;
            }
        }
        else
            errorCode = SNMP_BAD_VALUE;
    }
    else
    {
        // This is a multi-byte Set operation.
        // Check with application to see if this many bytes can be
        // written to current variable.
        if ( !SNMPIsValidSetLen(rec->id, dataLen) )
            errorCode = SNMP_BAD_VALUE;

        // Even though there may have been error processing this
        // variable, we still need to reply with original data
        // so at least copy those bytes.
        while( dataLen-- )
        {
            dataValue.byte = _SNMPGet();

            _SNMPPut(dataValue.byte);
            copiedBytes++;

            // Ask applicaton to set this variable only if there was
            // no previous error.
            if ( errorCode == SNMP_NO_ERR )
            {
                if ( !SNMPSetVar(rec->id, rec->index, ref++, dataValue) )
                    errorCode = SNMP_BAD_VALUE;
            }
        }
        // Let application know about end of data transfer
        if ( errorCode == SNMP_NO_ERR )
            SNMPSetVar(rec->id, rec->index, (WORD)SNMP_END_OF_VAR, dataValue);
    }

    *errorStatus = errorCode;

    return copiedBytes;
}




static BYTE ProcessGetVar(OID_INFO *rec, BOOL bAsOID)
{
    BYTE ref;
    BYTE temp;
    SNMP_VAL v;
    BYTE varLen;
    BYTE dataType;
    DATA_TYPE_INFO dataTypeInfo;
    WORD offset;
    WORD prevOffset;

    v.dword   = 0;

    // Non-leaf node does not contain any data.
    if ( rec->nodeInfo.Flags.bIsParent )
        return 0;

    // If current OID is Simple variable and index is other than .0
    // we don't Get this variable.
    if ( !rec->nodeInfo.Flags.bIsSequence )
    {
        // index of other than '0' is not invalid.
        if ( rec->index > 0 )
            return 0;
    }

    dataType = rec->dataType;
    if ( !GetDataTypeInfo(dataType, &dataTypeInfo) )
        return 0;

    if ( !bAsOID )
    {
        _SNMPPut(dataTypeInfo.asnType);

        offset = SNMPTxOffset;
        _SNMPPut(dataTypeInfo.asnLen);
    }

    if ( rec->nodeInfo.Flags.bIsConstant )
    {
        MPFSGetBegin(rec->hData);

        varLen = MPFSGet();
        temp = varLen;
        while( temp-- )
            _SNMPPut(MPFSGet());

        MPFSGetEnd();
    }
    else
    {
        ref = SNMP_START_OF_VAR;
        v.dword = 0;
        varLen = 0;

        do
        {
            if ( SNMPGetVar(rec->id, rec->index, &ref, &v) )
            {
                if ( dataTypeInfo.asnLen != 0xff )
                {
                    varLen = dataTypeInfo.asnLen;

                    while( dataTypeInfo.asnLen )
                        _SNMPPut(v.v[--dataTypeInfo.asnLen]);

                    break;
                }
                else
                {
                    varLen++;
                    _SNMPPut(v.v[0]);
                }
            }
            else
                return 0;

        } while( ref != SNMP_END_OF_VAR );
    }

    if ( !bAsOID )
    {
        prevOffset = _SNMPGetTxOffset();

        _SNMPSetTxOffset(offset);
        _SNMPPut(varLen);

        _SNMPSetTxOffset(prevOffset);

        varLen++;
        varLen++;
    }


    return varLen;
}


static void SetErrorStatus(WORD errorStatusOffset,
                           WORD errorIndexOffset,
                           SNMP_ERR_STATUS errorStatus,
                           BYTE errorIndex)
{
    WORD prevOffset;

    prevOffset = _SNMPGetTxOffset();

    _SNMPSetTxOffset(errorStatusOffset);
    _SNMPPut((BYTE)errorStatus);

    _SNMPSetTxOffset(errorIndexOffset);
    _SNMPPut(errorIndex);

    _SNMPSetTxOffset(prevOffset);
}
