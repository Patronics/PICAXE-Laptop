'keyboard controller i2c slave test increment variables quickly
startup:
hi2csetup i2cslave, %01010100
main:
b0=b0+1
put 0,b0
goto main