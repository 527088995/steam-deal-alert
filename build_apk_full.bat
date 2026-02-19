@echo off
chcp 65001 >nul
echo ========== Steam Deal Alert 打包脚本 ==========
echo.

echo [1/5] 结束可能占用 Flutter 的 dart 进程...
taskkill /F /IM dart.exe 2>nul
timeout /t 2 /nobreak >nul

echo [2/5] 删除 Flutter 锁文件...
del /f /q "D:\Flutter\flutter_windows_v1.12.13\flutter\bin\cache\lockfile" 2>nul

echo [3/5] 使用官方源拉取依赖并打包（请保持网络畅通）...
set PUB_HOSTED_URL=https://pub.dev
set FLUTTER_STORAGE_BASE_URL=https://storage.googleapis.com
set ANDROID_HOME=D:\Android\Sdk
set ANDROID_SDK_ROOT=D:\Android\Sdk
set JAVA_HOME=E:\java\jdk-11.0.9
cd /d "%~dp0"

flutter pub get
if errorlevel 1 (
    echo pub get 失败，请检查网络或镜像配置。
    pause
    exit /b 1
)

flutter build apk --release
if errorlevel 1 (
    echo.
    echo 打包失败，请查看上方错误信息。
    pause
    exit /b 1
)

echo.
echo [4/5] 检查已连接设备...
set ADB=%ANDROID_HOME%\platform-tools\adb.exe
"%ADB%" devices
echo.

echo [5/5] 安装到手机（若有设备）...
"%ADB%" install -r "build\app\outputs\apk\release\app-release.apk"
if errorlevel 1 (
    echo 安装失败或未连接设备，请用 USB 连接手机并开启 USB 调试后重试。
) else (
    echo 已安装到手机，可手动启动应用。
    "%ADB%" shell am start -n com.steamdeal.alert/.MainActivity 2>nul
)

echo.
echo ========== 完成 ==========
echo APK 位置: build\app\outputs\apk\release\app-release.apk
echo ==============================
pause
