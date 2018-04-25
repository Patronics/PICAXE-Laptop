#picaxe 28x2
symbol cursorrow= b3
symbol cursorcol= b4
symbol cursorpos= b5
setup:
hi2csetup i2cmaster,%01010100,i2cfast_16,i2cbyte
pause 600
serout C.1, N2400, (254,1)'clear display
pause 40
serout C.1, N2400, (254,14)
serout C.1, N2400, (254,128)
cursorrow = 0
cursorcol = 0
getakey:
	pause 400
	
	hi2cin 0,(b0,b1,b2)
	'sertxd(#b23,",",#b24,cr,lf)
	if b0<> 1 then 
		b1 = 0						'if b0 != 1, then set received byte to 0
	else
		'sertxd ("got a key")
		hi2cout 0,(0)
	endif					'reset keyboard status byte
	'hi2csetup i2cmaster,RAM_A,i2cslow_16,i2cword
	if b1 = 0 then getakey
	'debug
	'goto getakey
	select case b1
	case 90                                  'enter
		cursorrow = 21
	case 102                                 'backspace
		cursorrow=cursorrow-1
		gosub position
			cursorrow=cursorrow-1
		serout C.1,N2400, (" ")
		'if cursorrow <19 then
		' cursorcol=cursorcol-2
		' cursorrow = 18
		 'serout C.1, N2400, ("row")
		'endif
	case 107                                  'left arrow
		cursorrow=cursorrow-2
		'if cursorrow <19 then
		' cursorcol=cursorcol-2
		' cursorrow = 18
		' serout C.1, N2400, ("row")
		'endif
			
		'serout C.1 N2400 (254,16)
	case 116                                  'right arrow
		serout C.1,N2400, (254,20)
	case 114                                  'down arrow
		inc cursorcol
		dec cursorrow
	case 117                                  'up arrow
		dec cursorcol
		dec cursorrow
		
	else
		serout C.1,N2400, (b2)
	endselect
	
	inc cursorrow
	gosub position
		goto getakey
position:
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
		serout C.1, N2400, (254,cursorpos)
		return
	goto getakey