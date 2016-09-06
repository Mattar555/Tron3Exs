; Program for Task 5.
    
    list p = 18f452
    include  "configReg.inc"
    include  "p18f452.inc"

RES_VECT  CODE    0x0000            ; Processor reset vector
          GOTO    Setup             ; Go to beginning of program

RCISR:    CODE    0x0008            ; High Priority Interrupt Vector Address
          GOTO    RCISR
	  
CCPISR:   CODE    0x0018            ; Low Priority Interrupt Vector Address
          GOTO    CCPISR
	  
	  UDATA_ACS
	                            ; The Dividend in our scenario is a function
				    ; of the clock frequency of the MCU and the
				    ; pre-scaler chosen. Using a pre-scaler of
				    ; one means the dividend is 1E6. For our 
				    ; program it will remain constant. See 
				    ; Lab Book for derivaton of formula
				    
DVDEND_MEGA	  RES	    1       ; The Fourth Byte of the dividend 
TEMP_MEGA	  RES       1
DVDEND_UPPER      RES       1       ; The Third Byte of the dividend
TEMP_UPPER        RES       1
DVDEND_HIGH       RES       1       ; The Second Byte of the dividend 
TEMP_HIGH         RES       1      
DVDEND_LOWER      RES       1       ; The First Byte of the dividend
TEMP_LOWER        RES       1      
      
                                    ; The allowable frequencies can be 
				    ; accomodated by 16 bits.
				    
FREQ_HIGH         RES       1       ; The higher byte of the frequency				    
FREQ_LOW       	  RES       1       ; The lower byte of the frequency
	  
	                            ; Definining the remainder of the division
				    ; process. 16 Bits Required
	  
RMNDER_HIGH       RES       1       ; The high portion of the remainder 
RMNDER_LOW        RES       1       ; The low portion of the remainder       

	                            ; Defining the Quotient Q

QOTENT_MEGA       RES       1       ; Fourth Byte of Q				    
QOTENT_UPPER      RES       1       ; Third Byte of Q
QOTENT_HIGH       RES       1       ; Second Byte of Q
QOTENT_LOWER      RES       1       ; First Byte of Q
      
      
     
COUNTER           RES       1       ; Used to determine which bit to clear from
	                            ; the Q throughout the division algorithim
				    
T_COUNT           RES       1       ; Temporary variable for the counter defined
                                    ; above	   
      
TEMP              RES       1       ; Temporary variable. Will be relied upon
	                            ; extensively throughout the program   
				    
				    
				    
                                    ; Storage variables for the subtraction 				    
STRCT_LOW         RES       1
STRCT_HIGH        RES       1
	
	                            ; Various flags used throughout the division
				    ; procedure
				    
TWENTY_FOUR       RES     1            
SIXTEEN           RES     1          
EIGHT             RES     1           
	                            ; Which byte to clear from Q during the div
				    ; process? This is given by the value of the
				    ; flags below
				    
MEGA              RES     1           
UPP               RES     1
HGH               RES     1
LO                RES     1

	                              ; Duty Cycle - related 
				      
DCYC_H            RES     1           ; The Duty Cycle expressed as a percentage
	                              ; The High_Portion will always be cleared
				      ; However we need it in the multiplication
				      ; algorithim
DCYC_L            RES     1           ; DC takes vales between 0 and 100. Hence
	                              ; the lower byte is sufficient to 
				      ; accomodate it
TOTCYC_L          RES     1                
TOTCYC_H          RES     1           ; Total number of cycles. This is 
	                              ; essentially the total number of cycles
				      ; to generate the required period. However
				      ; we are interested in high_cycles and 
				      ; low_cycles which are just fractions of 
				      ; TOTCYC. TOTCYC helps getting low_cycles
				      ; without going through the multiplication
				      ; procedure because H_CYC + L_CYC = TOTCYC
H_CYC_H           RES     1           ; Number of cycles of the high portion of
                                      ; the wave
H_CYC_L           RES     1		
L_CYC_L	          RES     1
L_CYC_H           RES     1           ; Number of cycles of the low portion of 
                                      ; the wave

				      ; We store the results of the 
				      ; multiplication procedure in the 
				      ; following
				      
                                      ; Note even though it is technically a 16
				      ; by 16 bit multiplication the range of
				      ; frequencies dictated will result in a 
				      ; max value of 500,000 for the 
				      ; multiplication procedure. Which can be
				      ; accomodated by three bytes. However the
				      ; fourth byte is just included for 
                                      ; completeness sake.
PROD_MEGA         RES     1				      
STORE_MEGA	  RES     1
PROD_UPPER        RES     1	  
STORE_UPPER       RES     1
PROD_HIGH         RES     1       
STORE_HIGH        RES     1
PROD_LOWER        RES     1	
STORE_LOWER       RES     1
                                     ; Defining the divisor in the second 
				     ; division process. It is 100
				     
DIVSOR_LOW        RES     1          ;  
DIVSOR_HIGH       RES     1	     ; Will always be zero.
       
MULT_FLAG         RES     1  
	 
HI_LOW            RES     1          ; Flag to toggle between the high and low
	                             ; portion of the square wave
				     
				     ; Used for saving and retrieving context
				     ; during the interrupt service routine
T_BSR             RES     1				     
T_WREG            RES     1
T_STAT            RES     1
	    
	                             ; The following globals aid during the 
				     ; serial interrupt service routine.
				     ; They essentially keep track of how much
				     ; times a particular key was depressed.
				     ; They are essentially incrementers/
				     ; decrementers that have a set range of 
				     ; values they cannot exceed. See Lab Book
				     ; for a more thorough explanation
				     
A_PRESS           RES     1          ; A increases Frequency by 200
S_PRESS           RES     1          ; S decreases Frequency by 200
D_PRESS           RES     1          ; D increases Duty Cycle by 10%
F_PRESS           RES     1	     ; F decreases Duty Cycle by 10%
	   
RC_TEMP           RES     1          ; Temp variable used in the RCISR	
	   
                                     ; The ASCII values of A,S,D and F
				     
A_VALUE           RES     1                    	   
S_VALUE           RES     1
D_VALUE           RES     1
F_VALUE           RES     1
	   
DC_INC            RES     1          ; Duty Cycle Increment/Decrement (as a %)
FR_INC            RES     1	     ; Freqeuncy increment/decrement.
	    
MAIN_PROG CODE                       ; Let linker place main program

Setup:
    
    BRA          Timer_Set          ; Proceed to the routine to configure the
                                    ; timer module
    
VarSet:    
    
                                    ; We initialize the variables/flags used 
				    ; throughout the program
				    
				    ; The allowable ranges of the PRESS 
				    ; variables lie between 0 and the specified
				    ; value as below
    MOVLW         D'25'
    MOVWF         A_PRESS           ; A_PRESS init to 25. See Lab Book
    MOVLW         D'23'
    MOVWF         S_PRESS
    MOVLW         D'4'
    MOVWF         D_PRESS
    MOVWF         F_PRESS
    MOVLW	  D'32'				    
    MOVWF         COUNTER           ; Set Counter to 32 
    MOVLW         D'24'
    MOVWF         TWENTY_FOUR
    MOVLW         D'16'
    MOVWF         SIXTEEN
    MOVLW         D'8'
    MOVWF         EIGHT      
    
    CLRF          HI_LOW            ; Initially begin with the low portion of
                                    ; the wave
				    
                                    ; We define the dividend 
				    
    CLRF          DVDEND_MEGA       ; 1E6 is 24 bits. So the bits of the fourth
                                    ; byte is just zero
    MOVLW         B'00001111'       ; Upper Byte of 1E6
    MOVWF         DVDEND_UPPER      
    MOVLW         B'01000010'       ; Higher Byte of 1E6
    MOVWF         DVDEND_HIGH       
    MOVLW         B'01000000'       ; Lower Byte of 1E6
    MOVWF         DVDEND_LOWER  
    
    CLRF          DIVSOR_HIGH       ; Divisor is 100 for the second division 
                                    ; process. The high byte will be zero as
				    ; 100 is an 8 bit number
    MOVLW         B'01100100'	    ; The bit pattern of 100
    MOVWF         DIVSOR_LOW
    
                                    ; Duty Cycle Init. Assuming an initial
				    ; freqeuncy of 10,000 the total number of
				    ; cycles is 100. Assuming an initial DC of
				    ; 50 % means we initial the high and low 
				    ; cycles to value of 50. Hence the 
				    ; corresponding high bytes are 0
    
    CLRF	  H_CYC_H
    CLRF          L_CYC_H
    MOVLW         B'00110010'       ; The bit pattern of 50
    MOVWF         H_CYC_L
    MOVWF         L_CYC_L
    
                                    ; Defining the ASCII Values of A,S,D and F
    MOVLW         D'65'
    MOVWF         A_VALUE           ; ASCII A
    MOVLW         D'83'
    MOVWF         S_VALUE           ; ASCII S
    MOVLW         D'68'
    MOVWF         D_VALUE           ; ASCII D
    MOVLW         D'70'
    MOVWF         F_VALUE           ; ASCII F
                                   
                                    ; How much we modify the DC and FREQ GV's
				    ; in the ISR
				    
    MOVLW         D'10'
    MOVWF         DC_INC
    MOVLW         D'200'
    MOVWF         FR_INC
    
FreqSet:                            ; We are initilizing the frequency to 10000
                                    ; It is subject to change later during 
				    ; program execution (Main SR)
				    ; We set an initial frequency of 5000Hz. The
				    ; smooth execution of the program depends on
				    ; this initial value
    
    MOVLW         B'10001000'       ; Lower Byte of 5000
    MOVWF         FREQ_LOW
    MOVLW         B'00010011'       ; Higher Byte of 5000
    MOVWF         FREQ_HIGH
    
DCSet:                              ; We are initilizing the DC to 50 percent.
                                    ; It is subject to change later during 
				    ; program execution (Main SR)
    
    CLRF         DCYC_H             ; This will always be zero
    MOVLW        B'00110010'        ; DC init to 50 initially.
    MOVWF        DCYC_L             ; 
    CLRF         MULT_FLAG          ; So we start with the division of clock
                                    ; cycle by frequency routine, not the 
				    ; division of the result (multiplied by DC)
				    ; over 100 to get the H_CYC value
    
                                    ; Do not forget to enable interrupts just
				    ; before main
				    
    BRA          Int_Set            ; Configuring interrupts just prior to 
                                    ; program execution
Main:
    
    GOTO          Divide
    
         
    

    
    
Divide:
    
                                    ; First initilize the Q. See description
				    ; below. 
				    
				    ; Irrespective of whether or not we are 
				    ; performing the first or second division
				    ; we still set the Q bits 
QSet:
                                    ; Set all the bits of all bytes of Q 
				    ; initially. Throughout the division 
				    ; algorithim depending on whether a borrow
				    ; bit from the subtraction process (divisor
				    ; from remainder) we clear the relevant bit.
				    ; Otherwise we do nothing (we would set the
				    ; bit if no borrow but they are already set
				    ; so to speak.
				    ; As per the above we set all the bits of Q
				    
    SETF          QOTENT_MEGA                
    SETF          QOTENT_UPPER
    SETF          QOTENT_HIGH
    SETF          QOTENT_LOWER
    
                                    ; All the bits of all bytes of Q are set
				    
RSet:				    ; Clear remainder initially
    
    CLRF          RMNDER_HIGH
    CLRF          RMNDER_LOW
    
DvdSet:                             ; Set the temp variables for the dividend
                                    ; to the actual value of the dividend
				    ; so the dividend (which is meant to be a 
				    ; constant; 1E6) remains constant
				    
    TSTFSZ        MULT_FLAG         ; The Dividend depends on whether or not we
                                    ; are in the first or second division 
				    ; process
    BRA           DvdSetM           ; Go to this SR if we are in the second div
                                    ; process. Otherwise proceed as below
				    
    MOVFF         DVDEND_MEGA,TEMP_MEGA
    MOVFF         DVDEND_UPPER,TEMP_UPPER
    MOVFF         DVDEND_HIGH,TEMP_HIGH
    MOVFF         DVDEND_LOWER,TEMP_LOWER
    BRA           DVarSet
    
DvdSetM:                            ; Second division process. Set the dividend
                                    ; accordingly
    
    MOVFF         PROD_MEGA,TEMP_MEGA
    MOVFF         PROD_UPPER,TEMP_UPPER
    MOVFF         PROD_HIGH,TEMP_HIGH
    MOVFF         PROD_LOWER,TEMP_LOWER
    
DVarSet:                             ; Setting the variables in the divison 
                                     ; process
    				    
    MOVFF         COUNTER,T_COUNT    ; Reset T_COUNT to 32 
    BCF           STATUS,C           ; Clear the carry bit initially
    
Stage1:                              ; This process is the same for the first
                                     ; and second division process. Hence no 
				     ; need for testing the MULT_FLAG
    
    RLCF        TEMP_LOWER           ; If MSB that was lost (hence 1) it will 
                                     ; appear in the Carry bit and transfers to 
				     ; the LSB of the second byte (MSB of first
				     ; byte that is)
    RLCF        TEMP_HIGH                 
    RLCF        TEMP_UPPER
    RLCF        TEMP_MEGA            ; If MSB here was one it will be lost (but
                                     ; regained through the carry bit of the 
				     ; previous instruction (if it were to be 1)
				     ; and the lost bit will be the carry bit
				     ; We transfer this "lost" bit to the MSB
				     ; of the MEGA byte to the LSB of the low
				     ; byte of the remainder. As required
    RLCF        RMNDER_LOW
    RLCF        RMNDER_HIGH
    
    
    
Stage2:
    
    TSTFSZ      MULT_FLAG
    BRA         Stage2M
    MOVF        FREQ_LOW,0           ; WREG = FREQ_LOW
    SUBWF       RMNDER_LOW,0         ; RMNDER_LOW - DIVISOR_LOW. Store into WREG
    MOVWF       STRCT_LOW            ; PLace the above into STORE_LOW
    MOVF        FREQ_HIGH,0          ; WREG = FREQ_HIGH
    BTFSS       STATUS,C             ; Skip next step if no Borrow
    INCFSZ      FREQ_HIGH,0          ; WREG += 1 if Borrow bit present. If 
                                     ; overflow occured as a result of the 
				     ; increment then forgo the following step
    SUBWF       RMNDER_HIGH,0        ; RMNDER_HIGH - DIVSOR_HIGH. Store into W
    MOVWF       STRCT_HIGH           ; Move the above into STRCT_HIGH
    BTFSS       STATUS,C             ; Check if Borrow is present in the higher
                                     ; byte subtraction.
    BRA         Borrow               ; There was a borrowing procedure. Go to
                                     ; the Borrow SR
				     ; If no borrow present then update the 
				     ; value of remainder accordingly. Otherwise
				     ; restore remainder is to retain its 
				     ; orginal values in the case of a borrow
				     ; Remainder Values to update according to
				     ; the subtraction (Remainder-Divisor and
				     ; store the values in the remainder) 
				     
    MOVFF       STRCT_LOW,RMNDER_LOW 
    MOVFF       STRCT_HIGH,RMNDER_HIGH
    
    BRA         Stage3
                                    
                                     ; By construction above the remainders need
				     ; not be restored because we transferred 
				     ; the subtraction results to WREG. So we
				     ; figure out which bit to clear off the
				     ; quotient now
				     
Stage2M:
    
    MOVF        DIVSOR_LOW,0         ; WREG = FREQ_LOW
    SUBWF       RMNDER_LOW,0         ; RMNDER_LOW - DIVISOR_LOW. Store into WREG
    MOVWF       STRCT_LOW            ; PLace the above into STORE_LOW
    MOVF        DIVSOR_HIGH,0        ; WREG = FREQ_HIGH
    BTFSS       STATUS,C             ; Skip next step if no Borrow
    INCFSZ      DIVSOR_HIGH,0        ; WREG += 1 if Borrow bit present. If 
                                     ; overflow occured as a result of the 
				     ; increment then forgo the following step
    SUBWF       RMNDER_HIGH,0        ; RMNDER_HIGH - DIVSOR_HIGH. Store into W
    MOVWF       STRCT_HIGH           ; Move the above into STRCT_HIGH
    BTFSS       STATUS,C             ; Check if Borrow is present in the higher
                                     ; byte subtraction.
    BRA         Borrow               ; There was a borrowing procedure. Go to
                                     ; the Borrow SR
				     ; If no borrow present then update the 
				     ; value of remainder accordingly. Otherwise
				     ; restore remainder is to retain its 
				     ; orginal values in the case of a borrow
				     ; Remainder Values to update according to
				     ; the subtraction (Remainder-Divisor and
				     ; store the values in the remainder) 
				     
    MOVFF       STRCT_LOW,RMNDER_LOW 
    MOVFF       STRCT_HIGH,RMNDER_HIGH
    
    BRA         Stage3
    
    
    
    
Borrow:                              ; Check which bit we have to clear amongst
                                     ; the bytes of Q. The variable TEMP and
				     ; the flags below aid in determining the
				     ; relevant bit
    
    MOVF        TWENTY_FOUR,0        ; WREG = 24
    CPFSGT      T_COUNT              ; Counter > 24?
    BRA         Upper_Check          ; If not proceed to this SR
    SUBWF       T_COUNT,0            ; Counter - 24. Store into WREG
    MOVWF       TEMP                 ; Transfer the contents of WREG into TEMP
    DECF        TEMP                 ; Zero indexed
    INCF        MEGA                 ; Set the MEGA Flag so we know to update
                                     ; the MEGA byte of the dividend
    CLRF        UPP                  ; Clear the remaining flags
    CLRF        HGH
    CLRF        LO
    BRA         Clear                ; Proceed to the SR which deals with 
                                     ; clearing the relevant bit
				     
				     
Upper_Check:
    
    MOVF       SIXTEEN,0             ; WREG = 16
    CPFSGT     T_COUNT               ; Counter > 16 ?
    BRA        High_Check            ; If not go to High_Check SR
    SUBWF      T_COUNT,0             ; WREG = COUNTER - 16
    MOVWF      TEMP                  ; TEMP = WREG
    DECF       TEMP                  ; Zero indexed
    INCF       UPP                   ; Set the flag
    CLRF       MEGA                  ; Clear the remaining flags. Only clearing
                                     ; the MEGA flag is required. The others are
				     ; not. Since the Sub-Routines in which they
				     ; are incremented/set will not be entered 
				     ; into yet. However they are cleared for
				     ; completeness.
    CLRF       HGH
    CLRF       LO
    BRA        Clear
    
High_Check:
    
    MOVF      EIGHT,0
    CPFSGT    T_COUNT
    BRA       Low_Check
    SUBWF     T_COUNT,0
    MOVWF     TEMP
    DECF      TEMP
    INCF      HGH                    
    CLRF      MEGA                   
    CLRF      UPP                   ; Only this line is really required (for 
                                    ; the flag clearance that is) as MEGA and
				    ; UPPER are already cleared and LO is never
				    ; set.
    CLRF      LO
    BRA       Clear
    
Low_Check:                          ; Enter this SR if counter lies between 1 
                                    ; and 8 inclusive. We still need to 
				    ; decrement as usual.
				    
    
    MOVFF     T_COUNT,TEMP
    DECF      TEMP
    INCF      LO
    CLRF      HGH                   ; Only this line from the flag clearance 
                                    ; instruction is technically required.
    CLRF      MEGA
    CLRF      UPP
    BRA       Clear
                                    
                                    ; Rest assured TEMP lies between 0 and 7 in
				    ; all cases
    
Clear:                              ; Now we check both TEMP and which flag 
                                    ; (amongst the UPP,MEGA,HGH or LO) is set
				    ; and act accordingly. (As in disable the 
				    ; relevant bit)
    				    
    MOVLW     D'7'
    CPFSLT    TEMP                  ; This implies the next instruction (if 
                                    ; executed) implies TEMP = 7
    BRA       Clear7                ; Hence go to the relevant SR
    MOVLW     D'6'                  ; The same process applies sequentially to
                                    ; the remaining digits
    CPFSLT    TEMP
    BRA       Clear6
    MOVLW     D'5'
    CPFSLT    TEMP
    BRA       Clear5
    MOVLW     D'4'
    CPFSLT    TEMP
    BRA       Clear4
    MOVLW     D'3'
    CPFSLT    TEMP
    BRA       Clear3
    MOVLW     D'2'
    CPFSLT    TEMP
    BRA       Clear2
    MOVLW     D'1'
    CPFSLT    TEMP
    BRA       Clear1
    BRA       Clear0                ; Entering this statement must, by the 
                                    ; process of elimination, imply TEMP = 0.
				    
				    ; Within the ClearX SR's we check which
                                    ; flag is set and act accordingly

Clear7:                            
    				    
    TSTFSZ    MEGA                  ; Is the MEGA flag set?
    BRA       Clear7M               ; If yes go to this SR? Otherwise proceed
                                    ; below
    TSTFSZ    UPP                   ; Is the UPP flag set?
    BRA       Clear7U               ; If yes go to this SR. Otherwise check HGH
    TSTFSZ    HGH                   ; Is HGH set? 
    BRA       Clear7H               ; If set go this SR. Otherwise go to LO SR
    BRA       Clear7L               ; HGH,UPP and MEGA = 0 imply LO = 1 by 
                                    ; construction

Clear7M:
    BCF       QOTENT_MEGA,7
    GOTO      Stage3
Clear7U:
    BCF       QOTENT_UPPER,7
    GOTO      Stage3
Clear7H:
    BCF       QOTENT_HIGH,7
    GOTO      Stage3
Clear7L:
    BCf       QOTENT_LOWER,7
    GOTO      Stage3
    
Clear6:                            
    				    
    TSTFSZ    MEGA                  ; Is the MEGA flag set?
    BRA       Clear6M               ; If yes go to this SR? Otherwise proceed
                                    ; below
    TSTFSZ    UPP                   
    BRA       Clear6U
    TSTFSZ    HGH
    BRA       Clear6H               ;
    BRA       Clear6L               ; HGH,UPP and MEGA = 0 imply LO = 1 by 
                                    ; construction

Clear6M:
    BCF       QOTENT_MEGA,6
    GOTO      Stage3
Clear6U:
    BCF       QOTENT_UPPER,6
    GOTO      Stage3
Clear6H:
    BCF       QOTENT_HIGH,6
    GOTO      Stage3
Clear6L:
    BCf       QOTENT_LOWER,6
    GOTO      Stage3 

Clear5:                            
    				    
    TSTFSZ    MEGA                  ; Is the MEGA flag set?
    BRA       Clear5M               ; If yes go to this SR? Otherwise proceed
                                    ; below
    TSTFSZ    UPP                   
    BRA       Clear5U
    TSTFSZ    HGH
    BRA       Clear5H               ;
    BRA       Clear5L               ; HGH,UPP and MEGA = 0 imply LO = 1 by 
                                    ; construction

Clear5M:
    BCF       QOTENT_MEGA,5
    GOTO      Stage3
Clear5U:
    BCF       QOTENT_UPPER,5
    GOTO      Stage3
Clear5H:
    BCF       QOTENT_HIGH,5
    GOTO      Stage3
Clear5L:
    BCf       QOTENT_LOWER,5
    GOTO      Stage3  
    
Clear4:                            
    				    
    TSTFSZ    MEGA                  ; Is the MEGA flag set?
    BRA       Clear4M               ; If yes go to this SR? Otherwise proceed
                                    ; below
    TSTFSZ    UPP                   
    BRA       Clear4U
    TSTFSZ    HGH
    BRA       Clear4H               ;
    BRA       Clear4L               ; HGH,UPP and MEGA = 0 imply LO = 1 by 
                                    ; construction

Clear4M:
    BCF       QOTENT_MEGA,4
    GOTO      Stage3
Clear4U:
    BCF       QOTENT_UPPER,4
    GOTO      Stage3
Clear4H:
    BCF       QOTENT_HIGH,4
    GOTO      Stage3
Clear4L:
    BCf       QOTENT_LOWER,4
    GOTO      Stage3  
    
    
Clear3:                            
    				    
    TSTFSZ    MEGA                  ; Is the MEGA flag set?
    BRA       Clear3M               ; If yes go to this SR? Otherwise proceed
                                    ; below
    TSTFSZ    UPP                   
    BRA       Clear3U
    TSTFSZ    HGH
    BRA       Clear3H               ;
    BRA       Clear3L               ; HGH,UPP and MEGA = 0 imply LO = 1 by 
                                    ; construction

Clear3M:
    BCF       QOTENT_MEGA,3
    GOTO      Stage3
Clear3U:
    BCF       QOTENT_UPPER,3
    GOTO      Stage3
Clear3H:
    BCF       QOTENT_HIGH,3
    GOTO      Stage3
Clear3L:
    BCf       QOTENT_LOWER,3
    GOTO      Stage3   
    
    
    
Clear2:                            
    				    
    TSTFSZ    MEGA                  ; Is the MEGA flag set?
    BRA       Clear2M               ; If yes go to this SR? Otherwise proceed
                                    ; below
    TSTFSZ    UPP                   
    BRA       Clear2U
    TSTFSZ    HGH
    BRA       Clear2H               ;
    BRA       Clear2L               ; HGH,UPP and MEGA = 0 imply LO = 1 by 
                                    ; construction

Clear2M:
    BCF       QOTENT_MEGA,2
    GOTO      Stage3
Clear2U:
    BCF       QOTENT_UPPER,2
    GOTO      Stage3
Clear2H:
    BCF       QOTENT_HIGH,2
    GOTO      Stage3
Clear2L:
    BCf       QOTENT_LOWER,2
    GOTO      Stage3  
    
    
Clear1:                            
    				    
    TSTFSZ    MEGA                  ; Is the MEGA flag set?
    BRA       Clear1M               ; If yes go to this SR? Otherwise proceed
                                    ; below
    TSTFSZ    UPP                   
    BRA       Clear1U
    TSTFSZ    HGH
    BRA       Clear1H               ;
    BRA       Clear1L               ; HGH,UPP and MEGA = 0 imply LO = 1 by 
                                    ; construction

Clear1M:
    BCF       QOTENT_MEGA,1
    GOTO      Stage3
Clear1U:
    BCF       QOTENT_UPPER,1
    GOTO      Stage3
Clear1H:
    BCF       QOTENT_HIGH,1
    GOTO      Stage3
Clear1L:
    BCf       QOTENT_LOWER,1
    GOTO      Stage3    
    
    
Clear0:                            
    				    
    TSTFSZ    MEGA                  ; Is the MEGA flag set?
    BRA       Clear0M               ; If yes go to this SR? Otherwise proceed
                                    ; below
    TSTFSZ    UPP                   
    BRA       Clear0U
    TSTFSZ    HGH
    BRA       Clear0H               ;
    BRA       Clear0L               ; HGH,UPP and MEGA = 0 imply LO = 1 by 
                                    ; construction

Clear0M:
    BCF       QOTENT_MEGA,0
    GOTO      Stage3
Clear0U:
    BCF       QOTENT_UPPER,0
    GOTO      Stage3
Clear0H:
    BCF       QOTENT_HIGH,0
    GOTO      Stage3
Clear0L:
    BCf       QOTENT_LOWER,0
    GOTO      Stage3  
      
    
Stage3:   
                                    ; The above procedure (Stage 1 and 2) is to 
				    ; occur 32 times such that all bits of Q
				    ; are checked (either cleared or left set)
				    ; and thus the T_COUNT variable comes into
				    ; play
 
    DECFSZ     T_COUNT               
    BRA        Stage1
    BRA        Terminate
    
Terminate:
    
    TSTFSZ     MULT_FLAG
    GOTO       Subtract             ; Do not forget to reset the MULT_FLAG in
                                    ; in the subtraction routine. Right now
				    ; the variables QOTENT_HIGH(LOWER) contain
				    ; the high duty cycle time. Subtract from
				    ; the TOTCYC_L(H) to obtain the low cycle 
				    ; time
    GOTO       Multiply
    
    
Multiply:
    
MVarSet:                             ; Recall the result of the division process
                                     ; is a 16 bit number. Thus the High and Low
				     ; Bytes of Q are required. Given the 
				     ; desired frequencies as dictated by the 
				     ; question the Upper and Mega Byte are
				     ; expected to be cleared anyhow
				     
				     ; The result of the division process is the
				     ; total number of cycles. We need 2 bytes
				     ; to fully represent the number however
				     
				     ; The results of the division process is 
				     ; the total number of cycles trivially
    
    MOVFF      QOTENT_LOWER,TOTCYC_L 
    MOVFF      QOTENT_HIGH,TOTCYC_H
    
    CLRF       STORE_MEGA
    CLRF       STORE_UPPER
    CLRF       STORE_HIGH
    CLRF       STORE_LOWER
                                     ; The important thing to note prior to this
				     ; is that DCYC_H(L) and TOTCYC_H(L) are 
				     ; unaltered in the multiplication process
				     ; below as any results of the command MULWF
				     ; are transferred to the PRODH:PRODL 
				     ; register pair
    
MStage1:
    
    MOVF            DCYC_L,0          ; WREG = LB2
    MULWF           TOTCYC_L          ; PRODH contains te higher byte and PRODL
                                      ; contains the lower byte. Both WREG and F
				      ; are unchanged as a result of this 
				      ; operation
    				      
    MOVFF           PRODH,STORE_HIGH  ; As name implies
    MOVFF           PRODL,STORE_LOWER ; As name implies

MStage2:
    
    MULWF           TOTCYC_H          ; Recall at this stage WREG = LB2. Hence
                                      ; LB2 times HB1. Store result into PRODH
				      ; and PRODL
    MOVF            PRODL,0           ; WREG = PRODL
    ADDWFC          STORE_HIGH,1      ; STORE_HIGH += PRODL
    MOVF            PRODH,0           ; WREG = PRODH
    ADDWFC          STORE_UPPER,1     ; STORE_UPPER += PRODH
    
MStage3:
    
    MOVF            TOTCYC_L,0        ; WREG = LB1
    MULWF           DCYC_H            ; LB1 times HB2. Store into PRODH and 
                                      ; PRODL
    MOVF            PRODL,0           ; WREG = PRODL
    ADDWFC          STORE_HIGH,1      ; STORE_HIGH += PRODL
    MOVF            PRODH,0           ; WREG = PRODH
    ADDWFC          STORE_UPPER,1     ; STORE_UPPER += PRODH
    
MStage4:
    
    MOVF            TOTCYC_H,0        ; WREG = HB1
    MULWF           DCYC_H            ; HB1 times HB2. Store result into PRODH
                                      ; and PRODL
    MOVF            PRODL,0           ; WREG = PRODL
    ADDWFC          STORE_UPPER,1     ; STORE_UPPER += PRODL
    MOVF            PRODH,0           ; WREG = PRODH
    ADDWFC          STORE_MEGA,1      ; STORE_MEGA += PRODH
    
                                      ; Store the results of the multiplication
				      ; in PROD_XXXX
    
    MOVFF           STORE_MEGA,PROD_MEGA
    MOVFF           STORE_UPPER,PROD_UPPER
    MOVFF           STORE_HIGH,PROD_HIGH
    MOVFF           STORE_LOWER,PROD_LOWER
    
    INCF            MULT_FLAG
    
    GOTO            Divide            ; Now we must divide the result by 100
                                      ; to obtain the high cycle times
    
 
Subtract:
    
    BCF             STATUS,C
    CLRF            MULT_FLAG         ; Next time we enter the division routine
                                      ; we perform the first division. That is,
				      ; divide the desired frequency from the 
				      ; clock frequency to get the total number
				      ; of cycles
				      ; Now at this stage QOTENT_HIGH(LOW) 
				      ; are respectively H_CYC_H(LOW)
				      ; We subtract from TOTCYC_H(LOW) 
				      ; respectively to obtain L_CYC_H(L) 
    
    MOVFF           QOTENT_HIGH,H_CYC_H
    MOVFF           QOTENT_LOWER,H_CYC_L
    
    MOVF            QOTENT_LOWER,0    ; WREG = QOTENT_LOW
    SUBWF           TOTCYC_L,0        ; TOTCYC_L - QOTENT_LOW. Store into WREG
    MOVWF           L_CYC_L           ; 
    MOVF            QOTENT_HIGH,0     ; WREG = QOTENT_HIGH
    BTFSS           STATUS,C       
    INCFSZ          QOTENT_HIGH,0 
    SUBWF           TOTCYC_H,0
    MOVWF           L_CYC_H
    
    GOTO            Main
    
    
    
    
    
Timer_Set:
                                      ; Timer 3 will be used. That being said
				      ; TImer 1 is perfectly ok as well. It all
				      ; comes down to preference.
    MOVLW	     B'11000001'
    MOVWF            T3CON            ; Timer 3 enabled. TImer 3 is the 
                                      ; reference clock source for both CCP 
				      ; modules. Use internal clock. Pre-scale
				      ; of one. (which equates to a dividend of
				      ; 1E6)
    BRA              CCP_Set
    
                                   
CCP_Set:                              
                                      ; CCP Module 1 will be used.
				      
    				      
    BSF              CCP1CON,CCP1M3   
    BCF              CCP1CON,CCP1M2
    BSF              CCP1CON,CCP1M1
    BCF              CCP1CON,CCP1M0
                                      ; The following instructions simply sets
				      ; a software interrupt on compare match
				      ; The output of the CCP1 Pin is unaffected
				      
    BCF              TRISC,RC6        ; Required for serial transmission
    BSF              TRISC,RC7        ; Required for serial transmission
    BCF              TRISC,RC2        ; Configure Port 2 as output
    
    BRA              Serial_Set	      ; Now Configure Serial Module
    
    
Serial_Set:
    
    BCF              TXSTA,TX9        ; Enable eight bit transmission
    BSF              TXSTA,TXEN       ; Enables the tranmsitter
    BCF              TXSTA,SYNC       ; Asynchronous Mode
    BSF              TXSTA,BRGH       ; "High" Setting of the Baud Rate
    BSF              RCSTA,SPEN       ; Serial Port Enabled
    BCF              RCSTA,RX9        ; 8 Bit Reception
    BSF              RCSTA,CREN       ; Enables Reciever
    MOVLW            D'25'
    MOVWF            SPBRG            ; 9600 Baud Rate
    
    
    BRA              VarSet
    
Int_Set:
    
    BCF              INTCON,GIEH
    BCF              INTCON,GIEL       ; Initially disable all interrupts as the
                                       ; following instuctions can be defined as
				       ; a "critical region"
    BSF              RCON,IPEN         ; Enable interrupt priority
    BSF              IPR1,RCIP         ; The Reciever Interrupt takes the higher
                                       ; Priority in this program
    BCF              IPR1,CCP1IP       ; CCP1 Module is now the lower priority
    BSF              PIE1,CCP1IE       ; Enable interrupts associated with the 
                                       ; CCP1 Module CHANGE
    BCF              PIE2,CCP2IE       ; Disable interrupts associated with the
                                       ; CCP2 Module
    BSF              PIE1,RCIE         ; Enable interrupts associated with the
                                       ; Serial Reciever Module
    CLRF             PIR1              ; Enable subsequent access into the ISR
    BSF              INTCON,GIEH       ; 
    BSF              INTCON,GIEL       ; Re-enable interrupts
    
    BRA              Main              ; Go back to the main routine
    
    
    
CCPISR:
    
    BTFSS            PIR1,CCP1IF        ; Is the source of the interrupt the 
                                        ; CCP1 Compare?
    RETFIE                              ; If not return from ISR. Otherwise 
                                        ; proceed below
					
					; Save context
    MOVFF            STATUS,T_STAT
    MOVFF            BSR,T_BSR
    MOVWF            T_WREG
    
    TSTFSZ           HI_LOW             ; Low or High portion?
    BRA              SqHigh             ; Deal with the High Portion in the 
                                        ; specified SR. Otherwise deal with the
					; low portion directly below
					
					
SqLow:
    
    MOVF             L_CYC_L,0          ; WREG takes the value of the lower byte
                                        ; of the total amount of LOW cycles
    ADDWF            CCPR1L             ; Add the low byte. The Carry bit may
                                        ; or may not be set
    MOVF             L_CYC_H,0          ; WREG takes the value of the lower byte
                                        ; of the total amount of LOW cycles
    ADDWFC           CCPR1H             ; Add the high byte and take into 
                                        ; the carry bit (if present)
    INCF             HI_LOW             ; Next time deal with the high portion
    BCF              PORTC,2            ; Set low Pin 2 of Port C
    BRA              Ret_Int            ; Branch to this SR
    
SqHigh:
    
    MOVF             H_CYC_L,0          ; WREG takes the value of the lower byte
                                        ; of the total amount of HIGH cycles
    ADDWF            CCPR1L             ; Add the low byte. The carry bit may
                                        ; or may not be triggered
    MOVF             H_CYC_H,0          ; WREG takes the value of the high byte
                                        ; of the total amount of HIGH cycles
    ADDWFC           CCPR1H             ; Add the High Byte with the carry if
                                        ; present
    BSF              PORTC,2		; Set High Pin 2 of PORTC			
    CLRF             HI_LOW             ; Next time deal with the low portion
    
Ret_Int:
    
    BCF              PIR1,CCP1IF        ; Clearing interrupt flag 
                                      
    MOVFF            T_STAT,STATUS      ; Restoring context
    MOVFF            T_WREG,WREG
    MOVFF            T_BSR,BSR
    
    RETFIE                              ; Return from the ISR to whatever 
                                        ; the return address is as pointed to by
					; the program counter
					
					
					
RCISR:
    
    BTFSS            PIR1,RCIF          ; Double checking to see whether or not
                                        ; the reciver flag has been set
    RETFIE                              ; If not set return from interrupt
    
    MOVFF            STATUS,T_STAT      ; Save Context
    MOVFF            BSR,T_BSR
    MOVWF            T_WREG
    
    MOVFF            RCREG,RC_TEMP      ; Put the typed in character (whatever
                                        ; it may be; into RC_TEMP)
					
    MOVF             A_VALUE,0          ; WREG = A_VALUE
    CPFSGT           RC_TEMP            ; Skip the next instruction if the 
                                        ; recieved character is "alphabetically"
					; greater than A
    BRA              CheckA             ; Proceed to this SR otherwise to verify
                                        ; whether or not the recieved character
					; is indeed A and act accordingly
					; The ORDER in which the characters are
					; checked is of importance
    MOVF             D_VALUE,0          ; WREG = D_VALUE
    CPFSGT           RC_TEMP            ; Check whether or not the recieved 
                                        ; character is greater than D?
    BRA              CheckD             ; Go to this SR to verify if its really
                                        ; D
    MOVF             F_VALUE,0          ; Otherwise check for F
    CPFSGT           RC_TEMP
    BRA              CheckF
    MOVF             S_VALUE,0
    CPFSGT           RC_TEMP
    BRA              CheckS
		                        ; We can ascertain at this stage neither
					; of A,D,S or F were depressed hence 
					; return from the interrupt.
SerialDone:
                                        ; Restore Context prior to exiting
    MOVFF            T_STAT,STATUS
    MOVFF            T_BSR,BSR
    MOVF             T_WREG,0
    
    RETFIE
    
CheckA:                                 ; This stage means RCREG was less than 
                                        ; or equal to 60. We still have to 
					; make sure if its indeed 60. Not less
					; than
    
    CPFSLT           RC_TEMP            ; Skip next instruction if less than
    BRA              AZero              ; A was recieved signalling an increase
                                        ; in frequency. However bear in mind
					; there is a max value. We cannot keep
					; increasing definitely. This is 
					; signalled by the A_PRESS variable 
					; being zero. So AZero checks whether or
					; not the max freqeuncy was attained or 
					; not. In such case we simply return
					; from interrupt because we cannot 
					; increase anymore.
					
    BRA              SerialDone         ; Return from interrupt because we know
                                        ; for certain the recieved character is
					; not A,S,D or F
    
CheckD:
    
    CPFSLT           RC_TEMP
    BRA              DZero
    BRA              SerialDone
    
CheckF:
    
    CPFSLT           RC_TEMP
    BRA              FZero
    BRA              SerialDone
    
CheckS:
    
    CPFSLT           RC_TEMP
    BRA              SZero
    BRA              SerialDone
    
AZero:
    
    TSTFSZ           A_PRESS               ; Recall this variable going to zero 
                                           ; means the max frequency was 
					   ; attained and we cannot increase 
					   ; anymore. Hence skip the next step
					   ; and simply return from interrupt.
    BRA              FreqInc               ; If the max frequency was not 
                                           ; attained we are in the clearance to
					   ; increase frequency. So proceed to 
					   ; the relevant sub-routine.
    BRA              SerialDone            ; The max frequeny is attained. 
                                           ; Return from the sub-routine
    
FreqInc:  
    
    DECF             A_PRESS               ; We increased the frequency. The 
                                           ; A_PRESS is decreased by one 
					   ; indicating the number of presses
					   ; of A allowed decreases.
    INCF             S_PRESS               ; Increasing the frequency means 
                                           ; there is room for decreasing 
					   ; frequency. Hence the number of 
					   ; allowable presses for decreasing
					   ; frequency increases by one.
    MOVF             FR_INC,0
    ADDWF            FREQ_LOW              ; Add the low byte
    BTFSS            STATUS,C              ; If carry present skip next line
    BRA              SerialDone            ; No carry. We are done
    INCF             FREQ_HIGH             ; Add the carry to the higher byte
    BRA              SerialDone            ; Now we are done
    
    
DZero:
    
    TSTFSZ           D_PRESS
    BRA              DCInc
    BRA              SerialDone
    
DCInc:
    
    DECF             D_PRESS
    INCF             F_PRESS
    MOVF             DC_INC,0
    ADDWF            DCYC_L               ; No need for carry bit because DCYC_H
                                          ; is always zero as the values lie
					  ; between 0 and 100 so the carry bit 
					  ; is never set in the addition process
    BRA              SerialDone
    
FZero:
    
    TSTFSZ           F_PRESS
    BRA              DCDec
    BRA              SerialDone
    
DCDec:
    
    DECF             F_PRESS
    INCF             D_PRESS
    MOVF             DC_INC,0
    SUBWF            DCYC_L
    BRA              SerialDone
    
    
SZero:
    
    TSTFSZ           S_PRESS
    BRA              FreqDec
    BRA              SerialDone
    
FreqDec:
    
    DECF             S_PRESS
    INCF             A_PRESS
    MOVF             FR_INC,0
    SUBWF            FREQ_LOW
    BTFSS            STATUS,C
    BRA              Brrw
    BRA              SerialDone
    
Brrw:
    
    DECF             FREQ_HIGH
    BRA              SerialDone
    
    
    END