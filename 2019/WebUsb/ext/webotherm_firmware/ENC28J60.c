/*********************************************************************
 *
 *     MAC Module (Microchip ENC28J60) for Microchip TCP/IP Stack
 *
 *********************************************************************
 * FileName:        ENC28J60.c
 * Dependencies:    ENC28J60.h
 *					MAC.h
 *					string.h
 *                  StackTsk.h
 *                  Helpers.h
 *					Delay.h
 * Processor:       PIC18
 * Complier:        MCC18 v3.00 or higher
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
 * Author               Date   		Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Howard Schlunder		6/28/04	Original
 * Howard Schlunder		10/8/04	Cleanup
 * Howard Schlunder		10/19/04 Small optimizations and more cleanup
 * Howard Schlunder		11/29/04 Added Set/GetCLKOUT
 * Howard Schlunder		12/23/05 Added B1 silicon errata workarounds
 * Howard Schlunder		1/09/06	Added comments and minor mods
 * Howard Schlunder		1/18/06 Added more silicon errata workarounds
 * Howard Schlunder		2/20/06 Fixed TXSTART, RXSTOP
********************************************************************/
#define THIS_IS_MAC_LAYER

#include <string.h>
#include "StackTsk.h"
#include "Helpers.h"
#include "Delay.h"
#include "MAC.h"
#include "ENC28J60.h"
#include "usart.h"


#if defined(STACK_USE_SLIP)
#error Unexpected module is detected.
#error This file must be linked when SLIP module is not in use.
#endif


/** D E F I N I T I O N S ****************************************************/
/* Hardware interface to NIC. */
#define MCP_RESET_TRIS	(TRISB_RB5)
#define MCP_RESET_IO	(LATB5)
#define MCP_CS_TRIS		(TRISB_RB3)
#define MCP_CS_IO		(LATB3)
// The following SPI pins are used but are not configurable
//   RC3 is used for the SCK pin and is an output
//   RC4 is used for the SDI pin and is an input
//   RC5 is used for the SDO pin and is an output
// IMPORTANT SPI NOTE: The code in this file expects that the SPI interrupt 
//		flag (PIR1_SSPIF) be clear at all times.  If the SPI is shared with 
//		other hardware, the other code should clear the PIR1_SSPIF when it is 
//		done using the SPI.

// Since the ENC28J60 doesn't support auto-negotiation, full-duplex mode is 
// not compatible with most switches/routers.  If a dedicated network is used 
// where the duplex of the remote node can be manually configured, you may 
// change this configuration.  Otherwise, half duplex should always be used.
#define HALF_DUPLEX
//#define FULL_DUPLEX
//#define LEDB_DUPLEX

/* Pseudo Functions */
#define LOW(a) 					(a & 0xFF)
#define HIGH(a) 				((a>>8) & 0xFF)
#define SPISelectEthernet()		MCP_CS_IO = 0
#define SPIUnselectEthernet()	MCP_CS_IO = 1

/* NIC RAM definitions */
#define RAMSIZE	8192ul		
#define TXSTART (RAMSIZE-(MAC_TX_BUFFER_COUNT * (MAC_TX_BUFFER_SIZE + 8ul)))
#define RXSTART	(0ul)						// Should be an even memory address
#define	RXSTOP	((TXSTART-2ul) | 0x0001ul)	// Odd for errata workaround
#define RXSIZE	(RXSTOP-RXSTART+1ul)

/* ENC28J60 Opcodes (to be ORed with a 5 bit address) */
#define	WCR (0b010<<5)			// Write Control Register command
#define BFS (0b100<<5)			// Bit Field Set command
#define	BFC (0b101<<5)			// Bit Field Clear command
#define	RCR (0b000<<5)			// Read Control Register command
#define RBM ((0b001<<5) | 0x1A)	// Read Buffer Memory command
#define	WBM ((0b011<<5) | 0x1A) // Write Buffer Memory command
#define	SR  ((0b111<<5) | 0x1F)	// System Reset command does not use an address.  
								//   It requires 0x1F, however.

#define ETHER_IP	(0x00u)
#define ETHER_ARP	(0x06u)

#define MAXFRAMEC	(1500u+sizeof(ETHER_HEADER)+4u)

// A generic structure representing the Ethernet header starting all Ethernet 
// frames
typedef struct _ETHER_HEADER
{
    MAC_ADDR        DestMACAddr;
    MAC_ADDR        SourceMACAddr;
    WORD_VAL        Type;
} ETHER_HEADER;

// A header appended at the start of all RX frames by the hardware
typedef struct _MCP_PREAMBLE
{
    WORD			NextPacketPointer;
    RXSTATUS		StatusVector;

    MAC_ADDR        DestMACAddr;
    MAC_ADDR        SourceMACAddr;
    WORD_VAL        Type;
} MCP_PREAMBLE;

typedef struct _DATA_BUFFER
{
	WORD_VAL StartAddress;
//	WORD_VAL EndAddress;
	BOOL bFree;
} DATA_BUFFER;


/* Prototypes of functions intended for MAC layer use only */
static void BankSel(WORD Register);
static REG ReadETHReg(BYTE Address);
static REG ReadMACReg(BYTE Address);
static void WriteReg(BYTE Address, BYTE Data);
static void BFCReg(BYTE Address, BYTE Data);
static void BFSReg(BYTE Address, BYTE Data);
static void SendSystemReset(void);
#ifdef MAC_POWER_ON_TEST
static BOOL TestMemory(void);
#endif

/* Internal and externally used MAC level variables */
#if MAC_TX_BUFFER_COUNT > 1
static DATA_BUFFER TxBuffers[MAC_TX_BUFFER_COUNT];
#endif
BYTE NICCurrentTxBuffer;

/* Internal MAC level variables and flags */
WORD_VAL NextPacketLocation;
WORD_VAL CurrentPacketLocation;
BOOL WasDiscarded;


void SetCLKOUT(BYTE NewConfig);

/******************************************************************************
 * Function:        void MACInit(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        MACInit sets up the PIC's SPI module and all the 
 *					registers in the ENC28J60 so that normal operation can 
 *					begin.
 *
 * Note:            None
 *****************************************************************************/
void MACInit(void)
{
	BYTE i;
	
	// Deassert the nRESET pin on the ENC28J60.  The internal 
	// weak pull on the nRESET pin will get the job done anyway,
	// so this isn't necessary, but it may provide extra noise immunity, 
	// should someone put their finger on the pin or otherwise cause a leakage
	// path to ground on this pin.
	MCP_RESET_TRIS = 0;
	MCP_RESET_IO = 1;

	/*
	 * Set up the SPI module on the PIC for communications with the ENC28J60
	 */
	SPIUnselectEthernet();
	MCP_CS_TRIS = 0;		// Make the Chip Select pin an output

	TRISC_RC3 = 0;			// Set RC3 (SCK) pin as an output
	TRISC_RC4 = 1;			// Make sure RC4 (SDI) pin is an input
	TRISC_RC5 = 0;			// Set RC5 (SDO) pin as an output
	SSPCON1 = 0x20;			// SSPEN bit is set, SPI in master mode, FOSC/4, 
							//   IDLE state is low level
	PIR1_SSPIF = 0;
	SSPSTAT_CKE = 1; 		// Transmit data on rising edge of clock
	SSPSTAT_SMP = 0;		// Input sampled at middle of data output time

	// Wait for CLKRDY to become set.
	// Bit 3 in ESTAT is an unimplemented bit.  If it reads out as '1' that
	// means the part is in RESET or otherwise our SPI pin is being driven
	// incorrectly.  Make sure it is working before proceeding.
	DBGCMT("ClkRDY wait");
	do
	{
		i = ReadETHReg(ESTAT).Val;
	} while((i & 0x08) || (~i & ESTAT_CLKRDY));
	DBGCMT("ok");


#ifdef MAC_POWER_ON_TEST
	// Do the memory test and enter a while always trap if a hardware error 
	// occured.  The LEDA and LEDB pins will be configured to blink 
	// periodically in an abnormal manner to indicate to the user that the 
	// error occured.
	if( !TestMemory() )
	{
		SetLEDConfig(0x0AA2);		// Set LEDs to blink periodically
		while(1);			
	}
#endif

	// RESET the entire ENC28J60, clearing all registers
	DBGCMT("1");

	SendSystemReset();	
    DelayMs(1);
	DBGCMT("2");

#if MAC_TX_BUFFER_COUNT > 1
    // On Init, all transmit buffers are free.
    for (i = 0; i < MAC_TX_BUFFER_COUNT; i++ )
    {
        TxBuffers[i].StartAddress = TXSTART + ((WORD)i * (MAC_TX_BUFFER_SIZE+8));
        TxBuffers[i].bFree = TRUE;
    }
#endif
    NICCurrentTxBuffer = 0;
	
	/*
	 * Start up in Bank 0 and configure the receive buffer boundary pointers 
	 * and the buffer write protect pointer (receive buffer read pointer)
	 */
	WasDiscarded = TRUE;
	NextPacketLocation.Val = RXSTART;
	WriteReg(ERXSTL, LOW(RXSTART));
	WriteReg(ERXSTH, HIGH(RXSTART));
	WriteReg(ERXRDPTL, LOW(RXSTOP));	// Write low byte first
	WriteReg(ERXRDPTH, HIGH(RXSTOP));	// Write high byte last
#if RXSTOP != 0x1FFF	// The RESET default ERXND is 0x1FFF
	WriteReg(ERXNDL, LOW(RXSTOP));
	WriteReg(ERXNDH, HIGH(RXSTOP));
#endif
#if TXSTART != 0		// The RESET default ETXST is 0
	WriteReg(ETXSTL, LOW(TXSTART));
	WriteReg(ETXSTH, HIGH(TXSTART));
#endif
	DBGCMT("3");

	/*
	 * Enter Bank 1 and configure Receive Filters 
	 * (No need to reconfigure - Unicast OR Broadcast with CRC checking is 
	 * acceptable)
	 */
	 //BankSel(ERXFCON);
	 //WriteReg(ERXFCON, ERXFCON_CRCEN);


	/*
	 * Enter Bank 2 and configure the MAC
	 */
	BankSel(MACON1);

	// Enable the receive portion of the MAC
	WriteReg(MACON1, MACON1_TXPAUS | MACON1_RXPAUS | MACON1_MARXEN);
	
	// Pad packets to 60 bytes, add CRC, and check Type/Length field.
	WriteReg(MACON3, MACON3_PADCFG0 | MACON3_TXCRCEN | MACON3_FRMLNEN);
	DBGCMT("4");

	// Set non-back-to-back inter-packet gap to 9.6us.  The back-to-back 
	// inter-packet gap (MABBIPG) is set by MACSetDuplex() which is called 
	// later.
	WriteReg(MAIPGL, 0x12);
	WriteReg(MAIPGH, 0x0C);

	// Set the maximum packet size which the controller will accept
	WriteReg(MAMXFLL, LOW(MAXFRAMEC));	
	WriteReg(MAMXFLH, HIGH(MAXFRAMEC));
	
	/*
     * Enter Bank 3 and initialize physical MAC address registers
	 */
	BankSel(MAADR1);
    WriteReg(MAADR1, MY_MAC_BYTE1);
    WriteReg(MAADR2, MY_MAC_BYTE2);
    WriteReg(MAADR3, MY_MAC_BYTE3);
    WriteReg(MAADR4, MY_MAC_BYTE4);
    WriteReg(MAADR5, MY_MAC_BYTE5);
    WriteReg(MAADR6, MY_MAC_BYTE6);
	DBGCMT("5");

	// Disable half duplex loopback in PHY.  Bank bits changed to Bank 2 as a 
	// side effect.
	WritePHYReg(PHCON2, PHCON2_HDLDIS);

	// Configure LEDA to display LINK status, LEDB to display TX/RX activity
	SetLEDConfig(0x0472);
	
	// Set the MAC and PHY into the proper duplex state
#if defined(FULL_DUPLEX)
	MACSetDuplex(FULL);		// Function exits with Bank 2 selected
#elif defined(HALF_DUPLEX)
	MACSetDuplex(HALF);		// Function exits with Bank 2 selected
#else
	// Use the external LEDB polarity to determine weather full or half duplex 
	// communication mode should be set.  
	MACSetDuplex(USE_PHY);	// Function exits with Bank 2 selected
#endif
	DBGCMT("6");

///	SetCLKOUT(2);

	// Enable packet reception
	BFSReg(ECON1, ECON1_RXEN);
	DBGCMT("7");

}//end MACInit


/******************************************************************************
 * Function:        BOOL MACIsLinked(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          TRUE: If the PHY reports that a link partner is present 
 *						  and the link has been up continuously since the last 
 *						  call to MACIsLinked()
 *					FALSE: If the PHY reports no link partner, or the link went 
 *						   down momentarily since the last call to MACIsLinked()
 *
 * Side Effects:    None
 *
 * Overview:        Returns the PHSTAT1.LLSTAT bit.
 *
 * Note:            None
 *****************************************************************************/
BOOL MACIsLinked(void)
{
	// LLSTAT is a latching low link status bit.  Therefore, if the link 
	// goes down and comes back up before a higher level stack program calls
	// MACIsLinked(), MACIsLinked() will still return FALSE.  The next 
	// call to MACIsLinked() will return TRUE (unless the link goes down 
	// again).
	return ReadPHYReg(PHSTAT1).PHSTAT1bits.LLSTAT;
}

/******************************************************************************
 * Function:        BOOL MACIsTxReady(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          TRUE: If no Ethernet transmission is in progress
 *					FALSE: If a previous transmission was started, and it has 
 *						   not completed yet.  While FALSE, the data in the 
 *						   transmit buffer and the TXST/TXND pointers must not
 *						   be changed.
 *
 * Side Effects:    None
 *
 * Overview:        Returns the ECON1.TXRTS bit.
 *
 * Note:            None
 *****************************************************************************/
BOOL MACIsTxReady(void)
{
    return !ReadETHReg(ECON1).ECON1bits.TXRTS;
}


void MACReserveTxBuffer(BUFFER buffer)
{
#if MAC_TX_BUFFER_COUNT > 1
    TxBuffers[buffer].bFree = FALSE;
#endif
}


void MACDiscardTx(BUFFER buffer)
{
#if MAC_TX_BUFFER_COUNT > 1
    TxBuffers[buffer].bFree = TRUE;
    NICCurrentTxBuffer = buffer;
#endif
}


/******************************************************************************
 * Function:        void MACDiscardRx(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Marks the last received packet (obtained using 
 *					MACGetHeader())as being processed and frees the buffer 
 *					memory associated with it
 *
 * Note:            None
 *****************************************************************************/
void MACDiscardRx(void)
{
	WORD_VAL NewRXRDLocation;

	// Make sure the current packet was not already discarded
	if( WasDiscarded )
		return;
	WasDiscarded = TRUE;
	
	// Decrement the next packet pointer before writing it into 
	// the ERXRDPT registers.  This is a silicon errata workaround.
	// RX buffer wrapping must be taken into account if the 
	// NextPacketLocation is precisely RXSTART.
	NewRXRDLocation.Val = NextPacketLocation.Val - 1;
	if(NewRXRDLocation.Val < RXSTART || NewRXRDLocation.Val > RXSTOP)
	{
		NewRXRDLocation.Val = RXSTOP;
	}

	// Decrement the RX packet counter register, EPKTCNT
	BFSReg(ECON2, ECON2_PKTDEC);

	// Move the receive read pointer to unwrite-protect the memory used by the 
	// last packet.  The writing order is important: set the low byte first, 
	// high byte last.
	BankSel(ERXRDPTL);
	WriteReg(ERXRDPTL, LSB(NewRXRDLocation));
	WriteReg(ERXRDPTH, MSB(NewRXRDLocation));
}


/******************************************************************************
 * Function:        WORD MACGetFreeRxSize(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          A WORD estimate of how much RX buffer space is free at 
 *					the present time.
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 *****************************************************************************/
WORD MACGetFreeRxSize(void)
{
	WORD_VAL ReadPT, WritePT;

	// Read the Ethernet hardware buffer write pointer.  Because packets can be 
	// received at any time, it can change between reading the low and high 
	// bytes.  A loop is necessary to make certain a proper low/high byte pair
	// is read.
	BankSel(EPKTCNT);
	do {
		// Save EPKTCNT in a temporary location
		ReadPT.v[0] = ReadETHReg(EPKTCNT).Val;
	
		BankSel(ERXRDPTL);
		WritePT.v[0] = ReadETHReg(ERXWRPTL).Val;
		WritePT.v[1] = ReadETHReg(ERXWRPTH).Val;
	
		BankSel(EPKTCNT);
	} while(ReadETHReg(EPKTCNT).Val != ReadPT.v[0]);
	
	// Determine where the write protection pointer is
	BankSel(ERXRDPTL);
	ReadPT.v[0] = ReadETHReg(ERXRDPTL).Val;
	ReadPT.v[1] = ReadETHReg(ERXRDPTH).Val;
	
	// Calculate the difference between the pointers, taking care to account 
	// for buffer wrapping conditions
	if ( WritePT.Val > ReadPT.Val )
		return (RXSTOP - RXSTART) - (WritePT.Val - ReadPT.Val);
	else if ( WritePT.Val == ReadPT.Val )
		return RXSIZE - 1;
	else
		return ReadPT.Val - WritePT.Val - 1;
}


/******************************************************************************
 * Function:        BOOL MACGetHeader(MAC_ADDR *remote, BYTE* type)
 *
 * PreCondition:    None
 *
 * Input:           *remote: Location to store the Source MAC address of the 
 *							 received frame.
 *					*type: Location of a BYTE to store the constant 
 *						   MAC_UNKNOWN, ETHER_IP, or ETHER_ARP, representing 
 *						   the contents of the Ethernet type field.
 *
 * Output:          TRUE: If a packet was waiting in the RX buffer.  The 
 *						  remote, and type values are updated.
 *					FALSE: If a packet was not pending.  remote and type are 
 *						   not changed.
 *
 * Side Effects:    Last packet is discarded if MACDiscardRx() hasn't already
 *					been called.
 *
 * Overview:        None
 *
 * Note:            None
 *****************************************************************************/
BOOL MACGetHeader(MAC_ADDR *remote, BYTE* type)
{
    MCP_PREAMBLE header;

	// Test if at least one packet has been received and is waiting
	BankSel(EPKTCNT);
	if( ReadETHReg(EPKTCNT).Val == 0 )
		return FALSE;	

	// Make absolutely certain that any previous packet was discarded	
	if( WasDiscarded == FALSE)
		MACDiscardRx();

	// Save the location of this packet
	CurrentPacketLocation.Val = NextPacketLocation.Val;

	// Set the SPI read pointer to the beginning of the next unprocessed packet
	BankSel(ERDPTL);
	WriteReg(ERDPTL, LSB(NextPacketLocation));
	WriteReg(ERDPTH, MSB(NextPacketLocation));

	// Obtain the MAC header from Ethernet buffer
	MACGetArray((BYTE*)&header, sizeof(header));

	// The EtherType field, like most items transmitted on the Ethernet medium
	// are in big endian.
    header.Type.Val = swaps(header.Type.Val);

	// Save the location where the hardware will write the next packet to
	NextPacketLocation.Val = header.NextPacketPointer;

	// Return the Ethernet frame's Source MAC address field to the caller
	// This parameter is useful for replying to requests without requiring an 
	// ARP cycle.
    memcpy((void*)remote->v, (void*)header.SourceMACAddr.v, sizeof(*remote));

	// Return a simplified version of the EtherType field to the caller
    *type = MAC_UNKNOWN;
    if( (header.Type.v[1] == 0x08u) && 
    	((header.Type.v[0] == ETHER_IP) || (header.Type.v[0] == ETHER_ARP)) )
    	*type = header.Type.v[0];
           
    WasDiscarded = FALSE;	// Mark this packet as discardable
	return TRUE;
}


/******************************************************************************
 * Function:        void    MACPutHeader(MAC_ADDR *remote,
 *					                     BYTE type,
 *                   					 WORD dataLen)
 *
 * PreCondition:    MACIsTxReady() must return TRUE.
 *
 * Input:           *remote: Pointer to memory which contains the destination
 * 							 MAC address (6 bytes)
 *					type: The constant ETHER_ARP or ETHER_IP, defining which 
 *						  value to write into the Ethernet header's type field.
 *					dataLen: Length of the Ethernet data payload
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            Because of the dataLen parameter, it is probably 
 *					advantagous to call this function immediately before 
 *					transmitting a packet rather than initially when the 
 *					packet is first created.  The order in which the packet
 *					is constructed (header first or data first) is not 
 *					important.
 *****************************************************************************/
void    MACPutHeader(MAC_ADDR *remote,
                     BYTE type,
                     WORD dataLen)
{

	BankSel(EWRPTL);

#if MAC_TX_BUFFER_COUNT > 1
	// Set the SPI write pointer to the beginning of the transmit buffer
	WriteReg(EWRPTL, ((WORD_VAL*)&TxBuffers[NICCurrentTxBuffer].StartAddress->v[0]));
	WriteReg(EWRPTH, ((WORD_VAL*)&TxBuffers[NICCurrentTxBuffer].StartAddress->v[1]));

	// Calculate where to put the TXND pointer
    dataLen += (WORD)sizeof(ETHER_HEADER) + TxBuffers[NICCurrentTxBuffer].StartAddress;
#else
	// Set the SPI write pointer to the beginning of the transmit buffer
	WriteReg(EWRPTL, LOW(TXSTART));
	WriteReg(EWRPTH, HIGH(TXSTART));

	// Calculate where to put the TXND pointer
    dataLen += (WORD)sizeof(ETHER_HEADER) + TXSTART;
#endif

	// Write the TXND pointer into the registers, given the dataLen given
	WriteReg(ETXNDL, ((WORD_VAL*)&dataLen)->v[0]);
	WriteReg(ETXNDH, ((WORD_VAL*)&dataLen)->v[1]);

	// Set the per-packet control byte and write the Ethernet destination 
	// address
	MACPut(0x00);	// Use default control configuration
    MACPutArray((BYTE*)remote, sizeof(*remote));

	// Write our MAC address in the Ethernet source field
    MACPut(MY_MAC_BYTE1);
    MACPut(MY_MAC_BYTE2);
    MACPut(MY_MAC_BYTE3);
    MACPut(MY_MAC_BYTE4);
    MACPut(MY_MAC_BYTE5);
    MACPut(MY_MAC_BYTE6);

	// Write the appropriate Ethernet Type WORD for the protocol being used
    MACPut(0x08);
    MACPut((type == MAC_IP) ? ETHER_IP : ETHER_ARP);
}

/******************************************************************************
 * Function:        void MACFlush(void)
 *
 * PreCondition:    A packet has been created by calling MACPut() and 
 *					MACPutHeader().
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        MACFlush causes the current TX packet to be sent out on 
 *					the Ethernet medium.  The hardware MAC will take control
 *					and handle CRC generation, collision retransmission and 
 *					other details.
 *
 * Note:			After transmission completes (MACIsTxReady() returns TRUE), 
 *					the packet can be modified and transmitted again by calling 
 *					MACFlush() again.  Until MACPutHeader() or MACPut() is 
 *					called (in the TX data area), the data in the TX buffer 
 *					will not be corrupted.
 *****************************************************************************/
void MACFlush(void)
{
	// Reset transmit logic if a TX Error has previously occured
	// This is a silicon errata workaround
	if(ReadETHReg(EIR).EIRbits.TXERIF)
	{
		BFCReg(EIR, EIR_TXERIF);
		BFSReg(ECON1, ECON1_TXRST);
		BFCReg(ECON1, ECON1_TXRST);
	}

	// Start the transmission
	// After transmission completes (MACIsTxReady() returns TRUE), the packet 
	// can be modified and transmitted again by calling MACFlush() again.
	// Until MACPutHeader() is called, the data in the TX buffer will not be 
	// corrupted.
	BFSReg(ECON1, ECON1_TXRTS);
}


/******************************************************************************
 * Function:        void MACSetRxBuffer(WORD offset)
 *
 * PreCondition:    A packet has been obtained by calling MACGetHeader() and 
 *					getting a TRUE result.
 *
 * Input:           offset: WORD specifying how many bytes beyond the Ethernet 
 *							header's type field to relocate the SPI read and 
 *							write pointers.
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        SPI read and write pointers are updated.  All calls to 
 *					MACGet(), MACPut(), MACGetArray(), and MACPutArray(), 
 *					and various other functions will use these new values.
 *
 * Note:			RXSTOP must be statically defined as being > RXSTART for 
 *					this function to work correctly.  In other words, do not 
 *					define an RX buffer which spans the 0x1FFF->0x0000 memory
 *					boundary.
 *****************************************************************************/
void MACSetRxBuffer(WORD offset)
{
	WORD_VAL ReadPT;

	// Determine the address of the beginning of the entire packet
	// and adjust the address to the desired location
	ReadPT.Val = CurrentPacketLocation.Val + sizeof(MCP_PREAMBLE) + offset;
	
	// Since the receive buffer is circular, adjust if a wraparound is needed
	if ( ReadPT.Val > RXSTOP )
		ReadPT.Val -= RXSIZE;
	
	// Set the SPI read and write pointers to the new calculated value
	BankSel(ERDPTL);
	WriteReg(ERDPTL, ReadPT.v[0]);
	WriteReg(ERDPTH, ReadPT.v[1]);
	WriteReg(EWRPTL, ReadPT.v[0]);
	WriteReg(EWRPTH, ReadPT.v[1]);
}


/******************************************************************************
 * Function:        void MACSetTxBuffer(BUFFER buffer, WORD offset)
 *
 * PreCondition:    None
 *
 * Input:           buffer: BYTE specifying which transmit buffer to seek 
 *							within.  If MAC_TX_BUFFER_COUNT <= 1, this 
 *							parameter is not used.
 *					offset: WORD specifying how many bytes beyond the Ethernet 
 *							header's type field to relocate the SPI read and 
 *							write pointers.
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        SPI read and write pointers are updated.  All calls to 
 *					MACGet(), MACPut(), MACGetArray(), and MACPutArray(), 
 *					and various other functions will use these new values.
 *
 * Note:			None
 *****************************************************************************/
void MACSetTxBuffer(BUFFER buffer, WORD offset)
{
    NICCurrentTxBuffer = buffer;

	// Calculate the proper address.  Since the TX memory area is not circular,
	// no wrapparound checks are necessary. +1 adjustment is needed because of 
	// the per packet control byte which preceeds the packet in the TX memory 
	// area.
#if MAC_TX_BUFFER_COUNT > 1
	offset += TxBuffers[buffer].StartAddress + 1 + sizeof(ETHER_HEADER);
#else
	offset += TXSTART + 1 + sizeof(ETHER_HEADER);
#endif

	// Set the SPI read and write pointers to the new calculated value
	BankSel(EWRPTL);
	WriteReg(ERDPTL, ((WORD_VAL*)&offset)->v[0]);
	WriteReg(ERDPTH, ((WORD_VAL*)&offset)->v[1]);
	WriteReg(EWRPTL, ((WORD_VAL*)&offset)->v[0]);
	WriteReg(EWRPTH, ((WORD_VAL*)&offset)->v[1]);
}


#if defined(MCHP_MAC)
// MACCalcRxChecksum() and MACCalcTxChecksum() use the DMA module to calculate
// checksums.  These two functions have been tested.
/******************************************************************************
 * Function:        WORD MACCalcRxChecksum(WORD offset, WORD len)
 *
 * PreCondition:    None
 *
 * Input:           offset	- Number of bytes beyond the beginning of the 
 *							Ethernet data (first byte after the type field) 
 *							where the checksum should begin
 *					len		- Total number of bytes to include in the checksum
 *
 * Output:          16-bit checksum as defined by rfc 793.
 *
 * Side Effects:    None
 *
 * Overview:        This function performs a checksum calculation in the MAC
 *                  buffer itself using the hardware DMA module
 *
 * Note:            None
 *****************************************************************************/
WORD MACCalcRxChecksum(WORD offset, WORD len)
{
	WORD_VAL temp;

	// Add the offset requested by firmware plus the Ethernet header
	temp.Val = CurrentPacketLocation.Val + sizeof(MCP_PREAMBLE) + offset;
	if ( temp.Val > RXSTOP )		// Adjust value if a wrap is needed
		temp.Val -= RXSIZE;

	// Program the start address of the DMA
	BankSel(EDMASTL);
	WriteReg(EDMASTL, temp.v[0]);
	WriteReg(EDMASTH, temp.v[1]);

	// Calculate the end address, given the start address and len
	temp.Val += len-1;
	if ( temp.Val > RXSTOP )		// Adjust value if a wrap is needed
		temp.Val -= RXSIZE;

	// Program the end address of the DMA
	WriteReg(EDMANDL, temp.v[0]);
	WriteReg(EDMANDH, temp.v[1]);
	
	// Do the checksum calculation
	BFSReg(ECON1, ECON1_DMAST | ECON1_CSUMEN);
	while(ReadETHReg(ECON1).ECON1bits.DMAST);

	// Swap endianness and return
	temp.v[1] = ReadETHReg(EDMACSL).Val;
	temp.v[0] = ReadETHReg(EDMACSH).Val;
	return temp.Val;
}


/******************************************************************************
 * Function:        WORD MACCalcTxChecksum(WORD offset, WORD len)
 *
 * PreCondition:    None
 *
 * Input:           offset	- Number of bytes beyond the beginning of the 
 *							Ethernet data (first byte after the type field) 
 *							where the checksum should begin
 *					len		- Total number of bytes to include in the checksum
 *
 * Output:          16-bit checksum as defined by rfc 793.
 *
 * Side Effects:    None
 *
 * Overview:        This function performs a checksum calculation in the MAC
 *                  buffer itself using the hardware DMA module
 *
 * Note:            None
 *****************************************************************************/
WORD MACCalcTxChecksum(WORD offset, WORD len)
{
	WORD_VAL temp;

	// Program the start address of the DMA, after adjusting for the Ethernet 
	// header
#if MAC_TX_BUFFER_COUNT > 1
	temp.Val = TxBuffers[NICCurrentTxBuffer].StartAddress + sizeof(ETHER_HEADER)
				+ offset + 1;	// +1 needed to account for per packet control byte
#else
	temp.Val = TXSTART + sizeof(ETHER_HEADER)
				+ offset + 1;	// +1 needed to account for per packet control byte
#endif
	BankSel(EDMASTL);
	WriteReg(EDMASTL, temp.v[0]);
	WriteReg(EDMASTH, temp.v[1]);
	
	// Program the end address of the DMA.
	temp.Val += len-1;
	WriteReg(EDMANDL, temp.v[0]);
	WriteReg(EDMANDH, temp.v[1]);
	
	// Do the checksum calculation
	BFSReg(ECON1, ECON1_DMAST | ECON1_CSUMEN);
	while(ReadETHReg(ECON1).ECON1bits.DMAST);

	// Swap endianness and return
	temp.v[1] = ReadETHReg(EDMACSL).Val;
	temp.v[0] = ReadETHReg(EDMACSH).Val;
	return temp.Val;
}


/******************************************************************************
 * Function:        WORD CalcIPBufferChecksum(WORD len)
 *
 * PreCondition:    Read buffer pointer set to starting of checksum data
 *
 * Input:           len: Total number of bytes to calculate the checksum over. 
 *						 The first byte included in the checksum is the byte 
 *						 pointed to by ERDPT, which is updated by calls to 
 *						 MACGet(), MACSetRxBuffer(), MACSetTxBuffer(), etc.
 *
 * Output:          16-bit checksum as defined by rfc 793.
 *
 * Side Effects:    None
 *
 * Overview:        This function performs a checksum calculation in the MAC
 *                  buffer itself.  The ENC28J60 has a hardware DMA module 
 *					which can calculate the checksum faster than software, so 
 *					this function replaces the CaclIPBufferChecksum() function 
 *					defined in the helpers.c file.  Through the use of 
 *					preprocessor defines, this replacement is automatic.
 *
 * Note:            This function works either in the RX buffer area or the TX
 *					buffer area.  No validation is done on the len parameter.
 *****************************************************************************/
WORD CalcIPBufferChecksum(WORD len)
{
	WORD_VAL temp;

	// Take care of special cases which the DMA cannot be used for
	if(len == 0u)
		return 0xFFFF;
	else if(len == 1u)
		return ~(((WORD)MACGet())<<8);
		

	// Set the DMA starting address to the SPI read pointer value
	BankSel(ERDPTL);
	temp.v[0] = ReadETHReg(ERDPTL).Val;
	temp.v[1] = ReadETHReg(ERDPTH).Val;
	WriteReg(EDMASTL, temp.v[0]);
	WriteReg(EDMASTH, temp.v[1]);
	
	// See if we are calculating a checksum within the RX buffer (where 
	// wrapping rules apply) or TX/unused area (where wrapping rules are 
	// not applied)
	if(temp.Val >= RXSTART && temp.Val <= RXSTOP)
	{
		// Calculate the DMA ending address given the starting address and len 
		// parameter.  The DMA will follow the receive buffer wrapping boundary.
		temp.Val += len-1;
		if(temp.Val > RXSTOP)
		{
			temp.Val -= RXSIZE;
		}
	}
	else
	{
		temp.Val += len-1;
	}	
	
	// Write the DMA end address
	WriteReg(EDMANDL, temp.v[0]);
	WriteReg(EDMANDH, temp.v[1]);
	
	// Begin the DMA checksum calculation and wait until it is finished
	BFSReg(ECON1, ECON1_DMAST | ECON1_CSUMEN);
	while(ReadETHReg(ECON1).ECON1bits.DMAST);

	// Return the resulting good stuff
	temp.v[0] = ReadETHReg(EDMACSL).Val;
	temp.v[1] = ReadETHReg(EDMACSH).Val;
	return temp.Val;
}
#endif	// End of MCHP_MAC specific code


/******************************************************************************
 * Function:        void MACCopyRxToTx(WORD RxOffset, WORD TxOffset, WORD len)
 *
 * PreCondition:    None
 *
 * Input:           RxOffset: Offset in the RX buffer (0=first byte of 
 * 							  destination MAC address) to copy from.
 *					TxOffset: Offset in the TX buffer (0=first byte of
 *							  destination MAC address) to copy to.
 *					len:	  Number of bytes to copy
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        If the TX logic is transmitting a packet (ECON1.TXRTS is 
 *					set), the hardware will wait until it is finished.  Then, 
 *					the DMA module will copy the data from the receive buffer 
 *					to the transmit buffer.
 *
 * Note:            None
 *****************************************************************************/
// Remove this line if your application needs to use this 
// function.  This code has NOT been tested.
#if 0 
void MACCopyRxToTx(WORD RxOffset, WORD TxOffset, WORD len)
{
	WORD_VAL temp;

	temp.Val = CurrentPacketLocation.Val + RxOffset + sizeof(MCP_PREAMBLE);
	if ( temp.Val > RXSTOP )		// Adjust value if a wrap is needed
		temp.Val -= RXSIZE;

	BankSel(EDMASTL);
	WriteReg(EDMASTL, temp.v[0]);
	WriteReg(EDMASTH, temp.v[1]);

	temp.Val += len-1;
	if ( temp.Val > RXSTOP )		// Adjust value if a wrap is needed
		temp.Val -= RXSIZE;

	WriteReg(EDMANDL, temp.v[0]);
	WriteReg(EDMANDH, temp.v[1]);
	
	TxOffset += TXSTART+1;
	WriteReg(EDMADSTL, ((WORD_VAL*)&TxOffset)->v[0]);
	WriteReg(EDMADSTH, ((WORD_VAL*)&TxOffset)->v[1]);
	
	// Do the DMA Copy.  The DMA module will wait for TXRTS to become clear 
	// before starting the copy.
	BFCReg(ECON1, ECON1_CSUMEN);
	BFSReg(ECON1, ECON1_DMAST);
	while(ReadETHReg(ECON1).ECON1bits.DMAST);
}
#endif


#if defined(MAC_FILTER_BROADCASTS)
// NOTE: This code has NOT been tested.  See StackTsk.h's explanation
// of MAC_FILTER_BROADCASTS.
/******************************************************************************
 * Function:        void MACSetPMFilter(BYTE *Pattern, 
 *										BYTE *PatternMask, 
 *										WORD PatternOffset)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 * 					MACIsTxReady() must return TRUE
 *
 * Input:           *Pattern: Pointer to an intial pattern to compare against
 *					*PatternMask: Pointer to an 8 byte pattern mask which 
 *								  defines which bytes of the pattern are 
 *								  important.  At least one bit must be set.
 *					PatternOffset: Offset from the beginning of the Ethernet 
 *								   frame (1st byte of destination address), to
 *								   begin comparing with the given pattern.
 *
 * Output:          None
 *
 * Side Effects:    Contents of the TX buffer space are overwritten
 *
 * Overview:        MACSetPMFilter sets the hardware receive filters for: 
 *					CRC AND (Unicast OR Pattern Match).  As a result, only a 
 *					subset of the broadcast packets which are normally 
 *					received will be received.
 *
 * Note:            None
 *****************************************************************************/
void MACSetPMFilter(BYTE *Pattern, 
					BYTE *PatternMask, 
					WORD PatternOffset)
{
	WORD_VAL i;
	BYTE *MaskPtr;
	BYTE UnmaskedPatternLen;
	
	// Set the SPI write pointer and DMA startting address to the beginning of 
	// the transmit buffer
	BankSel(EWRPTL);
	WriteReg(EWRPTL, LOW(TXSTART));
	WriteReg(EWRPTH, HIGH(TXSTART));
	WriteReg(EDMASTL, LOW(TXSTART));
	WriteReg(EDMASTH, HIGH(TXSTART));

	// Fill the transmit buffer with the pattern to match against.  Only the 
	// bytes which have a mask bit of 1 are written into the buffer and will
	// subsequently be used for checksum computation.  
	MaskPtr = PatternMask;
	for(i.Val = 0x0100; i.v[0] < 64; i.v[0]++)
	{
		if( *MaskPtr & i.v[1] )
		{
			MACPut(*Pattern);
			UnmaskedPatternLen++;
		}
		Pattern++;
		
		i.v[1] <<= 1;
		if( i.v[1] == 0u )
		{
			i.v[1] = 0x01;
			MaskPtr++;
		}
	}

	// Calculate and set the DMA end address
	i.Val = TXSTART + (WORD)UnmaskedPatternLen - 1;
	WriteReg(EDMANDL, i.v[0]);
	WriteReg(EDMANDH, i.v[1]);

	// Calculate the checksum on the given pattern using the DMA module
	BFSReg(ECON1, ECON1_DMAST | ECON1_CSUMEN);
	while(ReadETHReg(ECON1).ECON1bits.DMAST);

	// Make certain that the PM filter isn't enabled while it is 
	// being reconfigured.
	BankSel(ERXFCON);
	WriteReg(ERXFCON, ERXFCON_UCEN | ERXFCON_CRCEN | ERXFCON_BCEN);

	// Get the calculated DMA checksum and store it in the PM 
	// checksum registers
	i.v[0] == ReadETHReg(EDMACSL).Val;
	i.v[1] == ReadETHReg(EDMACSH).Val;
	WriteReg(EPMCSL, i.v[0]);
	WriteReg(EPMCSH, i.v[0]);

	// Set the Pattern Match offset and 8 byte mask
	WriteReg(EPMOL, ((WORD_VAL*)&PatternOffset)->v[0]);
	WriteReg(EPMOH, ((WORD_VAL*)&PatternOffset)->v[1]);
	for(i.Val = EPMM0; i.Val <= EPMM7 ; i.Val++)
	{
		WriteReg(i.Val, *PatternMask++);
	}

	// Begin using the new Pattern Match filter instead of the 
	// broadcast filter
	WriteReg(ERXFCON, ERXFCON_UCEN | ERXFCON_CRCEN | ERXFCON_PMEN);
}//end MACSetPMFilter


/******************************************************************************
 * Function:        void MACDisablePMFilter(void)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        MACDisablePMFilter disables the Pattern Match receive 
 *					filter (if enabled) and returns to the default filter 
 *					configuration of: CRC AND (Unicast OR Broadcast).
 *
 * Note:            None
 *****************************************************************************/
void MACDisablePMFilter(void)
{
	BankSel(ERXFCON);
	WriteReg(ERXFCON, ERXFCON_UCEN | ERXFCON_CRCEN | ERXFCON_BCEN);
	return;
}//end MACDisablePMFilter
#endif // end of MAC_FILTER_BROADCASTS specific code


/******************************************************************************
 * Function:        BYTE MACGet()
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 * 					ERDPT must point to the place to read from.
 *
 * Input:           None
 *
 * Output:          Byte read from the ENC28J60's RAM
 *
 * Side Effects:    None
 *
 * Overview:        MACGet returns the byte pointed to by ERDPT and 
 *					increments ERDPT so MACGet() can be called again.  The 
 *					increment will follow the receive buffer wrapping boundary.
 *
 * Note:            None
 *****************************************************************************/
BYTE MACGet()
{
	SPISelectEthernet();
	SSPBUF = RBM;
	while(!PIR1_SSPIF);		// Wait until opcode/address is transmitted.
	PIR1_SSPIF = 0;
	SSPBUF = 0;				// Send a dummy byte to receive the register 
							//   contents.
	while(!PIR1_SSPIF);		// Wait until register is received.
	PIR1_SSPIF = 0;
	SPIUnselectEthernet();

	return SSPBUF;
}//end MACGet


/******************************************************************************
 * Function:        WORD MACGetArray(BYTE *val, WORD len)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 * 					ERDPT must point to the place to read from.
 *
 * Input:           *val: Pointer to storage location
 *					len:  Number of bytes to read from the data buffer.
 *
 * Output:          Byte(s) of data read from the data buffer.
 *
 * Side Effects:    None
 *
 * Overview:        Burst reads several sequential bytes from the data buffer 
 *					and places them into local memory.  With SPI burst support, 
 *					it performs much faster than multiple MACGet() calls.
 *					ERDPT is incremented after each byte, following the same 
 *					rules as MACGet().
 *
 * Note:            None
 *****************************************************************************/
WORD MACGetArray(BYTE *val, WORD len)
{
	WORD i;

	// Start the burst operation
	SPISelectEthernet();
	SSPBUF = RBM;			// Send the Read Buffer Memory opcode.
	i = 0;		
	val--;
	while(!PIR1_SSPIF);		// Wait until opcode/address is transmitted.
	PIR1_SSPIF = 0;

	// Read the data
	while(i<len)
	{
		SSPBUF = 0;			// Send a dummy byte to receive a byte 
		i++;
		val++;
		while(!PIR1_SSPIF);	// Wait until byte is received.
		PIR1_SSPIF = 0;
		*val = SSPBUF;
	};

	// Terminate the burst operation
	SPIUnselectEthernet();

	return i;
}//end MACGetArray


/******************************************************************************
 * Function:        void MACPut(BYTE val)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 * 					EWRPT must point to the location to begin writing.
 *
 * Input:           Byte to write into the ENC28J60 buffer memory
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        MACPut outputs the Write Buffer Memory opcode/constant 
 *					(8 bits) and data to write (8 bits) over the SPI.  
 *					EWRPT is incremented after the write.
 *
 * Note:            None
 *****************************************************************************/
void MACPut(BYTE val)
{
	SPISelectEthernet();
	SSPBUF = WBM;			// Send the opcode and constant.
	while(!PIR1_SSPIF);		// Wait until opcode/constant is transmitted.
	PIR1_SSPIF = 0;
	SSPBUF = val;			// Send the byte to be writen.
	while(!PIR1_SSPIF);		// Wait until byte is transmitted.
	PIR1_SSPIF = 0;
	SPIUnselectEthernet();
}//end MACPut


/******************************************************************************
 * Function:        void MACPutArray(BYTE *val, WORD len)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 * 					EWRPT must point to the location to begin writing.
 *
 * Input:           *val: Pointer to source of bytes to copy.
 *					len:  Number of bytes to write to the data buffer.
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        MACPutArray writes several sequential bytes to the 
 *					ENC28J60 RAM.  It performs faster than multiple MACPut()
 *					calls.  EWRPT is incremented by len.
 *
 * Note:            None
 *****************************************************************************/
void MACPutArray(BYTE *val, WORD len)
{
	// Select the chip and send the proper opcode
	SPISelectEthernet();
	SSPBUF = WBM;			// Send the Write Buffer Memory opcode
	while(!PIR1_SSPIF);		// Wait until opcode/constant is transmitted.
	PIR1_SSPIF = 0;

	// Send the data
	while(len)
	{
		SSPBUF = *val;		// Start sending the byte
		val++;				// Increment after writing to SSPBUF to increase speed
		len--;				// Decrement after writing to SSPBUF to increase speed
		while(!PIR1_SSPIF);	// Wait until byte is transmitted
		PIR1_SSPIF = 0;
	};

	// Terminate the burst operation
	SPIUnselectEthernet();
}//end MACPutArray


/******************************************************************************
 * Function:        static void SendSystemReset(void)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        SendSystemReset sends the System Reset SPI command to 
 *					the Ethernet controller.  It resets all register contents 
 *					(except for ECOCON) and returns the device to the power 
 *					on default state.
 *
 * Note:            None
 *****************************************************************************/
static void SendSystemReset(void)
{
	SPISelectEthernet();
	SSPBUF = SR;
	while(!PIR1_SSPIF);		// Wait until the command is transmitted.
	PIR1_SSPIF = 0;
	SPIUnselectEthernet();
}//end SendSystemReset


/******************************************************************************
 * Function:        REG ReadETHReg(BYTE Address)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 * 					Bank select bits must be set corresponding to the register 
 * 					to read from.
 *
 * Input:           5 bit address of the ETH control register to read from.
 *					  The top 3 bits must be 0.
 *
 * Output:          Byte read from the Ethernet controller's ETH register.
 *
 * Side Effects:    None
 *
 * Overview:        ReadETHReg sends the 8 bit RCR opcode/Address byte over 
 *					the SPI and then retrives the register contents in the 
 *					next 8 SPI clocks.
 *
 * Note:            This routine cannot be used to access MAC/MII or PHY 
 *					registers.  Use ReadMACReg() or ReadPHYReg() for that 
 *					purpose.  
 *****************************************************************************/
static REG ReadETHReg(BYTE Address)
{
	// Select the chip and send the Read Control Register opcode/address
	SPISelectEthernet();
	SSPBUF = RCR | Address;	
	while(!PIR1_SSPIF);		// Wait until the opcode/address is transmitted
	PIR1_SSPIF = 0;
	SSPBUF = 0;				// Send a dummy byte to receive the register 
							//   contents
	while(!PIR1_SSPIF);		// Wait until the register is received
	PIR1_SSPIF = 0;
	SPIUnselectEthernet();

	return *((REG*)&SSPBUF);
}//end ReadETHReg


/******************************************************************************
 * Function:        REG ReadMACReg(BYTE Address)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 * 					Bank select bits must be set corresponding to the register 
 * 					to read from.
 *
 * Input:           5 bit address of the MAC or MII register to read from.
 *					  The top 3 bits must be 0.
 *
 * Output:          Byte read from the Ethernet controller's MAC/MII register.
 *
 * Side Effects:    None
 *
 * Overview:        ReadMACReg sends the 8 bit RCR opcode/Address byte as well 
 *					as a dummy byte over the SPI and then retrives the 
 *					register contents in the last 8 SPI clocks.
 *
 * Note:            This routine cannot be used to access ETH or PHY 
 *					registers.  Use ReadETHReg() or ReadPHYReg() for that 
 *					purpose.  
 *****************************************************************************/
static REG ReadMACReg(BYTE Address)
{
	SPISelectEthernet();
	SSPBUF = RCR | Address;	// Send the Read Control Register opcode and 
							//   address.
	while(!PIR1_SSPIF);		// Wait until opcode/address is transmitted.
	PIR1_SSPIF = 0;
	SSPBUF = 0;				// Send a dummy byte 
	while(!PIR1_SSPIF);		// Wait for the dummy byte to be transmitted
	PIR1_SSPIF = 0;
	SSPBUF = 0;				// Send another dummy byte to receive the register 
							//   contents.
	while(!PIR1_SSPIF);		// Wait until register is received.
	PIR1_SSPIF = 0;
	SPIUnselectEthernet();
	
	return *((REG*)&SSPBUF);
}//end ReadMACReg


/******************************************************************************
 * Function:        ReadPHYReg
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 *
 * Input:           Address of the PHY register to read from.
 *
 * Output:          16 bits of data read from the PHY register.
 *
 * Side Effects:    Alters bank bits to point to Bank 2
 *
 * Overview:        ReadPHYReg performs an MII read operation.  While in 
 *					progress, it simply polls the MII BUSY bit wasting time.
 *
 * Note:            None
 *****************************************************************************/
PHYREG ReadPHYReg(BYTE Register)
{
	PHYREG Result;

	// Set the right address and start the register read operation
	BankSel(MIREGADR);
	WriteReg(MIREGADR, Register);
	WriteReg(MICMD, MICMD_MIIRD);	

	// Loop to wait until the PHY register has been read through the MII
	// This requires 10.24us
	BankSel(MISTAT);
	while(ReadMACReg(MISTAT).MISTATbits.BUSY);

	// Stop reading
	BankSel(MIREGADR);
	WriteReg(MICMD, 0x00);	
	
	// Obtain results and return
	Result.VAL.v[0] = ReadMACReg(MIRDL).Val;
	Result.VAL.v[1] = ReadMACReg(MIRDH).Val;
	return Result;
}//end ReadPHYReg


/******************************************************************************
 * Function:        void WriteReg(BYTE Address, BYTE Data)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 * 					Bank select bits must be set corresponding to the register 
 *					to modify.
 *
 * Input:           5 bit address of the ETH, MAC, or MII register to modify.  
 *					  The top 3 bits must be 0.  
 *					Byte to be written into the register.
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        WriteReg sends the 8 bit WCR opcode/Address byte over the 
 *					SPI and then sends the data to write in the next 8 SPI 
 *					clocks.
 *
 * Note:            This routine is almost identical to the BFCReg() and 
 *					BFSReg() functions.  It is seperate to maximize speed.  
 *					Unlike the ReadETHReg/ReadMACReg functions, WriteReg() 
 *					can write to any ETH or MAC register.  Writing to PHY 
 *					registers must be accomplished with WritePHYReg().
 *****************************************************************************/
static void WriteReg(BYTE Address, BYTE Data)
{
	SPISelectEthernet();
	SSPBUF = WCR | Address;	// Send the opcode and address.
	while(!PIR1_SSPIF);		// Wait until opcode/address is transmitted.
	PIR1_SSPIF = 0;
	SSPBUF = Data;			// Send the byte to be writen.
	while(!PIR1_SSPIF);		// Wait until register is written.
	PIR1_SSPIF = 0;
	SPIUnselectEthernet();
}//end WriteReg


/******************************************************************************
 * Function:        void BFCReg(BYTE Address, BYTE Data)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 * 					Bank select bits must be set corresponding to the register 
 *					  to modify.
 *
 * Input:           5 bit address of the register to modify.  The top 3 bits 
 *					  must be 0.  
 *					Byte to be used with the Bit Field Clear operation.
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        BFCReg sends the 8 bit BFC opcode/Address byte over the 
 *					SPI and then sends the data in the next 8 SPI clocks.
 *
 * Note:            This routine is almost identical to the WriteReg() and 
 *					BFSReg() functions.  It is separate to maximize speed.  
 *					BFCReg() must only be used on ETH registers.
 *****************************************************************************/
static void BFCReg(BYTE Address, BYTE Data)
{
	SPISelectEthernet();
	SSPBUF = BFC | Address;	// Send the opcode and address.
	while(!PIR1_SSPIF);		// Wait until opcode/address is transmitted.
	PIR1_SSPIF = 0;
	SSPBUF = Data;			// Send the byte to be writen.
	while(!PIR1_SSPIF);		// Wait until register is written.
	PIR1_SSPIF = 0;
	SPIUnselectEthernet();
}//end BFCReg


/******************************************************************************
 * Function:        void BFSReg(BYTE Address, BYTE Data)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 * 					Bank select bits must be set corresponding to the register 
 *					to modify.
 *
 * Input:           5 bit address of the register to modify.  The top 3 bits 
 *					  must be 0.  
 *					Byte to be used with the Bit Field Set operation.
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        BFSReg sends the 8 bit BFC opcode/Address byte over the 
 *					SPI and then sends the data in the next 8 SPI clocks.
 *
 * Note:            This routine is almost identical to the WriteReg() and 
 *					BFCReg() functions.  It is separate to maximize speed.
 *					BFSReg() must only be used on ETH registers.
 *****************************************************************************/
static void BFSReg(BYTE Address, BYTE Data)
{
	SPISelectEthernet();
	SSPBUF = BFS | Address;	// Send the opcode and address.
	while(!PIR1_SSPIF);		// Wait until opcode/address is transmitted.
	PIR1_SSPIF = 0;
	SSPBUF = Data;			// Send the byte to be writen.
	while(!PIR1_SSPIF);		// Wait until register is written.
	PIR1_SSPIF = 0;
	SPIUnselectEthernet();
}//end BFSReg


/******************************************************************************
 * Function:        WritePHYReg
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 *
 * Input:           Address of the PHY register to write to.
 *					16 bits of data to write to PHY register.
 *
 * Output:          None
 *
 * Side Effects:    Alters bank bits to point to Bank 3
 *
 * Overview:        WritePHYReg performs an MII write operation.  While in 
 *					progress, it simply polls the MII BUSY bit wasting time.
 *
 * Note:            None
 *****************************************************************************/
void WritePHYReg(BYTE Register, WORD Data)
{
	// Write the register address
	BankSel(MIREGADR);
	WriteReg(MIREGADR, Register);
	
	// Write the data
	// Order is important: write low byte first, high byte last
	WriteReg(MIWRL, ((WORD_VAL*)&Data)->v[0]);	
	WriteReg(MIWRH, ((WORD_VAL*)&Data)->v[1]);

	// Wait until the PHY register has been written
	BankSel(MISTAT);
	while(ReadMACReg(MISTAT).MISTATbits.BUSY);
}//end WritePHYReg


/******************************************************************************
 * Function:        BankSel
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 *
 * Input:           Register address with the high byte containing the 2 bank 
 *					  select 2 bits.
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        BankSel takes the high byte of a register address and 
 *					changes the bank select bits in ETHCON1 to match.
 *
 * Note:            None
 *****************************************************************************/
static void BankSel(WORD Register) 
{
	BFCReg(ECON1, ECON1_BSEL1 | ECON1_BSEL0);
	BFSReg(ECON1, ((WORD_VAL*)&Register)->v[1]);
}//end BankSel


/******************************************************************************
 * Function:        static BOOL TestMemory(void) 
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 *
 * Input:           None
 *
 * Output:          TRUE if the memory tests have passed 
 *					FALSE if the BIST has detected a hardware fault
 *
 * Side Effects:    Alters the state of numerous control registers and all 
 *					RAM bytes.
 *
 * Overview:        The internal BIST and DMA modules are used to fill the 
 *					entire dual port memory and calculate a checksum of the 
 *					data stored within.  Address and Random fill modes are 
 *					used.
 *
 * Note:            For the Random Fill mode, the random number generator is
 *					seeded by the contents of the TMR0L PIC SFR.  If the timer
 *					is running, additional confidence that the memory is 
 *					working can be obtained by calling TestMemory multiple 
 *					times.
 *****************************************************************************/
#if defined(MAC_POWER_ON_TEST)
static BOOL TestMemory(void) 
{
	#define RANDOM_FILL		0b0000
	#define ADDRESS_FILL	0b0100
	#define PATTERN_SHIFT	0b1000
	#define RANDOM_RACE		0b1100
	
	WORD_VAL DMAChecksum, BISTChecksum;
	
	
	// Select Bank 0 and disable anything that could have been in progress
	WriteReg(ECON1, 0x00);
	
	// Set up necessary pointers for the DMA to calculate over the entire 
	// memory
	WriteReg(EDMASTL, 0x00);
	WriteReg(EDMASTH, 0x00);
	WriteReg(EDMANDL, LOW(RAMSIZE-1u));
	WriteReg(EDMANDH, HIGH(RAMSIZE-1u));
	WriteReg(ERXNDL, LOW(RAMSIZE-1u));
	WriteReg(ERXNDH, HIGH(RAMSIZE-1u));

	// Enable Test Mode and do an Address Fill
	BankSel(EBSTCON);
	WriteReg(EBSTCON, EBSTCON_TME | 
						 EBSTCON_BISTST | 
						 ADDRESS_FILL);
	
	
	// Wait for the BIST to complete and disable test mode before 
	// starting any DMA operations.
	while(ReadETHReg(EBSTCON).EBSTCONbits.BISTST);
	BFCReg(EBSTCON, EBSTCON_TME);


	// Begin reading the memory and calculating a checksum over it
	// Block until the checksum is generated
	BFSReg(ECON1, ECON1_DMAST | ECON1_CSUMEN);
	BankSel(EDMACSL);
	while(ReadETHReg(ECON1).ECON1bits.DMAST);

	// Obtain the resulting DMA checksum and the expected BIST checksum
	DMAChecksum.v[0] = ReadETHReg(EDMACSL).Val;
	DMAChecksum.v[1] = ReadETHReg(EDMACSH).Val;
	BankSel(EBSTCSL);
	BISTChecksum.v[0] = ReadETHReg(EBSTCSL).Val;
	BISTChecksum.v[1] = ReadETHReg(EBSTCSH).Val;
	BFCReg(EBSTCON, EBSTCON_TME);
	
	// Compare the results
	// 0xF807 should always be generated in Address fill mode
	if( (DMAChecksum.Val != BISTChecksum.Val) || (DMAChecksum.Val != 0xF807) )
		return FALSE;
	
	// Seed the random number generator and begin another Random Fill test 
	// with the DMA and BIST memory access ports swapped.
	WriteReg(EBSTSD, TMR0L);
	WriteReg(EBSTCON, EBSTCON_TME | 
					  EBSTCON_PSEL | 
					  EBSTCON_BISTST | 
					  RANDOM_FILL);
						 
						 
	// Wait for the BIST to complete and disable test mode since 
	// we won't be needing it anymore
	while(ReadETHReg(EBSTCON).EBSTCONbits.BISTST);
	BFCReg(EBSTCON, EBSTCON_TME);
	
	
	// Begin reading the memory and calculating a checksum over it
	// Block until the checksum is generated
	BFSReg(ECON1, ECON1_DMAST | ECON1_CSUMEN);
	BankSel(EDMACSL);
	while(ReadETHReg(ECON1).ECON1bits.DMAST);

	// Obtain the resulting DMA checksum and the expected BIST checksum
	DMAChecksum.v[0] = ReadETHReg(EDMACSL).Val;
	DMAChecksum.v[1] = ReadETHReg(EDMACSH).Val;
	BankSel(EBSTCSL);
	BISTChecksum.v[0] = ReadETHReg(EBSTCSL).Val;
	BISTChecksum.v[1] = ReadETHReg(EBSTCSH).Val;
	
	return (DMAChecksum.Val == BISTChecksum.Val);
}//end TestMemory
#endif


/******************************************************************************
 * Function:        void MACSetDuplex(DUPLEX DuplexState) 
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 *
 * Input:           Member of DUPLEX enum:
 *						FULL: Set full duplex mode
 *						HALF: Set half duplex mode
 *						USE_PHY: Set the MAC to match the PHYDPLXMODE bit in 
 *								 PHYCON.  This is controlled by LEDB on RESET.
 *
 * Output:          None
 *
 * Side Effects:    Changes bank bits to Bank 2.
 *
 * Overview:        Disables RX, TX logic, sets MAC up for full duplex 
 *					operation, sets PHY up for full duplex operation, and 
 *					reenables RX logic.  The back-to-back inter-packet gap 
 *					register (MACBBIPG) is updated to maintain a 9.6us gap.
 *
 * Note:            If a packet is being transmitted or received while this 
 *					function is called, it will be aborted.
 *****************************************************************************/
void MACSetDuplex(DUPLEX DuplexState)
{
	REG Register;
	PHYREG PhyReg;
	
	// Disable receive logic and abort any packets currently being transmitted
	BFCReg(ECON1, ECON1_TXRTS | ECON1_RXEN);
	
	// Set the PHY to the proper duplex mode
	PhyReg = ReadPHYReg(PHCON1);
	if(DuplexState == USE_PHY)
	{
		DuplexState = PhyReg.PHCON1bits.PDPXMD;
	}
	else
	{
		PhyReg.PHCON1bits.PDPXMD = DuplexState;
		WritePHYReg(PHCON1, PhyReg.Val);
	}

	// Set the MAC to the proper duplex mode
	BankSel(MACON3);
	Register = ReadMACReg(MACON3);
	Register.MACON3bits.FULDPX = DuplexState;
	WriteReg(MACON3, Register.Val);

	// Set the back-to-back inter-packet gap time to IEEE specified 
	// requirements.  The meaning of the MABBIPG value changes with the duplex
	// state, so it must be updated in this function.
	// In full duplex, 0x15 represents 9.6us; 0x12 is 9.6us in half duplex
	WriteReg(MABBIPG, DuplexState ? 0x15 : 0x12);	
	
	// Reenable receive logic
	BFSReg(ECON1, ECON1_RXEN);
}//end MACSetDuplex


/******************************************************************************
 * Function:        void MACPowerDown(void)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        MACPowerDown puts the ENC28J60 in low power sleep mode. In
 *					sleep mode, no packets can be transmitted or received.  
 *					All MAC and PHY registers should not be accessed.
 *
 * Note:            If a packet is being transmitted while this function is 
 * 					called, this function will block until it is it complete.
 *					If anything is being received, it will be completed.
 *****************************************************************************/
void MACPowerDown(void)
{
	// Disable packet reception
	BFCReg(ECON1, ECON1_RXEN);

	// Make sure any last packet which was in-progress when RXEN was cleared 
	// is completed
	while(ReadETHReg(ESTAT).ESTATbits.RXBUSY);

	// If a packet is being transmitted, wait for it to finish
	while(ReadETHReg(ECON1).ECON1bits.TXRTS);
	
	// Enter sleep mode
	BFSReg(ECON2, ECON2_PWRSV);
}//end MACPowerDown


/******************************************************************************
 * Function:        void MACPowerUp(void)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        MACPowerUp returns the ENC28J60 back to normal operation
 *					after a previous call to MACPowerDown().  Calling this 
 *					function when already powered up will have no effect.
 *
 * Note:            The first packet transmitted may get lost at the RX end if
 *					you don't wait for the link to go up first.  MACIsLinked() 
 *					can be called to determine if a link is established.
 *****************************************************************************/
void MACPowerUp(void)
{	
	// Leave power down mode
	BFCReg(ECON2, ECON2_PWRSV);

	// Wait for the 300us Oscillator Startup Timer (OST) to time out.  This 
	// delay is required for the PHY module to return to an operational state.
	while(!ReadETHReg(ESTAT).ESTATbits.CLKRDY);
	
	// Enable packet reception
	BFSReg(ECON1, ECON1_RXEN);
}//end MACPowerUp


/******************************************************************************
 * Function:        void SetCLKOUT(BYTE NewConfig)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 *
 * Input:           NewConfig - 0x00: CLKOUT disabled (pin driven low)
 *								0x01: Divide by 1 (25 MHz)
 *								0x02: Divide by 2 (12.5 MHz)
 *								0x03: Divide by 3 (8.333333 MHz)
 *								0x04: Divide by 4 (6.25 MHz, POR default)
 *								0x05: Divide by 8 (3.125 MHz)
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Writes the value of NewConfig into the ECOCON register.  
 *					The CLKOUT pin will beginning outputting the new frequency
 *					immediately.
 *
 * Note:            
 *****************************************************************************/
void SetCLKOUT(BYTE NewConfig)
{	
	BankSel(ECOCON);
	WriteReg(ECOCON, NewConfig);
}//end SetCLKOUT


/******************************************************************************
 * Function:        BYTE GetCLKOUT(void)
 *
 * PreCondition:    SPI bus must be initialized (done in MACInit()).
 *
 * Input:           None
 *
 * Output:          BYTE - 0x00: CLKOUT disabled (pin driven low)
 *						   0x01: Divide by 1 (25 MHz)
 *						   0x02: Divide by 2 (12.5 MHz)
 *						   0x03: Divide by 3 (8.333333 MHz)
 *						   0x04: Divide by 4 (6.25 MHz, POR default)
 *						   0x05: Divide by 8 (3.125 MHz)
 *						   0x06: Reserved
 *						   0x07: Reserved
 *
 * Side Effects:    None
 *
 * Overview:        Returns the current value of the ECOCON register.
 *
 * Note:            None
 *****************************************************************************/
BYTE GetCLKOUT(void)
{	
	BankSel(ECOCON);
	return ReadETHReg(ECOCON).Val;
}//end GetCLKOUT
