@echo off
setlocal
cd /d "%~dp0"
title Codex Account Manager Setup
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" -Mode Install
if errorlevel 1 (
  echo.
  echo Installation failed.
  pause
  exit /b 1
)
echo.
echo Done. You can now run: codex-account
echo If Windows Terminal was already open, open a new terminal window.
pause
