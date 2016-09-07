/* 
 * File:   Ex7_Ext.c
 * Author: Marwan
 *
 * Created on August 31, 2016, 12:55 PM
 */

#include <stdio.h>
#include <stdlib.h>
#include <p18f452.h>
#include <usart.h>           /* USART functions defined here */
#include<string.h>
#include"configReg.h"
#define BUFFSIZE 100
#define CR       13
#define NL       10
#define RC_BM    0x20
#define TX_BM    0x10

// Store the received character here //

volatile char buffer[BUFFSIZE];

// Defining the insertion pointers //

volatile char *ptWrt = buffer;
volatile char *ptRd = buffer;
 

 

// Global variables to be used in the interrupts hence the need for volatile

 
 
 volatile int wrtCnt;
 
 volatile int rdCnt;
 
 volatile int txFin;
 
 volatile char tmp;
 



// Defining the functions to be used in this task //

void pgm2ram(static char* dest,static rom char* src);
void trCon(void);
void intCon(void);
void hpISR(void);
void intVar(void);

// We define the interrupts here //

#pragma code highVec = 0x08
void interrupt_at_highVec(void)
{
    _asm GOTO hpISR _endasm
}
   
#pragma code

// Recall there are two potential sources of interrupt. Since we have only
// one address it is up to the user to manually check which one is the one that
// is triggered (If statements with PIR1) and act accordingly. 

// Note however by construction only one/none is on at any given time //
// So if RCV is on then TX is off and vice versa

#pragma interrupt hpISR
void hpISR(void)
{   
    /* Debugging purposes */
     _asm NOP _endasm
             
    /* If the RCREG buffer is full */         
    if (PIR1 & RC_BM)
    {
        /* Store the received char in tmp */
        tmp = RCREG;
        /* Put that received char into the buff via the insertion pointer */
        *ptWrt++ = tmp;
        /* Increment the number of insertion procedures */
        wrtCnt++;
        /* If the number if insertion procedures exceeds the length of the */
        /* buffer then reset to zero and repoint to the beginning. This means */
        /* The data written at the beginning will be overwritten */
        if (wrtCnt >= BUFFSIZE)
        {
            ptWrt = buffer;
            wrtCnt = 0;
        }
        /* If user hit enter signifying hes done */
        if (tmp == CR)
        {
            /* Disable receive interrupt and enable transmit interrupt */
            PIE1 = 0x10;
        }
    }
     /* Is the TXREG buffer empty? */
    else if (PIR1 & TX_BM)
    {
        /* Have we reached the end of the string yet? */
        if (txFin)
        {
            txFin--;
            /* Recall at this stage we outputted the CR so now we have to go */
            /* to a new line */
            TXREG = NL;
            /* Re enable RCV and disable TX */
            PIE1 = 0x20;
            return;
        }
        /* Otherwise keep outputting through the reading pointer */
       TXREG = *ptRd++;
       rdCnt++;
       /* If we exceeded the length of allocated bytes to the buffer */
       if (rdCnt >= BUFFSIZE)
       {
           rdCnt = 0;
           ptRd = buffer;
       }
       /* Stop when the number of writing and reading procedures coincide */
       if (rdCnt == wrtCnt)
       {
           txFin++;
       }
    }
}

/*
 * 
 */
void main(void)
{
    /* Small memory model. Define all local variables first and foremost */
    
  
    
    txFin = 0;
    wrtCnt = 0;
    rdCnt = 0;  
    tmp = 0;
    
    intVar();
    
  
    
    /* Configure Interrupts */
    
    intCon();
    
    /* Configure USART module */
    
    trCon();
   
    /* Wait for interrupts */
    while(1)
    {
        ;
    }
   
    
   
}

void pgm2ram(static char *dest,static rom char* src)
{
    /* Copy until the end */
    
    while ((*dest++ = *src++) != '\0');
    
}

void trCon(void)
{
    /* Transmit Interrupt, Asynchronous mode, eight bit transmission, High BR*/
    TXSTA = 0x64;
    /* Enable 8 bit reception */
    RCSTA = 0x90;
    /* 9600 Baud Rate */
    SPBRG = 25;
    /* Enable Serial Ports for transmission and reception */
    /* Set bit 7 and clear the remaining bits */
    TRISC = 0x80;
}


void intCon(void)
{
    /* Disable Interrupts temporarily */
    INTCON &= 0x3F;
    
    /* Enable Priorities */
    RCON |= 0x80;
    
    /* Transmission and Reception high priority */
    IPR1 = 0x30;
    
    /* Transmission interrupts disabled temporarily because we receive prior */
    /* to transmission */
    /* We re-enable transmit interrupts and disable receive interrupts later */
    PIE1 = 0x20; 
    
    /* Re - enable interrupts */
    INTCON |= 0xC0;
    
    
}


void intVar(void)
{
    txFin = 0;
    wrtCnt = 0;
    rdCnt = 0;  
    tmp = 0;
    
}
