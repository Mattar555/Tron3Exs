;*  Exercise 1: Potentiometers and LEDS
;**********************************************************
;*  Microchip Technology Incorporated
;*  1 Aug 2016
;*  Assembled with MPASM V3.30
;**********************************************************
;*  This program configures the A/D Module to convert on
;*  A/D channel 0 (the potentiometer) and display the
;*  results on the LEDS on PORTB in a "light bar" pattern
;**********************************************************
;*  This program was written by Marwan Attar and David     
;*  Rapisarda.
;*  Last update: 10 Aug 2016. Line 42    
;**********************************************************    

    list p=18f452

    
    include "p18f452.inc"
    include "configReg.inc"


    ; Start at the reset address. There *must* be code at address 
    ; 0x000 since the PC is loaded with address 0 when the processor 
    ; comes out of reset. This declares a code section named 'RST'.
RST	code 0x0000 
        goto Setup


    
	code    0x0030
	
; The Following subroutine configures the A/D Module and PORTB as output	
	
Setup:
   CLRF     PORTB           ; If LED's on turn them off
   CLRF     TRISB           ; Configure Port B as output
   MOVLW    B'01000001'     ; Move the value enclosed in the string into WREG
   MOVWF    ADCON0          ; Turn on A2D. FOSC/8
   MOVLW    B'00001110'     ;  
   MOVWF    ADCON1          ; Configure channel zero as analogue. Data left 
                            ; justified. Will appear in the ADRESH
   MOVLW    B'11000111'    
   MOVWF    T0CON           ; Prescale value of 256
   CLRF     TMR0            ; Ensure Acquisition time is met
   
   
Main:
   ;CLRF     TMR0            ; NEW. Ensures acquisition time is met by waiting
                            ; for TMR0 to overflow.
   BTFSS    INTCON,TMR0IF   ; If bit TMROIF of INTCON is set skip the following
                            ; instruction. Otherwise goto Main and repeat this
			    ; particular instruction. We wait conversion time
			    ; amount prior to setting the go bit of ADCON0 to 
			    ; initiate another conversion
   goto     Main
   BCF      INTCON,TMR0IF   ; Clear the bit. Must be cleared by software.
   BSF      ADCON0,GO       ; Ready to start the A/D Conversion
   

WaitForAdConversion:
   BTFSS    PIR1,ADIF             ; Skip the next step if A2D Conversion is done
   goto     WaitForAdConversion   ; Otherwise repeat the above step
   
Routine0:                         ; NEW
    movlw   B'00000000'           ; Write zero to WREG
    CPFSEQ  ADRESH                ; Is ADRESH = 0?
    goto    Routine1              ; If not equal perform this step. If equal 
                                  ; skip this step
    CLRF    PORTB                 ; Extinguish all LED
    goto    WaitForSwitchRelease  ; go to the specified routine
   
Routine1:
    movlw   B'01000000'           ; WREG has the value of 64
    CPFSLT  ADRESH                ; Compare the value of ADRESH with 64. If less
                                  ; than 64 skip the step below
    goto    Routine2              ; If greater than or equal to 64 then go to 
                                  ; Routine 2
    movlw   B'00000001'           ; The number lies between 0 and 63. 
    MOVWF   PORTB                 ; Turn on the first LED
    CLRF    PORTB
    goto    WaitForSwitchRelease
    
Routine2: 
    movlw   B'10000000'           ; Write 128 to WREG
    CPFSLT  ADRESH                ; Compare conversion result with 128
    goto    Routine3              ; If less than 128 skip this step. Otherwise
                                  ; proceed to routine 3
    movlw   B'00000011'           ; Write 3 to WREG
    MOVWF   PORTB                 ; Turn on the first and second LED only
    CLRF    PORTB                  
    goto    WaitForSwitchRelease
    
Routine3:
    movlw   B'11000000'            ; Write 192 to WREG
    CPFSLT  ADRESH                 ; If ADRESH < 192 skip the next step
    goto    Routine4               ; If >= 192 go to Routine 4
    movlw   B'00000111'            ; Write 7 to WREG
    MOVWF   PORTB                  ; Turn on first,second and third LEDs
    CLRF    PORTB                  
    goto    WaitForSwitchRelease
    
Routine4:
    MOVLW  B'00001111'              ; The number must lie between 192 and 255
    MOVWF  PORTB                    ; Write 15 to WREG and turn on all LEDs
    CLRF   PORTB
    goto   WaitForSwitchRelease
    

WaitForSwitchRelease:		
    btfss   PORTA, 4                 ; Pause while the switch is pressed
    goto    WaitForSwitchRelease

    movwf   PORTB
    goto    Main                     ; Restart procedure

    end

;*******************************************************************************    