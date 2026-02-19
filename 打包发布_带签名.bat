@echo off
chcp 65001 >nul
echo ========================================
echo   一键打出带 release 签名的 AAB
echo   用于上传 Google Play
echo ========================================
echo.

set PUB_HOSTED_URL=https://pub.dev
set FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com
set ANDROID_HOME=D:\Android\Sdk
set JAVA_HOME=E:\java\jdk-11.0.9
cd /d "%~dp0"

if not exist "android\key.properties" (
    echo [提示] 未找到 android\key.properties，无法使用 release 签名。
    echo.
    echo 请先完成一次性配置：
    echo   1. 双击运行 android\create_keystore.bat 生成密钥库
    echo   2. 将 android\key.properties.example 复制为 android\key.properties
    echo   3. 在 key.properties 里填写 storePassword、keyPassword、keyAlias=upload、storeFile=../upload-keystore.jks
    echo.
    echo 完成后再次运行本脚本即可打出已签名的 AAB。
    pause
    exit /b 1
)

if not exist "android\upload-keystore.jks" (
    echo [提示] 未找到 android\upload-keystore.jks，请先运行 android\create_keystore.bat 生成。
    pause
    exit /b 1
)

echo 正在打包 release 签名 AAB，请稍候...
echo.
flutter pub get
if errorlevel 1 (
    echo pub get 失败
    pause
    exit /b 1
)

flutter build appbundle --release
if errorlevel 1 (
    echo 打包失败，请查看上方错误信息
    pause
    exit /b 1
)

echo.
echo ========================================
echo [完成] 已生成带 release 签名的 AAB
echo 路径: build\app\outputs\bundle\release\app-release.aab
echo 请将此文件上传到 Google Play 控制台
echo ========================================
pause
