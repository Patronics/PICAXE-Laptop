'picaxe laptop demo program slot 0        'by Patrick Leiser
'© Patrick Leiser Feel free to use this program, but leave this copyright message intact.
#picaxe 28x2
#slot 0
#revision 4
'pinout
'                       _________
'              reset | rst  B.7 |  LED (red)
'                       | A.0  B.6|  Speakers
'                       | A.1  B.5|
'                       | A.2  B.4|
'                       | A.3  B.3|
'              serin  |serin B.2|  keyboard wakeup (currently unused)
'            serout |A.4   B.1|
'                  0V | 0V   B.0|
'                       | res   +V|    +5V
'                       | res  0V |       0V
'  SD card busy | C.0  C.7|
'   OLED serout | C.1  C.6|
'                       | C.2  C.5|
'               hi2c | C.3  C.4|  hi2c (keyboard and SD card)
'                       _________
#define 8mhz       'clock frequency is 8mhz
'#define 16mhz      'too fast for display, overclock display to 32 Mhz?
#ifdef 8mhz
setfreq m8      'set clock frequency to 8MHz
symbol screenspeed=N2400_8       'N2400 at 8 MHz
symbol i2cspeed=i2cfast_8            'i2c 400khz at 8 MHz
#endif
#ifdef 16mhz
setfreq m16     'set clock frequency to 16 MHz     
symbol screenspeed=N2400_16        'N2400 at 16 MHz
symbol i2cspeed=i2cfast_16               'i2c 400khz at 16 MHz
#endif
'i2c constants
symbol alfat=%10100100       'sd card reader
symbol keyboard=%01010100       'keyboard reading PICAXE 28X2
'system variables
symbol screenlevel=bit0        'unused scrolling function
symbol tempbit1 =bit1          'temporary bit 1
symbol tempbit2=bit2            'tempoary bit 2
symbol loopcount=b11           ' number of loops in for...next loops
symbol menupage=b21          'which page of menu you are on
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
'game variables
'symbol guesscount = b11
'symbol hitcount = b0
'symbol gamerandom = b12
'symbol gamerandom2 =b13
'symbol gamerandom3 =b14
'symbol gamerandom4 =b15
'symbol gamerandom5 =b16
'symbol gamerandom6 =b17
'symbol gamerandom7 =b18
'symbol gamerandom8 =b19


'math variables
'symbol math1=w3 'b4/b5
'symbol mathone=w3 'b4/b5
'symbol math2=w4 'b6/b7
'symbol mathtwo=w4 'b6/b7
'symbol mathresult=w6'b8/b9
'startup


if pinC.4=0 then                           ' if i2c read/write in progress
	for loopcount = 0 to 15
		toggle C.3                       'clear i2c bus read/write
		pause 30
		if pinC.4=1 then exit
	next loopcount
endif
hi2csetup i2cmaster,alfat,i2cspeed,i2cbyte     'setup i2c comunication for SD card reader
'pause 200
hi2cout ("I M:",lf)     'initalise sd card

setup:
hi2cin (b12)
if b12=255 then setup2
if b12 <> "!" then setup
hi2cin (b12,b12,b12)

hi2cout ("I M:",lf)
setup2:
#ifdef 8mhz
'pause 600
tune B.6,4,($40,$42,$44,$45,$47,$02,$49)      'startup chime
#endif
#ifdef 16mhz
tune B.6,8,($40,$42,$44,$45,$47,$02,$49)      'startup chime
#endif
serout C.1, screenspeed, (254,128,254,1)'clear display

'read voltage
'CalibAdc10 tempw1      'read voltage of internal fixed voltage reference
gosub getvolts
'tempw1 = 10476 / tempw1      'convert to volts
if tempw1<38 then
	gosub powerdisplay
	sound B.6, (50,50,100,50)
	gosub getakey
endif
#ifdef 8mhz
pause 30               'pause 30  ms
#endif
#ifdef 16mhz
pause 70
#endif

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'menus
main:
'clearvar:
'for bptr=5 to 255
'	@bptr=0
'next bptr
menu:        'main menu
serout C.1,screenspeed, (254,128,254,1)     'clear display
	pause 30
select case menupage    'select page
case 0    'first page
	serout C.1,screenspeed, ("1 Utilities",254,192,"2 Tests",254,148,"3 SD card",254,212,"4 run",180)    'menu display
	'serout C.1,N2400,(254,192,"2 Tests")

	'serout C.1,N2400,(254,148,"3 SD card")
	'serout C.1,N2400,(254,148,"3 games")
	'serout C.1,N2400, (254,212,"4 favorites  ",180)
	'serout C.1,N2400, (254,212,"4 other")
	'serout C.1,N2400,(254,212,"4 calculator")
case 1    '2nd page
	serout C.1,screenspeed,("5 other")
else 
	menupage=0
	goto menu
endselect
gosub getakey
branch keynum, (menu,utilitymenu, testmenu,gamemenu,favoritesmenu,othermenu)          'go to menu item selected by key on keyboard
'if keynum = 10 then
	select case keyraw     'shortcut keys
	case 29         'w
		goto wordeditsetup
	case 45          'r
		goto sdreadsetup
	case 75          'l
		goto sdinitalizelist
	case 33          'c
		goto calculatorsetup
	endselect
'endif
if keyraw=90 or keyraw= 114 then
	inc menupage
elseif keyraw=102 or keyraw=117 then
	dec menupage
endif
goto menu

utilitymenu:             'utility menu
serout C.1,screenspeed, (254,128)
serout C.1, screenspeed, (254,1)
pause 30
serout C.1,screenspeed, ("1 Wordedit")
serout C.1,screenspeed, (254,192,"2 calculator")
serout C.1,screenspeed, (254,148,"3 Timer")
'serout C.1,N2400,(254,148,"3 ")

'serout C.1,N2400,(254,212,"4 ")

gosub getakey
branch keynum,(menu,wordeditsetup,calculatorsetup,countdowntimer)

if keyraw= 118 or keyraw=108 then menu
goto utilitymenu


testmenu:            'test menu
serout C.1,screenspeed, (254,128)
serout C.1, screenspeed, (254,1)
pause 30
serout C.1,screenspeed, ("1 list characters")
serout C.1,screenspeed,(254,192,"2 Keyboard to screen")
serout C.1,screenspeed,(254,148,"3 read power supply")
serout C.1,screenspeed,(254,212,"4 System info")
'serout C.1,N2400, (254,212,"4 SD card read")
'serout C.1,N2400,(254,212,"4 calculator")

gosub getakey
branch keynum,(menu,listcharacters,keyboardtoscreen,readpower,sysinfo)',gettime)

if keyraw=118 or keyraw=108 then menu
goto testmenu

sdmenu:
gamemenu:   'sd card menu, used to be game menu
'run 1
serout C.1,N2400, (254,128,254,1)
select case menupage
case 0
serout C.1, screenspeed, ("1 read sdcard")
serout C.1, screenspeed, (254,192,"2 about PLOS")
serout C.1, screenspeed, (254,148,"3 add to visitor log")
serout C.1, screenspeed, (254,212,"4 view visitor log ",180)  '180=arrow
'serout C.1,N2400, ("no games, press esc")
'serout C.1,N2400,(254,192,"- subtraction")
'serout C.1,N2400,(254,148,"* multiplication")
'serout C.1,N2400,(254,212,"/ division")
                                                                                                                                
case 1
	serout C.1, screenspeed, ("5 list sd files") 
	serout C.1, screenspeed, (254,192,"6 tutorial")
else
	menupage=0
	goto gamemenu
endselect
gosub getakey
branch keynum, (menu,sdreadsetup,sdaboutsetup,visitorlogappend,visitorlogreadsetup,sdinitalizelist,tutorialsetup)
if keyraw =118 or keyraw=108 then menu
if keyraw=90 or keyraw= 114 then
	inc menupage
elseif keyraw=102 or keyraw= 117 then
	dec menupage
endif
	
goto sdmenu

favoritesmenu:                      'run menu
serout C.1,screenspeed, (254,128,254,1)
pause 30
serout C.1,screenspeed, ("choose slot number")

gosub getakey
select case keynum
case 0
	run 0          'main program, this one
case 1
	run 1
case 2
	run 2
case 3
	run 3
endselect

if keyraw = 118 or keyraw =108 then menu
goto favoritesmenu

othermenu:
serout C.1,screenspeed, (254,128)
serout C.1, screenspeed, (254,1)
pause 30
serout C.1,screenspeed, ("1 star animation")

gosub getakey
branch keynum, (menu,staranimatesetup)

if keyraw = 118 or keyraw =108 then menu
goto othermenu
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'sub program 1: wordedit
'a text editor like pages or word
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
hi2cout [alfat],("O 1A>M:\\screenshots",92)   '92=\      \\=\
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
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'sub program 2: keyboard to screen
keyboardtoscreen:     'show information about key on screen
	gosub getakey    'read a key
	serout C.1,screenspeed, (254,128,254,1)   'clear screen
	serout C.1,screenspeed, (#keyraw," ",keyascii," ",#keyascii," ",#keynum)   'display information about key
	if keyraw = 118 then    'if escape
		#ifdef 8mhz
		pause 1000      'pause a second
		#endif
		#ifdef 16mhz
		pause 2000           '1 sec
		#endif
		goto menu       'go to menu
	endif	
	goto keyboardtoscreen   'loop
	
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'sub program 3: list characters
listcharacters:      'list caracters avaiable for display
serout C.1,screenspeed,(254,128) ; move to start of first line
for temp1 = 0 to 252     'all characters, no commands
	serout C.1,screenspeed,(temp1," ")  'display character and space
	inc cursorrow   'next position on display
	gosub position
	gosub checkforkey    'check if esc has been pressed
	if  keyraw= 118 then menu
next temp1
	
goto listcharacters

'gettime:    'unused routine to retrive time
'serout C.1, screenspeed, (254,128,254,1)
'pause 30
'hi2cout ("G D",lf)
'for loopcount =0 to 11
'	hi2cin (b12)
'	serout C.1, screenspeed, (b12)
'next loopcount
'serout C.1, screenspeed, (254,192)
'hi2cout ("G T",lf)
'for loopcount =0 to 8
'	hi2cin (b12)
'	serout C.1, screenspeed, (b12)
'next loopcount
'gosub getakey
'goto menu
'settime:
'hi2cout ("T B",lf)
'hi2cin (b12,b12,b12,b12)
'pause 200
'hi2cout ("S 42566DA0",lf)
'hi2cin (b12,b12,b12,b12)
'goto menu
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'voltage reader
readpower:
serout C.1,screenspeed, (254,128,254,1)  'clear display
pause 30
gosub getvolts
gosub powerdisplay
gosub getakey
goto main
getvolts:
CalibAdc10 tempw1
tempw1 = 10476 / tempw1
bintoascii tempw1,temp3,temp3,temp4           'lower byte of temp w1
return
powerdisplay:
'tempw1 = 52377 /tempw1 * 2
'serout C.1,screenspeed, (#tempw1)
serout C.1, screenspeed, ("power=",temp3,".",temp4," V")
serout C.1, screenspeed, (254,192,"full charge=4.5 V")
return
'gosub getakey
'goto main
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
sdaboutsetup:
pause 30
hi2cout [alfat],("O 0R>M:\\system\\about.txt",lf)        '\\= \
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
select case b12
case"$"
	exit
case lf,cr            'enter
	cursorrow=0
	inc cursorcol
	if cursorcol >=4 then sdreadpageend           'end of page
case 23                   'end of transmision
	gosub getakey                      'wait for keypress
	hi2cout ("C 0",lf)                 'close handle 
	goto menu                         'goto menu
case 9
	cursorrow=cursorrow+3
case 7              'bell
	' bell tone
tune B.6,8,($02,$07)
case 255
	serout C.1, screenspeed,("error")
	gosub getakey
	goto menu
case <31
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


visitorlogappend:         'add to visitor log
serout C.1, screenspeed,(254,1)         'clear screen
pause 30'wait for screen to clear
do
'	pause 100
loop until pinC.0=0       'wait for buisy pin to go low
hi2cout [alfat],("O 1A>M:\\data\\visitor log.txt",lf)'open M:data\visitor log.txt in write mode file handle 1
hi2cin (b12,b12,b12,b12)  'read error code
serout C.1, screenspeed, (254,128,"initials?")    'prompt user for initials
gosub getakey     'get a key
serout C.1, screenspeed,(254,148,keyascii,".")       'display key
b13=keyascii      'store data in b13
gosub getakey     'get a key
serout C.1, screenspeed,(keyascii,".")  'display key
do
'pause 100
loop until pinC.0=0      'wait until busy bin is low
hi2cout ("W 1>5",lf)      'write handle 1, five characters
'pause 10
for loopcount=0 to 19       'repeat 20 times
hi2cin (b12)      'read a character
serout C.1, screenspeed, (b12)     'output to screen
inc cursorrow    'move cursor
gosub position     'update cursor position
next loopcount
'pause 1000
hi2cout (b13,".",keyascii,". ")       'write initials to SD card
serout C.1,screenspeed, (254,192)       'begining of display
'pause 1000
hi2cout ("C 1",lf)       'close file handle
pause 100
for loopcount=0 to 26     'repeat 27 times
hi2cin (b12)     'read character
serout C.1, screenspeed, (b12)      'output to display
'sertxd("3")
next loopcount   'repeat
serout C.1, screenspeed, ("complete")     'output to display "complete"
pause 1000   'pause a second
'toggle b.7
goto menu    'goto main menu


visitorlogreadsetup:     'read visitor log
'pause 30
hi2cout [alfat],("O 0R>M:\\data\\visitor log.txt",lf)      'open file on handle 0, read mode, path M:\data\visitor log.txt
'pause 500
goto presdread    'setup for sd card read

tutorialsetup:    'read tutorial
'pause 30
hi2cout [alfat],("O 0R>M:\\system\\tutorial.txt",lf)    'open handle 0, read mode, file path M:\system\tutorial.txt
'pause 500
goto presdread    'setup for sd card read

sdinitalizelist:     'initalize list of files
serout C.1, screenspeed, (254,128,254,1)      ' top of display, clear display
temp1=0
ptr=0
loopcount=0
tempbit1=0
pause 30
cursorrow=0
cursorcol=0
hi2cout [alfat],("@ M:",92)
hi2cin (b12,b12,b12)
serout C.1, screenspeed, ("file path:",254,192)
gosub sdout
serout C.1, screenspeed, (254,148,"press any key for",254,212,"manual mode")
for loopcount=0 to 3
pause 500
gosub checkforkey
if keyraw<> 0 then    'if key is pressed
	tempbit1=1
	exit
next loopcount
endif
listfiles:
serout C.1, screenspeed, (254,1)    'clear display
cursorrow=0
cursorcol=0
gosub position
hi2cout ("N",lf)
hi2cin (b12,b12,loopcount)
if b12="0" and loopcount="4" then    'if end of menu
	hi2cin (b12)
	goto menu
endif
loopcount=0
hi2cin (b12)
do
hi2cin (b12)
if b12= lf then    'next data field
	inc cursorcol
	cursorrow=0
	inc loopcount
	
endif
'if loopcount >1 then' and loopcount <4 then
if b12<> "!" then         'if not end of command
	serout C.1, screenspeed, (b12)     'output to display data recived
	if cursorcol=0 then
		@ptr=b12'inc=b12
		sertxd (@ptrinc)
	endif
	inc cursorrow
	gosub position
else
	hi2cin (b12,b12,b12)
	cursorrow=0
	cursorcol=0
	gosub position
	if tempbit1=0 then    'if automatic mode
		#ifdef 8mhz
		pause 1000   'pause 1 second
		#endif
		#ifdef 16mhz
		pause 2000    '1000 at 16 mhz
		#endif
		gosub checkforkey
		if keyraw=90 then        'enter
	ptr=0
	hi2cout [alfat],("O 0R>M:",92)     'open a file in handle 0, read mode with a path starting with M:\
	do
		if @ptr=0 then
			exit
		endif
		hi2cout (@ptrinc)
	loop
	hi2cout (lf)
	goto presdread
endif
		if keyraw=118 then menu
		goto listfiles
	endif
	gosub getakey
	if keyraw=90 then        'enter
	ptr=0
	hi2cout [alfat],("O 0R>M:",92)     'open a file in handle 0, read mode with a path starting with M:\
	do
		if @ptr=0 then
			exit
		endif
		sertxd (@ptr)
		hi2cout (@ptrinc)
	loop
	hi2cout (lf)
	goto presdread
endif
	if keyraw= 118 then menu
	'pause 1000
	'sertxd ("@")
	goto listfiles
endif
if loopcount=4 then
	exit
endif
loop
gosub getakey

	
if keyraw= 118 then menu    'if esc goto menu
'sertxd ("!")
goto listfiles    'repeat

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'calculator
calculatorsetup:
tempw1=0    'clear variables
tempw2=0    'clear variables
serout C.1, screenspeed, (254,128,254,14,254,1)   'top of display, cursor on, clear display
pause 30
calculatoroperand1:
gosub getakey    'get a key
if keynum>= 10 and keyraw<> 90 and keyraw<>118 then 'not number, not enter, not escape
	'serout C.1,screenspeed, ("other")
	goto calculatoroperand1

elseif keyraw= 118 then       'esc
	goto menu
elseif keyraw= 90 then      'enter
	goto calculatoroperator    'select operator (*+/- ect)
'elseif keyraw=102 then     'backspace
'	tempw1=tempw1/10       'remove character
'	serout C.1,screenspeed, (254,128,#tempw1," ")
'	goto calculatoroperand1
else
	tempw1=tempw1*10     'shift left allowing for another digit
	tempw1=tempw1+keynum      'add new digit
	serout C.1, screenspeed, (254,128,#tempw1)     'display first operand
	goto calculatoroperand1      'recive next digit
endif
calculatoroperator:       'select operator (+-*/ ect)
serout C.1, screenspeed, (254,192)', "op")
gosub getakey
select case keyraw
case 85   '+      add
	temp5=0
	serout C.1,screenspeed, ("+")
case 78    '-    
	temp5=1
	serout C.1,screenspeed, ("-")
case 62    '*    multiply
	temp5=2
	serout C.1,screenspeed, ("*")
case 74     '/    divide
	temp5=3
	serout C.1,screenspeed, ("/")
case 54     '^  square root
	temp5=4
	serout C.1,screenspeed, ("square root")
	goto calculate      'unary operator, skip reciving second value
case 45      'r random
	temp5=5
	goto calculate
case 118     'esc
	goto menu
else
	goto calculatoroperator
endselect
calculatoroperand2:
serout C.1,screenspeed, (254,148)
gosub getakey
if keynum>= 10 and keyraw<> 90 and keyraw<>118 then 'not number, not enter
	goto calculatoroperand2
elseif keyraw= 118 then
	goto menu
elseif keyraw= 90 then
	'serout C.1, screenspeed, ("enter")
	goto calculate
'elseif keyraw=102 then
'	tempw2=tempw2/10
'	serout C.1,screenspeed, (254,148,#tempw2," ")
'	goto calculatoroperand2
else
	tempw2=tempw2*10
	tempw2=tempw2+keynum
	serout C.1, screenspeed, (254,148,#tempw2)
	goto calculatoroperand2
endif
goto calculatoroperand2
calculate:
select case temp5
case 0
	let tempw1=tempw1+tempw2
'	serout C.1,screenspeed, ("+")
case 1
	let tempw1=tempw1-tempw2
'	serout C.1,screenspeed, ("-")
case 2
	let tempw1=tempw1*tempw2
'	serout C.1,screenspeed, ("*")
case 3
	let tempw1=tempw1/tempw2
'	serout C.1,screenspeed, ("/")
case 4
	let tempw1= SQR tempw1
case 5
	if tempw1=0 then
	touch16 0, temp1
	touch16 0, temp2
	endif
	random tempw1
'else
'	 serout C.1, screenspeed, ("error")
endselect
serout C.1,screenspeed, (254,212,#tempw1)',254,192,#tempw1)
do
	gosub getakey
	if keyraw=90 then
		serout C.1, screenspeed, (254,1)
		pause 30
		serout C.1, screenspeed, (254,128,#tempw1)
		tempw2=0
		goto calculatoroperator
	elseif keyraw=118 then
		goto menu
	elseif keyraw=102 then
		goto calculatorsetup
	endif
loop

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
countdowntimer:     'countdown timer      runs in background, can have other active applications running
if timer <> 0 then timerdisplay
serout C.1,screenspeed, (254,1,"seconds?")
tempw1=0
seconds:
gosub getakey
if keynum>= 10 and keyraw<> 90 and keyraw<>118 then 'not number, not enter, not escape
	'serout C.1,screenspeed, ("other")
	goto seconds
elseif keyraw= 118 then       'esc
	goto menu
elseif keyraw= 90 then      'enter
goto countdownstart	
'elseif keyraw=102 then     'backspace
'	tempw1=tempw1/10       'remove character
'	serout C.1,screenspeed, (254,128,#tempw1," ")
'	goto calculatoroperand1
else
	tempw1=tempw1*10     'shift left allowing for another digit
	tempw1=tempw1+keynum      'add new digit
	serout C.1, screenspeed, (254,128,#tempw1)     'display first operand
	goto seconds      'recive next digit
endif

countdownstart:
timer=65535-tempw1
'serout C.1,screenspeed, ("timer=",#timer)
settimer t1s_8
flags=0
setintflags %10000000,%10000000
'serout C.1,screenspeed,("timer set")
'gosub getakey
goto timerdisplay

interrupt:
settimer off
timer=0
do
sound B.6, (100,100,50,100,100,100,150,100)
gosub checkforkey
if keycheck=1 then
	exit
endif
loop
return

timerdisplay:
tempw1=65535-timer
serout C.1,screenspeed, (254,128,#tempw1)
pause 1000
serout C.1, screenspeed,(254,1)
gosub checkforkey
if keyraw=118 then main
goto timerdisplay
'guesslocation:      'inefficeint and complicated, may come back to later
'	serout C.1, N2400, (254,14,254,128)
'	gosub getakey
		
'	readadc 17,gamerandom
'	readadc 17,gamerandom2
'	readadc 17,gamerandom3
'	readadc 17,gamerandom4
	
'guesslocation1:
'	random gamerandom
'	serout C.1, N2400, ("1")
'	select case gamerandom
'	case <128
	'	goto guesslocation1
	'case <168
'		goto  guesslocation2
'	case <192
'		goto guesslocation1
'	case <232
'		goto guesslocation2
'	else
'		goto guesslocation1
	'endselect
	
'guesslocation2:
'	random gamerandom2
'	serout C.1, N2400, ("2")
'	select case gamerandom2
'	case <148
'		goto guesslocation2
'	case <168
'		goto  guesslocation3
'	case <192
'		goto guesslocation2
'	case <232
'		goto guesslocation3
'	else
'		goto guesslocation2
'	endselect
'		
'guesslocation3:
'	random gamerandom3
'	serout C.1, N2400, ("3")
'	select case gamerandom3
'	case <148
'		goto guesslocation3
'	case <168
'		goto  guesslocation4
'	case <192
'		goto guesslocation3
'	case <232
'		goto guesslocation4
'	else
'		goto guesslocation3
'	endselect
'	
'guesslocation4:
'	random gamerandom4
'	serout C.1, N2400, ("4")
'	select case gamerandom4
'	case <148
'		goto guesslocation4
'	case <168
'		goto  guesslocationplay
'	case <192
'		goto guesslocation4
'	case <232
'		goto guesslocationplay
'	else
'		goto guesslocation4
'	endselect
	
'guesslocationplay:
'	if hitcount= 15 then
''	serout C.1,N2400,(254,128,"You win!",254,192,"it took ",#guesscount,"guesses")
'	goto gamemenu
'	endif
'	gosub getakey
'	select case keyraw
'		case 118                        'esc or home
'		serout C.1, N2400, (254,1)
'		pause 30
'		goto gamemenu
'	case 90                                  'enter
'		goto locationcheck
'	case 107                                  'left arrow
'		if cursorrow = 0 then
'			dec cursorcol
'			cursorrow = 20
'		endif
'		cursorrow=cursorrow - 1
'	case 116                                  'right arrow
'		inc cursorrow
'	case 114                                  'down arrow
'		inc cursorcol
'		'dec cursorrow
'	case 117                                  'up arrow
'		dec cursorcol
'		'dec cursorrow
'	endselect
'	gosub position
'		inc guesscount
'	goto guesslocationplay
'	
'locationcheck:
'	gosub position
'		select case cursorpos
'		case gamerandom
'			serout C.1, N2400, ("X")
'			bit8=1
'			goto guesslocationplay
'		case gamerandom2
'			serout C.1, N2400, ("X")
'			bit9=1
'			goto guesslocationplay
'		case gamerandom3
'			serout C.1, N2400, ("X")
''			bit10=1
'			goto guesslocationplay
'		case gamerandom4
'			serout C.1, N2400, ("X")
'			bit11=1
'			goto guesslocationplay
'		else
'			serout C.1, N2400, ("O")
'			inc cursorrow
'			goto guesslocationplay
'		endselect
'		goto guesslocationplay

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
sysinfo:     'system info
serout C.1, screenspeed, (254,128,254,1)
pause 30
readrevision temp1
serout C.1, screenspeed, ("Revision #",#temp1)
readfirmware temp1
serout C.1, screenspeed, (254,192,"Firmware #",#temp1)
readsilicon temp1
serout C.1, screenspeed, (254,148,"Silicon #",#temp1)
'readinternaltemp IT_4V5, 0 ,temp1         'M2 only, not X2
'serout C.1, screenspeed, (254,148,"CPU temp",#temp1)
gosub getakey
goto menu
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
staranimatesetup:     'star animation
serout C.1, screenspeed, (254,14)   'turn on cursor
'staranimate:
do
serout C.1, screenspeed, (" ")
inc cursorrow
gosub position
gosub checkforkey
if keyraw = 118 then
	exit
endif
loop
goto menu
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
#rem                                           'inefficient and complicated, may come back to later
calculatormenu:
serout C.1,N2400, (254,128)
serout C.1, N2400, (254,1)
pause 30
serout C.1,N2400, ("+ addition")
serout C.1,N2400,(254,192,"- subtraction")
serout C.1,N2400,(254,148,"* multiplication")
serout C.1,N2400,(254,212,"/ division")
gosub getakey
select case keyraw
case  121                           '+
	serout C.1, N2400, (254,1)
	pause 30
	goto add
case 123                            '-
	serout C.1, N2400, (254,1)
	pause 30
	goto subtract
case 124                          '*
	serout C.1, N2400, (254,1)
	pause 30
	goto multiply
case 74
	serout C.1, N2400, (254,1)
	pause 30
	goto divide
case 118
	goto menu
else
	 goto calculatormenu
endselect
add:
	gosub getakey
		if math1<6500 then
		math1=math1*10
		select case keyraw
		case 22
			math1=math1+1
		case 30
			math1=math1+2
		case 38
			math1=math1+3
		case 37
			math1=math1+4
		case 46
			math1=math1+5
		case 54
			math1=math1+6
		case 61
			math1=math1+7
		case 62
			math1=math1+8
		case 70 
			math1=math1+9
		case 69
		endselect
		else goto add
		endif
		
subtract:
multiply:
divide:
goto calculatormenu
#endrem

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
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'go to power saving mode   
'powersaversetup:       'unused power saving routine
'gosub scrollright
'powersaver:
'serout C.1, screenspeed, ("sleeping")
'hintsetup %01000100
'sleep 14                                  '65535 =~38 hours
'high b.7
'pause 250
'low b.7
'if pinB.2=0 then powersaver
'serout C.1,screenspeed,("awake")
'pause 100
'gosub scrollleft
'return
'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'scrollright:       'unused scrolling routines
'if screenlevel=0 then
'for loopcount=0 to 19
'	serout C.1,screenspeed,(254,24,254,168)
'next loopcount
'screenlevel=1
'endif
'return

'scrollleft:        'unused scrolling routine
'if screenlevel=1 then
'for loopcount=0 to 19
'	serout C.1,screenspeed,(254,28)
'next loopcount
'screenlevel=0
'endif
'return

'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'pageselect:       'unused sd card page selecting routine
'select case keynum
'case 0
'	temp1="0"
'	temp2="0"
'	'temp3="0"
'case 1
'	temp1="0"
'	temp2="5"
'	'temp3="0"
'case 2
'	temp1="0"
'	temp2="A"
'	'temp3="0"
'case 3
'	temp1="0"
'	temp2="F"
'	'temp3="0"
'case 4
'	temp1="1"
'	temp2="4"
'	'temp3="0"
''case 5
'	temp1="1"
'	temp2="9"
'	'temp3="0"
'case 6
'	temp1="1"
'	temp2="E"
'	'temp3="0"
'case 7
'	temp1="2"
'	temp2="3"
'	'temp3="0"
'case 8
'	temp1="2"
'	temp2="8"
'	'temp3="0"
'case 9
'	temp1="2"
'	temp2="D"
	'temp3="0"
'endselect
'return
#ifdef 8mhz
#ifdef 16mhz
#error "both 8 and 16 mhz defined"     'if both clock frequencys defined create error message
#endif
#endif

#ifndef 8mhz
#ifndef 16mhz
#error "frequency not defined"       'if neither clock frequency defined create error message
#endif
#endif