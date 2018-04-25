#picaxe 28x2
hi2csetup i2cmaster,%01010100,i2cfast_16,i2cbyte
pause 600
serout C.1, N2400, (254,1)'clear display
pause 40
serout C.1, N2400, (254,128)
getakey:
	pause 400
	
	hi2cin 0,(b0,b1,b2)
	'sertxd(#b23,",",#b24,cr,lf)
	if b0<> 1 then 
		b1 = 0						'if tempb0 != 1, then set received byte to 0
	else
		'sertxd ("got a key")
		hi2cout 0,(0)
	endif					'reset keyboard status byte
	'hi2csetup i2cmaster,RAM_A,i2cslow_16,i2cword
	if b1 = 0 then getakey
	'debug
	'goto getakey
	serout C.1,N2400, ("     ")
	serout C.1,N2400, (254,128)
	serout C.1,N2400, (#b1," ",b2," ",#b2)
	serout C.1,N2400, (254,128)
	goto getakey