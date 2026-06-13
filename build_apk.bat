@echo off
set "GRADLE_USER_HOME=%~dp0.gradle_home"
flutter build apk --release %*
