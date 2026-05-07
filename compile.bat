@echo off
cls

tasm tateti\soundi.asm tateti\soundi
tlink /t tateti\soundi.obj, tateti\soundi
tateti\soundi

pause >nul
cls

tasm tateti\tateti.asm tateti\tateti
tasm tateti\Ltateti.asm tateti\Ltateti
tlink tateti\tateti.obj tateti\Ltateti.obj, tateti\tateti.exe

echo ENTER para ejecutar ...
pause >nul
tateti\tateti.exe

