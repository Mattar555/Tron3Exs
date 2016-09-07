/* 
 * File:   configReg.h
 * Author: mrid
 *
 * Created on 25 August 2016, 10:37 AM
 */

#ifndef CONFIGREG_H
#define	CONFIGREG_H

// Configuration Register 1H
// Oscillator switch disabled, EC oscillator.
// Use OSC = HS or OSC = HSPLL for the minimal board (10MHz/40MHz)
#pragma     config   OSCS=OFF, OSC=EC       // for PICDem2 board (4MHz external clock)

// Configuration Register 2L
// Brown-out reset disabled, Brown-out voltage 2.7V, Power-on timer enabled
#pragma     config    BOR=OFF, BORV=27, PWRT=ON

// Program Configuration Register 2H
// Watch-dog Timer disabled, Watch Dog Timer PostScaler count = 1:128
#pragma     config    WDT=OFF, WDTPS=128

// Program Configuration Register 3H
// CCP2 Mux enabled (RC1)
//#pragma     config    CCP2MUX=OFF           // CCP2 is on RB3 - alternate pin
#pragma     config    CCP2MUX=ON            // CCP2 is on RC1 - Default

// Configuration Register 4L
// Stack Overflow Reset enabled, Low Voltage Programming disabled, Debug enabled
#pragma     config    STVR=ON, LVP=OFF, DEBUG=ON

// Configuration Register 5L
// Code protection disabled
#pragma     config    CP0=OFF, CP1=OFF, CP2=OFF, CP3=OFF

// Configuration Register 5H
// Boot block and EEPROM code protection disabled
#pragma     config    CPB=OFF, CPD=OFF

// Configuration Register 6L
// PROM Write protection off
#pragma     config    WRT0=OFF, WRT1=OFF, WRT2=OFF, WRT3=OFF

// Configuration Register 6H
// Config Register, Boot block, EEPROM Write protection off
#pragma     config    WRTC=OFF, WRTB=OFF, WRTD=OFF

// Configuration Register 7L
#pragma     config    EBTR0=OFF, EBTR1=OFF, EBTR2=OFF, EBTR3=OFF

// Configuration Register 7H
// Boot block table read protection off
#pragma     config    EBTRB=OFF

#endif	/* CONFIGREG_H */

