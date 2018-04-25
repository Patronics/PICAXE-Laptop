 
; AXE134 Serial 20x4 OLED using PICAXE-18M2*
; Emulates basic serial operation of the popular AXE033 module
; CPS, May 2011
; JB,  Jan 2012

#picaxe 18M2


; Supported Commands
; 0-7, 8-15	CGRAM characters
; 16-252	normal ASCII characters, according to selected character map table
; 253, X	display 12 character pre-saved message from EEPROM memory, X can be 0-11
; 254, X	OLED command, X can be 0 to 255 
; 255, X	control outputs C.2, C.1, C.0 (via lower 3 bits of X)

#define use_welcome	; display the welcome message upon power up

symbol baud = N2400_16	; Serial baud rate 2400,N,8,1. Note main program runs at 16MHz

symbol spare0 	= C.0 ; spare output 0
symbol spare1 	= C.1 ; spare output 1
symbol spare2 	= C.2 ; spare output 2
symbol RX		= C.5	; serial receive pin
symbol enable 	= C.6	; OLED enable
symbol rs 		= C.7	; OLED RS 

; OLED data pins are on B.0 to B.7

; Store the 20 character user defined messages in EEPROM data memory
; First two messages are optionally used as welcome message

; Please remember 4 line displays always use the strange 1-3-2-4 line layout.

EEPROM  00, ("  PLOS starting up  ") 	; store msg 0 in the EEPROM memory
EEPROM  20, ("designed, built, and") 	; store msg 1 in the EEPROM memory
EEPROM  40, ("   programmed by    ") 	; store msg 2 in the EEPROM memory
EEPROM  60, ("   Patrick Leiser   ") 	; store msg 3 in the EEPROM memory
EEPROM  80, ("This is msg 4       ") 	; store msg 4 in the EEPROM memory
EEPROM 100, ("This is msg 5       ") 	; store msg 5 in the EEPROM memory
EEPROM 120, ("This is msg 6       ") 	; store msg 6 in the EEPROM memory
EEPROM 140, ("This is msg 7       ") 	; store msg 7 in the EEPROM memory
EEPROM 160, ("This is msg 8       ") 	; store msg 8 in the EEPROM memory
EEPROM 180, ("This is msg 9       ") 	; store msg 9 in the EEPROM memory
EEPROM 200, ("This is msg 10      ") 	; store msg 10 in the EEPROM memory
EEPROM 220, ("This is msg 11      ") 	; store msg 11 in the EEPROM memory

;initialise OLED
init:
	gosub OLED_init 		; initialise OLED

; display welcome message if desired
#ifdef use_welcome	
	let b1 = 0			; message 0 on top line
	gosub msg			; do it

	low rs			; command mode
	let pinsB = 192		; move to line 2, instruction 192
	pulsout enable,1  	; pulse the enable pin to send data.
	high rs			; character mode again
	
	let b1 = 1 			; message 1 on bottom line
	gosub msg			; do it
		
		
	low rs			; command mode
	let pinsB = 148		; move to line 2, instruction 192
	pulsout enable,1  	; pulse the enable pin to send data.
	high rs			; character mode again
	
	let b1 = 2 			; message 2 on bottom line
	gosub msg			; do it
	low rs			; command mode
	let pinsB = 212		; move to line 2, instruction 192
	pulsout enable,1  	; pulse the enable pin to send data.
	high rs			; character mode again
	
	let b1 = 3 			; message 3 on bottom line
	gosub msg			; do it
#endif		
		
; main program loop, runs at 16MHz

main:

	serin RX,baud,b1			; wait for the next byte

	; NB keep character mode test as first item in this list to optimise speed
	if b1 < 253 then
		let pinsB = b1 		; output the data
		pulsout enable,1  	; pulse the enable pin to send data.
		goto main			; quickly loop back to top
	else if b1 = 254 then
		low rs 	     		; change to command mode for next character
		serin RX,baud,b1		; wait for the command byte
		let pinsB = b1 		; output the data
		pulsout enable,1  	; pulse the enable pin to send data.
		high rs			; back to character mode
		goto main			; quickly loop back to top
	else if b1 = 253 then
		serin RX,baud,b1		; wait for the next byte
		gosub msg			; do the 16 character message
		goto main			; back to top
	else ; must be 255
		serin RX,baud,b1		; wait for the next byte
		let pinsC = b1 & %00000111 | %10000000
						; output the data on C.0 to C.1, keep RS high
		goto main			; back to top
	end if


; power on OLED initialisation sub routine
OLED_init:
	let dirsC = %11000111	; PortC 0,1,2,6,7 all outputs
	let dirsB = %11111111	; PortB all outputs

	; Winstar OLED Module Initialisation
	; according to WS0010 datasheet (8 bit mode)

	pause 500 			; Power stabilistation = 500ms

	; Function set - select only one of these 4 character table modes
	;let pinsB = %00111000 	; 8 bit, 2 line, 5x8 , English_Japanese table
	let pinsB = %00111001 	; 8 bit, 2 line, 5x8 , Western_European table1
	;let pinsB = %00111010 	; 8 bit, 2 line, 5x8 , English_Russian  table
	;let pinsB = %00111011 	; 8 bit, 2 line, 5x8 , Western_European table2
	
	pulsout enable,1  	; 
		
	let pinsB = %00001100	; Display on, no cursor, no blink
	pulsout enable,1 	

	let pinsB = %00000001 	; Display Clear
	pulsout enable,1
	pause 7			; Allow 6.2ms to clear display

	setfreq m16			; now change to 16Mhz

	let pinsB = %00000010 	; Return Home
	pulsout enable,1

	let pinsB = %00000110 	; Entry Mode, ID=1, SH=0
	pulsout enable, 1

	high rs			; Leave in character mode
	return


; display message from EEPROM sub routine
; message number 0-11 must be in b1 when called
; uses (alters) b1, b2, b3, b4
msg:
	let b2 = b1 // 12 * 20		; EEPROM start address is 0 to 11 multiplied by 20
	let b3 = b2 + 20 - 1 		; end address is start address + (20 - 1)
	for b4 = b2 to b3			; for 20 times
		read b4,b1			; read next character from EEPROM data memory into b1
		let pinsB = b1 		; output the data
		pulsout enable,1  	; pulse the enable pin to send data.
	next b4				; next loop
	return
	

'* note that this code came with the AXE134G OLED display I bought, I modified it to customise the startup message
'* the original code can be found at http://www.picaxe.com/downloads/axe134y.bas.txt
'* the other two programs (the main program and the keyboard program) are original and writen by me
'*they can be found at http://patrickleiser.weebly.com/picaxe-computer.html