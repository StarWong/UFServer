@echo off
title ��װT3BackUP����
Set InstallDir=C:\Windows
Copy "AppFunc.dll" "%InstallDir%\AppFunc.dll" /y
Copy "DBSQL.dll" "%InstallDir%\DBSQL.dll" /y
Copy "T3BackUp.ini" "%InstallDir%\T3BackUp.ini" /y
Copy "T3BackUp.exe" "%InstallDir%\T3BackUp.exe" /y
pause
"%InstallDir%\T3BackUp.exe" /install
sc description UFBackUp "Author:ranger"
net start UFBackUp
pause&exit

