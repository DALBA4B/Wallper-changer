# Управление Wallpaper Changer: смена папки обоев или перенос программы
param([ValidateSet("wallpapers", "move")][string]$Mode)

function Wait-Key {
    Write-Host "Для продолжения нажми Enter..."
    [void][System.Console]::ReadLine()
    while ([System.Console]::KeyAvailable) { [void][System.Console]::ReadKey($true) }
}

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
    Wait-Key; exit 1
}

if ($Mode -eq "wallpapers") {
    $folder = Select-Folder "Выбери новую папку, ОТКУДА брать обои"
    if (-not $folder) { Write-Host "Отменено."; Wait-Key; exit 1 }
    Set-Content (Join-Path $installDir "config.txt") -Value $folder -NoNewline
    Write-Host "[OK] Теперь обои берутся из: $folder" -ForegroundColor Green
}
else {
    $parent = Select-Folder "Выбери папку, КУДА перенести программу (внутри будет создана подпапка WallpaperChanger)"
    if (-not $parent) { Write-Host "Отменено."; Wait-Key; exit 1 }
    if ((Split-Path $parent -Leaf) -eq "WallpaperChanger") { $newDir = $parent } else { $newDir = Join-Path $parent "WallpaperChanger" }
    if ($newDir -eq $installDir) { Write-Host "Это та же папка. Ничего не делаем."; Wait-Key; exit 0 }

    # Создаём папку, если её нет
    $files = @("wallpaper.ps1", "install.ps1", "manage.ps1", "uninstall.ps1", "START.bat", "UNINSTALL.bat")
    try {
        if (-not (Test-Path -LiteralPath $newDir)) {
            New-Item -ItemType Directory -Path $newDir -ErrorAction Stop | Out-Null
        }
        foreach ($f in $files) {
            $src = Join-Path $installDir $f
            if (Test-Path $src) { Copy-Item $src (Join-Path $newDir $f) -Force -ErrorAction Stop }
        }
        $config = Join-Path $installDir "config.txt"
        if (Test-Path $config) { Copy-Item $config $newDir -Force -ErrorAction Stop }
    } catch {
        Write-Host "Ошибка переноса в $newDir" -ForegroundColor Red
        Write-Host $_.Exception.Message
        Wait-Key; exit 1
    }

    # Перевешиваем автозагрузку на новое место
    $lnk = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\wallpaper.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($lnk)
    $shortcut.TargetPath = "powershell.exe"
    $shortcut.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$newDir\wallpaper.ps1`""
    $shortcut.WindowStyle = 7
    $shortcut.Save()

    # Чистим старое место
    foreach ($f in $files) {
        Remove-Item (Join-Path $installDir $f) -Force -ErrorAction SilentlyContinue
    }
    Remove-Item (Join-Path $installDir "config.txt") -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $installDir "last_wallpaper.txt") -Force -ErrorAction SilentlyContinue

    Write-Host "[OK] Программа перенесена в: $newDir" -ForegroundColor Green
    Write-Host "Автозагрузка обновлена."
}
Wait-Key
