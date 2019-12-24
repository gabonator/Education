#ifndef USART_H
#define USART_H

#include "compiler.h"
#include "stacktsk.h"

#define DBGCMD(cmd) cmd
#define DBG(cmd) 	{ USARTPutROMString(#cmd); cmd }
#define DBGCMT(cmd) { USARTPut('['); USARTPutROMString(cmd); USARTPut(']'); }

//#define BAUD_RATE       (9600)     // bps
#define BAUD_RATE       (38400)     // bps
//#define SPBRG_VAL   ( ((CLOCK_FREQ/10/BAUD_RATE)/16) - 1)

//#define USART_USE_BRGH_LOW
#if defined(USART_USE_BRGH_LOW)
    #define SPBRG_VAL   ( ((CLOCK_FREQ/10/BAUD_RATE)/64) - 1)
#else
    #define SPBRG_VAL   ( ((CLOCK_FREQ/10/BAUD_RATE)/16) - 1)
#endif


//#define SPBRG_VAL   26
#if SPBRG_VAL > 255
    #error "Calculated SPBRG value is out of range for currnet CLOCK_FREQ."
#endif

#if SPBRG_VAL < 5
    #error "Calculated SPBRG value is out of range for currnet CLOCK_FREQ."
#endif

#define USARTIsGetReady()   (PIR1_RCIF)
#define USARTGet()          (RCREG)
void DBGHEX(BYTE c);

unsigned char USARTgetch();
unsigned char USARTGetByte(void);
void USARTPutInt(signed int i);

void USARTPutROMString(ROM char const *str);
void USARTPut(BYTE c);
void USARTPutString(BYTE *s);
void USARTPutROMString(ROM char const * str);
BYTE USARTGetString(char *buffer, BYTE bufferLen);
#endif