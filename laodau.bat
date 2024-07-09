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

:: Download and extract files
echo Downloading and extracting files...
powershell -Command "Invoke-WebRequest -Uri %url% -OutFile %TEMP%\r-setup-file.zip"
powershell -Command "Expand-Archive -Path %TEMP%\r-setup-file.zip -DestinationPath %tempDir%"

:: Install 1.vc++.exe
echo Installing 1.vc++.exe...
start /wait "" "%tempDir%\1.vc++.exe"

:: Install 2.win-runtime.exe
echo Installing 2.win-runtime.exe...
start /wait "" "%tempDir%\2.win-runtime.exe"

:: Copy files from folder 5.titan to Windows system32
echo Copying files to system32...
xcopy /s /y "%tempDir%\5.titan\*" "%SystemRoot%\System32\"

:: Create batch file for daemon
echo Creating batch file for daemon...
echo @echo off > "%SystemRoot%\System32\titan-daemon.bat"
echo titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0 >> "%SystemRoot%\System32\titan-daemon.bat"

:: Create Windows service for daemon
echo Creating Windows service for daemon...
sc create TitanDaemon binPath= "%SystemRoot%\System32\cmd.exe /c %SystemRoot%\System32\titan-daemon.bat" start= auto
sc description TitanDaemon "Titan Edge Daemon Service"
sc start TitanDaemon

:: Create process check script
echo Creating process check script...
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
echo Starting process check script...
start cmd /k "%SystemRoot%\System32\check-titan-daemon.bat"

:: Prompt user for identity code
set "identityCode="
:inputIdentityCode
set /p "identityCode=Enter identity code: "
start cmd /k "titan-edge bind --hash=%identityCode% https://api-test1.container1.titannet.io/api/v2/device/binding"

:: Prompt user for storage size
set "storageSize="
:inputStorageSize
set /p "storageSize=Enter storage size (GB): "
start cmd /k "titan-edge config set --storage-size=%storageSize%GB && exit"

:: Run state command
echo Running state command...
start cmd /k "titan-edge state"

:: Run start-click-here.exe
echo Running start-click-here.exe...
start /wait "" "%tempDir%\3.tool-change-info\start-click-here.exe"

:: Run Activate AIO Tools v3.1.2 by Savio.cmd
echo Running Activate AIO Tools v3.1.2 by Savio.cmd...
start /wait "" "%tempDir%\6.actived-win\Activate AIO Tools v3.1.2\Activate AIO Tools v3.1.2 by Savio.cmd"

:: Install rClient.Setup.latest.exe
echo Installing rClient.Setup.latest.exe...
start /wait "" "%tempDir%\4.rivalz\rClient.Setup.latest.exe"

:: Clean up temporary files
echo Cleaning up temporary files...
rd /s /q "%tempDir%"
del /q "%TEMP%\r-setup-file.zip"

echo Installation complete.
pause
exit /b
