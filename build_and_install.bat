@echo off
set PUB_HOSTED_URL=https://pub.dev
set FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com
set ANDROID_HOME=D:\Android\Sdk
set ANDROID_SDK_ROOT=D:\Android\Sdk
set JAVA_HOME=E:\java\jdk-11.0.9
cd /d "%~dp0"

taskkill /F /IM dart.exe 2>nul
del /f /q "D:\Flutter\flutter_windows_v1.12.13\flutter\bin\cache\lockfile" 2>nul

echo Running flutter pub get...
flutter pub get
if errorlevel 1 exit /b 1

echo Running flutter build apk --release...
flutter build apk --release
if errorlevel 1 exit /b 1

set ADB=%ANDROID_HOME%\platform-tools\adb.exe
echo Installing to device...
"%ADB%" install -r "build\app\outputs\apk\release\app-release.apk"
if errorlevel 1 (
    echo Install failed or no device. Connect phone with USB debugging.
) else (
    "%ADB%" shell am start -n com.steamdeal.alert/.MainActivity 2>nul
    echo Installed and launched.
)
echo APK: build\app\outputs\apk\release\app-release.apk
pause
