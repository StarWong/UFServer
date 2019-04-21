@echo off
title Ð¶ÔØT3BackUP·þÎñ
Set Uninstalldir=C:\Windows
net stop UFBackUp
if exist "%Uninstalldir%\T3BackUp.exe" "%Uninstalldir%\T3BackUp.exe" /uninstall
del "%Uninstalldir%\AppFunc.dll" /f /s /q
del "%Uninstalldir%\DBSQL.dll" /f /s /q
del "%Uninstalldir%\T3BackUp.ini" /f /s /q
del "%Uninstalldir%\T3BackUp.exe" /f /s /q
pause&exit