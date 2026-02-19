@echo off
REM Add Flutter on D drive to PATH for this session. Run before: flutter doctor / pub get / build
set "FLUTTER_ROOT=D:\development\flutter"
if not exist "%FLUTTER_ROOT%\bin\flutter.bat" (
    echo Flutter not found at %FLUTTER_ROOT%. Please complete install or extract zip there.
    pause
    exit /b 1
)
set "PATH=%FLUTTER_ROOT%\bin;%PATH%"
REM 国内镜像：pub 包与 Flutter 资源
set "PUB_HOSTED_URL=https://mirrors.tuna.tsinghua.edu.cn/dart-pub"
set "FLUTTER_STORAGE_BASE_URL=https://mirrors.tuna.tsinghua.edu.cn/flutter"
echo Flutter (D) + TUNA mirror is ready: %FLUTTER_ROOT%
flutter --version
exit /b 0
