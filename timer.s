#include <xc.inc>
    
global Setup_Timer, Button_Pressed,Start_Timer,Button_Released,Process_Timer,TIMER0_ISR
global Elapsed_Time_L,Elapsed_Time_M,Elapsed_Time_H  
    
psect udata_acs
Overflow_Count:ds 1 

TMR0_HIGH:ds 1        

TMR0_LOW:ds 1         

Elapsed_Time_L:ds 1   
   
Elapsed_Time_M:ds 1   

Elapsed_Time_H:ds 1
    
delay_count: ds 1      ; Variable for delay routine counter
    
    

psect timer_code, class=CODE

; Initialization Routine

Setup_Timer:

    clrf Overflow_Count, A ; Reset overflow counter
 
    ; Set up Timer0

    movlw 0b00000111    ; Configure Timer0: 16-bit, Fosc/4, 1:256 prescaler

    movwf T0CON,A

    clrf TMR0L,A          ; Clear Timer0 low byte

    clrf TMR0H,A          ; Clear Timer0 high byte
    
    movlw 0b10000000      ;configure interrupt
    
    movwf INTCON,A
    
    ; Configure RJ0 as input
    bsf TRISJ, 0,A        ; Set RJ0 (PORTJ, bit 0) as input
    clrf    TRISD
    return
 
Button_Pressed:

    btfss PORTJ, 0,A      ; Wait for RJ0 to go high, bit test file, skip if set
    
    goto Button_Pressed ;loop until pressed
    
    movlw 0xFF            ; Load 0xFF into W for delay counter initialization
    movwf delay_count, A  ; Initialize delay counter
    call delay            ; Call delay subroutine
    
    btfss PORTJ, 0,A      ; Wait for RJ0 to go high, bit test file, skip if set
    
    goto Button_Pressed ;loop until pressed
    
    return
 
    ; Start Timer0
    ;goto Start_Timer
    
    
Start_Timer:
    bcf TMR0IE      ;disenable timer0 interrupt
    
    bcf TMR0IF      ;clear overflow flag
    
    clrf TMR0L,A       ;clear timer
    
    clrf TMR0H,A
    
    clrf Overflow_Count,A
    
    clrf Elapsed_Time_L,A
    
    clrf Elapsed_Time_M,A
    
    clrf Elapsed_Time_H,A
    
    bsf TMR0ON     ;start timer
    
    bsf TMR0IE     ;enable timer0 interrupt
    
    return
    
    ;goto Button_Released
    
Button_Released:
    
    btfsc PORTJ,0,A
    
    goto Button_Released;loop until released
    
    movlw 0xFF            ; Load 0xFF into W for delay counter initialization
    movwf delay_count, A  ; Initialize delay counter
    call delay            ; Call delay subroutine
    
    
    btfsc PORTJ,0,A
    
    goto Button_Released;loop until released
    
    ; if released
    bcf TMR0ON      ; stop Timer
    
    bcf TMR0IE      ;disenable timer0 interrupt
    
    call Process_Timer     
    
    return
    
    
Process_Timer:
    
    movf Overflow_Count, W, A           
    
    movwf Elapsed_Time_H, A   ; high 8 bit = overflowcount
    
    movf TMR0H, W,A           
    
    movwf Elapsed_Time_M,A   ; ELAPSED_TIME_M = high bit of TMR0
    
    movf TMR0L, W,A           
    
    movwf Elapsed_Time_L,A   ; ELAPSED_TIME_L = Low bit of TMR0
    
    
    return
    

TIMER0_ISR:

    btfss TMR0IF ; Check if Timer0 overflowed (flag)

    retfie f          ; Return if not a Timer0 interrupt, return from interrupt enable
 
    incf Overflow_Count, F, A ; Increment overflow counter, increment file register, save to file
    movff   Overflow_Count, PORTD

    bcf TMR0IF     ; Clear Timer0 interrupt flag

    retfie f            ; Return from interrupt
    
    
delay:
    decfsz delay_count, A ; Decrement the delay counter until zero
    bra delay             ; Loop until counter is zero
    return                ; Return from delay subroutine


