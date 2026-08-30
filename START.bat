@echo off
chcp 65001 >nul
title Wallpaper Changer - установка
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
