    list p = 18f452
    include "configReg.inc"
    include "p18f452.inc"

RES_VECT    CODE    0x0000            ; Processor reset vector
    GOTO    SETUP                     ; Go to beginning of program
    
    
RCVISR:     CODE    0x0008            ; Configure HP ISR for the USART reciever
            goto    RCVISR

    UDATA_ACS
temlen  res  1                        ; The length of the string is stored here   
length  res  1                        ; Also here
toggle  res  1                        ; Toggle between two possible sub routines
                                      ; to be executed during program 
				      ; implementation
recieve res  1                        ; Flag to see whether recieve message or
                                      ; not
wTemp   res  1                        ; Temporary variables for the ISR to store
stat    res  1                        ; WREG,STATUS and BSR respectively
tBSR    res  1  
WrtCnt  res  1                        ; Number of times a write/read has been 
RdCnt   res  1                        ; executed with respect to the ring buffer
temp    res  1   
  
      CODE
     
buffer  RES  100                      ; Reserve 10 bytes for the message
string  DB  "test",0x0d,0x0a,0        ; Append the carriage return and new line
                                      ; character in addition to the terminating
				      ; character in the end (respectively)

MAIN_PROG CODE                        ; Let linker place main program 
 
             

SETUP:
    
   RCALL    InterSet                ; Go to the InterSet SubRoutine where the
                                    ; the serial interrupts will be enabled
   RCALL    SerialSet               ; Configure the SCI Module				    
   LFSR     FSR0,buffer             ; Let the FSR0 point to the buffer which is
                                    ; located in data memory
   LFSR     FSR1,buffer		    ; Same for FSR1 (File Select Register 1)		    
   CLRF     length                  ; Length of the string is initially zero
   CLRF     recieve                 ; Recieve flag initially zero
   CLRF     temlen       
   MOVLW     D'100'                 ; Set WREG to equal to the number of bytes
                                    ; allocated to the buffer. In other words
				    ; set WREG to the length of the buffer                 
    
Main:
    TSTFSZ   recieve                ; See whether or not we recieved the entire
                                    ; message. This is signified as the recieve
				    ; flag is set
    goto     TX232                  ; go to the routine which will transmit the
                                    ; required message once the recieve flag is
				    ; set
    BRA      Main                   ; Otherwise branch back to the top and wait
                                    ; for the entirety of the message 
    
    
TX232:                              ; NOW even if overflow occured in the sense
                                    ; WrtCnt overflowed and went back to the
				    ; beginning. Nevertheless, we do the same 
				    ; for RdCnt. If exceeded the length reset to
				    ; zero. And stop transmission as soon as 
				    ; RdCnt coinced with WrtCnt. In such case 
				    ; disable the recieve flag and re-eneble 
				    ; interrupts. And proceed back to the main
				    ; routine. Now Recall FSR1 is the pointer
				    ; associated with reading operations.
Write:   
    MOVFF    POSTINC1,TXREG         ; Put the character pointed to at by the 
                                    ; pointer to TXREG and increment the pointer
				    ; for the subsequent character
Wait:    
    BTFSS    PIR1,TXIF              ; Wait for the interrupt flag to be set. 
                                    ; This occurs whenever TXREG is empty. NOTE
				    ; the interrupt enable bit does not need to
				    ; be set. Only enable the interrupt from PIE
				    ; if interrupt service routines will be used
    BRA      Wait                   ; Skip this line if TXIF bit is set
    INCF     RdCnt                  ; A read operation has been performed
    MOVF     temp,0
    CPFSLT   RdCnt                  ; Compare RdCnt with WREG (100) to see if
                                    ; a possible reset is required
    goto     ResRd                  ; If greater than or equal to 100 go to SR
    
RCheck:
    MOVF     WrtCnt,0               ; WREG = WrtCnt
    CPFSEQ   RdCnt                  ; Compare RdCnt with WrtCnt
    BRA      Write                  ; If not yet equal (RdCnt lags WrtCnt) 
                                    ; repeat the transmission procedure for the 
				    ; subsequent character
    BRA      WStop				    
    
    
 
ResRd:
    LFSR     FSR1,buffer            ; If overflow repoint to the beginning of
                                    ; the buffer
    CLRF     RdCnt                  ; Reset the read counter variable
    goto     RCheck                 ; Proceed to this SR
    
WStop: 
    MOVLW    D'100'                 ; WREG = length of buffer. We will need this
                                    ; WREG restored value in the Recieve 
				    ; Interrupt when we compare W
    CLRF     recieve                ; Toggle recieve back to zero
    BSF      INTCON,GIEH            ; Re-enable high priority interrupts
    BSF      INTCON,GIEL            ; Re-enable low priority interrupts
    BRA      Main
InterSet:

    BCF      INTCON,GIEH            ; Disable high priority interrupts
    BCF      INTCON,GIEL            ; Disable low priority interrupts
    BSF      RCON,IPEN              ; Enable priorities
    MOVLW    B'00100000'            
    MOVWF    IPR1                   ; High priority for the reciever interrupt  				    
    BSF      PIE1,RCIE              ; Enable interrupts for the USART reciever 
                                    ; mode
    CLRF     PIR1                   ; Enable subseqeuent access into the ISR
    BSF      INTCON,GIEH            ; Re-enable high priority interrupts
    BSF      INTCON,GIEL
    RETURN                          ; Interrupts enabled for Part 2
    
    
SerialSet:
    BCF      TRISC,RC6              ; Configure Pin RC6
    BSF      TRISC,RC7              ; Configure Pin RC7
    BCF      TXSTA,TX9              ; Enable 8 bit transmission
    BSF      TXSTA,TXEN             ; Enable transmission
    BCF      TXSTA,SYNC             ; Ansynchronous mode
    BSF      TXSTA,BRGH             ; High Baud Rate Enabled (see Notes why this
                                    ; is preferred to Low Baud Rate)
    BSF      RCSTA,SPEN	            ; Serial port enabled
    MOVLW    D'25'                  ; WREG = 25
    MOVWF    SPBRG                  ; Generate the required Baud Rate of 9600
                                    ; TO DO: Configure reciever bits for Part B
    BCF      RCSTA,RX9              ; Select 8 bit reception
    BSF      RCSTA,CREN             ; Enables reciever 
    
    RETURN			
  
RCVISR:
    BTFSS    PIR1,RCIF
    RETFIE
    MOVFF    STATUS,stat            ; Store STATUS,BSR and WREG into stat,tBSR
    MOVFF    BSR,tBSR               ; and wTemp respectively
    MOVWF    wTemp
    MOVFF    RCREG,temp
   ; BTFSS    PIR1,RCIF              ; Doubler checking whether or not the RCIF
                                    ; flag has been set or not
    ;RETFIE                          ; If the RCIF flag has been set then skip
                                    ; this step. 
    			    
    ;MOVFF    RCREG,POSTINC0         ; Put the recieved character in the buffer
                                    ; and increment the pointer to the next
				    ; position	
    MOVFF    temp,POSTINC0	
   ; MOVFF    temp,INDF0
    INCF     WrtCnt                 ; Keep track of how many writing procedures
                                    ; took place
    CPFSLT   WrtCnt                 ; Compare the number of writing operations
                                    ; with the length of the buffer. (WREG)
    goto     ResWrt                 ; If greater than or equal go to this SR
                                    
Check:
    MOVLW    D'10'                  ; WREG = value of carriage return character
   ; CPFSEQ   RCREG                  ; Has the carriage return character been
                                    ; recieved?
    CPFSEQ   temp				    
    goto     Restore                ; If less than or equal go to STOP
    goto     Stop
Restore:    
    MOVFF    stat,STATUS            ; Restore STATUS,BSR and WREG resgisters
    MOVFF    tBSR,BSR               ; respectively
    MOVF     wTemp,0
    MOVWF    temp;                  ; Set temp to the value of 100 prior to 
                                    ; leaving this ISR before the TX232 SR
    RETFIE
    
ResWrt:                             ; If the number of writing operations 
                                    ; exceeded the number of allocated bytes to 
				    ; the buffer
    LFSR     FSR0,buffer            ; Re-point to tbe beginning of the buffer
    CLRF     WrtCnt                 ; Reset the writing operations to zero
    goto     Check                  ; go to the specified sub-routine
 
Stop:
    INCF     recieve                ; The message has been recieved
    BCF      INTCON,GIEH            ; Disable high and low priority interrupts
    BCF      INTCON,GIEL            ; temporarily
    goto     Restore                ; Go to the specified SR
    
    
    END