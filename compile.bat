@echo off
cls

tasm soundi.asm soundi
tlink /t soundi.obj, soundi
soundi

pause >nul
cls

tasm tateti.asm tateti
tasm Ltateti.asm Ltateti
tlink tateti.obj Ltateti.obj, tateti.exe

echo ENTER para ejecutar ...
pause >nul
tateti.exe