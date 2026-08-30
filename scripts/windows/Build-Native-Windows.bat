@echo off
title Build Native Windows App - Local Ecosystem
echo ========================================================
echo   Building Native Flutter Windows Desktop Executable
echo ========================================================
echo.

cd /d "%~dp0App"

echo Running flutter pub get...
call flutter pub get

echo.
echo Compiling Native Windows Desktop App (Release mode)...
call flutter build windows --release

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ========================================================
    echo   [BUILD FAILED] Missing Native C++ Build Tools
    echo ========================================================
    echo Flutter requires Visual Studio C++ build tools to compile
    echo native Windows .exe applications.
    echo.
    echo To install them automatically:
    echo 1. Run "Install-VS-BuildTools.bat" in the main folder.
    echo    OR download from https://visualstudio.microsoft.com/downloads/
    echo    and check "Desktop development with C++".
    echo.
    echo 2. After installation completes, run this script again!
    echo ========================================================
    pause
    exit /b 1
)

echo.
echo ========================================================
echo   Copying Native Executable ^& Assets to Output
echo ========================================================

set OUT_DIR=%~dp0build_artifacts\windows\LocalEcosystem-Native
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

xcopy /E /I /Y /Q "%~dp0App\build\windows\x64\runner\Release\*" "%OUT_DIR%\"
copy /Y "%~dp0build_artifacts\windows\LocalEcosystem\app_icon.ico" "%OUT_DIR%\"

echo.
echo [SUCCESS] 100%% Native Windows Desktop Application Built!
echo Output location: %OUT_DIR%\local_ecosystem.exe
echo.
pause
