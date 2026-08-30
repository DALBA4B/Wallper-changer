@echo off
chcp 65001 >nul
title Wallpaper Changer - удаление

:: 1. Убираем из автозагрузки
set "LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\wallpaper.lnk"
if exist "%LNK%" (
    del "%LNK%"
    echo [OK] Автозагрузка удалена
) else (
    echo Автозагрузка не найдена - пропускаем
)

:: 2. Удаляем файлы проекта (папка установки или текущая)
echo.
set /p "TARGET=Удалить файлы Wallpaper Changer из папки (Enter = эта папка): "
if "%TARGET%"=="" set "TARGET=%~dp0"

if not exist "%TARGET%\wallpaper.ps1" (
    echo Файлы не найдены в "%TARGET%"
    pause
    exit /b 1
)

:: Удаляем через временный скрипт, чтобы можно было стереть и саму папку
set "CLEAN=%TEMP%\wc_cleanup.bat"
> "%CLEAN%" echo @echo off
>> "%CLEAN%" echo timeout /t 1 /nobreak ^>nul
>> "%CLEAN%" echo rmdir /s /q "%TARGET%"
>> "%CLEAN%" echo del /f /q "%CLEAN%"
start "" /min "%CLEAN%"
echo [OK] Файлы удаляются...
