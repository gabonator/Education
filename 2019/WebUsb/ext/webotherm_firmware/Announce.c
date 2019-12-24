/*********************************************************************
 *
 *                  Announce Module for Microchip TCP/IP Stack
 *
 *********************************************************************
 * FileName:        announce.c
 * Dependencies:    UDP.h
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
 * Howard Schlunder     10/7/04	Original
 * Howard Schlunder		2/9/05	Simplified MAC address to text 
 *								conversion logic
 * Howard Schlunder		2/14/05	Fixed subnet broadcast calculation
 ********************************************************************/
#define THIS_IS_ANNOUNCE

#include "UDP.h"
#include "Helpers.h"

#if !defined(STACK_USE_ANNOUNCE)
    #error Announce module included while STACK_USE_ANNOUNCE is not defined
#endif

#define ANNOUNCE_PORT	30303


/*********************************************************************
 * Function:        void AnnounceIP(void)
 *
 * PreCondition:    Stack is initialized()
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        AnnounceIP opens a UDP socket and transmits a 
 *					broadcast packet to port 30303.  If a computer is
 *					on the same subnet and a utility is looking for 
 *					packets on the UDP port, it will receive the 
 *					broadcast.  For this application, it is used to 
 *					announce the change of this board's IP address.
 *					The messages can be viewed with the MCHPDetect.exe
 *					program.
 *
 * Note:            A UDP socket must be available before this 
 *					function is called.  It is freed at the end of 
 *					the function.  MAX_UDP_SOCKETS may need to be 
 *					increased if other modules use UDP sockets.
 ********************************************************************/
void AnnounceIP(void)
{
	UDP_SOCKET	MySocket;
	NODE_INFO	Remote;
	BYTE 		i;
	
	// Set the socket's destination to be a broadcast over our IP 
	// subnet
	// Set the MAC destination to be a broadcast
	Remote.MACAddr.v[0] = 0xFF;
	Remote.MACAddr.v[1] = 0xFF;
	Remote.MACAddr.v[2] = 0xFF;
	Remote.MACAddr.v[3] = 0xFF;
	Remote.MACAddr.v[4] = 0xFF;
	Remote.MACAddr.v[5] = 0xFF;
	
	// Set the IP subnet's broadcast address
	Remote.IPAddr.Val = (AppConfig.MyIPAddr.Val & AppConfig.MyMask.Val) | 
						 ~AppConfig.MyMask.Val;
	
	// Open a UDP socket for outbound transmission
	MySocket = UDPOpen(2860, &Remote, ANNOUNCE_PORT);
	
	// Abort operation if no UDP sockets are available
	// If this ever happens, incrementing MAX_UDP_SOCKETS in 
	// StackTsk.h may help (at the expense of more global memory 
	// resources).
	if( MySocket == INVALID_UDP_SOCKET )
		return;
	
	// Make certain the socket can be written to
	while( !UDPIsPutReady(MySocket) );
	
	// Begin sending our MAC address in human readable form.
	// The MAC address theoretically could be obtained from the 
	// packet header when the computer receives our UDP packet, 
	// however, in practice, the OS will abstract away the useful
	// information and it would be difficult to obtain.  It also 
	// would be lost if this broadcast packet were forwarded by a
	// router to a different portion of the network (note that 
	// broadcasts are normally not forwarded by routers).
	UDPPut('M');
	UDPPut('A');
	UDPPut('C');
	UDPPut(' ');
	UDPPut('A');
	UDPPut('d');
	UDPPut('d');
	UDPPut('r');
	UDPPut('e');
	UDPPut('s');
	UDPPut('s');
	UDPPut(':');
	UDPPut(' ');
	
	// Convert the MAC address bytes to hex (text) and then send it
	i = 0;
	while(1)
	{
		UDPPut(btohexa_high(AppConfig.MyMACAddr.v[i]));
	    UDPPut(btohexa_low(AppConfig.MyMACAddr.v[i]));
	    if(++i == 6)
	    	break;
	    UDPPut('-');
	}

	// Send some other human readable information.
	UDPPut('.');
	UDPPut(' ');
	UDPPut('M');
	UDPPut('y');
	UDPPut(' ');
	UDPPut('I');
	UDPPut('P');
	UDPPut(' ');
	UDPPut('A');
	UDPPut('d');
	UDPPut('d');
	UDPPut('r');
	UDPPut('e');
	UDPPut('s');
	UDPPut('s');
	UDPPut(' ');
	UDPPut('h');
	UDPPut('a');
	UDPPut('s');
	UDPPut(' ');
	UDPPut('c');
	UDPPut('h');
	UDPPut('a');
	UDPPut('n');
	UDPPut('g');
	UDPPut('e');
	UDPPut('d');
	UDPPut('.');
	
	// Send the packet
	UDPFlush();
	
	// Close the socket so it can be used by other modules
	UDPClose(MySocket);
}
