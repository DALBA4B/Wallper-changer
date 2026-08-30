@echo off
chcp 65001 >nul
title Wallpaper Changer - удаление
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1"
