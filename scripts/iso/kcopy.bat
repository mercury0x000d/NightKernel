@echo off

REM copies a file to the C: drive to save you time

:copy
echo.
echo renaming the FreeDOS kernel...
rename C:\kernel.sys FDKERN.SYS 
echo copying the new kernel...
copy kernel.sys C:\kernel.sys
