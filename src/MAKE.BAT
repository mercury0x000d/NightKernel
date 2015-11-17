@echo off
del kasm.obj
del kc.obj
del kernel.sys
del a:\kernel.sys
cls

nasm -f bin -o kernel.sys kernel.asm

copy kernel.sys a:\kernel.sys
echo.
