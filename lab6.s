; Archivo:	main.s
; Dispositivo:	PIC16F887
; Autor:	Melanie Samayoa
; Compilador:	pic-as (v2.35), MPLABX V6.00
;                
; Programa:	TMR1 e Incremento de variable segundos
; Hardware:	LEDs en el PORTD		
;
; Creado: 2 marzo 2022
; �ltima modificaci�n: 2 marzo 2022
    
PROCESSOR 16F887
    
; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = ON            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = ON              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>
 
  
; ------- VARIABLES EN MEMORIA --------
PSECT udata_shr		    ; Memoria compartida
    tempw:		DS 1
    temp_status:	DS 1
   
PSECT resVect, class=CODE, abs, delta=2
ORG 00h			    ; posici�n 0000h para el reset
;------------ VECTOR RESET --------------
resetVec:
    PAGESEL main	    ; Cambio de pagina
    GOTO    main
    
PSECT intVect, class=CODE, abs, delta=2
ORG 04h			    ; posici�n 0004h para interrupciones
;------- VECTOR INTERRUPCIONES ----------
push:
    MOVWF   tempw	    ; Guardamos W
    SWAPF   STATUS, W
    MOVWF   temp_status    ; Guardamos STATUS
    
isr:
    
    BTFSC   TMR2IF
    CALL   aumentar
    
pop:
    SWAPF   temp_status, W  
    MOVWF   STATUS	    ; Recuperamos el valor de reg STATUS
    SWAPF   tempw, F	    
    SWAPF   tempw, W	    ; Recuperamos valor de W
    RETFIE		    ; Regresamos a ciclo principal
    
aumentar:
    BCF TMR2IF
    MOVLW 0x01
    XORWF PORTD
    RETURN
    
PSECT code, delta=2, abs
ORG 100h		    ; posici�n 100h para el codigo
 
;------------- CONFIGURACION ------------
main:
    CALL    configio	    ; Configuraci�n de I/O
    CALL    configwatch    ; Configuraci�n de Oscilador
    CALL    configtmr2   ; Configuraci�n de TMR0
    CALL    configint	    ; Configuraci�n de interrupciones
    BANKSEL PORTD	    ; Cambio a banco 00
    
loop:
    ; C�digo que se va a estar ejecutando mientras no hayan interrupciones
    GOTO   loop	    
    
;------------- SUBRUTINAS ---------------
    
configwatch:
    BANKSEL OSCCON	    ; cambiamos a banco 1
    BSF	    OSCCON, 0	    ; SCS -> 1, Usamos reloj interno
    BSF	    OSCCON, 6
    BCF	    OSCCON, 5
    BSF	    OSCCON, 4	    ; IRCF<2:0> -> 101 2MHz
    RETURN
    
; Configuramos el TMR0 para obtener un retardo de 50ms
configtmr2:
    BANKSEL PR2
    MOVLW   244
    MOVWF   PR2	    ; 500ms retardo
    BANKSEL T2CON	    ; cambiamos de banco
    BSF	    T2CKPS1		    ; prescaler a TMR2
    BSF	    T2CKPS0		    ; PS<1:0> -> 1x prescaler 1 : 16
    
    BSF	    TOUTPS3		    ; TMR2 postscaler 
    BSF	    TOUTPS2
    BSF	    TOUTPS1
    BSF	    TOUTPS0		    ; PS<3:0> 1111 postescaler 1:16
    BSF	    TMR2ON		    ; Enciende el TMR2
    
   RETURN 
   
 configio:
    BANKSEL ANSEL
    CLRF    ANSEL
    CLRF    ANSELH	        ; I/O digitales
    BANKSEL TRISD
    CLRF    TRISD		; PORTD como salida
    BANKSEL PORTD
    CLRF    PORTD		; Apagamos PORTD
    RETURN
    
configint:
    BANKSEL PIE1 
    BSF	    TMR2IE
    BANKSEL INTCON
    BSF	    PEIE	    ; Habilitamos interrupciones
    BSF	    GIE		    ; Habilitamos interrupcion TMR0
    BCF	    TMR2IF
    RETURN

END
