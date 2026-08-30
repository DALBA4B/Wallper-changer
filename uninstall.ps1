function Wait-Key {
    Write-Host "Для продолжения нажми Enter..."
    [void][System.Console]::ReadLine()
    while ([System.Console]::KeyAvailable) { [void][System.Console]::ReadKey($true) }
}
# Деинсталлятор Wallpaper Changer
$ErrorActionPreference = "Continue"

# Определяем, где лежит установленная программа (там же wallpaper.ps1 + config.txt)
$installDir = $PSScriptRoot
if (-not (Test-Path (Join-Path $installDir "wallpaper.ps1"))) {
    # Возможно, UNINSTALL запущен из репозитория — ищем через ярлык автозагрузки
    $lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\wallpaper.lnk"
    if (Test-Path $lnk) {
        $shell = New-Object -ComObject WScript.Shell
        $args = $shell.CreateShortcut($lnk).Arguments
        if ($args -match '"([^"]+wallpaper\.ps1)"') {
            $installDir = Split-Path $Matches[1]
        }
    }
}

Write-Host "Wallpaper Changer - удаление" -ForegroundColor Cyan
Write-Host ""

# Сначала подтверждение, потом любые действия
Write-Host "Будет удалено:"
Write-Host "  - ярлык автозагрузки"
if (Test-Path (Join-Path $installDir "wallpaper.ps1")) {
    Write-Host "  - файлы программы из '$installDir'"
}
Write-Host ""
$answer = Read-Host "Удалить Wallpaper Changer? (Y/N)"
if ($answer -notmatch "^[YyДд]") {
    Write-Host "Отменено. Ничего не удалено." -ForegroundColor Yellow
    Wait-Key
    exit 0
}

# 1. Снимаем с автозагрузки
$lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\wallpaper.lnk"
if (Test-Path $lnk) {
    Remove-Item $lnk -Force
    Write-Host "[OK] Ярлык автозагрузки удалён" -ForegroundColor Green
} else {
    Write-Host "[--] Ярлык автозагрузки не найден (уже удалён?)" -ForegroundColor DarkYellow
}

# 2. Удаляем файлы программы — ТОЛЬКО свои файлы по списку, папку не трогаем
$files = @("wallpaper.ps1", "install.ps1", "manage.ps1", "uninstall.ps1",
           "START.bat", "UNINSTALL.bat", "README.md", "config.txt", "last_wallpaper.txt")
$targets = @()
foreach ($f in $files) {
    $p = Join-Path $installDir $f
    if (Test-Path $p) { $targets += $p }
}

if ($targets.Count -gt 0) {
    # Удаляем через внешний bat, чтобы можно было стереть и скрипт, из которого запущено удаление
    $cleanup = Join-Path $env:TEMP "wc_cleanup.bat"
    $lines = @("@echo off", "timeout /t 2 /nobreak >nul")
    foreach ($t in $targets) { $lines += "del /f /q `"$t`"" }
    $lines += "del /f /q `"%~f0`""
    $lines | Out-File $cleanup -Encoding ascii
    Start-Process cmd.exe -ArgumentList "/c `"$cleanup`"" -WindowStyle Hidden
    Write-Host "[OK] Файлы программы удаляются ($($targets.Count) шт.)..." -ForegroundColor Green
} else {
    Write-Host "[--] Файлы программы не найдены в $installDir" -ForegroundColor DarkYellow
}

Write-Host ""
Write-Host "Готово!" -ForegroundColor Green
Wait-Key
