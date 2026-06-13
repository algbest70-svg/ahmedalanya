@echo off
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "PATH=%JAVA_HOME%\bin;%PATH%"
echo [0/3] Cleaning up background processes...
taskkill /f /im java.exe /t 2>nul
taskkill /f /im gradlew.bat /t 2>nul
echo.
echo [1/3] Using Java version:
java -version
echo.
echo [2/3] Cleaning project...
call flutter clean
echo.
echo [3/3] Building APK...
call flutter build apk --release --no-tree-shake-icons
echo.
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ======================================================
    echo BUILD SUCCESSFUL!
    echo Your APK is at:
    echo build\app\outputs\flutter-apk\app-release.apk
    echo ======================================================
) else (
    echo.
    echo ======================================================
    echo BUILD FAILED with error code %ERRORLEVEL%
    echo ======================================================
)
pause
