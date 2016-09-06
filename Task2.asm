;*  Exercise 2: CCP PWM MODE
;**********************************************************
;*  Microchip Technology Incorporated
;*  5 Aug 2016
;*  Assembled with MPASM V3.30
;**********************************************************
;*  This program configures the A/D Module to convert on
;*  A/D channel 0 (the potentiometer) and controls the 
;*  Duty Cycle of a square wave as outputted via the
;*  PWM mode of the CCP module    
;**********************************************************
;*  This program was written by Marwan Attar and David     
;*  Rapisarda.
;*  Last update: 12 Aug 2016.     
;**********************************************************    
    
    list p = 18f452
    
    
    include "configReg.inc"
    include "p18f452.inc"
    
RST CODE    0x0000                  ; processor reset vector
    GOTO    Setup                   ; go to beginning of program



    CODE    0x0030    

Setup:
    MOVLW   B'01000001'             ; Place value of literal into WREG
    MOVWF   ADCON0                  ; Channel zero as output. Turn on A/D module
                                    ; Clock FOSC/8
    MOVLW   B'00001110'		    ; Place binary value of literal into WREG		    
    MOVWF   ADCON1                  ; FOSC/8. Channel zero as analog input.
                                    ; Results left justified
    MOVLW   B'11111111'             ; Place binary value of literal into WREG				    
    MOVWF   PR2                     ; The period register (of Timer2) which is
                                    ; used in the PWM output takes the value
				    ; 255. (See Notes for more detail; Page 12)
    MOVLW   B'00000100'		    ; Place binary literal value into WREG
    MOVWF   T2CON                   ; Timer 2 on. Prescale value of 1
    BCF     TRISC,1                 ; Pin 1 of port C is tied to the output of
                                    ; CCP2 in PWM mode. Refer to datasheet pg 5.
    MOVLW   B'11000111'             ; Place binary literal value into WREG.
    MOVWF   T0CON		    ; Timer0 on. Prescale value of 256. 
                                    ; Configured as 8 bit counter.
    MOVLW   B'00001100'             ; Place binary literal into WREG
    MOVWF   CCP2CON                 ; Configure CCP2 as PWM mode. We do not 
                                    ; modify the bits associated with the DC 
				    ; just yet.
Main:
    BTFSS   INTCON,TMR0IF           ; Ensures acquisition time is met
    goto    Main                    ; Repeat process until overflow occurs.
    BCF     INTCON,TMR0IF           ; Clear associated bit
    BSF     ADCON0,GO               ; Ready to initiate acquisition process.

Acquire:
    BTFSS   PIR1,ADIF               ; Wait till result obtained
    goto    Acquire                 ; Repeat process until result acquired
                                    
                                    ; Recall now the acquisiton results are 
				    ; found in ADRESH and bits 7 and 6 of ADRESL
				    ; We transfer ADRESH into CCPR2L and bits
				    ; 7 and 6 of ADRESL into bits 5 and 4 of 
				    ; CCP2CON respectively
				    

    MOVLW   B'00000000'             ; WREG = 0
    ADDWF   ADRESH,W                ; Add zero to ADRESH (value unaltered and 
                                    ; store result into WREG. Transferring 
				    ; the value of ADRESH into W. Find an 
				    ; alternative methodology for this.
    MOVWF   CCPR2L                  ; 8 bits of the 10 bits used to determine
                                    ; the DC are filled. We now deal with the
				    ; remaining 2 bits

Routine0:
    MOVLW   B'00000000'             ; WREG = 0
    CPFSEQ  ADRESL                  ; Is ADRESL = 0? (implies bits 7,6 are 0)
    goto    Routine1                ; If equal skip this step. Otherwise proceed
                                    ; to Routine1
				    ; Bits 7 and 6 of ADRESL are zero if reached
				    ; here
    BCF     CCP2CON,DC2B1           ; Clear bit 5 of CCP2CON
    BCF     CCP2CON,DC2B0           ; Clear bit 4 of CCP2CON
    goto    Main                    ; Restart process
				    
Routine1:
    MOVLW   B'01000000'             ; WREG = 64. We now verify if only bit 6 of
                                    ; ADRESL is set
    CPFSEQ  ADRESL                  ; ADRESL = 64? 
    goto    Routine2                ; If inequality proceed to Routine2. 
                                    ; If equality proceed as below
    BSF     CCP2CON,DC2B0           ; Set bit 4
    BCF     CCP2CON,DC2B1           ; Clear bit 5
    goto    Main

Routine2:
    MOVLW   B'10000000'             ; WREG = 128. See whether or not bit 7 is 
                                    ; set
    CPFSEQ  ADRESL                  ; ADRESL = 128?
    goto    Routine3                ; If inequality go to Routine3. Otherwise
                                    ; proceed as below
    BSF     CCP2CON,DC2B1           ; Set bit 5
    BCF     CCP2CON,DC2B0           ; Clear bit 4
    goto    Main                    ; Re-start process
    
				    ; If Routines 0,1 and 2 were not executed
				    ; then by construction ADRESL must be 192
				    ; Checking is thus redundant and thus is not
				    ; required
       
Routine3:
    BSF     CCP2CON,DC2B1           ; Set bit 5
    BSF     CCP2CON,DC2B0           ; Set bit 4
    goto    Main
		
    END
    
;*******************************************************************************    