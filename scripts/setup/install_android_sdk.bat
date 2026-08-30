@echo off
set "JAVA_HOME=C:\Users\Aprajit\tools\jdk-17\jdk-17.0.20.1+1"
set "PATH=%JAVA_HOME%\bin;%PATH%"
set "ANDROID_HOME=C:\Users\Aprajit\tools\android-sdk"
set "ANDROID_SDK_ROOT=C:\Users\Aprajit\tools\android-sdk"

echo JAVA_HOME is %JAVA_HOME%

echo.
echo Accepting Android Licenses...
(for /l %%i in (1,1,30) do @echo y) | "%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" --sdk_root="%ANDROID_HOME%" --licenses

echo.
echo Installing Android SDK Platform, Build-Tools, and Platform-Tools...
(for /l %%i in (1,1,30) do @echo y) | "%ANDROID_HOME%\cmdline-tools\latest\bin\sdkmanager.bat" --sdk_root="%ANDROID_HOME%" "platform-tools" "platforms;android-34" "build-tools;34.0.0"

echo.
echo Android SDK installation complete!
