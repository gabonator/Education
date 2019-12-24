/*
#if (!defined(DS_Read)) || (!defined(DS_Hi))
#error define DS interface
#endif
*/

//#define DelayUs(a)	Delay10us((a)/10u);

unsigned char DS_Init( void );
void DS_Out( unsigned char );
unsigned char DS_In( void );
void DS_Error(void);

#define _ASSERT(x)

#define DS_REG_TempLSB 0
#define DS_REG_TempMSB 1
#define DS_REG_UserTh 2
#define DS_REG_UserTl 3
#define DS_REG_CntRemain 6
#define DS_REG_CntPerDeg 7
#define DS_REG_CntPerCrc 8

// nefunguje error checking
#define DS_ERROR(a) ( a == 0x8000 || a == 0x8001 || a == 0x8002 )
#define DS_ERR_INIT1	0x8000
#define DS_ERR_INIT2	0x8001
#define DS_ERR_COMP		0x8002

// scratchpad ram
unsigned char buff[9];

int GetDS1820(void)
{
	unsigned char n;
	unsigned int temp;

 	if (!DS_Init())
		return DS_ERR_INIT1;

	DS_Out(0xcc);	// skip ROM
	DS_Out(0x44);	// perform temperature conversion

	// ak vracia 0xAA skontrolovat typ obvodu, musi DS1820
	//DS_Power();

	// konverzia max.750ms
	DelayMs(250);	
	DelayMs(250);	
	DelayMs(250);	
	
	if (!DS_Init())
		return DS_ERR_INIT2;
	
	DS_Out(0xcc);
	DS_Out(0xbe);	// read result
	
	for (n = 0; n < 9; n++)
		buff[n] = DS_In();

	temp = buff[1];
	temp <<= 8;
	temp |= buff[0];

#define _tempMulBits 4
#define _tempMul 16

	temp <<= _tempMulBits-1;	//temp *= _tempMul/2;
	// teplota je v °C * _tempMul
	
	// extended measurement
	if ( buff[DS_REG_CntPerDeg] != 0x10 )
		return DS_ERR_COMP;

	temp -= _tempMul/4;  //0.25*_tempMul;
	temp += buff[DS_REG_CntPerDeg];
	temp -= buff[DS_REG_CntRemain];

	return temp;	
}

// 1wire 

unsigned char DS_Init(void)
{	
   DS_Hi();
   DS_Low();
   Delay10us(25);   
   Delay10us(25);
   DS_Hi();
   Delay10us(10);	// po nejakych 120 sa uvolni !

   if (DS_Get())
		return 0;

   Delay10us(20);
   Delay10us(20);
   return 1;
}

unsigned char DS_In(void)
{
   unsigned char n, i_byte;

   for (n=0; n<8; n++)
   {
	DS_Low();
	DS_Hi();
#asm
      NOP
      NOP
      NOP
#endasm
      i_byte >>= 1;
	  DS_Read();
      if ( DS_Get() )
        i_byte |= 0x80;	// least sig bit first

      Delay10us(6);
   }
   return i_byte;
}

void DS_Out(unsigned char d)
{
	unsigned char n;
	for(n=0; n<8; n++)
	{
		DS_Low();

		if (d & 1)
		{
			DS_Hi();
			Delay10us(6);
		} else
		{
			Delay10us(6);
			DS_Hi();
      	}
      	d >>= 1;
   }
}
/*
void DS_Hi(void)
{
	DS_Dir = 1;
}

void DS_Low(void)
{
	DS_Dir = 0;
	DS_Pin = 0;
}
*/