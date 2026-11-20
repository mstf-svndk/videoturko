@echo off
rem VideoTurko - Monster (RTX 2050 4 GB) tek tik: kurulum yoksa kurar, sonra video uretir.
cd /d "%~dp0"
set "ISTEM=istem.txt"
set "KARE=192"
if exist runs\hazir.json goto sor
echo == ilk kurulum: motor + modeller (29,3 GiB) indirilecek
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\kur-monster.ps1
if errorlevel 1 goto son
:sor
set /p ISTEM="Istem dosyasi (bos = istem.txt): "
if "%ISTEM%"=="" set ISTEM=istem.txt
if not exist "%ISTEM%" ( echo Istem dosyasi yok: %ISTEM% & goto son )
set /p KARE="Kare sayisi (56/73/.../192/209, bos = 192): "
if "%KARE%"=="" set KARE=192
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\uret.ps1 -Istem "%ISTEM%" -Kare %KARE%
:son
pause
