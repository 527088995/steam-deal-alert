@echo off
chcp 65001 >nul
echo 正在打包 Android APK，请确保已关闭其他 Flutter 进程（如 IDE 中的 run）...
echo.

flutter build apk --release

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========== 打包成功 ==========
    echo APK 位置: build\app\outputs\flutter-apk\app-release.apk
    echo 可将该文件拷贝到手机安装。
    echo ==============================
) else (
    echo.
    echo 打包失败，请检查上方错误信息。
)

pause
