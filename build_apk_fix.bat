@echo off
echo [1/4] Cleaning Flutter...
flutter clean

echo [2/4] Cleaning Pub Cache (This may take time)...
call flutter pub cache clean --force

echo [3/4] Fetching Dependencies...
flutter pub get

echo [4/4] Building Release APK...
flutter build apk --release --no-tree-shake-icons

echo.
echo ======================================================
echo If the build finished successfully, your APK is at:
echo build\app\outputs\flutter-apk\app-release.apk
echo ======================================================
pause
