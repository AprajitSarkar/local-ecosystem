@echo off
title Install Visual Studio C++ Build Tools for Flutter Windows
echo =======================================================================
echo   Installing Visual Studio 2022 C++ Tools for Windows App Compilation
echo =======================================================================
echo.
echo Flutter needs the C++ Desktop workload to compile native .exe apps.
echo.
echo Installing via Windows Package Manager (winget)...
echo.

winget install --id Microsoft.VisualStudio.2022.BuildTools --override "--passive --wait --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended" --accept-package-agreements --accept-source-agreements

if %ERRORLEVEL% EQU 0 (
    echo.
    echo =======================================================================
    echo [SUCCESS] Visual Studio C++ Build Tools installed successfully!
    echo Now run Build-Native-Windows.bat to compile your native Windows app.
    echo =======================================================================
) else (
    echo.
    echo =======================================================================
    echo If winget requires elevation, download and run the installer directly:
    echo https://visualstudio.microsoft.com/downloads/
    echo (Make sure to check "Desktop development with C++" during setup)
    echo =======================================================================
)

pause
