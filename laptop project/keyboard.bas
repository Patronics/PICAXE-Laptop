'keyboard.bas   keyboard monitering program for PLOS laptop         by Patrick Leiser
'© (c) Patrick Leiser.    Feel free to use this program, but leave this copyright message intact.
'i2c scratchpad locations:
'0: keycheck
'1: keyraw
'2: keyascii
'3:keynum
#picaxe 28x2
symbol shift=bit0
symbol caps=bit1
symbol keyheld=bit2
symbol keyraw=b5
symbol keycheck=b1
symbol keyascii=b2
symbol keynum=b3
symbol powerstate=b4
symbol repeatkey=b6
symbol loopcount=w4
EEPROM $00,("?9?5312C?A864?~?")	' Function keys
EEPROM $10,("?????Q!???ZSAW@?")	' Main keyboard keys
EEPROM $20,("?CXDE$#?? VFTR%?")
EEPROM $30,("?NBHGY^???MJU&*?")
EEPROM $40,("?<KIO)(??>?L:P_?")
EEPROM $50,("??",34,"?{+????",181,"}?|?") '"??'?[=?????]???")      '\\=\    34="
EEPROM $60,("?",218,"????",127,"??1?",127,"7???")	' Numeric keypad keys
EEPROM $70,("0.",180,"5",126,179,"??B+3-*9??")'     * = print screen	
   TABLE $00,("?9?5312C?a864?'?")	' Function keys
   TABLE $10,("?????q1???zsaw2?")	' Main keyboard keys
   TABLE $20,("?cxde43?? vftr5?")
   TABLE $30,("?nbhgy6???mju78?")
   TABLE $40,("?,kio09??./l;p-?")
   TABLE $50,("??'?[=????",181,"]?",92,"?") '"??'?[=?????]???")      '\\=\
   TABLE $60,("?",218,"????",127,"??1?",127,"7???")	' Numeric keypad keys
   TABLE $70,("0.",180,"5",126,179,"??B+3-*9??")
startup:
'setfreq m8
put 0,0
hi2csetup i2cslave,%01010100
pause 500
'kbled %10000101			'disable LED blinking (enable capslock and scroll lock, disable numlock)
kbled $80
main:
'	pause 100
	'sertxd("getting key ")
	kbin keyraw			'grab one character
	gotkey:
	if keyraw=128 then           'print screen (tries to capitalise instead without this)
	elseif keyraw=18 or keyraw=89 then
		shift=1
		goto main
	elseif keyraw = 88 then
		inc caps
		keyraw=88
		goto repeatcheck
		'sertxd ("caps")
		'goto main
	endif
	'sertxd("got key ")
	'sertxd(#b0)
	'sertxd(cr)
	get 0,b1
	'if b1=1 then main		'if status=ready, discard character

	put 1,keyraw			'if status <> ready, store character
	if caps=1 or shift=1 then
		'sertxd ("capitalised")
	read keyraw,b2                    'read eeprom for capitalised ascii
	shift=0
	else
	readtable keyraw,b2
	endif
	put 2,b2
	select case keyraw     'numbers or significant commands
	case 69
		b3=0
	case 22
		b3=1
	case 30
		b3=2
	case 38
		b3=3
	case 37
		b3=4
	case 46
		b3=5
	case 54
		b3=6
	case 61
		b3=7
	case 62
		b3=8
	case 70
		b3=9
	'case 63                    'sleep button
	'	powerstate=1
	'	b3=11                'sleep command on master
	'case 94                       'wake up button
	'	high A.3
	'	powerstate=0
	'	b3=12
	'	pause 500
	'	low A.3
	else
		b3=10
	endselect
	put 3,b3
	put 0,1			'update status=ready
	'pause 400
	do
	get 0,keycheck 'b1
	loop until keycheck=2
	'debug
	'goto main
	if keyheld=1 then fastrepeat
'else continues to repeatcheck

repeatcheck:           'prevent repeats if key is held too long
kbin [350,norepeat], repeatkey
'sertxd ("1")
if repeatkey=keyraw then
	inc loopcount
	if loopcount>10 then
	loopcount=0
		goto fastrepeat'main
	endif
	goto repeatcheck
else'if repeatkey <> keyraw then
	keyraw=repeatkey
	repeatkey=0
	goto gotkey
endif
goto main
norepeat:
 repeatkey=0
 keyheld=0
goto main

fastrepeat:
'sertxd ("F")
kbin [100,norepeat],repeatkey
if repeatkey=keyraw then
	keyheld=1
	goto gotkey
	'inc loopcount
	'if loopcount>3 then
	'	loopcount=0
	'	goto gotkey
	'endif
	'goto fastrepeat
else
	keyraw=repeatkey
	repeatkey=0
	goto gotkey
endif
goto main
		
