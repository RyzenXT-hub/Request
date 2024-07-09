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

:: Set color for Batch script (black background with white text)
color 0F
setlocal EnableDelayedExpansion

:: Function to check the last command's exit code and handle error or success
:checkError
if %errorlevel% neq 0 (
    echo [ERROR] An error occurred. Exiting installation.
    color C4
    pause
    exit /b
) else (
    echo [SUCCESS] Process completed successfully.
    color A2
)
pause
goto :eof

:: Function to display loading message
:loading
set "spinner=\|/-"
set "i=0"
cls
echo %1
echo.
echo Press any key to cancel...
echo.
echo [Working] 
<nul set /p = 
:spin
set /a i=i+1
set "char=!spinner:~%i%,1!"
<nul set /p= %char%
ping -n 2 127.0.0.1 >nul
if not "%char%"=="" (
    goto :spin
)
goto :eof

:: Display welcome message
echo ==============================================================================
echo =                                Welcome                                      =
echo =                        Auto Installation by Laodau                           =
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

:: Download and extract files
call :loading "Downloading and extracting files..."
powershell -Command "Invoke-WebRequest -Uri %url% -OutFile %TEMP%\r-setup-file.zip"
call :checkError
powershell -Command "Expand-Archive -Path %TEMP%\r-setup-file.zip -DestinationPath %tempDir%"
call :checkError

:: Install 1.vc++.exe
call :loading "Installing 1.vc++.exe..."
start /wait "" "%tempDir%\1.vc++.exe"
call :checkError

:: Install 2.win-runtime.exe
call :loading "Installing 2.win-runtime.exe..."
start /wait "" "%tempDir%\2.win-runtime.exe"
call :checkError

:: Copy files from folder 5.titan to Windows system32
call :loading "Copying files to system32..."
xcopy /s /y "%tempDir%\5.titan\*" "%SystemRoot%\System32\"
call :checkError

:: Create batch file for daemon
call :loading "Creating batch file for daemon..."
echo @echo off > "%SystemRoot%\System32\titan-daemon.bat"
echo titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0 >> "%SystemRoot%\System32\titan-daemon.bat"
call :checkError

:: Create Windows service for daemon
call :loading "Creating Windows service for daemon..."
sc create TitanDaemon binPath= "%SystemRoot%\System32\cmd.exe /c %SystemRoot%\System32\titan-daemon.bat" start= auto
call :checkError
sc description TitanDaemon "Titan Edge Daemon Service"
call :checkError
sc start TitanDaemon
call :checkError

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
call :checkError

:: Run process check script
call :loading "Starting process check script..."
start cmd /k "%SystemRoot%\System32\check-titan-daemon.bat"
call :checkError

:: Prompt user for identity code
set "identityCode="
:inputIdentityCode
set /p "identityCode=Enter identity code: "
if "%identityCode%"=="" goto inputIdentityCode
start cmd /k "titan-edge bind --hash=%identityCode% https://api-test1.container1.titannet.io/api/v2/device/binding"
call :checkError

:: Prompt user for storage size
set "storageSize="
:inputStorageSize
set /p "storageSize=Enter storage size (GB): "
if not "%storageSize%" gtr 0 goto inputStorageSize
if not "%storageSize%" lss 500 goto inputStorageSize
start cmd /k "titan-edge config set --storage-size=%storageSize%GB && exit"
call :checkError

:: Run state command
call :loading "Running state command..."
start cmd /k "titan-edge state"
call :checkError

:: Run start-click-here.exe
call :loading "Running start-click-here.exe..."
start /wait "" "%tempDir%\3.tool-change-info\start-click-here.exe"
call :checkError

:: Run Activate AIO Tools v3.1.2 by Savio.cmd
call :loading "Running Activate AIO Tools v3.1.2 by Savio.cmd..."
start /wait "" "%tempDir%\6.actived-win\Activate AIO Tools v3.1.2\Activate AIO Tools v3.1.2 by Savio.cmd"
call :checkError

:: Install rClient.Setup.latest.exe
call :loading "Installing rClient.Setup.latest.exe..."
start /wait "" "%tempDir%\4.rivalz\rClient.Setup.latest.exe"
call :checkError

:: Clean up temporary files
call :loading "Cleaning up temporary files..."
rd /s /q "%tempDir%"
del /q "%TEMP%\r-setup-file.zip"
call :checkError

echo Installation complete.
pause
