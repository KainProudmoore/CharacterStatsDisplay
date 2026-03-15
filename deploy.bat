@echo off
chcp 65001 >nul
echo ========================================
echo   CharacterStatsDisplay Deploy Tool
echo ========================================
echo.

set SOURCE=%~dp0
set TARGET=E:\Game\BLZ\World of Warcraft\_retail_\Interface\AddOns\CharacterStatsDisplay

echo [Step 1] Remove old addon...
if exist "%TARGET%" (
    rd /s /q "%TARGET%"
    echo          Old version removed
) else (
    echo          No old version found
)

echo [Step 2] Create target directory...
mkdir "%TARGET%" 2>nul

echo [Step 3] Copy plugin files only...

REM Core plugin files
copy "%SOURCE%CharacterStatsDisplay.toc" "%TARGET%\" >nul
copy "%SOURCE%Core.lua" "%TARGET%\" >nul

REM Optional: Documentation (safe to include)
if exist "%SOURCE%CHANGELOG.md" copy "%SOURCE%CHANGELOG.md" "%TARGET%\" >nul
if exist "%SOURCE%DESIGN.md" copy "%SOURCE%DESIGN.md" "%TARGET%\" >nul

REM Copy Assets folder if exists
if exist "%SOURCE%Assets\" (
    xcopy "%SOURCE%Assets\" "%TARGET%Assets\" /E /I /Y >nul
    echo          Assets copied
)

REM Copy Localization folder if exists
if exist "%SOURCE%Localization\" (
    xcopy "%SOURCE%Localization\" "%TARGET%Localization\" /E /I /Y >nul
    echo          Localization copied
)

echo.
echo ========================================
echo   Deploy Complete!
echo ========================================
echo.
echo Only these files were deployed:
dir /b "%TARGET%"
echo.
pause
