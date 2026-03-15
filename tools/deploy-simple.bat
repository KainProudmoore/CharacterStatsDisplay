@echo off
chcp 65001 >nul
echo ========================================
echo   CharacterStatsDisplay Deploy Tool
echo ========================================
echo.
echo Step 1: Remove old addon...
rd /s /q "E:\Game\BLZ\World of Warcraft\_retail_\Interface\AddOns\CharacterStatsDisplay" 2>nul
echo Step 2: Copy new files...
robocopy "%~dp0" "E:\Game\BLZ\World of Warcraft\_retail_\Interface\AddOns\CharacterStatsDisplay" /E /XD .git .vscode /XF deploy.bat deploy.ps1
echo.
echo ========================================
echo   Deploy Complete!
echo ========================================
pause
