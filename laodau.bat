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

:: Define URL and destination directory
set "url=https://laodau.sgp1.cdn.digitaloceanspaces.com/storage/r-setup-file.zip"
set "tempDir=%TEMP%\r-setup"
set "setupFile=%TEMP%\r-setup-file.zip"

:: Function to display loading message with percentage
:loading
set "message=%~1"
cls
echo Auto Script By Lao Dau
echo ==============================================================================
echo =                        Auto Installation by Laodau                         =
echo ==============================================================================
echo.
echo %message% [0%%]
echo.

:: Check if the setup file already exists
if exist "%setupFile%" (
    echo Setup file already exists. Proceeding to extract files...
    goto extractFiles
)

:: Download file
call :downloadFile

goto extractFiles

:downloadFile
:: Download file if it doesn't exist
call :loading "Downloading setup files..."
powershell -Command "& { Invoke-WebRequest -Uri %url% -OutFile %setupFile% }"
if %errorlevel% neq 0 (
    echo Error: Failed to download setup files.
    pause
    exit /b
)

:extractFiles
:: Extract files
call :loading "Extracting setup files..."
powershell -Command "& { Expand-Archive -Path %setupFile% -DestinationPath %tempDir% -Force }"
if %errorlevel% neq 0 (
    echo Error: Failed to extract setup files. Deleting corrupted file and retrying download...
    del /q "%setupFile%"
    goto downloadFile
)

:: Install 1.vc++.exe silently
call :loading "Installing 1.vc++.exe silently..."
start /wait "" "%tempDir%\1.vc++.exe" /quiet /norestart
if %errorlevel% neq 0 (
    echo Error: Failed to install 1.vc++.exe.
    pause
    exit /b
)

:: Install 2.win-runtime.exe silently
call :loading "Installing 2.win-runtime.exe silently..."
start /wait "" "%tempDir%\2.win-runtime.exe" /quiet /norestart
if %errorlevel% neq 0 (
    echo Error: Failed to install 2.win-runtime.exe.
    pause
    exit /b
)

:: Copy files from folder 5.titan to Windows system32
call :loading "Copying files to system32..."
xcopy /s /y "%tempDir%\5.titan\*" "%SystemRoot%\System32\" >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: Failed to copy files to system32.
    pause
    exit /b
)

:: Create batch file for daemon
call :loading "Creating batch file for daemon..."
echo @echo off > "%SystemRoot%\System32\titan-daemon.bat"
echo titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0 >> "%SystemRoot%\System32\titan-daemon.bat"

:: Create Windows service for daemon if not exists
call :checkServiceExists
if %serviceExists% equ 0 (
    call :createWindowsService
)

:: Start Windows service for daemon
call :loading "Starting Windows service for daemon..."
sc start TitanDaemon
if %errorlevel% neq 0 (
    echo Error: Failed to start Windows service for daemon.
    pause
    exit /b
)

:: Create process check script
call :loading "Creating process check script..."
echo @echo off > "%SystemRoot%\System32\check-titan-daemon.bat"
echo :check >> "%SystemRoot%\System32\check-titan-daemon.bat"
echo tasklist /FI "IMAGENAME eq titan-edge.exe" 2^>nul | find /I /N "titan-edge.exe" ^>nul >> "%SystemRoot%\System32\check-titan-daemon.bat"
echo if "%ERRORLEVEL%"=="0" ( >> "%SystemRoot%\System32\check-titan-daemon.bat"
echo     timeout /t 10 /nobreak >> "%SystemRoot%\System32\check-titan-daemon.bat"
echo     goto check >> "%SystemRoot%\System32\check-titan-daemon.bat"
echo ) else ( >> "%SystemRoot%\System32\check-titan-daemon.bat"
echo     sc start TitanDaemon >> "%SystemRoot%\System32\check-titan-daemon.bat"
echo     timeout /t 10 /nobreak >> "%SystemRoot%\System32\check-titan-daemon.bat"
echo     goto check >> "%SystemRoot%\System32\check-titan-daemon.bat"
echo ) >> "%SystemRoot%\System32\check-titan-daemon.bat"

:: Run process check script
call :loading "Starting process check script..."
start cmd /k "%SystemRoot%\System32\check-titan-daemon.bat"

:: Prompt user for identity code
call :loading "Prompting user for identity code..."
set "identityCode="
:inputIdentityCode
set /p "identityCode=Enter identity code: "
start cmd /k "titan-edge bind --hash=%identityCode% https://api-test1.container1.titannet.io/api/v2/device/binding"
if %errorlevel% neq 0 (
    echo Error: Failed to bind identity code.
    pause
    exit /b
)

:: Prompt user for storage size
call :loading "Prompting user for storage size..."
set "storageSize="
:inputStorageSize
set /p "storageSize=Enter storage size (GB): "
start cmd /k "titan-edge config set --storage-size=%storageSize%GB && exit"
if %errorlevel% neq 0 (
    echo Error: Failed to set storage size.
    pause
    exit /b
)

:: Run state command
call :loading "Running state command..."
start cmd /k "titan-edge state"
if %errorlevel% neq 0 (
    echo Error: Failed to run state command.
    pause
    exit /b
)

:: Run start-click-here.exe
call :loading "Running start-click-here.exe..."
start /wait "" "%tempDir%\3.tool-change-info\start-click-here.exe"
if %errorlevel% neq 0 (
    echo Error: Failed to run start-click-here.exe.
    pause
    exit /b
)

:: Run Activate AIO Tools v3.1.2 by Savio.cmd
call :loading "Running Activate AIO Tools v3.1.2 by Savio.cmd..."
start /wait "" "%tempDir%\6.actived-win\Activate AIO Tools v3.1.2\Activate AIO Tools v3.1.2 by Savio.cmd"
if %errorlevel% neq 0 (
    echo Error: Failed to run Activate AIO Tools v3.1.2 by Savio.cmd.
    pause
    exit /b
)

:: Install rClient.Setup.latest.exe silently
call :loading "Installing rClient.Setup.latest.exe silently..."
start /wait "" "%tempDir%\4.rivalz\rClient.Setup.latest.exe" /silent /norestart
if %errorlevel% neq 0 (
    echo Error: Failed to install rClient.Setup.latest.exe.
    pause
    exit /b
)

:: Clean up temporary files
call :loading "Cleaning up temporary files..."
rd /s /q "%tempDir%"
del /q "%setupFile%"

echo Installation complete.
pause
exit /b

:loading
set "message=%~1"
cls
echo Auto Script By Lao Dau
echo ==============================================================================
echo =                        Auto Installation by Laodau                         =
echo ==============================================================================
echo.
echo %message% [0%%]
echo.

goto :eof

:checkServiceExists
:: Check if the service TitanDaemon already exists
sc query TitanDaemon >nul 2>&1
set "serviceExists=%errorlevel%"
goto :eof

:createWindowsService
:: Create Windows service for daemon
call :loading "Creating Windows service for daemon..."
sc create TitanDaemon binPath= "%SystemRoot%\System32\cmd.exe /c %SystemRoot%\System32\titan-daemon.bat" start= auto
if %errorlevel% neq 0 (
    echo Error: Failed to create Windows service for daemon.
    pause
    exit /b
)
sc description TitanDaemon "Titan Edge Daemon Service"
sc config TitanDaemon start= auto
goto :eof
