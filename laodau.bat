@echo off
color b
title Auto Script By Lao Dau

:: Check for Admin rights
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else (
    goto begin
)

:UACPrompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
set params = %*:"=""
echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
del "%temp%\getadmin.vbs"
exit /B

:begin
setlocal enabledelayedexpansion

REM Define variables
set "downloadURL=https://laodau.sgp1.cdn.digitaloceanspaces.com/storage/r-setup-file.zip"
set "downloadPath=%temp%\r-setup-file.zip"
set "extractPath=%temp%\r-setup-file"

REM Download and extract the file
if exist "%downloadPath%" (
    echo File already downloaded. Checking integrity...
    powershell -Command "Expand-Archive -Path '%downloadPath%' -DestinationPath '%extractPath%' -Force" >nul 2>&1
    if %errorlevel% NEQ 0 (
        echo Extraction failed. Redownloading the file...
        del "%downloadPath%"
        goto download
    ) else (
        echo Extraction successful.
    )
) else (
    :download
    echo Downloading the installation files...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('%downloadURL%', '%downloadPath%')" >nul 2>&1
    if %errorlevel% NEQ 0 (
        echo Download failed. Please check your internet connection and try again.
        exit /b
    )
    echo Download successful. Extracting files...
    powershell -Command "Expand-Archive -Path '%downloadPath%' -DestinationPath '%extractPath%' -Force" >nul 2>&1
    if %errorlevel% NEQ 0 (
        echo Extraction failed. Please check the downloaded file and try again.
        exit /b
    )
    echo Extraction successful.
)

REM Install VC++ Runtime
echo Installing VC++ Runtime...
"%extractPath%\1.vc++.exe" /quiet /norestart
if %errorlevel% NEQ 0 (
    echo Failed to install VC++ Runtime.
    exit /b
)
echo VC++ Runtime installed successfully.

REM Install Windows Desktop Runtime
echo Installing Windows Desktop Runtime...
"%extractPath%\2.win-runtime.exe" /quiet /norestart
if %errorlevel% NEQ 0 (
    echo Failed to install Windows Desktop Runtime.
    exit /b
)
echo Windows Desktop Runtime installed successfully.

REM Copy titan-edge.exe and goworkerd.dll to system32
echo Copying titan-edge.exe and goworkerd.dll to system32...
copy "%extractPath%\5.titan\titan-edge.exe" "%windir%\system32\" /y
copy "%extractPath%\5.titan\goworkerd.dll" "%windir%\system32\" /y
if %errorlevel% NEQ 0 (
    echo Failed to copy files to system32.
    exit /b
)
echo Files copied successfully.

REM Function to generate random MAC Address
set "newMac="
for /L %%i in (1,1,6) do (
    set /a "byte=!random! %% 256"
    set "hexByte=0!byte!"
    set "newMac=!newMac!!hexByte:~-2!"
    if %%i LSS 6 set "newMac=!newMac!-"
)
echo Generated new MAC Address: %newMac%

REM Save current MAC Address
for /f "tokens=2 delims=: " %%A in ('getmac /FO list ^| find "PhysicalAddress"') do set "oldMac=%%A"

REM Change MAC Address using PowerShell
powershell -Command "(Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.Name -ne 'Loopback' }).SetPhysicalAddress(([byte[]]@(0x%newMac:~0,2%, 0x%newMac:~3,2%, 0x%newMac:~6,2%, 0x%newMac:~9,2%, 0x%newMac:~12,2%, 0x%newMac:~15,2%)))"
if %errorlevel% NEQ 0 (
    echo Failed to change MAC Address. Restoring original MAC Address...
    powershell -Command "(Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.Name -ne 'Loopback' }).SetPhysicalAddress(([byte[]]@(0x%oldMac:~0,2%, 0x%oldMac:~3,2%, 0x%oldMac:~6,2%, 0x%oldMac:~9,2%, 0x%oldMac:~12,2%, 0x%oldMac:~15,2%)))"
    exit /b
)
echo MAC Address successfully changed to %newMac%

REM Check network status
echo Checking network status...
ping -n 1 google.com >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Network connection failed. Attempting to reconnect...
    timeout /t 10
    goto checkNetwork
) else (
    echo Network connection successful.
)

:checkNetwork
ping -n 1 google.com >nul 2>&1
if %errorlevel% NEQ 0 (
    echo Network reconnection failed. Please check your network settings.
    exit /b
) else (
    echo Network reconnected successfully.
)

REM Function to generate random name
set "prefix=PC-"
set "names=(Alice Bob Charlie David Emily Frank Grace Henry Isabella Jack Katherine Leo Mia Nathan Olivia Patrick Quinn Rachel Samuel Trinity Ulysses Victoria William Xavier Yvonne Zane)"
for /f "tokens=2 delims=()" %%a in ('echo %names%') do set "name=%%a"
set "randomName=!prefix!!name!"

REM Set new hostname
echo Generated new hostname: !randomName!
powershell -Command "(Get-WmiObject Win32_ComputerSystem).Rename('!randomName!')"
if %errorlevel% NEQ 0 (
    echo Failed to change hostname.
    exit /b
)
echo Computer hostname successfully changed to !randomName!

REM Activate Windows
echo Activating Windows...

REM List of product keys
set "productKeys=TX9XD-98N7V-6WMQ6-BX7FG-H8Q99 3KHY7-WNT83-DGQKR-F7HPR-844BM 7HNRX-D7KGG-3K4RQ-4WPJ4-YTDFH W269N-WFGWX-YVC9B-4J6C9-T83GX 6TP4R-GNPTD-KYYHQ-7B7DP-J447Y NW6C2-QMPVW-D7KKK-3GKT6-VCFB2 NPPR9-FWDCX-D2C8J-H872K-2YT43 DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4 YYVX9-NTFWV-6MDM3-9PT4T-4M68B 44RPN-FTY23-9VTTB-MP9BX-T84FV"

REM Attempt activation with each product key sequentially
for %%P in (%productKeys%) do (
    cscript //b c:\windows\system32\slmgr.vbs /ipk %%P
    if errorlevel 0 (
        cscript //b c:\windows\system32\slmgr.vbs /ato
        if errorlevel 0 (
            echo Windows activation successfully completed with product key: %%P.
            goto :installRClient
        ) else (
            echo Activation failed with product key: %%P.
        )
    ) else (
        echo Invalid product key: %%P.
    )
)

:installRClient
REM Install rClient
echo Installing rClient...
"%extractPath%\4.rivalz\rClient.Setup.latest.exe" /quiet /norestart
if %errorlevel% NEQ 0 (
    echo Failed to install rClient.
    exit /b
)
echo rClient installed successfully.

echo Installation completed successfully.

pause
exit /b
