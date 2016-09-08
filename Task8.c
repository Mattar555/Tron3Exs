/* 
 * File:   Task8.c
 * Author: Marwan
 *
 * Created on September 1, 2016, 2:24 PM
 */

#include <stdio.h>
#include <stdlib.h>
#include <spi.h>
#include <p18f452.h>
#include "configReg.h"

#define ADDER   33333

void spiCon(void);
void intCon(void);
void ccpCon(void);
void timCon(void);
void ptcCon(void);
void hpISR(void);

#pragma code highVec = 0x08
void interrupt_at_highVec(void)
{
    _asm GOTO hpISR _endasm
}

#pragma code

#pragma interrupt hpISR
void hpISR(void)
{
    char x = 0;
    if (PIR2bits.CCP2IF)
    {
        CCPR2 += ADDER;
        PIR2bits.CCP2IF = 0;
        /* Read the incoming data */
        PORTCbits.RC2 = 0;
        /* Delay to ensure data is loaded */
        delay3CC();
        /* Write the data to PORTC(4) */
        PORTCbits.RC2 = 1; 
        /* Delay to shift all 8 bits */
        delay10CC(); 
        /* Put the data on PORTC(4) in x */
        x = getcSPI();
        /* The data is now located in PORTC(5). Output that to the serial in */
        /* Parallel out register */
        putcSPI(x);
    }
   
}

/*
 * 
 */
void main(void) {

    
    spiCon();
    ccpCon();
    timCon();
    ptcCon();
    intCon();
    
    while(1)
    {
        ;
    }
}

void spiCon(void)
{
    OpenSPI(SPI_FOSC_4, MODE_00, SMPMID);
}

void intCon(void)
{
    /* Disable Interrupts temporarily */
    INTCON &= 0x3F;
    
    /* Enable Priorities */
    RCON |= 0x80;
    
    PIE2 = 0x01;
    IPR2 = 0x01;
    
     /* Re - enable interrupts */
    INTCON |= 0xC0;
}

void  ccpCon(void)
{
    CCP2CONbits.CCP2M3 = 1;
    CCP2CONbits.CCP2M2 = 0;
    CCP2CONbits.CCP2M1 = 1;
    CCP2CONbits.CCP2M0 = 0;
}

void timCon(void)
{
    T3CONbits.T3CKPS1 = 0;
    T3CONbits.T3CKPS0 = 0;
    T3CONbits.T3CCP2 = 1;
    T3CONbits.T3CCP1 = 0;
    T3CONbits.T3SYNC = 0;
    T3CONbits.TMR3CS = 0;
    T3CONbits.TMR3ON = 1;
    
}

void ptcCon(void)
{
    // Pin 4 of PORTC is the output (input from the parallel in serial out reg)
    
    TRISC = 0xEF;
    
    /* This is connected to PL bit and we initally set it low to read data */
    /* Recall when PL is high we are outputting the read data based on the */
    /* clock frequency chosen */
    PORTCbits.RC2 = 0;
}