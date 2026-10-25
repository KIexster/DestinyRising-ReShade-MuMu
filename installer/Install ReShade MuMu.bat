@echo off
rem Opens the ReShade for MuMuPlayer installer (window with DirectX / Vulkan / Uninstall options)
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File "%~dp0Installer.ps1"
