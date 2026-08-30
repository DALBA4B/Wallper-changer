# Установщик Wallpaper Changer: два окна выбора папок, затем всё настраивается само
Add-Type -AssemblyName System.Windows.Forms

function Select-Folder($Description) {
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = $Description
    $dialog.ShowNewFolderButton = $true
    if ($dialog.ShowDialog() -eq "OK") { return $dialog.SelectedPath }
    return $null
}

Write-Host "Wallpaper Changer - установка" -ForegroundColor Cyan

# 1. Откуда брать обои
$wallpaperFolder = Select-Folder "Выбери папку, ОТКУДА брать картинки для обоев"
if (-not $wallpaperFolder) { Write-Host "Отменено." -ForegroundColor Yellow; pause; exit 1 }

# 2. Куда установить программу
$installDir = Select-Folder "Выбери папку, КУДА установить Wallpaper Changer"
if (-not $installDir) { Write-Host "Отменено." -ForegroundColor Yellow; pause; exit 1 }
New-Item -ItemType Directory -Force -Path $installDir | Out-Null

# Копируем основной скрипт и сохраняем конфиг
$sourceScript = Join-Path $PSScriptRoot "wallpaper.ps1"
$targetScript = Join-Path $installDir "wallpaper.ps1"
if ($sourceScript -ne $targetScript) {
    Copy-Item $sourceScript $targetScript -Force
}
Set-Content (Join-Path $installDir "config.txt") -Value $wallpaperFolder -NoNewline

# Создаём скрытый ярлык в автозагрузке
$startup = [Environment]::GetFolderPath("Startup")
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut("$startup\wallpaper.lnk")
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$installDir\wallpaper.ps1`""
$shortcut.WindowStyle = 7
$shortcut.Save()

Write-Host ""
Write-Host "Готово!" -ForegroundColor Green
Write-Host "Программа установлена в: $installDir"
Write-Host "Обои берутся из: $wallpaperFolder"
Write-Host "Автозапуск добавлен. Обои будут меняться при каждом включении ПК."
pause
