# 使用 D 盘环境打包 APK 并安装到手机（所有下载/缓存走 D 盘）
# 用法：手机 USB 连接并开启调试后，在 PowerShell 中执行 .\build-and-install-with-d.ps1
# 环境与 build-with-d.ps1 一致：Flutter、Pub、Gradle、Android SDK 均用 D 盘

$ErrorActionPreference = "Stop"
$env:PATH               = "D:\Android\Sdk\platform-tools;D:\development\flutter\bin;" + $env:PATH
$env:GRADLE_USER_HOME   = "D:\dev-config\gradle"
$env:PUB_CACHE          = "D:\dev-config\pub"
$env:ANDROID_HOME       = "D:\Android\Sdk"
$env:ANDROID_SDK_ROOT   = "D:\Android\Sdk"

Set-Location $PSScriptRoot

Write-Host "D drive env: Flutter, Pub, Gradle, Android SDK (all on D)..." -ForegroundColor Cyan
Write-Host "Building release APK..." -ForegroundColor Cyan
flutter build apk --release
if ($LASTEXITCODE -ne 0) { Write-Host "Build failed." -ForegroundColor Red; exit 1 }

$apk = ".\build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apk)) { Write-Host "APK not found: $apk" -ForegroundColor Red; exit 1 }

Write-Host "Installing to connected device..." -ForegroundColor Cyan
adb install -r (Resolve-Path $apk).Path
if ($LASTEXITCODE -ne 0) { Write-Host "Install failed. Check USB and 'adb devices'." -ForegroundColor Red; exit 1 }

Write-Host "Done. App installed." -ForegroundColor Green
