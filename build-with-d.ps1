# 使用 D 盘环境打包/运行（所有下载与缓存均放 D 盘）
# - Flutter SDK: D:\development\flutter
# - Pub 缓存:   D:\dev-config\pub
# - Gradle:     D:\dev-config\gradle
# - Android SDK: D:\Android\Sdk
# 用法: .\build-with-d.ps1                → 打包 release APK
#       .\build-with-d.ps1 run            → 安装到手机并运行 (flutter run)
#       .\build-with-d.ps1 build apk      → 显式打包 APK
#       .\build-with-d.ps1 build appbundle → 打包 AAB（Google Play 上架）

$ErrorActionPreference = "Stop"
$ProjectRoot = $PSScriptRoot

# D 盘环境（所有下载/缓存走 D 盘）
$env:PATH               = "D:\development\flutter\bin;" + $env:PATH
$env:GRADLE_USER_HOME   = "D:\dev-config\gradle"
$env:PUB_CACHE          = "D:\dev-config\pub"
$env:ANDROID_HOME       = "D:\Android\Sdk"
$env:ANDROID_SDK_ROOT   = "D:\Android\Sdk"

Write-Host "D drive env: Flutter(D), PUB_CACHE(D), GRADLE_USER_HOME(D), ANDROID_SDK(D)" -ForegroundColor Cyan
Write-Host "  GRADLE_USER_HOME = $env:GRADLE_USER_HOME"
Write-Host "  PUB_CACHE        = $env:PUB_CACHE"
Write-Host "  ANDROID_SDK_ROOT = $env:ANDROID_SDK_ROOT"
Write-Host ""

$cmd = $args
if ($cmd.Count -eq 0) {
    $cmd = @("build", "apk")
    Write-Host "未传参，默认执行: flutter build apk（AAB 用 .\build-aab-with-d.ps1）"
}

Set-Location $ProjectRoot
& flutter @cmd
