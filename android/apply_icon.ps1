# Apply app icon to Android launcher (supports non-square: center-crop to square)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$assets = "e:\steamGame\assets"
$src = $null
foreach ($name in @("app_icon_512.png", "app_icon_source.png")) {
    $p = Join-Path $assets $name
    if (Test-Path $p) { $src = $p; break }
}
if (-not $src) {
    Write-Host "No icon found. Put app_icon_source.png or app_icon_512.png in assets."
    exit 1
}

$res = "e:\steamGame\android\app\src\main\res"
$sizes = @{
    "mipmap-mdpi" = 48
    "mipmap-hdpi" = 72
    "mipmap-xhdpi" = 96
    "mipmap-xxhdpi" = 144
    "mipmap-xxxhdpi" = 192
}

$img = [System.Drawing.Image]::FromFile((Resolve-Path $src))
try {
    $w = $img.Width
    $h = $img.Height
    $side = [Math]::Min($w, $h)
    $x = [Math]::Max(0, ($w - $side) / 2)
    $y = [Math]::Max(0, ($h - $side) / 2)
    $rect = New-Object System.Drawing.Rectangle([int]$x, [int]$y, [int]$side, [int]$side)
    $cropped = New-Object System.Drawing.Bitmap($side, $side)
    $g = [System.Drawing.Graphics]::FromImage($cropped)
    $g.DrawImage($img, 0, 0, $rect, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    $img.Dispose()
    $img = $cropped
} catch {
    $img.Dispose()
    throw
}

try {
    foreach ($folder in $sizes.Keys) {
        $size = $sizes[$folder]
        $dir = Join-Path $res $folder
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        $out = Join-Path $dir "ic_launcher.png"
        $bmp = New-Object System.Drawing.Bitmap($img, $size, $size)
        $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
        $bmp.Dispose()
        Write-Host "Written $out ($size x $size)"
    }
} finally {
    $img.Dispose()
}
Write-Host "Done. Rebuild the app to see the new icon."
