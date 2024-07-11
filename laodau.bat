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

REM Check if zip file already downloaded
if not exist "%downloadedFile%" (
    echo Downloading installation files...
    bitsadmin /transfer "DownloadJob" %downloadURL% "%downloadedFile%"
    if %errorLevel% neq 0 (
        echo Download failed. Exiting...
        pause
        exit /b 1
    )
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

REM Run start-click-here.exe and perform actions using PowerShell
echo Running start-click-here.exe...
start "" "%tempDir%\start-click-here.exe"
timeout /t 5 >nul 2>&1  REM Wait for start-click-here.exe to open

REM PowerShell script to automate clicks
echo Automating clicks using PowerShell...

$ErrorActionPreference = "Stop"

# Wait for the start-click-here.exe window to appear
$windowTitle = "start-click-here"  # Update with actual window title if needed
$timeoutSeconds = 30
$window = Get-Process | Where-Object { $_.MainWindowTitle -eq $windowTitle } | Wait-UIAWindow -Timeout $timeoutSeconds

if ($window) {
    # Click on menu "VÀO SỬ DỤNG"
    $menuName = "VÀO SỬ DỤNG"  # Update with actual menu text
    $menu = $window | Get-UIAMenu | Where-Object { $_.Name -eq $menuName }
    $menu.Select()

    # Wait for the new application window "PUMIN INFO V.1.0"
    $newWindowTitle = "PUMIN INFO V.1.0"  # Update with actual window title
    $newWindow = Wait-UIAWindow -Name $newWindowTitle -Timeout $timeoutSeconds

    if ($newWindow) {
        # Click "TAO TỰ ĐỘNG" button 3 times
        $buttonName = "TAO TỰ ĐỘNG"  # Update with actual button text
        for ($i = 1; $i -le 3; $i++) {
            $button = $newWindow | Get-UIAButton | Where-Object { $_.Name -eq $buttonName }
            $button.Click()
            Start-Sleep -Milliseconds 500  # Wait 500 milliseconds between clicks
        }

        # Click "LƯU LẠI" button
        $saveButtonName = "LƯU LẠI"  # Update with actual button text
        $saveButton = $newWindow | Get-UIAButton | Where-Object { $_.Name -eq $saveButtonName }
        $saveButton.Click()
    } else {
        Write-Host "Failed to find or open 'PUMIN INFO V.1.0' window."
        goto :cleanupAndExit
    }
} else {
    Write-Host "Failed to find or open 'start-click-here.exe' window."
    goto :cleanupAndExit
}

# Activation of Windows (example code provided earlier)
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
