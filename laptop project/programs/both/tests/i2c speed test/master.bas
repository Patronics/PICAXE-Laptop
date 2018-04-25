'i2c test master read slave picaxe's variable
pause 1000
main:
hi2csetup i2cmaster, %01010100,i2cfast,i2cbyte
hi2cin 0,(b0)
hi2cin 0,(b1)
hi2cin 0,(b2)
hi2cin 0,(b3)
hi2cin 0,(b4)
hi2cin 0,(b5)
hi2cin 0,(b6)
hi2cin 0,(b7)
hi2cin 0,(b8)
hi2cin 0,(b9)
hi2cin 0,(b10)
pause 1000
debug
goto main