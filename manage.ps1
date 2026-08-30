# Управление Wallpaper Changer: смена папки обоев или перенос программы
param([ValidateSet("wallpapers", "move")][string]$Mode)

Add-Type -AssemblyName System.Windows.Forms

# Находим папку, куда установлена программа (по ярлыку автозагрузки)
function Get-InstallDir {
    $lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\wallpaper.lnk"
    if (Test-Path $lnk) {
        $shell = New-Object -ComObject WScript.Shell
        $args = $shell.CreateShortcut($lnk).Arguments
        if ($args -match '"([^"]+wallpaper\.ps1)"') {
            return Split-Path $Matches[1]
        }
    }
    # Fallback: программа установлена рядом с этим скриптом
    if (Test-Path (Join-Path $PSScriptRoot "wallpaper.ps1")) { return $PSScriptRoot }
    return $null
}

function Select-Folder($Description) {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $true
    if ($dialog.ShowDialog() -eq "OK") { return $dialog.SelectedPath }
    return $null
}

$installDir = Get-InstallDir
if (-not $installDir) {
    Write-Host "Программа не установлена. Сначала выбери пункт 1 (Установка)." -ForegroundColor Red
    pause; exit 1
}

if ($Mode -eq "wallpapers") {
    $folder = Select-Folder "Выбери новую папку, ОТКУДА брать обои"
    if (-not $folder) { Write-Host "Отменено."; pause; exit 1 }
    Set-Content (Join-Path $installDir "config.txt") -Value $folder -NoNewline
    Write-Host "[OK] Теперь обои берутся из: $folder" -ForegroundColor Green
}
else {
    $newDir = Select-Folder "Выбери папку, КУДА перенести программу"
    if (-not $newDir) { Write-Host "Отменено."; pause; exit 1 }
    if ($newDir -eq $installDir) { Write-Host "Это та же папка. Ничего не делаем."; pause; exit 0 }

    New-Item -ItemType Directory -Force -Path $newDir | Out-Null
    Copy-Item (Join-Path $installDir "wallpaper.ps1") $newDir -Force
    $config = Join-Path $installDir "config.txt"
    if (Test-Path $config) { Copy-Item $config $newDir -Force }

    # Перевешиваем автозагрузку на новое место
    $lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\wallpaper.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($lnk)
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$newDir\wallpaper.ps1`""
    $shortcut.WindowStyle = 7
    $shortcut.Save()

    # Чистим старое место
    Remove-Item (Join-Path $installDir "wallpaper.ps1") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $installDir "config.txt") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $installDir "last_wallpaper.txt") -Force -ErrorAction SilentlyContinue

    Write-Host "[OK] Программа перенесена в: $newDir" -ForegroundColor Green
    Write-Host "Автозагрузка обновлена."
}
pause
