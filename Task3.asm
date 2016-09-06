

    list p = 18f452
    include "configReg.inc"
    include "p18f452.inc"
    
RST   CODE    0x0000            ; processor reset vector
      GOTO    Setup             ; go to beginning of program
      
HISR: CODE    0x0008            ; Vector address for HP ISR
      goto    HP_ISR
      
LISR: CODE    0x0018            ; Vector address for LP ISR
      goto    LP_ISR
      
     

      UDATA_ACS                 ; Declare uninitialized data

HLVH  RES     1                 ; Reserve one byte for HLV: High_Low_Variable 
                                ; to be used in the HP ISR
HLVL  RES     1                 ; Reserve one byte for HLVL to be used in the 
                                ; LP ISR
HFHB  RES     1                 ; The higher freqeuncy higher byte
HFLB  RES     1                 ; The higher frequency lower byte
LFHB  RES     1                 ; The lower freqeuncy higher byte
LFLB  RES     1                 ; The lower frequency lower byte
STAT  RES     1                 ; Temporary value for STATUS register in ISR
TBSR  RES     1                 ; Temporary value for BSR register in ISR
TWRG  RES     1                 ; Temporary value for WREG in ISR
COUNT RES     1                 ; Counter variable decrements from 3 to 0
 

  
  
      CODE    0x0030            

Setup:
    goto    Config_TC           ; Sub Routine to configure Timer and CCP modules
  
Resume:
    goto    Config_Interrupt    ; Sub Routine to configure Interrupt module
    
Main:
    BRA     $                   ; Wait till interruption
    
    
Config_TC:
    MOVLW    B'10110101'         
    MOVWF    T1CON               ; Prescaler of 8. Use given internal clock.
                                 ; Timer1 on
    MOVLW    B'00001000'
    MOVWF    CCP1CON             ; Toggle output on interrupt on CCP1 Pin
    MOVWF    CCP2CON             ; Toggle output upon interrupt on CCP2 Pin
                                 ; CHANGE THESE LATER to just generate a 
				 ; software interrupt
    CLRF     TRISC               ; Configure Port C as output
    CLRF     TRISB               ; Configure Port B as output
    goto     Resume
    

    
Config_Interrupt:                ; See Page 28 Lab Book for more details
    BCF     INTCON,GIEH          ; Disable temporarily high priority interrupts
    BCF     INTCON,GIEL          ; Disable tempoaririly low priority interrupts
    BSF     RCON,IPEN            ; Enable priorities
    BSF     IPR1,CCP1IP          ; CCP1 has a higher priority interrupt
    BCF     IPR2,CCP2IP          ; CCP2 has a lower priority interrupt
    MOVLW   B'00000100'
    MOVWF   PIE1                 ; Enable interrupts for CCP1
    MOVLW   B'00000001'
    MOVWF   PIE2                 ; Enable interrupts for CCP2
    CLRF    PIR1                 ; To enable subsequent access into ISR 
    CLRF    PIR2                 ; To enable subsequent access into ISR
    BSF     INTCON,GIEH          ; Re-enable HP interrupts
    BSF     INTCON,GIEL          ; Re-enable LP interrupts
    goto    Variables
    
Variables:
    MOVLW   B'00000100'         ; Higher byte of 2500 (1250)
    MOVWF   HFHB                
    MOVLW   B'11100010'         ; Lower byte of 2500
    MOVWF   HFLB
    MOVLW   B'11110100'         ; Higher byte of 62500
    MOVWF   LFHB
    MOVLW   B'00100100'         ; Lower byte of 62500
    MOVWF   LFLB
    MOVLW   B'00000000'         ; Initilize the High_Low_Variable to 0 initially
    MOVWF   HLVH                
    MOVWF   HLVL
    MOVLW   B'00000010'         ; Value of 4
    MOVWF   COUNT               ; The variable COUNT is initilized to 3
    goto    Main                ; Go to Main and do nothing till interrupted
    
    
LP_ISR:
    MOVFF   STATUS,STAT         ; Save value of STATUS register 
    MOVFF   BSR,TBSR            ; Save value of BSR register
    MOVWF   TWRG                ; Save value of WREG register
    BTFSS   PIR2,CCP2IF         ; Has the CCP2 flag been set? Double check
    RETFIE                      ; If not set leave ISR. Otherwise proceed below
    MOVLW   B'00000000'        
    ADDWF   LFLB,0              ; WREG = LFLB
    ADDWF   CCPR2L              ; Add LFLB to CCPR2L
    BC      Carry_LP_ISR        ; If carry bit present go to Carry Sub Routine
Continue:
    MOVLW   B'00000000'         
    ADDWF   LFHB,0              ; WREG = LFHB
    ADDWF   CCPR2H              ; Add LFHB to CCPR2H
    DCFSNZ  COUNT               ; Only write to PORTB after four entries of the
                                ; ISR. (Refer to Page 38 LogBook)
    goto    WPORTB              ; If the ISR is entered a multiple of four times
                                ; goto WPORTB SR. Otherwise proceed below
Restore:    
    MOVFF   STAT,STATUS         ; Restore STATUS
    MOVFF   BSR,TBSR            ; Restore BSR
    MOVLW   B'00000000'          
    ADDWF   TWRG,0              ; Restore WREG
    BCF     PIR2,CCP2IF         ; Clear the bit to allow subsequent access
    RETFIE                      ; Return from interrupt
Carry_LP_ISR:
    INCF    CCPR2H              ; If carry bit present increment CCPR2H by one
    goto    Continue            ; Resume the addition process
WPORTB:
    MOVLW   B'00000010'         ; Restore the COUNT variable back to four
    MOVWF   COUNT          
    TSTFSZ  HLVL                ; See whether we are in the low or high portion
    goto    WriteHigh           ; Skip this step if we are in the low portion
WriteLow:                       ; This means HLVL = 0
    BCF     PORTB,INT2          ; Write zero to the relevant pin of PORTB
    INCF    HLVL                ; So that next time we enter WriteHigh SR
    goto    Restore             ; goto Restore
WriteHigh:                      ; This means HLVL = 1
    BSF     PORTB,INT2          ; Write one to the relevant pin of PORTB
    CLRF    HLVL                ; So that next time we enter WriteLow SR
    goto    Restore             ; goto Restore
    

HP_ISR:
    MOVFF   STATUS,STAT          ; Save value of STATUS register
    MOVFF   BSR,TBSR             ; Save value of BSR register
    MOVWF   TWRG                 ; Save value of the working register WREG
    BTFSS   PIR1,CCP1IF          ; Has CCP1F been triggered?
    RETFIE                       ; If not escape now. Otherwise skip this step
    MOVLW   B'00000000' 
    ADDWF   HFLB,0               ; WREG = HFLB
    ADDWF   CCPR1L               ; Add HFLB to CCPR1L
    BC      Carry_HP_ISR         ; If carry bit present proceed to Carry SR
Continue1:
    MOVLW   B'00000000'          ; 
    ADDWF   HFHB,0               ; WREG = HFHB
    ADDWF   CCPR1H               ; Add HFHB to CCPR1H
    TSTFSZ  HLVH                 ; See Whether HLVH is zero or one. 
    goto    WriteHigh1           ; Skip this step if zero. If one go to the SR
WriteLow1:                       ; This means HLVH = 0
    BCF     PORTB,CCP2_PORTB     ; Clear Pin3 of PORTB
    INCF    HLVH                 ; So that next time we enter WriteHigh1
Restore1:    
    MOVFF   STAT,STATUS          ; Restore STATUS
    MOVFF   TBSR,BSR             ; Restore BSR
    MOVLW   B'00000000'          
    ADDWF   TWRG,0               ; Restore WREG
    BCF     PIR1,CCP1IF          ; Clear bit to allow subsequent access
    RETFIE                       ; Return to Main
Carry_HP_ISR:
    INCF    CCPR1H               ; If carry bit increment the higher byte by one
    goto    Continue1            ; Resume addition
    
WriteHigh1:                      ; This means HLVH = 1
    BSF    PORTB,CCP2_PORTB      ; Set the relevant pin of PORTB
    CLRF   HLVH                  ; Enter the WriteLow Routine next time
    goto   Restore1
    
    END