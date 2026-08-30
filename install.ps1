function Wait-Key {
    Write-Host "Для продолжения нажми Enter..."
    [void][System.Console]::ReadLine()
    while ([System.Console]::KeyAvailable) { [void][System.Console]::ReadKey($true) }
}
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
if (-not $wallpaperFolder) { Write-Host "Отменено." -ForegroundColor Yellow; Wait-Key; exit 1 }

# 2. Куда установить программу
$installDir = Select-Folder "Выбери папку, КУДА установить Wallpaper Changer"
if (-not $installDir) { Write-Host "Отменено." -ForegroundColor Yellow; Wait-Key; exit 1 }

# Корень диска — плохое место: туда нужны права администратора и свалка файлов в корне
if ($installDir -match '^[A-Za-z]:\\?$') {
    Write-Host "Корень диска ($installDir) не подходит — выбери или создай обычную папку, например C:\WallpaperChanger" -ForegroundColor Red
    pause; exit 1
}

# Запрещаем «широкие» папки: программа создаёт несколько файлов и потом должна чисто удалиться
$forbidden = @(
    [Environment]::GetFolderPath("Desktop"),
    [Environment]::GetFolderPath("MyDocuments"),
    [Environment]::GetFolderPath("UserProfile"),
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Pictures",
    "$env:USERPROFILE\Desktop",
    "$env:SystemRoot"
)
if ($forbidden -contains $installDir.TrimEnd('\')) {
    Write-Host "В саму папку '$installDir' ставить нельзя — там лягут файлы программы среди твоих личных." -ForegroundColor Red
    Write-Host "Выбери или создай внутри неё отдельную подпапку (например, WallpaperChanger)." -ForegroundColor Yellow
    pause; exit 1
}

# Копируем все файлы программы и сохраняем конфиг
$files = @("wallpaper.ps1", "install.ps1", "manage.ps1", "uninstall.ps1", "START.bat", "UNINSTALL.bat", "README.md")
try {
    New-Item -ItemType Directory -Force -Path $installDir -ErrorAction Stop | Out-Null
    foreach ($f in $files) {
        $src = Join-Path $PSScriptRoot $f
        $dst = Join-Path $installDir $f
        if ((Test-Path $src) -and ($src -ne $dst)) {
            Copy-Item $src $dst -Force -ErrorAction Stop
        }
    }
    Set-Content (Join-Path $installDir "config.txt") -Value $wallpaperFolder -NoNewline -ErrorAction Stop
} catch {
    Write-Host "Ошибка установки в $installDir" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-Host "Возможно, нет прав на запись в эту папку. Выбери другую (например, внутри Документов или Рабочего стола)." -ForegroundColor Yellow
    Wait-Key; exit 1
}

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
Wait-Key
