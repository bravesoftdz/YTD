@echo off
call :build uDialogs.rc
goto konec

:build
brcc32 -ic:\c\mingw\include %1
if errorlevel 1 pause
goto konec

:konec
