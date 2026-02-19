@echo off
chcp 65001 >nul
set ADB=D:\Android\Sdk\platform-tools\adb.exe
set APK=%~dp0build\app\outputs\apk\release\app-release.apk

echo ========== 1. 请确保手机已用 USB 连接并弹出「允许 USB 调试」时点「允许」 ==========
echo.
%ADB% devices
echo.
if not exist "%APK%" (
    echo 错误：未找到 APK，请先打包。路径：%APK%
    pause
    exit /b 1
)

echo ========== 2. 安装 APK 到手机 ==========
%ADB% install -r "%APK%"
if errorlevel 1 (
    echo 安装失败。若显示 device unauthorized，请在手机上点「允许」后重新运行本脚本。
    pause
    exit /b 1
)

echo.
echo ========== 3. 启动应用并开始抓取日志（请保持手机连接） ==========
%ADB% shell am start -n com.steamdeal.alert/.MainActivity
timeout /t 3 /nobreak >nul

echo 正在抓取最近日志（含崩溃信息）...
%ADB% logcat -d -t 500 *:E 2>nul
echo.
echo 以上为错误级别日志。若应用闪退，请将上面输出复制给开发者分析。
pause
