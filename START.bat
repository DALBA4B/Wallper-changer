@echo off
title Wallpaper Changer

:menu
cls
echo =====================================
echo        WALLPAPER CHANGER
echo =====================================
echo.
echo   1. Установка
echo   2. Сменить папку с обоями
echo   3. Перенести программу в другую папку
echo   4. Удалить
echo   0. Выход
echo.
set /p choice="Выбери пункт: "

if "%choice%"=="1" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1" & goto menu
if "%choice%"=="2" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0manage.ps1" -Mode wallpapers & goto menu
if "%choice%"=="3" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0manage.ps1" -Mode move & goto menu
if "%choice%"=="4" powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" & goto menu
if "%choice%"=="0" exit
goto menu
