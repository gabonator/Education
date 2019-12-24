#define THIS_IS_UART_SERVER

#include <string.h>

#include "StackTsk.h"
#include "UDP2UART.h"
#include "UDP.h"
#include "Helpers.h"
#include "usart.h"


#if !defined(STACK_USE_UDP)
#error UDP Server module is not enabled.
#error Remove this file from your project to reduce your code size.
#endif

UDP_SOCKET U2USocket;

void UDP2UARTInit(void)
{
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
	U2USocket = UDPOpen(2860, &Remote, UDP2UART_PORT);
	if( U2USocket == INVALID_UDP_SOCKET )
	{
		DBGCMT("Cant open UDP socket");
	}
}

unsigned int nFrame = 0;
const char msg[] = "Ahoj, toto je pokusna sprava !";
void UDP2UARTServer(void)
{
	BYTE read;

	nFrame++;

	if ( UDPIsGetReady(U2USocket) )
	{
		DBGCMT("U2U>");
		while (UDPGet(&read))
			USARTPut(read);
	}

	if ( (nFrame > 300 ) && UDPIsPutReady(U2USocket) )
	{
		nFrame = 0;
		for (read=0; msg[read]; read++)
			UDPPut( msg[read] );
	
		// Send the packet
		UDPFlush();
	}
}

