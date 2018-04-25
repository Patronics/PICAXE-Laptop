main:
kbled %10000111 ; all LEDs on
pause 500 ; pause 0.5s
kbled %10000000 ; all LEDs off
pause 500 ; pause 0.5s
debug
goto main ; loop
