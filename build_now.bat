@echo off
set "ANDROID_HOME=D:\Android\Sdk"
set "PUB_HOSTED_URL=https://pub.dev"
set "FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com"
set "JAVA_HOME=E:\java\jdk-11.0.9"
cd /d "%~dp0"
flutter pub get
if errorlevel 1 exit /b 1
flutter build apk --release
if errorlevel 1 exit /b 1
echo BUILD_OK
