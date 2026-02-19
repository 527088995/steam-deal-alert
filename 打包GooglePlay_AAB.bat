@echo off
chcp 65001 >nul
echo Building AAB for Google Play (requires target API 35, JDK 17)...
echo.

REM Try JDK 17 (required by Android Gradle Plugin 8.6)
if exist "E:\java\jdk-17" (set "JAVA_HOME=E:\java\jdk-17" & goto :build)
if exist "E:\java\jdk-17.0.9" (set "JAVA_HOME=E:\java\jdk-17.0.9" & goto :build)
if exist "C:\Program Files\Java\jdk-17" (set "JAVA_HOME=C:\Program Files\Java\jdk-17" & goto :build)
if exist "C:\Program Files\Microsoft\jdk-17*" (
  for /d %%d in ("C:\Program Files\Microsoft\jdk-17*") do set "JAVA_HOME=%%d" & goto :build
)
echo [ERROR] JDK 17 not found. Build for Google Play (API 35) needs JDK 17.
echo Please install JDK 17 and either:
echo   1. Set JAVA_HOME to JDK 17, or
echo   2. Put JDK 17 in E:\java\jdk-17
echo Download: https://adoptium.net/ or https://www.oracle.com/java/technologies/downloads/#java17
pause
exit /b 1

:build
set ANDROID_HOME=D:\Android\Sdk
cd /d "e:\steamGame"
call flutter pub get
call flutter build appbundle --release
if %ERRORLEVEL% neq 0 (echo. & echo Build failed. & pause & exit /b 1)
echo.
echo Done. AAB: e:\steamGame\build\app\outputs\bundle\release\app-release.aab
pause
