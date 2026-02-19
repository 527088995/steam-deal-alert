# 使用 D 盘环境打包 AAB（用于 Google Play 上架）
# 用法：.\build-aab-with-d.ps1
# 输出：build\app\outputs\bundle\release\app-release.aab

$ErrorActionPreference = "Stop"
$env:PATH               = "D:\development\flutter\bin;" + $env:PATH
$env:GRADLE_USER_HOME   = "D:\dev-config\gradle"
$env:PUB_CACHE          = "D:\dev-config\pub"
$env:ANDROID_HOME       = "D:\Android\Sdk"
$env:ANDROID_SDK_ROOT   = "D:\Android\Sdk"

Set-Location $PSScriptRoot

Write-Host "D drive env: Flutter, Pub, Gradle, Android SDK (all on D)..." -ForegroundColor Cyan
Write-Host "Building release AAB (App Bundle for Google Play)..." -ForegroundColor Cyan
flutter build appbundle --release
if ($LASTEXITCODE -ne 0) { Write-Host "Build failed." -ForegroundColor Red; exit 1 }

$aab = ".\build\app\outputs\bundle\release\app-release.aab"
if (-not (Test-Path $aab)) { Write-Host "AAB not found: $aab" -ForegroundColor Red; exit 1 }

$resolved = (Resolve-Path $aab).Path
Write-Host "Done. AAB: $resolved" -ForegroundColor Green
Write-Host "Upload to Google Play Console: Play Console -> Your App -> Release -> Create new release -> Upload $resolved"
