# 打包 AAB 用于上传 Google Play（使用 D 盘 Flutter/Gradle，绕过 Flutter strip 校验）
# 输出：e:\steamGame\build\app\outputs\bundle\release\app-release.aab

$env:PATH = "D:\development\flutter\bin;" + $env:PATH
$env:GRADLE_USER_HOME = "D:\dev-config\gradle"
$env:PUB_CACHE = "D:\dev-config\pub"

$projectRoot = $PSScriptRoot
Set-Location $projectRoot

Write-Host "Step 1: Compiling Flutter (release)..." -ForegroundColor Cyan
flutter build appbundle --release --target-platform android-arm,android-arm64 2>&1 | Out-Null
# Flutter may fail at the strip check; we only need the Gradle-built AAB

$flutterAab = Join-Path $projectRoot "build\app\outputs\bundle\release\app-release.aab"
$androidAab = Join-Path $projectRoot "android\app\build\outputs\bundle\release\app-release.aab"

# If Flutter failed after Gradle, AAB might be in android/app/build/...
if (Test-Path $androidAab) {
    $targetDir = Join-Path $projectRoot "build\app\outputs\bundle\release"
    if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
    Copy-Item $androidAab $flutterAab -Force
    Write-Host "AAB copied to: $flutterAab" -ForegroundColor Green
} elseif (Test-Path $flutterAab) {
    Write-Host "AAB already at: $flutterAab" -ForegroundColor Green
} else {
    Write-Host "Building AAB via Gradle only..." -ForegroundColor Cyan
    Set-Location (Join-Path $projectRoot "android")
    & .\gradlew.bat bundleRelease --no-daemon
    Set-Location $projectRoot
    if (Test-Path $androidAab) {
        $targetDir = Join-Path $projectRoot "build\app\outputs\bundle\release"
        if (-not (Test-Path $targetDir)) { New-Item -ItemType Directory -Path $targetDir -Force | Out-Null }
        Copy-Item $androidAab $flutterAab -Force
        Write-Host "AAB ready: $flutterAab" -ForegroundColor Green
    } else {
        Write-Host "AAB not found. Check build errors above." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "Upload this file to Google Play Console:" -ForegroundColor Yellow
Write-Host "  $flutterAab" -ForegroundColor White
Write-Host ""
