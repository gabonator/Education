/*********************************************************************
 *
 *                  Tick Manager for PIC18
 *
 *********************************************************************
 * FileName:        Tick.c
 * Dependencies:    stackTSK.h
 *                  Tick.h
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
 * Author               Date        Comment
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 * Nilesh Rajbharti     6/28/01     Original        (Rev 1.0)
 * Nilesh Rajbharti     2/9/02      Cleanup
 * Nilesh Rajbharti     5/22/02     Rev 2.0 (See version.log for detail)
********************************************************************/

#define TICK_INCLUDE

#include "StackTsk.h"
#include "Tick.h"

#define TICK_TEMP_VALUE_1       \
        ((CLOCK_FREQ / 4) / (TICKS_PER_SECOND * TICK_PRESCALE_VALUE))

#if TICK_TEMP_VALUE_1 > 60000
#error TICK_PER_SECOND value cannot be programmed with current CLOCK_FREQ
#error Either lower TICK_PER_SECOND or manually configure the Timer
#endif

#define TICK_TEMP_VALUE         (65535 - TICK_TEMP_VALUE_1)

#define TICK_COUNTER_HIGH       ((TICK_TEMP_VALUE >> 8) & 0xff)
#define TICK_COUNTER_LOW        (TICK_TEMP_VALUE & 0xff)

#if (TICK_PRESCALE_VALUE == 2)
    #define TIMER_PRESCALE  (0)
#elif ( TICK_PRESCALE_VALUE == 4 )
    #define TIMER_PRESCALE  (1)
#elif ( TICK_PRESCALE_VALUE == 8 )
    #define TIMER_PRESCALE  (2)
#elif ( TICK_PRESCALE_VALUE == 16 )
    #define TIMER_PRESCALE  (3)
#elif ( TICK_PRESCALE_VALUE == 32 )
    #define TIMER_PRESCALE  (4)
#elif ( TICK_PRESCALE_VALUE == 64 )
    #define TIMER_PRESCALE  (5)
#elif ( TICK_PRESCALE_VALUE == 128 )
    #define TIMER_PRESCALE  (6)
#elif ( TICK_PRESCALE_VALUE == 256 )
    #define TIMER_PRESCALE  (7)
#else
    #error Invalid TICK_PRESCALE_VALUE specified.
#endif




TICK TickCount = 0;	// 10ms/unit


/*********************************************************************
 * Function:        void TickInit(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          Tick manager is initialized.
 *
 * Side Effects:    None
 *
 * Overview:        Initializes Timer0 as a tick counter.
 *
 * Note:            None
 ********************************************************************/
void TickInit(void)
{
    // Start the timer.
    TMR0L = TICK_COUNTER_LOW;
    TMR0H = TICK_COUNTER_HIGH;

    // 16-BIT, internal timer, PSA set to 1:256
    T0CON = 0b00000000 | TIMER_PRESCALE;


    // Start the timer.
    T0CON_TMR0ON = 1;

    INTCON_TMR0IF = 1;
    INTCON_TMR0IE = 1;

}


/*********************************************************************
 * Function:        TICK TickGet(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          Current tick value is given
 *					1 tick represents approximately 10ms
 *
 * Side Effects:    None
 *
 * Overview:        None
 *
 * Note:            None
 ********************************************************************/
TICK TickGet(void)
{
    return TickCount;
}


/*********************************************************************
 * Function:        void TickUpdate(void)
 *
 * PreCondition:    None
 *
 * Input:           None
 *
 * Output:          None
 *
 * Side Effects:    None
 *
 * Overview:        Internal Tick and Seconds count are updated.
 *
 * Note:            None
 ********************************************************************/
void TickUpdate(void)
{
    if ( INTCON_TMR0IF )
    {
        TMR0H = TICK_COUNTER_HIGH;
        TMR0L = TICK_COUNTER_LOW;

        TickCount++;

        // Remove this if not needed.
        // LATA4 ^= 1;

        INTCON_TMR0IF = 0;
    }
}









