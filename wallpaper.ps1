# Папка с обоями берётся из config.txt (создаётся установщиком install.ps1)
$configFile = Join-Path $PSScriptRoot "config.txt"
if (Test-Path $configFile) {
    $WallpaperFolder = (Get-Content $configFile -TotalCount 1).Trim()
} else {
    $WallpaperFolder = "$env:USERPROFILE\Pictures\wallpapers"
}

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

if (-not (Test-Path -LiteralPath $WallpaperFolder)) { exit }

$files = Get-ChildItem -LiteralPath $WallpaperFolder -File |
    Where-Object { $_.Extension -match '^\.(jpg|jpeg|png|bmp)$' }

if ($files.Count -eq 0) { exit }

# Не повторяем предыдущую обоину подряд
$stateFile = Join-Path $PSScriptRoot "last_wallpaper.txt"
if ($files.Count -gt 1 -and (Test-Path $stateFile)) {
    $last = Get-Content $stateFile -ErrorAction SilentlyContinue
    $filtered = @($files | Where-Object { $_.FullName -ne $last })
    if ($filtered.Count -gt 0) { $files = $filtered }
}

$image = ($files | Get-Random).FullName
Set-Content -Path $stateFile -Value $image -NoNewline

# 20 = SPI_SETDESKWALLPAPER, 3 = обновить и сохранить в реестр
[Wallpaper]::SystemParametersInfo(20, 0, $image, 3) | Out-Null
