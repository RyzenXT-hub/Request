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

REM Generate automation_script.ps1
echo Creating automation_script.ps1...
(
    echo # Start-Process -FilePath "%tempDir%\3.tool-change-info\start-click-here.exe" -Wait
    echo Start-Process -FilePath "\"%tempDir%\3.tool-change-info\start-click-here.exe\"" -Wait
    echo Start-Sleep -Seconds 5
    echo 
    echo # Define function to find menu item and click
    echo function Click-MenuItem {
    echo     param(
    echo         [string]`$menuItemName
    echo     )
    echo     `$window = Get-UIWindow -Name "PUMIN INFO V.1.0"
    echo     if (`$window -eq `$null) {
    echo         Write-Host "Window 'PUMIN INFO V.1.0' not found."
    echo         exit 1
    echo     }
    echo 
    echo     `$menu = Get-UIAControl -Parent `$window -ControlType "MenuBar"
    echo     if (`$menu -eq `$null) {
    echo         Write-Host "Menu bar not found."
    echo         exit 1
    echo     }
    echo 
    echo     `$menuItems = `$menu.FindAll([System.Windows.Automation.TreeScope]::Descendants, `
    echo         [System.Windows.Automation.PropertyCondition]::TrueCondition)
    echo     `$menuItem = `$menuItems | Where-Object { `$_.Current.Name -eq `$menuItemName }
    echo 
    echo     if (`$menuItem -eq `$null) {
    echo         Write-Host "Menu item '`$menuItemName' not found."
    echo         exit 1
    echo     }
    echo 
    echo     `$menuItem | Invoke-UIAControlClick
    echo }
    echo 
    echo # Click on menu item 'VÀO SỬ DỤNG'
    echo Click-MenuItem -menuItemName "VÀO SỬ DỤNG"
    echo Start-Sleep -Seconds 2
    echo 
    echo # Perform three clicks on button 'TAO TỰ ĐỘNG'
    echo for (`$i = 1; `$i -le 3; `$i++) {
    echo     `$button = Get-UIAControl -Name "TAO TỰ ĐỘNG"
    echo     if (`$button -eq `$null) {
    echo         Write-Host "Button 'TAO TỰ ĐỘNG' not found."
    echo         exit 1
    echo     }
    echo 
    echo     `$button | Invoke-UIAControlClick
    echo     Start-Sleep -Seconds 1
    echo }
    echo 
    echo # Click on button 'LƯU LẠI'
    echo `$buttonSave = Get-UIAControl -Name "LƯU LẠI"
    echo if (`$buttonSave -eq `$null) {
    echo     Write-Host "Button 'LƯU LẠI' not found."
    echo     exit 1
    echo }
    echo 
    echo `$buttonSave | Invoke-UIAControlClick
) > "%tempDir%\automation_script.ps1"

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
