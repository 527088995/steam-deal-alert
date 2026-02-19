@echo off
chcp 65001 >nul
echo ========== 环境诊断（不打包，只检查） ==========
echo.

set PUB_HOSTED_URL=https://pub.dev
set FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com
set JAVA_HOME=E:\java\jdk-11.0.9
cd /d "%~dp0"

echo [1] Flutter 与 Android 环境...
flutter doctor -v
echo.

echo [2] 依赖拉取（官方源）...
flutter pub get
if errorlevel 1 (
    echo.
    echo >>> pub get 失败：多为网络或镜像问题，请检查能否访问 https://pub.dev
) else (
    echo.
    echo >>> pub get 成功，依赖无问题。
)

echo.
echo ========== 若上面都正常，请用 build_apk_full.bat 打包 ==========
pause
