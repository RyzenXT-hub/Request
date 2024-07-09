@echo off
:: Check if script is running with administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting administrative privileges...
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\AdminPriv.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\AdminPriv.vbs"
    "%temp%\AdminPriv.vbs"
    del "%temp%\AdminPriv.vbs"
    exit /b
)

:: Set color for Batch script (black background with light aqua text)
color 0B
setlocal EnableDelayedExpansion

:: Display welcome message
cls
echo ==============================================================================
echo                        Auto Installation by Laodau                           
echo ==============================================================================
echo.
echo This installation will guide you through several steps to set up
echo and configure various required components. Please follow each step
echo carefully. This process may take some time. Thank you for your patience!
echo.
pause

:: Define URL and destination directory
set "url=https://laodau.sgp1.cdn.digitaloceanspaces.com/storage/r-setup-file.zip"
set "tempDir=%TEMP%\r-setup"

:: Function to display loading message with percentage
:loading
set "message=%~1"
cls
echo ==============================================================================
echo                        Auto Installation by Laodau                           
echo ==============================================================================
echo.
echo %message%
echo.
echo [Working]
echo [0%]
echo.
exit /b

:: Download and extract files
call :downloadAndExtract "Downloading and extracting files..."
call :installAndWait "%tempDir%\1.vc++.exe" "Installing 1.vc++.exe..."
call :installAndWait "%tempDir%\2.win-runtime.exe" "Installing 2.win-runtime.exe..."
call :copyFilesAndWait "%tempDir%\5.titan\*.*" "%SystemRoot%\System32" "Copying files to system32..."
call :createBatchFile "%SystemRoot%\System32\titan-daemon.bat" "Creating batch file for daemon..."
call :createWindowsService "TitanDaemon" "Creating Windows service for daemon..."
call :createProcessCheckScript "%SystemRoot%\System32\check-titan-daemon.bat" "Creating process check script..."
start cmd /k "%SystemRoot%\System32\check-titan-daemon.bat"

:: Prompt user for identity code
call :promptInput "Enter identity code: " "titan-edge bind --hash=%%identityCode%% https://api-test1.container1.titannet.io/api/v2/device/binding"

:: Prompt user for storage size
call :promptInput "Enter storage size (GB): " "titan-edge config set --storage-size=%%storageSize%%GB && exit"

:: Run state command
call :runCommandAndWait "titan-edge state" "Running state command..."

:: Run start-click-here.exe
call :runAndWait "%tempDir%\3.tool-change-info\start-click-here.exe" "Running start-click-here.exe..."

:: Run Activate AIO Tools v3.1.2 by Savio.cmd
call :runAndWait "%tempDir%\6.actived-win\Activate AIO Tools v3.1.2\Activate AIO Tools v3.1.2 by Savio.cmd" "Running Activate AIO Tools v3.1.2 by Savio.cmd..."

:: Install rClient.Setup.latest.exe
call :installAndWait "%tempDir%\4.rivalz\rClient.Setup.latest.exe" "Installing rClient.Setup.latest.exe..."

:: Clean up temporary files
call :cleanup "%tempDir%" "Cleaning up temporary files..."

echo Installation complete.
pause
exit /b

:: Subroutine to download and extract files
:downloadAndExtract
echo %message%
powershell -Command "Invoke-WebRequest -Uri %url% -OutFile %TEMP%\r-setup-file.zip"
powershell -Command "Expand-Archive -Path %TEMP%\r-setup-file.zip -DestinationPath %tempDir%"
echo.
exit /b

:: Subroutine to copy files and wait for completion
:copyFilesAndWait
echo %message%
xcopy /s /y %1 %2
echo.
exit /b

:: Subroutine to create batch file and wait for completion
:createBatchFile
echo %message%
echo @echo off > "%1"
echo titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0 >> "%1"
echo.
exit /b

:: Subroutine to create Windows service and wait for completion
:createWindowsService
echo %message%
sc create %1 binPath= "%SystemRoot%\System32\cmd.exe /c %SystemRoot%\System32\titan-daemon.bat" start= auto
sc description %1 "Titan Edge Daemon Service"
sc start %1
echo.
exit /b

:: Subroutine to create process check script and wait for completion
:createProcessCheckScript
echo %message%
echo @echo off > "%1"
echo :check >> "%1"
echo tasklist /FI "IMAGENAME eq titan-edge.exe" 2^>nul | find /I /N "titan-edge.exe" ^>nul >> "%1"
echo if "%ERRORLEVEL%"=="0" ( >> "%1"
echo     timeout /t 10 /nobreak >> "%1"
echo     goto check >> "%1"
echo ) else ( >> "%1"
echo     sc start TitanDaemon >> "%1"
echo     timeout /t 10 /nobreak >> "%1"
echo     goto check >> "%1"
echo ) >> "%1"
echo.
exit /b

:: Subroutine to prompt user input and execute command, waiting for completion
:promptInput
set /p "%1" identityCode=
start cmd /k "%2"
echo.
exit /b

:: Subroutine to run a command and wait for completion
:runCommandAndWait
echo %message%
start cmd /k "%1"
echo.
exit /b

:: Subroutine to run an executable and wait for completion
:runAndWait
echo %message%
start /wait "" "%1"
echo.
exit /b

:: Subroutine to install an executable and wait for completion
:installAndWait
echo %message%
start /wait "" "%1"
echo.
exit /b

:: Subroutine to clean up temporary files
:cleanup
echo %message%
rd /s /q "%1"
del /q "%TEMP%\r-setup-file.zip"
echo.
exit /b
