/* 
 * File:   main.c
 * Author: Marwan
 *
 * Created on August 28, 2016, 10:34 AM
 */

#include <stdio.h>
#include <stdlib.h>
#include<p18f452.h>            /* Required */
#include<adc.h>                /* ADC functions defined here */
#include<delays.h>             /* Delay functions here */



int ledON(int x);


void main (void)
{
    
    char bitMask = 0xF0;
    
    int result;               /* Store result here */
                              /* Integers are 16 bits and the result is 10 */
                              /* We cannot use chars as they are not big */
 
    
    OpenADC(ADC_FOSC_4 & ADC_LEFT_JUST & ADC_1ANA_0REF, ADC_CH0 & ADC_INT_OFF);
    
    TRISB &= bitMask;        /* Configure bits 0:3 of PORTB as output   */        
    
    while(1)
    {
        
      Delay10TCYx(2);         /* Wait 20 instruction cycles */
                              /* To factor into account the acquisition time */
      ConvertADC();           /* Initiate Conversion process */
      while (BusyADC());
      result = ReadADC();     /* Put 10 bit result in result */
      result >>= 8;           /* Right shift 8 times to place high byte in low
                                 byte */
      ledON(result);
    }

    
}
    
    
   


int ledON(int x) 
{
   if (x == 0)
   {
       PORTB = 0x00;
       return 0;
   }
   else if (x < 64)
   {
       PORTB = 0x01;
       return 0;
   }
   else if (x < 128)
   {
       PORTB = 0x03;
       return 0;
   }
   else if (x < 192)
   {
       PORTB = 0x07;
       return 0;
   }
   else
   {
       PORTB = 0x0F;
       return 0;
   }
}
