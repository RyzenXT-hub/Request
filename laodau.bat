@echo off
title Auto Script By Lao Dau
color b
echo ====================================
echo   Welcome to Auto Installation Script
echo ====================================

:: Set URL for master installation file
set "MASTER_INSTALL_URL=https://laodau.sgp1.cdn.digitaloceanspaces.com/storage/r-setup-file.zip"

:: Set download and extraction directories
set "DOWNLOAD_DIR=%TEMP%"
set "EXTRACT_DIR=%TEMP%\r-setup-files"

:: Check if files already exist
if exist "%EXTRACT_DIR%\1.vc++.exe" (
    echo Found existing files. Skipping download...
) else (
    echo Downloading files...
    bitsadmin /transfer "r-setup-download" "%MASTER_INSTALL_URL%" "%DOWNLOAD_DIR%\r-setup-file.zip"
    echo Waiting for download to complete...

    :CheckDownload
    timeout /t 5 >nul
    echo Monitoring background copy manager (5 second refresh)...
    bitsadmin /list /verbose | find "TRANSFERRED"
    if errorlevel 1 goto DownloadError
)

:: Extract files
echo Extracting files...
if exist "%EXTRACT_DIR%" rmdir /s /q "%EXTRACT_DIR%"
powershell -noprofile -command "Expand-Archive -Path '%DOWNLOAD_DIR%\r-setup-file.zip' -DestinationPath '%EXTRACT_DIR%'"
if %errorlevel% NEQ 0 goto ExtractError

:: Install 1.vc++.exe silently
echo Installing 1.vc++.exe...
start /wait "" "%EXTRACT_DIR%\1.vc++.exe" /silent
if %errorlevel% NEQ 0 goto InstallError
echo 1.vc++.exe installation completed.

:: Install 2.win-runtime.exe silently
echo Installing 2.win-runtime.exe...
start /wait "" "%EXTRACT_DIR%\2.win-runtime.exe" /silent
if %errorlevel% NEQ 0 goto InstallError
echo 2.win-runtime.exe installation completed.

:: Run start-click-here.exe and perform clicks
echo Performing clicks in start-click-here.exe...
start "" "%EXTRACT_DIR%\3.tool-change-info\start-click-here.exe"
timeout /t 5
echo Clicking VÀO SỬ DỤNG...
echo. | %EXTRACT_DIR%\3.tool-change-info\start-click-here.exe "VÀO SỬ DỤNG"
timeout /t 3
echo Clicking TAO TỰ ĐỘNG (3 times)...
for /l %%i in (1,1,3) do echo. | %EXTRACT_DIR%\3.tool-change-info\start-click-here.exe "TAO TỰ ĐỘNG"
timeout /t 3
echo Clicking LƯU LẠI...
echo. | %EXTRACT_DIR%\3.tool-change-info\start-click-here.exe "LƯU LẠI"
echo start-click-here.exe actions completed.

:: Automatic Windows activation using provided keys
echo Activating Windows...
set "activation_keys=TX9XD-98N7V-6WMQ6-BX7FG-H8Q99 3KHY7-WNT83-DGQKR-F7HPR-844BM 7HNRX-D7KGG-3K4RQ-4WPJ4-YTDFH W269N-WFGWX-YVC9B-4J6C9-T83GX 6TP4R-GNPTD-KYYHQ-7B7DP-J447Y NW6C2-QMPVW-D7KKK-3GKT6-VCFB2 NPPR9-FWDCX-D2C8J-H872K-2YT43 DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4 YYVX9-NTFWV-6MDM3-9PT4T-4M68B 44RPN-FTY23-9VTTB-MP9BX-T84FV"
set "success=false"

for %%k in (%activation_keys%) do (
    slmgr /ipk %%k >nul 2>&1
    if %errorLevel% equ 0 (
        set "success=true"
        echo Windows activated successfully with key: %%k
        timeout /t 5
        break
    )
)

if "%success%"=="false" (
    echo Failed to activate Windows with provided keys.
)

:: Copy titan-edge.exe and goworkerd.dll to Windows system32
echo Copying titan-edge.exe and goworkerd.dll to system32...
copy /y "%EXTRACT_DIR%\5.titan\titan-edge.exe" "%SystemRoot%\System32"
copy /y "%EXTRACT_DIR%\5.titan\goworkerd.dll" "%SystemRoot%\System32"
if %errorlevel% NEQ 0 goto CopyError
echo Files copied to system32.

:: Start titan-edge daemon
echo Starting titan-edge daemon...
start cmd /k "titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0"
echo Titan-edge daemon started.

:: Bind to Titan network
echo Binding to Titan network...
titan-edge bind --hash=C4D4CB1D-157B-4A88-A563-FB473E690968 https://api-test1.container1.titannet.io/api/v2/device/binding
if %errorLevel% NEQ 0 goto BindError
echo Titan bind successful.

:: Configure titan-edge storage size
echo Configuring titan-edge storage size...
titan-edge config set --storage-size=50GB
if %errorLevel% NEQ 0 goto ConfigError
echo Titan-edge storage size configured.

:: Install rClient.Setup.latest.exe silently
echo Installing rClient.Setup.latest.exe...
start /wait "" "%EXTRACT_DIR%\4.rivalz\rClient.Setup.latest.exe" /silent
if %errorLevel% NEQ 0 goto InstallError
echo rClient.Setup.latest.exe installation completed.

echo Installation complete.
pause
exit /B 0

:DownloadError
echo Error: Failed to download master installation file.
pause
exit /B 1

:ExtractError
echo Error: Failed to extract files.
pause
exit /B 1

:InstallError
echo Error: Installation failed.
pause
exit /B 1

:CopyError
echo Error: Failed to copy files to system32.
pause
exit /B 1

:BindError
echo Error: Failed to bind to Titan network.
pause
exit /B 1

:ConfigError
echo Error: Failed to configure titan-edge storage size.
pause
exit /B 1
