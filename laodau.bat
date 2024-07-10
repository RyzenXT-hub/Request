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
    echo Failed to install Windows Desktop Runtime. Retrying once...
    "%extractPath%\2.win-runtime.exe" /quiet /norestart
    if %errorlevel% NEQ 0 (
        echo Failed to install Windows Desktop Runtime again. Exiting...
        exit /b
    )
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

REM Open new terminal and run titan-edge daemon
echo Starting titan-edge daemon...
start cmd /k titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0
echo titan-edge daemon started in a new terminal.

REM Wait for titan-edge daemon to finish (optional)
echo Waiting for titan-edge daemon to initialize...
timeout /t 5 >nul

REM Bind titan-edge
echo Binding titan-edge...
titan-edge bind --hash=C4D4CB1D-157B-4A88-A563-FB473E690968 https://api-test1.container1.titannet.io/api/v2/device/binding
if %errorlevel% NEQ 0 (
    echo Binding failed.
) else (
    echo Binding successful.
)

REM Set storage size
echo Setting storage size...
titan-edge config set --storage-size=50GB
if %errorlevel% NEQ 0 (
    echo Failed to set storage size.
) else (
    echo Storage size set successfully.
)

REM Function to generate random MAC Address
set "chars=0123456789ABCDEF"
set "newMac="
for /l %%i in (1,1,12) do (
    set /a idx=!random! %% 16
    for %%j in (!idx!) do set "newMac=!newMac!!chars:~%%j,1!"
)
set "newMac=%newMac:~0,2%-%newMac:~2,2%-%newMac:~4,2%-%newMac:~6,2%-%newMac:~8,2%-%newMac:~10,2%"
echo Generated new MAC Address: %newMac%

REM Save current MAC Address
for /f "tokens=2 delims=: " %%A in ('getmac /FO list ^| find "PhysicalAddress"') do set "oldMac=%%A"

REM Change MAC Address using PowerShell
powershell -Command "(Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.Name -ne 'Loopback' }).SetPhysicalAddress(([byte[]]@(0x%newMac:~0,2%, 0x%newMac:~3,2%, 0x%newMac:~6,2%, 0x%newMac:~9,2%, 0x%newMac:~12,2%, 0x%newMac:~15,2%)))"
if %errorlevel% NEQ 0 (
    echo Failed to change MAC Address. Restoring old MAC Address...
    powershell -Command "(Get-NetAdapter | Where-Object { $_.Status -eq 'Up' -and $_.Name -ne 'Loopback' }).SetPhysicalAddress(([byte[]]@(0x%oldMac:~0,2%, 0x%oldMac:~3,2%, 0x%oldMac:~6,2%, 0x%oldMac:~9,2%, 0x%oldMac:~12,2%, 0x%oldMac:~15,2%)))"
    echo MAC Address restored to: %oldMac%
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
            goto :done
        ) else (
            echo Activation failed with product key: %%P.
        )
    ) else (
        echo Invalid product key: %%P.
    )
)

:done
echo All product keys failed. Windows activation could not be completed.

pause
exit /b
