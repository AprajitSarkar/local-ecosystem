@echo off
set "JAVA_HOME=C:\Users\Aprajit\tools\jdk-17\jdk-17.0.20.1+1"
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "ANDROID_HOME=C:\Users\Aprajit\tools\android-sdk"
set "ANDROID_SDK_ROOT=C:\Users\Aprajit\tools\android-sdk"

echo Installing CMake 3.22.1 and NDK...
(for /l %%i in (1,1,30) do @echo y) | "%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" --sdk_root="%ANDROID_HOME%" "cmake;3.22.1" "ndk;27.0.12077973"
