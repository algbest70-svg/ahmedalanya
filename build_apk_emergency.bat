@echo off
set "JAVA_HOME=C:\Program Files\Android\Android Studio\jbr"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo [1/5] Force-killing java and gradle...
taskkill /f /im java.exe /t 2>nul
taskkill /f /im gradlew.bat /t 2>nul

echo [2/5] Cleaning caches...
rd /s /q "C:\Users\mehdi\.gradle\caches" 2>nul
rd /s /q "android\.gradle" 2>nul

echo [3/5] Flutter clean...
call flutter clean

echo [4/5] Flutter pub get...
call flutter pub get

echo [5/5] Building APK (Release)...
call flutter build apk --release --no-tree-shake-icons -v

if %ERRORLEVEL% EQU 0 (
    echo BUILD SUCCESSFUL!
    echo APK is at build\app\outputs\flutter-apk\app-release.apk
) else (
    echo BUILD FAILED with code %ERRORLEVEL%
)
pause
