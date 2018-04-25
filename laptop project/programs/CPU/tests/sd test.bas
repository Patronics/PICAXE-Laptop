#slot 3
pause 1000
symbol alfat=%10100100       'sd card reader
symbol i2cspeed=i2cfast_16               'i2c 400khz at 16 MHz
hi2csetup i2cmaster,alfat,i2cspeed,i2cbyte     'setup i2c comunication for SD card reader
	serout C.1, N2400,(254,128,254,1)
	pause 40
		serout C.1, N2400,("SD card reader test",254,192)
do
	hi2cin (b0)
	serout C.1, N2400,(b0)
	pause 100
loop