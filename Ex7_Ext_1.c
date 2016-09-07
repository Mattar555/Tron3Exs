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
 

 

// Global variables to be used in the interrupts hence the need for volatile //

volatile int writeString;
 
 volatile int wrtCnt;
 
 volatile int rdCnt;
 
 volatile int txFin;
 
 volatile char tmp;
 
 // Global variable to be used in the transmission routine //
 
# pragma idata string
 char message[] = "You wrote: ";
 char*pMess = message;
 int length;
 int temlen;




void write(void);
void pgm2ram(static char* dest,static rom char* src);
void trCon(void);
void intCon(void);
void hpISR(void);
void initVar(void);

// We define the interrupts here //

#pragma code highVec = 0x08
void interrupt_at_highVec(void)
{
    _asm GOTO hpISR _endasm
}
   
#pragma code

/* We have multiple interrupt sources. We have to check which one is the one */
/* thats triggered */

#pragma interrupt hpISR
void hpISR(void)
{   
     _asm NOP _endasm
     /* If user wrote something */         
    if (PIR1 & RC_BM)
    {
        /* Put the byte into tmp */
        tmp = RCREG;
        /* Put the character into the buffer */
        *ptWrt++ = tmp;
        /* Increment the number of insertion procedures */
        wrtCnt++;
        /* If we exceeded the allocated bytes to the buffer */
        if (wrtCnt >= BUFFSIZE)
        {
            /* Repoint to the beginning of the buffer which implies */
            /* overwriting data */
            ptWrt = buffer;
            /* Reset the number of writing procedures */
            wrtCnt = 0;
        }
        /* Keep receiving and writing to the buffer until the enter button is */
        /* depressed */
        if (tmp == CR)
        {
            /* Disable receive interrupt and disable transmit interrupt */
            /* We disable transmit interrupt also because we use polling */
            /* routine to transmit you wrote: */
            /* This is indicated by the writeString flag going to 1 */
            PIE1 = 0x00;
            writeString++;
        }
    }
    else if (PIR1 & TX_BM)
    {
        /* txFin goes to one once the carriage return has been written */
        /* to TXREG. This occurs when wrtCnt = RdCnt */
        if (txFin)
        {
            txFin--;
            /* The newline goes after the cr */
            TXREG = NL;
            /* Now we re-enable receive interrupts */
            PIE1 = 0x20;
            return;
        }
        /* If we have not reached the cr character then keep writing to TXREG */
       TXREG = *ptRd++;
       /* Increment the number of reading procedures with each read */
       rdCnt++;
       /* Same as wrtCnt */
       if (rdCnt >= BUFFSIZE)
       {
           rdCnt = 0;
           ptRd = buffer;
       }
       /* This indicates now we wrote CR to the buffer */
       if (rdCnt == wrtCnt)
       { 
           /* So we trigger this so as to write newline next */
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
    
    
    initVar();
    
    length = strlen(message);
    
  
    
    /* Configure Interrupts */
    
    intCon();
    
    /* Configure USART module */
    
    trCon();
   
    /* Wait for interrupts */
    while(1)
    {
        if (writeString)
        {
         /* Recall WriteString = 1 once we received the message */
         /* We write You wrote: */
         /* prior to writing the actual message */   
         write();   
        }
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

void write(void)
{
    /* Enter here if we received the message*/
    /* Restore temlen*/ 
    /* Also the pointer points to the beginning of the You wrote string */
    temlen = length;
    pMess = message;
    /* While we have not exhausted the characters of the string You wrote */
    while(temlen)
    {
        /* Wait till TXEG is empty */
        while (!(PIR1 & TX_BM));
        /* Put the next character */
         TXREG = *pMess++;
         _asm NOP _endasm
         /* Once temlen = 0 we effectively reached the end of the string */        
         temlen--;        
    }
    /*So we dont enter this we dont have to*/
    writeString--;
    /* Enable transmit interrupt to transmit the actual message */
    PIE1 = 0x10;
}

void initVar(void)
{
    writeString = 0;
    txFin = 0;
    wrtCnt = 0;
    rdCnt = 0;  
    tmp = 0;
}