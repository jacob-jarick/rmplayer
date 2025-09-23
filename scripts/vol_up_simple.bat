@echo off
REM Windows volume up using PowerShell
start /min "" powershell -Command "$obj = New-Object -com WScript.Shell; for ($i = 0; $i -lt 3; $i++) { $obj.SendKeys([char]175); Start-Sleep -Milliseconds 50 }; Write-Host 'Volume increased'"
