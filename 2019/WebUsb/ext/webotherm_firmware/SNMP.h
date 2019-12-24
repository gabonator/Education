/*********************************************************************
 *
 *                  SNMP Defs for Microchip TCP/IP Stack
 *
 *********************************************************************
 * FileName:        SNMP.h
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
 * Nilesh Rajbharti     1/9/03  Original        (Rev 1.0)
 ********************************************************************/
#ifndef SNMP_H
#define SNMP_H

#include "StackTsk.h"

/*
 * This is the file that contains SNMP BIB file.
 * File name must contain all upper case letter and must match
 * with what was included in MPFS image.
 */
#define SNMP_BIB_FILE_NAME      "SNMP.BIB"


/*
 * This is the maximum length for community string.
 * Application must ensure that this length is observed.
 * SNMP module does not check for length overflow.
 */
#define SNMP_COMMUNITY_MAX_LEN  (8)
#define NOTIFY_COMMUNITY_LEN    (SNMP_COMMUNITY_MAX_LEN)

/*
 * Change this to match your OID string length.
 */
#define OID_MAX_LEN             (15)



#define SNMP_START_OF_VAR       (0)
#define SNMP_END_OF_VAR         (0xff)
#define SNMP_INDEX_INVALID      (0xff)

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
void SNMPInit(void);

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
BOOL SNMPTask(void);


/*
 * This is the SNMP OID variable id.
 * This id is assigned via MIB file.  Only dynamic and AgentID
 * variables can contian ID.  MIB2BIB utility enforces this
 * rules when BIB was generated.
 */
typedef BYTE SNMP_ID;
typedef BYTE SNMP_INDEX;

typedef union _SNMP_VAL
{
    DWORD dword;
    WORD  word;
    BYTE  byte;
    BYTE  v[sizeof(DWORD)];
} SNMP_VAL;

/*********************************************************************
 * Function:        BOOL SNMPGetVar(SNMP_ID var, SNMP_INDEX index,
 *                                  BYTE *ref, SNMP_VAL* val)
 *
 * PreCondition:    None
 *
 * Input:           var     - Variable id whose value is to be returned
 *                  index   - Index of variable that should be
 *                            transferred
 *                  ref     - Variable reference used to transfer
 *                            multi-byte data
 *                            It is always SNMP_START_OF_VAR when very
 *                            first byte is requested.
 *                            Otherwise, use this as a reference to
 *                            keep track of multi-byte transfers.
 *                  val     - Pointer to up to 4 byte buffer.
 *                            If var data type is BYTE, transfer data
 *                              in val->byte
 *                            If var data type is WORD, transfer data in
 *                              val->word
 *                            If var data type is DWORD, transfer data in
 *                              val->dword
 *                            If var data type is IP_ADDRESS, transfer data
 *                              in val->v[] or val->dword
 *                            If var data type is COUNTER32, TIME_TICKS or
 *                              GAUGE32, transfer data in val->dword
 *                            If var data type is ASCII_STRING or OCTET_STRING
 *                              transfer data in val->byte using multi-byte
 *                              transfer mechanism.
 *
 * Output:          TRUE if a value exists for given variable at given
 *                  index.
 *                  FALSE otherwise.
 *
 * Side Effects:    None
 *
 * Overview:        This is a callback function called by SNMP module.
 *                  SNMP user must implement this function in
 *                  user application and provide appropriate data when
 *                  called.
 *
 * Note:            None
 ********************************************************************/
#ifdef THIS_IS_SNMP_SERVER
    extern BOOL SNMPGetVar(SNMP_ID var, SNMP_INDEX index,
                           BYTE *ref, SNMP_VAL* val);
#endif


/*********************************************************************
 * Function:        BOOL SNMPGetNextIndex(SNMP_ID var,
 *                                        SNMP_INDEX *index)
 *
 * PreCondition:    None
 *
 * Input:           var     - Variable id whose value is to be returned
 *                  idnex   - Next Index of variable that should be
 *                            transferred
 *
 * Output:          TRUE if a next index value exists for given variable at given
 *                  index and index parameter contains next valid index.
 *                  FALSE otherwise.
 *
 * Side Effects:    None
 *
 * Overview:        This is a callback function called by SNMP module.
 *                  SNMP user must implement this function in
 *                  user application and provide appropriate data when
 *                  called.  This function will only be called for
 *                  OID variable of type sequence.
 *
 * Note:            None
 ********************************************************************/
#ifdef THIS_IS_SNMP_SERVER
    extern BOOL SNMPGetNextIndex(SNMP_ID var, SNMP_INDEX *index);
#endif


/*********************************************************************
 * Function:        BOOL SNMPIsValidSetLen(SNMP_ID var, BYTE len)
 *
 * PreCondition:    None
 *
 * Input:           var     - Variable id whose value is to be set
 *                  len     - Length value that is to be validated.
 *
 * Output:          TRUE if given var can be set to given len
 *                  FALSE if otherwise.
 *
 * Side Effects:    None
 *
 * Overview:        This is a callback function called by module.
 *                  User application must implement this function.
 *
 * Note:            This function will be called for only variables
 *                  that are defined as ASCII_STRING and OCTET_STRING
 *                  (i.e. data length greater than 4 bytes)
 ********************************************************************/
#ifdef THIS_IS_SNMP_SERVER
    extern BOOL SNMPIsValidSetLen(SNMP_ID var, BYTE len);
#endif


/*********************************************************************
 * Function:        BOOL SNMPSetVar(SNMP_ID var, SNMP_INDEX index,
 *                                  BYTE ref, SNMP_VAL val)
 *
 * PreCondition:    None
 *
 * Input:           var     - Variable id whose value is to be set
 *                  ref     - Variable reference used to transfer
 *                            multi-byte data
 *                            0 if first byte is set
 *                            otherwise nonzero value to indicate
 *                            corresponding byte being set.
 *                  val     - Up to 4 byte data value.
 *                            If var data type is BYTE, variable
 *                              value is in val->byte
 *                            If var data type is WORD, variable
 *                              value is in val->word
 *                            If var data type is DWORD, variable
 *                              value is in val->dword.
 *                            If var data type is IP_ADDRESS, COUNTER32,
 *                              or GAUGE32, value is in val->dword
 *                            If var data type is OCTET_STRING, ASCII_STRING
 *                              value is in val->byte; multi-byte transfer
 *                              will be performed to transfer remaining
 *                              bytes of data.
 *
 * Output:          TRUE if it is OK to set more byte(s).
 *                  FALSE if otherwise.
 *
 * Side Effects:    None
 *
 * Overview:        This is a callback function called by module.
 *                  User application must implement this function.
 *
 * Note:            This function may get called more than once
 *                  depending on number of bytes in a specific
 *                  set request for given variable.
 ********************************************************************/
#ifdef THIS_IS_SNMP_SERVER
    extern BOOL SNMPSetVar(SNMP_ID var, SNMP_INDEX index,
                            BYTE ref, SNMP_VAL val);
#endif



/*
 * This is the list of SNMP action a remote NMS can perform.
 * This inforamtion is passed to application via
 * callback SNMPValidate.
 * Application should validate the action for given community
 * string.
 */
typedef enum _SNMP_ACTION
{
    SNMP_GET            = 0xa0,
    SNMP_GET_NEXT       = 0xa1,
    SNMP_GET_RESPONSE   = 0xa2,
    SNMP_SET            = 0xa3,
    SNMP_TRAP           = 0xa4,
    SNMP_ACTION_UNKNOWN = 0
} SNMP_ACTION;

/*********************************************************************
 * Function:        BOOL SNMPValidate(SNMP_ACTION SNMPAction,
 *                                    char* community)
 *
 * PreCondition:    SNMPInit is already called.
 *
 * Input:           SNMPAction  - SNMP_GET to fetch a variable
 *                                SNMP_SET to write to a variable
 *                  community   - Community string as sent by NMS
 *
 * Output:          TRUE if password matches with given community
 *                  FALSE if otherwise.
 *
 * Side Effects:    None
 *
 * Overview:        This is a callback function called by module.
 *                  User application must implement this function
 *                  and verify that community matches with predefined
 *                  value.
 *
 * Note:            This validation occurs for each NMS request.
 ********************************************************************/
#ifdef THIS_IS_SNMP_SERVER
    extern BOOL SNMPValidate(SNMP_ACTION SNMPAction, char* community);
#endif



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
                        DWORD timestamp);


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
BOOL SNMPIsNotifyReady(IP_ADDR *remoteHost);


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
BOOL SNMPNotify(SNMP_ID var, SNMP_VAL val, SNMP_INDEX index);





#endif
