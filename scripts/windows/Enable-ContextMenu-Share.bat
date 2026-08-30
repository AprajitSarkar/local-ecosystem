@echo off
title Enable Right-Click "Share with Ecosystem"
echo ========================================================
echo   Enabling Windows Explorer Right-Click Context Menu
echo   "Share with Ecosystem" for Files and Folders...
echo ========================================================
echo.

set SCRIPT_DIR=%~dp0
set SCRIPT_DIR=%SCRIPT_DIR:~0,-1%

rem Resolve native executable and icon path
if exist "%SCRIPT_DIR%\build_artifacts\windows\LocalEcosystem-Native\local_ecosystem.exe" (
    set EXE_PATH=%SCRIPT_DIR%\build_artifacts\windows\LocalEcosystem-Native\local_ecosystem.exe
    set ICON_PATH=%SCRIPT_DIR%\build_artifacts\windows\LocalEcosystem-Native\app_icon.ico
) else (
    set EXE_PATH=%SCRIPT_DIR%\local_ecosystem.exe
    set ICON_PATH=%SCRIPT_DIR%\app_icon.ico
)

echo Target Executable: "%EXE_PATH%"
echo Target Icon:       "%ICON_PATH%"
echo.

rem 1. Context menu for all files (*)
reg add "HKCU\Software\Classes\*\shell\ShareWithEcosystem" /ve /d "Share with Ecosystem" /f >nul
reg add "HKCU\Software\Classes\*\shell\ShareWithEcosystem" /v "Icon" /d "\"%ICON_PATH%\"" /f >nul
reg add "HKCU\Software\Classes\*\shell\ShareWithEcosystem\command" /ve /d "\"%EXE_PATH%\" --share \"%%1\"" /f >nul

rem 2. Context menu for directories / folders
reg add "HKCU\Software\Classes\Directory\shell\ShareWithEcosystem" /ve /d "Share with Ecosystem" /f >nul
reg add "HKCU\Software\Classes\Directory\shell\ShareWithEcosystem" /v "Icon" /d "\"%ICON_PATH%\"" /f >nul
reg add "HKCU\Software\Classes\Directory\shell\ShareWithEcosystem\command" /ve /d "\"%EXE_PATH%\" --share \"%%1\"" /f >nul

rem 3. Context menu for folder background
reg add "HKCU\Software\Classes\Directory\Background\shell\ShareWithEcosystem" /ve /d "Share Folder with Ecosystem" /f >nul
reg add "HKCU\Software\Classes\Directory\Background\shell\ShareWithEcosystem" /v "Icon" /d "\"%ICON_PATH%\"" /f >nul
reg add "HKCU\Software\Classes\Directory\Background\shell\ShareWithEcosystem\command" /ve /d "\"%EXE_PATH%\" --share \"%%V\"" /f >nul

echo ========================================================
echo [SUCCESS] "Share with Ecosystem" is now active!
echo.
echo You can now right-click ANY file or folder in Windows 
echo File Explorer and click "Share with Ecosystem" to send 
echo it directly to your devices over Wi-Fi!
echo ========================================================
pause
