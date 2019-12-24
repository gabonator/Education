/*********************************************************************
 *
 *                  Microchip TCP/IP Stack Definations for PIC18
 *
 *********************************************************************
 * FileName:        StackTsk.h
 * Dependencies:    Compiler.h
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
 * Nilesh Rajbharti     8/10/01 Original        (Rev 1.0)
 * Nilesh Rajbharti     2/9/02  Cleanup
 * Nilesh Rajbharti     5/22/02 Rev 2.0 (See version.log for detail)
 * Nilesh Rajbharti     8/7/03  Rev 2.21 - TFTP Client addition
 * Howard Schlunder		9/30/04	Added MCHP_MAC, MAC_POWER_ON_TEST, 
 								EEPROM_BUFFER_SIZE, USE_LCD
 ********************************************************************/
#ifndef STACK_TSK_H
#define STACK_TSK_H

#include "Compiler.h"

/*
 * This value is used by TCP to implement timeout actions.
 * If SNMP module is in use, this value should be 100 as required
 * by SNMP protocol unless main application is providing separate
 * tick which 10mS.
 */
#define TICKS_PER_SECOND               (100)        // 10ms

#if (TICKS_PER_SECOND < 10 || TICKS_PER_SECOND > 255)
#error Invalid TICKS_PER_SECONDS specified.
#endif

/*
 * Manually select prescale value to achieve necessary tick period
 * for a given clock frequency.
 */
#define TICK_PRESCALE_VALUE             (256)

#if (TICK_PRESCALE_VALUE != 2 && \
     TICK_PRESCALE_VALUE != 4 && \
     TICK_PRESCALE_VALUE != 8 && \
     TICK_PRESCALE_VALUE != 16 && \
     TICK_PRESCALE_VALUE != 32 && \
     TICK_PRESCALE_VALUE != 64 && \
     TICK_PRESCALE_VALUE != 128 && \
     TICK_PRESCALE_VALUE != 256 )
#error Invalid TICK_PRESCALE_VALUE specified.
#endif

#if defined(WIN32)
    #undef TICKS_PER_SECOND
    #define TICKS_PER_SECOND        (1)
#endif


/*
 * This value is for performance enhancing features specific to 
 * Microchip Ethernet controllers.  If a non-Microchip Ethernet 
 * controller is used, this define must be commented out.  When 
 * defined, checksum computations will be offloaded to the hardware.
 */
#define MCHP_MAC

/*
 * This value is specific to the Microchip Ethernet controllers.  
 * If a different Ethernet controller is used, this define is not
 * used.  If a Microchip controller is used and a self memory test 
 * should be done when the MACInit() function is called, 
 * uncomment this define.  The test requires ~512 bytes of 
 * program memory.
 */
//#define MAC_POWER_ON_TEST


/*
 * This value is specific to the Microchip Ethernet controllers.  
 * If a different Ethernet controller is used, this define is not
 * used.  Ideally, when MAC_FILTER_BROADCASTS is defined, all 
 * broadcast packets that are received would be discarded by the 
 * hardware, except for ARP requests for our IP address.  This could 
 * be accomplished by filtering all broadcasts, but allowing the ARPs
 * using the patter match filter.  The code for this feature has been
 * partially implemented, but it is not complete nor tested, so this
 * option should remain unused in this stack version.
 */
//#define MAC_FILTER_BROADCASTS


/*
 * SPI Serial EEPROM buffer size.  To enhance performance while
 * cooperatively sharing the SPI bus with other peripherals, bytes 
 * read and written to the memory are locally buffered.  This 
 * parameter has no effect if spieeprom.c is not included in the 
 * project.  Legal sizes are 1 to the EEPROM page size.
 */
#define EEPROM_BUFFER_SIZE    			(12)


/*
 * The PICDEM.net board has an LCD module on it while other boards
 * do not have one.  Uncomment this define if an LCD is present and 
 * it should be used.
 */
#define USE_LCD

/*
 * This value is for Microchip 24LC256 - 256kb serial EEPROM
 */
#define EEPROM_CONTROL                  (0xa0)


/*
 * Number of bytes to be reserved before MPFS storage is to start.
 *
 * These bytes host application configurations such as IP Address,
 * MAC Address, and any other required variables.
 *
 * After making any change to this variable, MPFS.exe must be
 * executed with correct block size.
 * See MPFS.exe help message by executing MPFS /?
 */
#define MPFS_RESERVE_BLOCK              (32)



/*
 * Comment/Uncomment following lines depending on types of modules
 * are required.
 */
#define STACK_USE_ICMP
#define STACK_USE_HTTP_SERVER

/*
 * For demo purpose only, each sample project defines one or more
 * of following defines in compiler command-line options. (See
 * each MPLAB Project Node Properties under "Project->Edit Project" menu.
 * In real applcation, user may want to define them here.
 */
//#define STACK_USE_SLIP
//#define STACK_USE_IP_GLEANING
//#define STACK_USE_DHCP
//#define STACK_USE_FTP_SERVER
//#define STACK_USE_SNMP_SERVER
//#define STACK_USE_TFTP_CLIENT
//#define STACK_USE_ANNOUNCE

/*
 * Following low level modules are automatically enabled/disabled based on high-level
 * module selections.
 * If you need them with your custom application, enable it here.
 */
//#define STACK_USE_TCP
#define STACK_USE_UDP

// Uncomment following line if SNMP TRAP support is required
//#define SNMP_TRAP_DISABED

/*
 * When SLIP is used, DHCP is not supported.
 */
#if defined(STACK_USE_SLIP)
#undef STACK_USE_DHCP
#endif

/*
 * When MPFS_USE_PGRM is used, FTP is not supported.
 */
#if defined(MPFS_USE_PGRM)
#undef STACK_USE_FTP_SERVER
#endif


/*
 * Comment following line if StackTsk should wait for acknowledgement
 * from remote host before transmitting another packet.
 * Commenting following line may reduce throughput.
 */
#define TCP_NO_WAIT_FOR_ACK


/*
 * Uncomment following line if this stack will be used in CLIENT
 * mode.  In CLIENT mode, some functions specific to client operation
 * are enabled.
 */
//#define STACK_CLIENT_MODE


/*
 * If html pages are stored in internal program memory,
 * uncomment MPFS_USE_PRGM and comment MPFS_USE_EEPROM
 * If html pages are stored in external eeprom memory,
 * comment MPFS_USE_PRGM and uncomment MPFS_USE_EEPROM
 */
//#define MPFS_USE_PGRM
#define MPFS_USE_EEPROM

#if defined(MPFS_USE_PGRM) && defined(MPFS_USE_EEPROM)
#error Invalid MPFS Storage option specified.
#endif

#if !defined(MPFS_USE_PGRM) && !defined(MPFS_USE_EEPROM)
#error You have not specified MPFS storage option.
#endif


/*
 * When HTTP is enabled, TCP must be enabled.
 */
#if defined(STACK_USE_HTTP_SERVER)
    #if !defined(STACK_USE_TCP)
        #define STACK_USE_TCP
    #endif
#endif

/*
 * When FTP is enabled, TCP must be enabled.
 */
#if defined(STACK_USE_FTP_SERVER)
    #if !defined(STACK_USE_TCP)
        #define STACK_USE_TCP
    #endif
#endif

/*
 * When Announce is enabled, UDP must be enabled.
 */
#if defined(STACK_USE_ANNOUNCE)
    #if !defined(STACK_USE_UDP)
        #define STACK_USE_UDP
    #endif
#endif


#if defined(STACK_USE_FTP_SERVER) && !defined(STACK_CLIENT_MODE)
    #define STACK_CLIENT_MODE
#endif

#if defined(STACK_USE_SNMP_SERVER) && !defined(STACK_CLIENT_MODE)
    #define STACK_CLIENT_MODE
#endif

/*
 * When DHCP is enabled, UDP must also be enabled.
 */
#if defined(STACK_USE_DHCP)
    #if !defined(STACK_USE_UDP)
        #define STACK_USE_UDP
    #endif
#endif

#if defined(STACK_USE_SNMP_SERVER) && !defined(STACK_USE_UDP)
    #define STACK_USE_UDP
#endif

/*
 * When IP Gleaning is enabled, ICMP must also be enabled.
 */
#if defined(STACK_USE_IP_GLEANING)
    #if !defined(STACK_USE_ICMP)
        #define STACK_USE_ICMP
    #endif
#endif


/*
 * When TFTP Client is enabled, UDP must also be enabled.
 * And client mode must also be enabled.
 */
#if defined(STACK_USE_TFTP_CLIENT) && !defined(STACK_USE_UDP)
    #define STACK_USE_UDP
#endif

#if defined(STACK_USE_TFTP_CLIENT) && !defined(STACK_CLIENT_MODE)
    #define STACK_CLIENT_MODE
#endif


/*
 * DHCP requires unfragmented packet size of at least 328 bytes,
 * and while in SLIP mode, our maximum packet size is less than
 * 255.  Hence disallow DHCP module while SLIP is in use.
 * If required, one can use DHCP while SLIP is in use by modifying
 * C18 linker scipt file such that C18 compiler can allocate
 * a static array larger than 255 bytes.
 * Due to very specific application that would require this,
 * sample stack does not provide such facility.  Interested users
 * must do this on their own.
 */
#if defined(STACK_USE_SLIP)
    #if defined(STACK_USE_DHCP)
        #error DHCP cannot be used when SLIP is enabled.
    #endif
#endif


/*
 * Modify following macros depending on your interrupt usage
 */
#define ENABLE_INTERRUPTS()             INTCON_GIEH = 1
#define DISBALE_INTERRUPTS()            INTCON_GIEH = 0



/*
 * Default Address information - If not found in data EEPROM.
 */
#define MY_DEFAULT_IP_ADDR_BYTE1        (147)
#define MY_DEFAULT_IP_ADDR_BYTE2        (175)
#define MY_DEFAULT_IP_ADDR_BYTE3        (188)
#define MY_DEFAULT_IP_ADDR_BYTE4        (210)

#define MY_DEFAULT_MASK_BYTE1           (0xff)
#define MY_DEFAULT_MASK_BYTE2           (0xff)
#define MY_DEFAULT_MASK_BYTE3           (0xff)
#define MY_DEFAULT_MASK_BYTE4           (0x00)

#define MY_DEFAULT_GATE_BYTE1           MY_DEFAULT_IP_ADDR_BYTE1
#define MY_DEFAULT_GATE_BYTE2           MY_DEFAULT_IP_ADDR_BYTE2
#define MY_DEFAULT_GATE_BYTE3           MY_DEFAULT_IP_ADDR_BYTE3
#define MY_DEFAULT_GATE_BYTE4           MY_DEFAULT_IP_ADDR_BYTE4

#define MY_DEFAULT_MAC_BYTE1            (0x00)
#define MY_DEFAULT_MAC_BYTE2            (0x04)
#define MY_DEFAULT_MAC_BYTE3            (0xa3)
#define MY_DEFAULT_MAC_BYTE4            (0x00)
#define MY_DEFAULT_MAC_BYTE5            (0x00)
#define MY_DEFAULT_MAC_BYTE6            (0x00)



#define MY_MAC_BYTE1                    AppConfig.MyMACAddr.v[0]
#define MY_MAC_BYTE2                    AppConfig.MyMACAddr.v[1]
#define MY_MAC_BYTE3                    AppConfig.MyMACAddr.v[2]
#define MY_MAC_BYTE4                    AppConfig.MyMACAddr.v[3]
#define MY_MAC_BYTE5                    AppConfig.MyMACAddr.v[4]
#define MY_MAC_BYTE6                    AppConfig.MyMACAddr.v[5]

/*
 * Subnet mask for this node.
 * Must not be all zero's or else this node will never transmit
 * anything !!
 */
#define MY_MASK_BYTE1                   AppConfig.MyMask.v[0]
#define MY_MASK_BYTE2                   AppConfig.MyMask.v[1]
#define MY_MASK_BYTE3                   AppConfig.MyMask.v[2]
#define MY_MASK_BYTE4                   AppConfig.MyMask.v[3]

/*
 * Hardcoded IP address of this node
 * My IP = 10.10.5.10
 *
 * Gateway = 10.10.5.10
 */
#define MY_IP_BYTE1                     AppConfig.MyIPAddr.v[0]
#define MY_IP_BYTE2                     AppConfig.MyIPAddr.v[1]
#define MY_IP_BYTE3                     AppConfig.MyIPAddr.v[2]
#define MY_IP_BYTE4                     AppConfig.MyIPAddr.v[3]

/*
 * Harcoded Gateway address for this node.
 * This should be changed to match actual network environment.
 */
#define MY_GATE_BYTE1                   AppConfig.MyGateway.v[0]
#define MY_GATE_BYTE2                   AppConfig.MyGateway.v[1]
#define MY_GATE_BYTE3                   AppConfig.MyGateway.v[2]
#define MY_GATE_BYTE4                   AppConfig.MyGateway.v[3]


/*
 * TCP configurations
 * To minmize page update, match number of sockets and
 * HTTP connections with different page sources in a
 * page.
 * For example, if page contains reference to 3 more pages,
 * browser may try to open 4 simultaneous HTTP connections,
 * and to minimize browser delay, set HTTP connections to
 * 4, MAX_SOCKETS to 4.
 * If you are using ICMP or other applications, you should
 * keep at least one socket available for them.
 */

/*
 * Maximum sockets to be defined.
 * Note that each socket consumes 36 bytes of RAM.
 */
#define MAX_SOCKETS         (32u)

/*
 * Avaialble UDP Socket
 */
#define MAX_UDP_SOCKETS     (32u)


#if (MAX_SOCKETS <= 0 || MAX_SOCKETS > 255)
#error Invalid MAX_SOCKETS value specified.
#endif

#if (MAX_UDP_SOCKETS <= 0 || MAX_UDP_SOCKETS > 255 )
#error Invlaid MAX_UDP_SOCKETS value specified
#endif


#if !defined(STACK_USE_SLIP)
    #define MAC_TX_BUFFER_SIZE          (1024)
    #define MAC_TX_BUFFER_COUNT         (1)
	// Note: Defining MAC_TX_BUFFER_COUNT > 1 has NOT been tested,
	// which means the feature is probably broken at this time.
#else
/*
 * For SLIP, there can only be one transmit and one receive buffer.
 * Both buffer must fit in one bank.  If bigger buffer is required,
 * you must manually locate tx and rx buffer in different bank
 * or modify your linker script file to support arrays bigger than
 * 256 bytes.
 */
    #define MAC_TX_BUFFER_SIZE          (250)
    #define MAC_TX_BUFFER_COUNT         (1)
#endif
// Rests are Receive Buffers

#define MAC_RX_BUFFER_SIZE              (MAC_TX_BUFFER_SIZE)

#if (MAC_TX_BUFFER_SIZE <= 0 || MAC_TX_BUFFER_SIZE > 1500 )
#error Invalid MAC_TX_BUFFER_SIZE value specified.
#endif

#if ( (MAC_TX_BUFFER_SIZE * MAC_TX_BUFFER_COUNT) > (4* 1024) )
#error Not enough room for Receive buffer.
#endif

/*
 * Maximum numbers of simultaneous HTTP connections allowed.
 * Each connection consumes 10 bytes.
 */
#define MAX_HTTP_CONNECTIONS            (32u)

#if (MAX_HTTP_CONNECTIONS <= 0 || MAX_HTTP_CONNECTIONS > 255 )
#error Invalid MAX_HTTP_CONNECTIONS value specified.
#endif

#define AVAILABLE_SOCKETS (MAX_SOCKETS)
#if defined(STACK_USE_HTTP_SERVER)
    #define AVAILABLE_SOCKETS2 (AVAILABLE_SOCKETS - MAX_HTTP_CONNECTIONS)
#else
    #define AVAILABLE_SOCKETS2  (MAX_SOCKETS)
#endif

/*
 * When using FTP, you must have at least two sockets free
 */
#if defined(STACK_USE_FTP_SERVER)
    #define AVAILABLE_SOCKETS3 (AVAILABLE_SOCKETS2 - 2)
#else
    #define AVAILABLE_SOCKETS3  (AVAILABLE_SOCKETS2)
#endif

#if AVAILABLE_SOCKETS3 < 0
    #error Maximum TCP Socket count is not enough.
    #error Either increase MAX_SOCKETS or decrease module socket usage.
#endif


#define AVAILABLE_UDP_SOCKETS       (MAX_UDP_SOCKETS)
#if defined(STACK_USE_DHCP)
    #define AVAILABLE_UDP_SOCKETS2       (AVAILABLE_UDP_SOCKETS - 1)
#else
    #define AVAILABLE_UDP_SOCKETS2      AVAILABLE_UDP_SOCKETS
#endif

#if defined(STACK_USE_SNMP_SERVER)
    #define AVAILABLE_UDP_SOCKETS3      (AVAILABLE_UDP_SOCKETS2 - 1)
#else
    #define AVAILABLE_UDP_SOCKETS3      AVAILABLE_UDP_SOCKETS2
#endif

#if defined(STACK_USE_TFTP_CLIENT)
    #define AVAILABLE_UDP_SOCKETS4      (AVAILABLE_UDP_SOCKETS2)
#else
    #define AVAILABLE_UDP_SOCKETS4      AVAILABLE_UDP_SOCKETS3
#endif


#if AVAILABLE_UDP_SOCKETS4 < 0
    #error Maximum UDP Socket count is not enough.
    #error Either increase MAX_UDP_SOCKETS or decrease module UDP socket usage.
#endif



#undef BOOL
#undef TRUE
#undef FALSE
#undef BYTE
#undef WORD
#undef DWORD

typedef enum _BOOL { FALSE = 0, TRUE } BOOL;
typedef unsigned char BYTE;                 // 8-bit
typedef unsigned short int WORD;            // 16-bit
//#ifndef _WIN32
//typedef unsigned short long SWORD;          // 24-bit
//#else
typedef short int SWORD;
//#endif
typedef unsigned long DWORD;                // 32-bit

typedef union _BYTE_VAL
{
    struct
    {
        unsigned int b0:1;
        unsigned int b1:1;
        unsigned int b2:1;
        unsigned int b3:1;
        unsigned int b4:1;
        unsigned int b5:1;
        unsigned int b6:1;
        unsigned int b7:1;
    } bits;
    BYTE Val;
} BYTE_VAL;

typedef union _SWORD_VAL
{
    SWORD Val;
    struct
    {
        BYTE LSB;
        BYTE MSB;
        BYTE USB;
    } byte;
} SWORD_VAL;


typedef union _WORD_VAL
{
    WORD Val;
    struct
    {
        BYTE LSB;
        BYTE MSB;
    } byte;
    BYTE v[2];
} WORD_VAL;

#define LSB(a)          ((a).v[0])
#define MSB(a)          ((a).v[1])

typedef union _DWORD_VAL
{
    DWORD Val;
    struct
    {
        BYTE LOLSB;
        BYTE LOMSB;
        BYTE HILSB;
        BYTE HIMSB;
    } byte;
    struct
    {
        WORD LSW;
        WORD MSW;
    } word;
    BYTE v[4];
} DWORD_VAL;
#define LOWER_LSB(a)    ((a).v[0])
#define LOWER_MSB(a)    ((a).v[1])
#define UPPER_LSB(a)    ((a).v[2])
#define UPPER_MSB(a)    ((a).v[3])

typedef BYTE BUFFER;

typedef struct _MAC_ADDR
{
    BYTE v[6];
} MAC_ADDR;

typedef union _IP_ADDR
{
    BYTE        v[4];
    DWORD       Val;
} IP_ADDR;


typedef struct _NODE_INFO
{
    MAC_ADDR    MACAddr;
    IP_ADDR     IPAddr;
} NODE_INFO;

typedef struct _APP_CONFIG
{
    IP_ADDR     MyIPAddr;
    MAC_ADDR    MyMACAddr;
    IP_ADDR     MyMask;
    IP_ADDR     MyGateway;
    WORD_VAL    SerialNumber;
    IP_ADDR     SMTPServerAddr;     // Not used.
    struct
    {
        unsigned int bIsDHCPEnabled : 1;
    } Flags;
    IP_ADDR     TFTPServerAddr;
} APP_CONFIG;


typedef union _STACK_FLAGS
{
    struct
    {
        unsigned int bInConfigMode : 1;
    } bits;
    BYTE Val;
} STACK_FLAGS;


#ifndef THIS_IS_STACK_APPLICATION
    extern APP_CONFIG AppConfig;
#endif

#if defined(STACK_USE_IP_GLEANING) || defined(STACK_USE_DHCP)
    #ifndef STACK_INCLUDE
        extern STACK_FLAGS stackFlags;
    #endif
#endif

#if defined(STACK_USE_IP_GLEANING) || defined(STACK_USE_DHCP)
    #define StackIsInConfigMode()   (stackFlags.bits.bInConfigMode)
#else
    #define StackIsInConfigMode()   (FALSE)
#endif


/*********************************************************************
 * Function:        void StackInit(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          Stack and its componentns are initialized
 *
 * Side Effects:    None
 *
 * Note:            This function must be called before any of the
 *                  stack or its component routines be used.
 *
 ********************************************************************/
void StackInit(void);


/*********************************************************************
 * Function:        void StackTask(void)
 *
 * PreCondition:    StackInit() is already called.
 *
 * Input:           None
 *
 * Output:          Stack FSM is executed.
 *
 * Side Effects:    None
 *
 * Note:            This FSM checks for new incoming packets,
 *                  and routes it to appropriate stack components.
 *                  It also performs timed operations.
 *
 *                  This function must be called periodically called
 *                  to make sure that timely response.
 *
 ********************************************************************/
void StackTask(void);


#endif
