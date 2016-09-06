  
    list p = 18f452
    include "configReg.inc"
    include "p18f452.inc"

RES_VECT    CODE    0x0000            ; Processor reset vector
    GOTO    SETUP                     ; Go to beginning of program

    UDATA_ACS
temlen  res  1                        ; The length of the string is stored here   
length  res  1                        ; Also here
toggle  res  1                        ; Toggle between two possible sub routines
                                      ; to be executed during program 
				      ; implementation
buffer  RES  32				      
      CODE
     
;buffer  RES  10                       ; Reserve 10 bytes for the message
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
   MOVLW    B'00000000'             ; WREG = 0
   MOVWF    length                  ; Length of the string is initially zero
   MOVWF    temlen
   MOVWF    toggle
   INCF     toggle
   INCF     toggle                  ; Toggle  = 2 initially
TABLE_SETUP:
   DECF     toggle                  ; First entry into this SR toggle is 1 and
                                    ; hence the compare SR will be entered into
				    ; At the second entry into this SR toggle is
				    ; 0 and an alternative SR is entered into
   MOVLW    upper string
   MOVWF    TBLPTRU
   MOVLW    high  string
   MOVWF    TBLPTRH
   MOVLW    low  string  
   MOVWF    TBLPTRL
                                    ; At the end of this seqeunce TBLPTR points
				    ; to the correct area in program memory 
				    ; where the string is located. It points to
				    ; an address where the first lettet t is 
				    ; contained
   TBLRD *+                         ; Put the first byte (t) into the latch
   CLRF     WREG                    ; WREG = 0
   CPFSGT   toggle                  ; goto WrtBuff is toggle is zero. Otherwise
                                    ; go to the compare SR
   goto     WrtBuff
Compare:                            ; We compare the contents of the string with
                                    ; the terminating null in order to find the
				    ; length of the string
   CPFSGT    TABLAT                 ; Have we reached the end yet?
   goto      TABLE_SETUP            ; If yes go back to TABLE_SETUP
   INCF      length                 ; increment the length while we are not at 
                                    ; the end
   INCF      temlen				    
   TBLRD     *+                     ; Put the next character into the latch
   BRA       Compare                ; Restart cycle
   
WrtBuff:                            ; At this stage TABLAT is the first letter
                                    ; in the string because we restarted the 
				    ; table sequence
    MOVF     TABLAT,0               ; Move char from Latch into WREG
    MOVWF    POSTINC0               ; Put the character into buffer through FSR0
    TBLRD    *+                     ; Put the next character onto the latch
    DCFSNZ   length                 ; Restart the cycle string length amount
                                    ; of times
    BRA      Main                   ; Testing to see whether buffer contains the
                                    ; correct values
    BRA      WrtBuff                ; Write the string and store to buffer while
                                    ; we have not reached the end of the string
    
    
Main:
    
    goto     TX232                  ; go to the routine which will transmit the
                                    ; required message
    
    
    
TX232:
    MOVFF    temlen,length          ; Restore the length variable back to the
                                    ; original length of the string
    LFSR     FSR0,buffer            ; Pointer points to the beginning of the 
                                    ; string
Write:   
    MOVFF    POSTINC0,TXREG         ; Put the character pointed to at by the 
                                    ; pointer to TXREG and increment the pointer
				    ; for the subsequent character
Wait:    
    BTFSS    PIR1,TXIF              ; Wait for the interrupt flag to be set. 
                                    ; This occurs whenever TXREG is empty. NOTE
				    ; the interrupt enable bit does not need to
				    ; be set. Only enable the interrupt from PIE
				    ; if interrupt service routines will be used
    BRA      Wait                   ; Skip this line if TXIF bit is set
    DCFSNZ   length                 ; Decrement the length by 1
    goto     Main                   ; If zero restart procedure
    BRA      Write                  ; Otherwise proceed to the next character.
    
    
   
InterSet:
  
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
    RETURN			
  
 
    END