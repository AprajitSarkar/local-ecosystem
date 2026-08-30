@echo off
setlocal
cd /d "%~dp0"

echo ========================================================
echo   Registering "Send to Ecosystem" Context Menu
echo ========================================================

set "APP_EXE=%~dp0local_ecosystem.exe"
set "APP_ICON=%~dp0local_ecosystem.exe,0"

if not exist "%APP_EXE%" (
    set "APP_EXE=%~dp0build_artifacts\windows\LocalEcosystem-Native\local_ecosystem.exe"
    set "APP_ICON=%~dp0build_artifacts\windows\LocalEcosystem-Native\local_ecosystem.exe,0"
)

if not exist "%APP_EXE%" (
    echo [ERROR] Could not locate local_ecosystem.exe
    pause
    exit /b 1
)

echo Registering for Files...
reg add "HKCU\Software\Classes\*\shell\SendToLocalEcosystem" /ve /d "Send to Ecosystem" /f >nul
reg add "HKCU\Software\Classes\*\shell\SendToLocalEcosystem" /v "Icon" /d "\"%APP_ICON%\"" /f >nul
reg add "HKCU\Software\Classes\*\shell\SendToLocalEcosystem\command" /ve /d "\"%APP_EXE%\" --send \"%%1\"" /f >nul

echo Registering for Folders...
reg add "HKCU\Software\Classes\Directory\shell\SendToLocalEcosystem" /ve /d "Send to Ecosystem" /f >nul
reg add "HKCU\Software\Classes\Directory\shell\SendToLocalEcosystem" /v "Icon" /d "\"%APP_ICON%\"" /f >nul
reg add "HKCU\Software\Classes\Directory\shell\SendToLocalEcosystem\command" /ve /d "\"%APP_EXE%\" --send \"%%1\"" /f >nul

echo Registering for Directory Backgrounds...
reg add "HKCU\Software\Classes\Directory\Background\shell\SendToLocalEcosystem" /ve /d "Send to Ecosystem" /f >nul
reg add "HKCU\Software\Classes\Directory\Background\shell\SendToLocalEcosystem" /v "Icon" /d "\"%APP_ICON%\"" /f >nul
reg add "HKCU\Software\Classes\Directory\Background\shell\SendToLocalEcosystem\command" /ve /d "\"%APP_EXE%\" --send \"%%V\"" /f >nul

echo.
echo [SUCCESS] "Send to Ecosystem" right-click context menu registered successfully!
echo Files will now send silently in the background with native notifications and NO app window popup.
echo ========================================================

