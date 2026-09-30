@echo off
rem pi - run upstream pi from source (pi-space local launcher)
rem Delegates to pi.ps1 in this directory, same pattern as upstream pi-test.bat.
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS_EXE=pwsh.exe"

where %PS_EXE% >nul 2>nul
if errorlevel 1 set "PS_EXE=powershell.exe"

%PS_EXE% -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%pi.ps1" %*
exit /b %ERRORLEVEL%
