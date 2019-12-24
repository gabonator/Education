#include "usart.h"
/*
#define USARTIsGetReady()   (PIR1_RCIF)
#define USARTGet()          (RCREG)
void USARTPutROMString(ROM char const *str);
static void USARTPut(BYTE c)
static void USARTPutString(BYTE *s)
void USARTPutROMString(ROM char const * str)
BYTE USARTGetString(char *buffer, BYTE bufferLen)
*/

static const char hex[] = "0123456789abcdef";

unsigned char Hex2Dec(unsigned char ch)
{
	if ((ch>>4)==3)
		return ch&0xf;
	ch += 9;
	if ((ch>>4)==4)
		return ch&0xf;
	if ((ch>>4)==6)
		return ch&0xf;
	return 0;
}

void USARTPutInt(signed int i)
{
	char ch;
	if (i<0)
	{
		USARTPut('-');
		i = -i;
	}
#define mPL1(z)	ch = '0'; while (i>=z) { i-=z; ch++; }  USARTPut(ch);
	mPL1(10000)
	mPL1(1000)
	mPL1(100)
	mPL1(10)
	mPL1(1)
}

unsigned char USARTGetByte(void)
{
	unsigned char nReturn = 0;
	nReturn = Hex2Dec(USARTgetch());
	nReturn <<= 4;
	nReturn |= Hex2Dec(USARTgetch());
	return nReturn;
}

unsigned char USARTgetch() {
        while( !USARTIsGetReady() );

        return USARTGet();

	/* retrieve one byte */
//	while(!RCIF)	/* set when register is not empty */
//		continue;
//	return RCREG;	
}

void DBGHEX(BYTE c)
{
	USARTPut(hex[c>>4]);
	USARTPut(hex[c&15]);
}

void USARTPut(BYTE c)
{
    while( !TXSTA_TRMT);
    TXREG = c;
}

void USARTPutString(BYTE *s)
{
    BYTE c;

    while( (c = *s++) )
        USARTPut(c);
}

void USARTPutROMString(ROM char const * str)
{
    BYTE v;

    while( v = *str++ )
        USARTPut(v);
}


BYTE USARTGetString(char *buffer, BYTE bufferLen)
{
    BYTE v;
    BYTE count;

    count = 0;
    do
    {
        while( !USARTIsGetReady() );

        v = USARTGet();

        if ( v == '\r' || v == '\n' )
            break;

        count++;
        *buffer++ = v;
        *buffer = '\0';
        if ( bufferLen-- == 0 )
            break;
    } while(1);
    return count;
}


