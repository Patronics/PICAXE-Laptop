'picaxe laptop demo slot 1      'by Patrick Leiser
#picaxe 28x2
#slot 1

symbol screenspeed=N2400_8       'N2400 at 8 MHz
symbol i2cspeed=i2cfast_8            'i2c 400khz at 8 MHz
'system variables
symbol screenlevel=bit0        'unused scrolling function
symbol tempbit1 =bit1          'temporary bit 1
symbol tempbit2=bit2            'tempoary bit 2
symbol loopcount=b11           ' number of loops in for...next loops
symbol menupage=b21          'which page of menu you are on
'i2c constants
symbol alfat=%10100100       'sd card reader
symbol keyboard=%01010100       'keyboard reading PICAXE 28X2
'keyboard variables
symbol keycheck = b4              'will be one when data is valid, otherwise 0 or 255
symbol keyraw =b5                  'data direcly from keyboard
symbol keyascii = b6                'data from keyboard converted to ASCII
symbol keynum = b7                ' value of number keys 0-9
'wordedit variables
symbol cursorrow = b8             'part of row in wordedit
symbol cursorcol = b9              'part of colum in wordedit
symbol cursorpos = b10           'cursor position for OLED
'
symbol temp1=b14                    'temporary byte (8 bits)1
symbol temp2=b15                    'tempoaray byte 2
symbol tempw1=w7                   'tempoary word (16 bits) 1  (overlaps temp1 and temp2)
symbol temp3=b16                    'tempoary byte 3
symbol temp4=b17                    'tempoary byte 4
symbol tempw2=w8                  'tempoary word 2      (overlaps temp3 and temp4
symbol temp5=b18                   'tempoary byte 5
symbol temp6=b19                    'tempoary byte 6
symbol tempw3=w9                'tempoary word 3      (overlaps temp5 and temp6
symbol charremove=b20             'amount of sd card data to remove eg !00
'symbol charremove1=b24         'single character to remove eg !
symbol pointertrack=w11       'track pointer read loops
symbol first=b24
symbol second=b25

symbol commandpos=b26
symbol com1=b27
symbol com2=b28
symbol com3=b29
symbol prgtempw1=w15'b30&b31
symbol prgtempb1=b32
symbol prgtempb2=b33

main:
menu:             'menu
serout C.1,screenspeed, (254,128)
serout C.1, screenspeed, (254,1)
pause 30
serout C.1,screenspeed, ("1 write program")
serout C.1,screenspeed, (254,192,"2 run program")
serout C.1,screenspeed, (254,148,"3 LED")
serout C.1,screenspeed, (254,212,"4 run program V2")
gosub getakey
branch keynum,(menu,wordeditsetup,sdreadsetup,runled,programstart)'calculatorsetup,countdowntimer)

if keyraw= 118 or keyraw=108 then menu
goto menu



wordeditsetup:
serout C.1, screenspeed, (254,14,254,128,254,1)    'cursor on, top of display, clear display
pause 30
cursorrow=0         'top of display
cursorcol=0          'top of display
wordedit:
	gosub getakey       'get a key from keyboard
		
	select case keyraw     'select raw key value
	case 118                        'esc
		goto menu
	case 108              'home
		cursorrow=255
		cursorcol=0
	case 90                                  'enter
		cursorrow = 21
		@ptrinc=cr
		@ptrinc=lf
	case 102                                 'backspace
		if cursorrow = 0 then
			dec cursorcol
			cursorrow = 20
		endif
		cursorrow=cursorrow-1
		gosub position
			cursorrow=cursorrow-1
		serout C.1,screenspeed, (" ")
	case 13                                       'tab
		cursorrow=cursorrow+2
		serout C.1, screenspeed, ("  ")
		@bptrinc=9         'tab
		@ptrinc=9            'tab
		@bptrinc=0         'null
		@bptr=0              'null
	case 107                                  'left arrow
		if cursorrow = 0 then
			dec cursorcol
			cursorrow = 20
		endif
		cursorrow=cursorrow - 2
	case 116                                  'right arrow
	case 114                                  'down arrow
		inc cursorcol
		dec cursorrow
	case 117                                  'up arrow
		dec cursorcol
		dec cursorrow
	case 124
		serout C.1, screenspeed, (254,128,"print screen")
		goto printscreen
	else
		serout C.1,screenspeed, (keyascii)
		@bptr=keyascii                 'store contents of the screen for ability to save
		@ptrinc=keyascii              'store contents of the screen for abbility to save (work in progress)
	endselect
	
	inc cursorrow
	gosub position
		goto wordedit
position:              'update position of cursor
	if cursorrow >19 then
		inc cursorcol
		cursorrow=0
	endif
		select case cursorcol
		case 1
			cursorpos=192
			'serout C.1, N2400, (254, 192)
			'serout C.1, N2400, ("ln 1")
		case 2
			cursorpos=148
			'serout C.1, N2400, (254, 148)
			'serout C.1,N2400,("ln 2")
		case 3
			cursorpos=212
			'serout C.1,N2400, (254,212) 
			'serout C.1, n2400,("ln 4")
		else
			cursorpos=128
			'serout C.1,N2400,(254,128)
			'serout C.1,N2400,("ln 0")
			cursorcol=0
		endselect
		cursorpos = cursorrow+cursorpos
		bptr=cursorpos
		serout C.1, screenspeed, (254,cursorpos)
		return
	goto wordedit
	
	
printscreen:  ' save the contents of the screen to SD card
hi2cout [alfat],("O 1A>M:\\programs",92)   '92=\      \\=\
serout C.1, screenspeed, (254,128,"name (not full path)")
gosub sdout
pointertrack= ptr

first = pointertrack / 16 + "0"          '4 msb plus ascii "0"
If first > "9" Then                             'if more than "9"
  first = first + 7                              'add seven   (starting "A","B",etc
EndIf

second = pointertrack & $0F + "0"
If second > "9" Then
  second = second + 7
EndIf
hi2cout ("W 1>",first,second,lf)  'write handle 1, pointertrack characters, 
sertxd (#pointertrack)
hi2cin (b12,b12,b12,b12)
for ptr=0 to pointertrack
	
	
	hi2cout (@ptr)
	sertxd (@ptr,#ptr)
	for loopcount = 0 to 14
	hi2cin (b12)
	next loopcount
next ptr
'for bptr=128 to 147         'line 1
'	hi2cout ("W 1>1",lf)  'write handle 1, one character, 
'	hi2cin (b12)
'	serout C.1,screenspeed, (b12) 
'	hi2cin (b12)
'	serout C.1,screenspeed, (b12)
'	hi2cin (b12)
'	serout C.1,screenspeed, (b12)
'	hi2cin (b12)
'	serout C.1,screenspeed, (b12)
'	hi2cout(@bptr)
'	for loopcount = 0 to 14
'	hi2cin (b12)
'	next loopcount
'next bptr
'for bptr=192 to 211       'line 2
'	hi2cout ("W 1>1",lf)
'	hi2cin (b12,b12,b12,b12)
'	hi2cout(@bptr)
'	for loopcount = 0 to 14
'	hi2cin (b12)
'	next loopcount
'next bptr
'for bptr=148 to 167         'line 3
'	hi2cout ("W 1>1",lf)
'	hi2cin (b12,b12,b12,b12)
'	hi2cout(@bptr)
'	for loopcount = 0 to 14
'	hi2cin (b12)
'	next loopcount
'next bptr
'for bptr=212 to 241         'line 4
''	hi2cout ("W 1>1",lf)
'	hi2cin (b12,b12,b12,b12)
'	hi2cout(@bptr)
'	for loopcount = 0 to 14
'	hi2cin (b12)
'	next loopcount
'next bptr

hi2cout ("C 1",lf)
hi2cout ("C 1",lf)
hi2cin (b12,b12,b12,b12)

serout C.1, screenspeed, (254,128,"complete")
gosub getakey
goto wordeditsetup

runled:
pause 30
hi2cout [alfat],("O 0R>M:\\programs\\led.txt",lf)   '\\=\
goto presdread

sdreadsetup:         'read file at path indicated
serout C.1, screenspeed, (254,1)     'clear display
pause 30      'wait for display to clear
serout C.1, screenspeed, (254,128,"full file path",254,192)     'prompt user for full file path
hi2cout [alfat],("O 0R>M:",92)     'open a file in handle 0, read mode with a path starting with M:\
gosub sdout     'gosub sdout   (down two lines)
goto presdread   'goto sdreadsetup2
sdout:    'let the user choose file path
do    'start do loop
gosub getakey     'get a key
select case keyraw       'choose the value of raw key value
case 90
	exit
case 93                       '\
	hi2cout (92)        '\
	serout C.1,screenspeed, (218)
case 74, 76,84,91                   ' ilegal characters
case 118                          'escape or home
	hi2cout (lf)
	pause 50
	hi2cout ("C 0",lf)
	
else
	serout C.1, screenspeed, (keyascii)
	hi2cout (keyascii)
endselect
loop
hi2cout (lf)
return



presdread:          'setup for read
serout C.1,screenspeed, (254,128,254,1)  'clear screen
pause 30  'wait for display to clear
cursorrow=0 'first character of screen
cursorpos=0 'top of screen
gosub position    'update position
sdread:      'read SD card
'inc tempw3
'sertxd (" ",#tempw3," ")
'bug: read stops after 125th character.
'cursorrow=0
'gosub position
'hi2cin (b12,b12,b12)
hi2cout ("R 0",23,">1",lf)                           'read one byte of file     '23=end of transmit block in ASCII
'serout C.1, N2400, (254,128,254,1)    'go to first line
'pause 30
'sertxd ("R")
charactercutoff:                                    'cutoff error/sucess codes
do
hi2cin(b12)             'read a byte
loop until b12="!"       'loop until end of error codes
'sertxd ("1")
'if loopcount >= 4 then
loopcount=loopcount+1 max 5
'goto charactercutoff
if loopcount < 4 then charactercutoff   'loop four times
'endif
if charremove>0 then   'if charremove is more than 0 loop that many times
	dec charremove
	'sertxd ("2")
	goto charactercutoff
'if tempbit1=1 then
'	tempbit1=0
'	goto charactercutoff
endif
'if tempbit1=0 then
'	hi2cin (b12)
'	tempbit1=1
'endif
hi2cin (b12,b12,b12)',b12,b12)',b12)
'sertxd ("L")
'if tempbit2=0 then
'	hi2cin (b12)
'	tempbit2=1
'endif
'serout C.1, N2400, (254,128)       'output to display
'cursorrow=0
'cursorcol=0
'gosub position
do
hi2cin (b12)
sertxd ("select ",#b12," ",b12,lf)
@ptrinc=b12
select case b12
case"$"
	exit
case lf,cr            'enter
	'cursorrow=0
	'inc cursorcol
	'if cursorcol >=4 then sdreadpageend           'end of page
case 23                   'end of transmision
	gosub getakey                      'wait for keypress
	hi2cout ("C 0",lf)                 'close handle 
	goto menu                         'goto menu
'case 9
'	cursorrow=cursorrow+3
'case 7              'bell
	' bell tone
'tune B.6,8,($02,$07)
case 255
	serout C.1, screenspeed,("error")
	gosub getakey
	goto menu
case 65 to 90       'capital letter, comments
'case <31
case 97 to 122
	sertxd ("decode")
	goto commanddecode
case 32
	sertxd ("space")
	goto commandspace
endselect
gosub position
serout C.1, screenspeed, (b12)
'elseif b12=10 then                     'enter
'	inc cursorcol
'	cursorrow=0
'	gosub position
'if b12 <> "$" then
'endif
loop
charremove=1

inc cursorrow
if cursorrow>=20 and cursorcol >=3 then sdreadpageend       'end of page
if cursorcol >= 4 then sdreadpageend            'end of page 
gosub position
'hi2cin (b12,b12,b12,b12)	
goto sdread
sdreadpageend:                'end of page
do
gosub getakey
if keyraw=90 then                      'if key is enter then
	tempbit1=1
	'charremove=charremove+1
	tempbit2=1
	cursorrow = 0   'top of display
	cursorcol = 0    'top of display
	gosub position   ' update position
	goto presdread                   'goto next page
elseif keyraw=125 then
	hi2cout ("P 0>0",lf)
	goto presdread
'elseif keynum<10 then
	'keynum=keynum*50
	'gosub pageselect
'	hi2cout ("P 0>",#b7,lf)
'	tempbit1=1
	'charremove=1
	'tempbit2=1
'	goto presdread
elseif keyraw=118 then     'escape or
	hi2cout ("C 0",lf)
	hi2cin (b12,b12,b12,b12)
	'for loopcount= 0 to 17
	'hi2cin (b12)
	'next loopcount
	goto menu
endif
loop
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
commanddecode:
inc commandpos
select case commandpos
case 1
	com1=b12
case 2
	com2=b12
case 3
	com3=b12
endselect
hi2cin (b12,b12,b12,b12)
goto sdread
commandspace:
sertxd (com1,com2,com3)
if com1="l" and com2="e" and com3="d" then ledtoggle    'toggle  LED
'if com1="p"and com2="
goto sdread

programstart:
serout C.1,screenspeed,(254,128,254,1)
pause 30
ptr=0
readcommand:    'commanddecode replacement
gosub checkforkey
if keyraw=118 then  main  'escape
'sertxd (@ptr,"CR")
if @ptr=0 then main
if @ptrinc<>CR then readcommand      'check for carrage return
'sertxd (@ptr,"LF")
if @ptrinc<>LF then readcommand      'check for linefeed
'sertxd(@ptr)
   '@ptrinc increments for each step of select case, so have to increment manually
select case @ptr
case "l","L"
	goto command_L
case "p","P"
	goto command_P
endselect
goto readcommand
	command_L:
	'sertxd(#ptr,@ptr,"command_L")
	inc ptr
	select case @ptr
	case"e","E"
		goto command_LE
	endselect
	goto readcommand
		command_LE:
		'sertxd(#ptr,@ptr,"command_LE")
		inc ptr
		select case @ptr
		case"d","D"
			goto LEDtoggle2
		endselect
		goto readcommand
	command_P:
	inc ptr
	sertxd("command_P")
	select case @ptr
	case"r","R"
		goto command_PR
	case "a","A"
		goto command_PA
	endselect
	goto readcommand
	
		command_PA:
		inc ptr
		sertxd("command_P")
		select case @ptr
		case "u","U"
			goto command_PAU
		endselect
		goto readcommand
			
			command_PAU:
			inc ptr
			sertxd("command_P")
			select case @ptr
			case "s","S"
				goto command_PAUS
			endselect
			goto readcommand
			
				command_PAUS:
				inc ptr
				sertxd("command_P")
				select case @ptr
				case "e","E"
					goto pause_
				endselect
				goto readcommand
				
		command_PR:
		inc ptr
		select case @ptr
		case "i","I"
			goto command_PRI
		endselect
		goto readcommand
		
			command_PRI:
			inc ptr
			select case @ptr
			case "n","N"
				goto command_PRIN
			endselect
			goto readcommand
				
				command_PRIN:
				inc ptr
				select case @ptr
				case "t","T"
					goto print:
				endselect
				goto readcommand
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
ledtoggle2:          'replacement for ledtoggle
'sertxd(@ptr,"LED toggle")
toggle B.7
'gosub getakey
goto readcommand

print:                            'print to screen
inc ptr
if @ptr=cr or @ptr=0 then readcommand
serout C.1,screenspeed,(@ptrinc)
goto print

pause_:
sertxd("pause")
	prgtempw1=0
	inc ptr
	pause_loop:
	'prgtempw1=prgtempw1*10
	inc ptr
	if @ptr>="0" and @ptr<="9" then                      'if @ptr is a number
		prgtempb1=@ptr-"0"                                  'convert ascii to number
		prgtempw1=prgtempw1*10+prgtempb1
		goto pause_loop 
	'else goto pause_num       'implied, next in code
	endif   '    
	'select case @ptr     'numbers or significant commands
	'case "0"
	'	prgtempw1=prgtempw1*10'+0 implied
	'case "1"
	'	prgtempw1=prgtempw1*10+1
	'case "2"
	'	prgtempw1=prgtempw1*10+2
	'case "3"
	'	prgtempw1=prgtempw1*10+3
	'case "4"
	'	prgtempw1=prgtempw1*10+4
	'case "5"
	'	prgtempw1=prgtempw1*10+5
	'case "6"
	'	prgtempw1=prgtempw1*10+6
	'case "7"
	'	prgtempw1=prgtempw1*10+7
	'case "8"
	'	prgtempw1=prgtempw1*10+8
	'case "9"
	'	prgtempw1=prgtempw1*10+9
	'else 
	'	goto pause_num
	'endselect
	'goto pause_loop
pause_num:
sertxd("pausing",#prgtempw1,"ms")
pause prgtempw1
goto readcommand



ledtoggle:     'obsolete
'serout C.1,screenspeed,("led toggled")
toggle B.7
gosub getakey
hi2cout ("C 0",lf)                 'close handle
goto main


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
checkforkey:                             'check for a key, return even if no key pressed
'hi2csetup i2cmaster,%01010100,i2cfast,i2cbyte  'setup i2c master with keyboard slave
hi2cin [keyboard],0,(keycheck,keyraw,keyascii,keynum)

	if keycheck<>1 then 
		keyraw=0
		keyascii=0
		keynum= 10
	else
		hi2cout 0,(2)
	endif				

hi2csetup i2cmaster, alfat, i2cspeed, i2cbyte
return
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
getakey:                         'key detecting subroutine
	'hi2csetup i2cmaster,%01010100,i2cfast,i2cbyte  'setup i2c master with keyboard slave
'	sertxd("&")
	hi2cin [keyboard],0,(keycheck,keyraw,keyascii,keynum)    'get keyboard data formatted by keyboard processor
	'sertxd(#b23,",",#b24,cr,lf)
	if keycheck<> 1 then 'if ready byte is not equal to 1
		'keyraw = 0
'		sertxd ("#",#keycheck)
		pause 70   'pause 70 ms
		goto getakey     'loop
	else
		'sertxd ("got a key")
'		sertxd("+")
		hi2cout 0,(2)    'reset keyboard status byte
	endif
'	if keynum=11 then powersaversetup
'sertxd( "$")
hi2csetup i2cmaster, alfat, i2cspeed, i2cbyte      'setup i2c for SD card reader
'sertxd("-")
	return      'return to subroutine call