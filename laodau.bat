@echo off
cls
color b
title Auto Installation Script

REM Check if running as administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Administrator privileges required. Exiting...
    pause
    exit /b 1
)

REM Set variables
set "downloadURL=https://laodau.sgp1.cdn.digitaloceanspaces.com/storage/r-setup-file.zip"
set "tempDir=%TEMP%\r-setup-file"
set "downloadedFile=%tempDir%\r-setup-file.zip"

REM Function to extract zip file
:extractZip
echo Extracting files...
if exist "%tempDir%" rd /s /q "%tempDir%"
mkdir "%tempDir%"

REM Check if zip file already exists
if not exist "%downloadedFile%" (
    REM Download installation files only if zip file does not exist
    echo Downloading installation files...
    bitsadmin /transfer "DownloadJob" %downloadURL% "%downloadedFile%"
    if %errorLevel% neq 0 (
        echo Download failed. Exiting...
        pause
        exit /b 1
    )
) else (
    echo Installation files already downloaded. Skipping download.
)

REM Extract the downloaded zip file
powershell -Command "Expand-Archive -Path '%downloadedFile%' -DestinationPath '%tempDir%'"
if %errorLevel% neq 0 (
    echo Extraction failed. Cleaning up...
    rd /s /q "%tempDir%"
    goto :cleanupAndExit
)

REM Install 1.vc++.exe silently
echo Installing VC++ Redistributable...
"%tempDir%\1.vc++.exe" /quiet
if %errorLevel% neq 0 (
    echo VC++ Redistributable installation failed.
    goto :cleanupAndExit
)

REM Install 2.win-runtime.exe silently
echo Installing Windows Runtime...
"%tempDir%\2.win-runtime.exe" /quiet
if %errorLevel% neq 0 (
    echo Windows Runtime installation failed.
    goto :cleanupAndExit
)

REM Run start-click-here.exe
echo Running start-click-here.exe...
start "" "%tempDir%\3.tool-change-info\start-click-here.exe"
timeout /t 5 >nul 2>&1  REM Wait for start-click-here.exe to open

REM Run PowerShell script for UI automation
echo Automating clicks using PowerShell...
powershell -File "%tempDir%\automation_script.ps1"

REM Activation of Windows (example code provided earlier)
echo Activating Windows...
set "activationCodes=TX9XD-98N7V-6WMQ6-BX7FG-H8Q99 3KHY7-WNT83-DGQKR-F7HPR-844BM ..."
set "activationSuccess=false"

for %%c in (%activationCodes%) do (
    slmgr /ipk %%c
    if %errorLevel% equ 0 (
        set "activationSuccess=true"
        echo Windows activated successfully with key: %%c
        goto :continueInstallation
    )
)

if "%activationSuccess%"=="false" (
    echo Failed to activate Windows.
    goto :cleanupAndExit
)

:continueInstallation

REM Copy files from 5.titan to system32
echo Copying Titan files to system32...
copy "%tempDir%\5.titan\titan-edge.exe" "%SystemRoot%\system32\"
copy "%tempDir%\5.titan\goworkerd.dll" "%SystemRoot%\system32\"

REM Start titan-edge daemon
echo Starting titan-edge daemon...
start cmd /k titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0
if %errorLevel% neq 0 (
    echo Failed to start titan-edge daemon.
    goto :cleanupAndExit
)

REM Bind titan-edge
echo Binding titan-edge...
titan-edge bind --hash=C4D4CB1D-157B-4A88-A563-FB473E690968 https://api-test1.container1.titannet.io/api/v2/device/binding
if %errorLevel% neq 0 (
    echo Binding titan-edge failed.
    goto :cleanupAndExit
)

REM Set titan-edge config
echo Setting titan-edge configuration...
titan-edge config set --storage-size=50GB

REM Install rClient.Setup.latest.exe from 4.rivalz silently
echo Installing rClient.Setup.latest.exe...
"%tempDir%\4.rivalz\rClient.Setup.latest.exe" /quiet
if %errorLevel% neq 0 (
    echo rClient.Setup.latest.exe installation failed.
    goto :cleanupAndExit
)

echo All installation processes completed successfully.
pause
exit /b 0

:cleanupAndExit
echo An error occurred during installation. Cleaning up...
rd /s /q "%tempDir%"
pause
exit /b 1
