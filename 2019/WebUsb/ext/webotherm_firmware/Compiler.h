/*********************************************************************
 *
 *                  Compiler specific defs.
 *
 *********************************************************************
 * FileName:        Compiler.h
 * Dependencies:    None
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
 * Nilesh Rajbharti     11/14/01 Original        (Rev 1.0)
 * Nilesh Rajbharti     2/9/02  Cleanup
 * Nilesh Rajbharti     5/22/02 Rev 2.0 (See version.log for detail)
 * Howard Schlunder		11/30/04 Added some more defines
 ********************************************************************/
#ifndef COMPILER_H
#define COMPILER_H

#if defined(HI_TECH_C)
    #if defined(_MPC_)
        #define HITECH_C18
    #else
        #error "Unknown compiler is selected."
    #endif
#else
    #if !defined(_WIN32)
        #define MCHP_C18
    #endif
#endif

#if defined(MCHP_C18) && defined(HITECH_C18)
#error "Invalid Compiler selection."
#endif

#if !defined(MCHP_C18) && !defined(HITECH_C18) && !defined(_WIN32)
#error "Compiler not supported."
#endif

#if defined(MCHP_C18)
    #include <p18cxxx.h>    // p18cxxx.h must have current processor
                            // defined.
#endif

#if defined(HITECH_C18)
    #include <pic18.h>
    #include <stdio.h>
#endif

#include <stdlib.h>

/*
 * Clock frequency value.
 * This value is used to calculate Tick Counter value
 */

//#define CLOCK_FREQ              (40000000)      // Hz
#define CLOCK_FREQ              (62500000)      // Hz

// Some PIC18s have a Compatible 10-bit A/D which is operated differently
// from other PIC18s.  Add the proper define for your PICmicro if it too has a
// Compatible A/D (doesn't have an ADCON2 register).
#if defined(__18F452) || defined(__18C452) || defined(__18F252) || defined(__18C252) || \
	defined(_18F452) || defined(_18C452) || defined(_18F252) || defined(_18C252)
#define USE_COMPATIBLE_AD
#endif


#if defined(MCHP_C18)
    #define ROM                 rom

    #define LATD0               LATDbits.LATD0
    #define LATD1				LATDbits.LATD1
    #define LATD2               LATDbits.LATD2
    #define LATD3               LATDbits.LATD3
    #define LATD4               LATDbits.LATD4
    #define LATD5				LATDbits.LATD5
    #define LATD6               LATDbits.LATD6
    #define LATD7               LATDbits.LATD7

    #define LATA2               LATAbits.LATA2
    #define LATA3               LATAbits.LATA3
    #define LATA4               LATAbits.LATA4
    #define LATA5				LATAbits.LATA5
    #define LATB3				LATBbits.LATB3
    #define LATB4				LATBbits.LATB4
    #define LATB5				LATBbits.LATB5

    #define PORTB_RB0           PORTBbits.RB0
    #define PORTB_RB5           PORTBbits.RB5

    #define PORTA_RA4           PORTAbits.RA4
    #define PORTA_RA5           PORTAbits.RA5
    #define TRISA_RA2           TRISAbits.TRISA2
    #define TRISA_RA3			TRISAbits.TRISA3
    #define TRISA_RA5           TRISAbits.TRISA5
    
    #define TRISB_RB3			TRISBbits.TRISB3
    #define TRISB_RB4           TRISBbits.TRISB4
    #define TRISB_RB5           TRISBbits.TRISB5

    #define TRISC_RC7           TRISCbits.TRISC7
    #define TRISC_RC6           TRISCbits.TRISC6
    #define TRISC_RC5           TRISCbits.TRISC5
    #define TRISC_RC4           TRISCbits.TRISC4
    #define TRISC_RC3           TRISCbits.TRISC3
    #define TRISC_RC2           TRISCbits.TRISC2
    #define TRISC_RC1           TRISCbits.TRISC1
    #define TRISC_RC0           TRISCbits.TRISC0

    #define PORTC_RC7           PORTCbits.RC7
    #define PORTC_RC6           PORTCbits.RC6
    #define PORTC_RC5           PORTCbits.RC5
    #define PORTC_RC4           PORTCbits.RC4
    #define PORTC_RC3           PORTCbits.RC3
    #define PORTC_RC2           PORTCbits.RC2
    #define PORTC_RC1           PORTCbits.RC1
    #define PORTC_RC0           PORTCbits.RC0

    #define TRISD_RD7           TRISDbits.TRISD7
    #define TRISD_RD6           TRISDbits.TRISD6
    #define TRISD_RD5           TRISDbits.TRISD5
    #define TRISD_RD4           TRISDbits.TRISD4
    #define TRISD_RD3           TRISDbits.TRISD3
    #define TRISD_RD2           TRISDbits.TRISD2
    #define TRISD_RD1           TRISDbits.TRISD1
    #define TRISD_RD0           TRISDbits.TRISD0

    #define PORTD_RD7           PORTDbits.RD7
    #define PORTD_RD6           PORTDbits.RD6
    #define PORTD_RD5           PORTDbits.RD5
    #define PORTD_RD4           PORTDbits.RD4
    #define PORTD_RD3           PORTDbits.RD3
    #define PORTD_RD2           PORTDbits.RD2
    #define PORTD_RD1           PORTDbits.RD1
    #define PORTD_RD0           PORTDbits.RD0

    #define PORTE_RE2           PORTEbits.RE2
    #define PORTE_RE1           PORTEbits.RE1
    #define PORTE_RE0           PORTEbits.RE0

    #define INTCON_TMR0IE       INTCONbits.TMR0IE
    #define INTCON_TMR0IF       INTCONbits.TMR0IF
    #define INTCON2_RBPU        INTCON2bits.RBPU

    #define T0CON_TMR0ON        T0CONbits.TMR0ON

    #define SSPCON1_WCOL        SSPCON1bits.WCOL

    #define SSPCON2_SEN         SSPCON2bits.SEN
    #define SSPCON2_ACKSTAT     SSPCON2bits.ACKSTAT
    #define SSPCON2_RSEN        SSPCON2bits.RSEN
    #define SSPCON2_RCEN        SSPCON2bits.RCEN
    #define SSPCON2_ACKEN       SSPCON2bits.ACKEN
    #define SSPCON2_PEN         SSPCON2bits.PEN
    #define SSPCON2_ACKDT       SSPCON2bits.ACKDT

    #define SSPSTAT_R_W         SSPSTATbits.R_W
    #define SSPSTAT_BF          SSPSTATbits.BF
    #define SSPSTAT_SMP			SSPSTATbits.SMP
    #define SSPSTAT_CKE			SSPSTATbits.CKE

    #define INTCON_GIEH         INTCONbits.GIEH
    #define INTCON_GIEL         INTCONbits.GIEL

    #define PIR2_BCLIF          PIR2bits.BCLIF

    #define PIE1_TXIE           PIE1bits.TXIE
    #define PIE1_RCIE           PIE1bits.RCIE

    #define PIR1_RCIF           PIR1bits.RCIF
    #define PIR1_TXIF           PIR1bits.TXIF
    #define PIR1_SSPIF			PIR1bits.SSPIF

    #define TXSTA_TRMT          TXSTAbits.TRMT
    #define TXSTA_BRGH          TXSTAbits.BRGH

    #define RCSTA_CREN          RCSTAbits.CREN

    #define ADCON0_GO           ADCON0bits.GO
    #define ADCON0_ADON         ADCON0bits.ADON

    #define RCON_POR            RCONbits.POR


#if defined(__18F8720)
    #define TXSTAbits       TXSTA1bits
    #define TXREG           TXREG1
    #define TXSTA           TXSTA1
    #define RCSTA           RCSTA1
    #define SPBRG           SPBRG1
    #define RCREG           RCREG1
#endif


#endif

#if defined(HITECH_C18)
    #define ROM                 const

    #define memcmppgm2ram(a, b, c)      memcmp(a, b, c)
    #define memcpypgm2ram(a, b, c)      mymemcpy(a, b, c)
    #define itoa(val, string)           sprintf(string, "%u", val)
    #define ultoa(val, string)			sprintf(string, "%lu", val)

    extern void *mymemcpy(void * d1, const void * s1, unsigned char n);
    extern char *strupr(char*);

    /* Fix for HITECH C */
    #define TXREG       _TXREG
    static volatile near unsigned char       _TXREG       @ 0xFAD;


//    #define LATA2             LA2
//    #define LATA3             LA3
//    #define LATA4             LA4
//    #define LATA5				LA5
	#define PORTB_RB0			RB0
    #define PORTB_RB5           RB5

    #define PORTA_RA4           RA4
    #define PORTA_RA5           RA5
    #define TRISA_RA2           TRISA2
    #define TRISA_RA3			TRISA3
    #define TRISA_RA5           TRISA5
    
	#define TRISB_RB5			TRISB5
    #define TRISB_RB4			TRISB4
    #define TRISB_RB3			TRISB3

    #define TRISC_RC7           TRISC7
    #define TRISC_RC6           TRISC6
    #define TRISC_RC5           TRISC5
    #define TRISC_RC4           TRISC4
    #define TRISC_RC3           TRISC3
    #define TRISC_RC2           TRISC2
    #define TRISC_RC1           TRISC1
    #define TRISC_RC0           TRISC0

    #define PORTC_RC7           RC7
    #define PORTC_RC6           RC6
    #define PORTC_RC5           RC5
    #define PORTC_RC4           RC4
    #define PORTC_RC3           RC3
    #define PORTC_RC2           RC2
    #define PORTC_RC1           RC1
    #define PORTC_RC0           RC0

    #define TRISD_RD7           TRISD7
    #define TRISD_RD6           TRISD6
    #define TRISD_RD5           TRISD5
    #define TRISD_RD4           TRISD4
    #define TRISD_RD3           TRISD3
    #define TRISD_RD2           TRISD2
    #define TRISD_RD1           TRISD1
    #define TRISD_RD0           TRISD0

    #define PORTD_RD7           RD7
    #define PORTD_RD6           RD6
    #define PORTD_RD5           RD5
    #define PORTD_RD4           RD4
    #define PORTD_RD3           RD3
    #define PORTD_RD2           RD2
    #define PORTD_RD1           RD1
    #define PORTD_RD0           RD0


    #define PORTE_RE2           RE2
    #define PORTE_RE1           RE1
    #define PORTE_RE0           RE0

    #define INTCON_TMR0IE       TMR0IE
    #define INTCON_TMR0IF       TMR0IF
    #define INTCON2_RBPU        RBPU

    #define T0CON_TMR0ON        TMR0ON

    #define SSPCON1_WCOL        WCOL

    #define SSPCON2_SEN         SEN
    #define SSPCON2_ACKSTAT     ACKSTAT
    #define SSPCON2_RSEN        RSEN
    #define SSPCON2_RCEN        RCEN
    #define SSPCON2_ACKEN       ACKEN
    #define SSPCON2_PEN         PEN
    #define SSPCON2_ACKDT       ACKDT

    #define SSPSTAT_R_W         RW
    #define SSPSTAT_BF          BF
    #define SSPSTAT_SMP			SMP
    #define SSPSTAT_CKE			CKE

    #define INTCON_GIEH         GIEH
    #define INTCON_GIEL         GIEL

    #define PIR2_BCLIF          BCLIF

    #define PIE1_TXIE           TXIE
    #define PIE1_RCIE           RCIE

    #define PIR1_TXIF           TXIF
    #define PIR1_RCIF           RCIF
    #define PIR1_SSPIF			SSPIF


    #define TXSTA_TRMT          TRMT
    #define TXSTA_BRGH          BRGH

    #define RCSTA_CREN          CREN

    #define ADCON0_GO           GODONE
    #define ADCON0_ADON         ADON


    #define Nop()               asm("NOP");
    #define Reset()				asm("RESET");

    #define RCON_POR            POR

	#if defined(_18F8722)
		#define SSPCON1				SSP1CON1
		#define SSPIF				SSP1IF
		#define SSPBUF				SSP1BUF
		#define TXSTA				TXSTA1
		#define RCSTA				RCSTA1
		#define SPBRG				SPBRG1
		#define RCIF				RC1IF
		#define RCREG				RCREG1
	#endif

#endif


#endif
