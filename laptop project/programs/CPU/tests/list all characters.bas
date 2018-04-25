'list all characters
'for cpu OLED test
#picaxe 28x2



pause 600
serout C.1,N2400,(254,1)'clear display
pause 40
main:
pause 500
serout C.1,N2400,(254,128) ; move to start of first line
for b0 = 0 to 252
	serout C.1,N2400,(b0," ")
next b0
goto main