@echo off
setlocal enabledelayedexpansion

:: Change to the script's directory
pushd "%~dp0"

:: Create a backup of the original executable if not already present
if not exist "FTLGame_orig.exe" (
    echo Creating backup: FTLGame_orig.exe
    copy "FTLGame.exe" "FTLGame_orig.exe"
) else (
    :: Abort if there was already done a patched
    echo Patch already ran since FTLGame_orig.exe already exists.
    goto :exit
)

:: Check if the game executable exists
if not exist "FTLGame.exe" (
    echo ERROR: FTLGame.exe not found in the current folder.
    goto :restore
)


:: Store selection
echo.
echo Select your game store:
echo   1. Steam
echo   2. GOG
echo   3. Epic Games
echo   4. Origin (Old)
echo   5. EA
echo   6. Microsoft (Old)
echo   7. DRM Free (Includes Humble)
echo   0. Exit without patching
echo.

:: User input
choice /c 12345670 /n /m "Enter your choice (1-7, 0 to exit): "

:: Exact match on errorlevel
if %errorlevel% == 8 goto :exit
if %errorlevel% == 7 set STORE=Humble
if %errorlevel% == 6 set STORE=Microsoft
if %errorlevel% == 5 set STORE=EA
if %errorlevel% == 4 set STORE=Origin
if %errorlevel% == 3 set STORE=Epic
if %errorlevel% == 2 set STORE=GOG
if %errorlevel% == 1 set STORE=Steam

:: Fallback – should not happen
if not defined STORE (
    echo ERROR: Invalid selection.
    goto :exit
)

echo Selected store: %STORE%

:: For stores that have multiple patches (especially Steam), try all matching files
set "PATCH_DIR=%CD%\patch\"
set SUCCESS=0

echo Current directory: %CD%
:: Build list using dir /b to avoid wildcard oddities
set COUNT=0
for /f "delims=" %%F in ('dir /b "%PATCH_DIR%\%STORE%-*.bps" 2^>nul') do (
    set /a COUNT+=1
    set "PATCHES[!COUNT!]=%%F"
)

if %COUNT% equ 0 (
    echo ERROR: No patch files found for %STORE% in %PATCH_DIR%
    pause
    goto :restore
)

echo.
echo Found %COUNT% patch(es) for %STORE%. Trying each until one works...

:: Save original game for potential restore
copy /y "FTLGame.exe" "FTLGame_temp.exe" >nul

:: Try each patch
for /L %%i in (1,1,%COUNT%) do (
    set "CURFILE=!PATCHES[%%i]!"
    set "CURPATCH=%PATCH_DIR%\!CURFILE!"
    set "CURNAME=!CURFILE!"

    echo Trying !CURNAME! ...

    set "OUTFILE=%TEMP%\bpsapply_out_%%i.txt"
    :: Correct order: target first, patch second
    "%CD%\patch\bpsapply.exe" "%CD%\FTLGame.exe" "!CURPATCH!" > "!OUTFILE!" 2>&1

    findstr /C:"#1: Source checksum doesn't match" "!OUTFILE!" >nul
    if errorlevel 1 (
        echo SUCCESS: !CURNAME! applied correctly.
        set SUCCESS=1
        del "!OUTFILE!" 2>nul
        goto :patch_done
    ) else (
        echo Failed: !CURNAME! Wrong version or store.
        copy /y "FTLGame_temp.exe" "FTLGame.exe" >nul
        del "!OUTFILE!" 2>nul
    )
)

:patch_done
del "FTLGame_temp.exe" 2>nul

if %SUCCESS% equ 0 (
    echo.
    echo ERROR: No compatible patch found for %STORE% version.
    echo Restoring original backup...
    copy /y "FTLGame_orig.exe" "FTLGame.exe"
    if exist "FTLGame_orig.exe" (
        del "FTLGame_orig.exe" 2>nul
    )
) else (
    echo.
    echo Patch applied successfully!
)

pause
goto :end

:restore
echo Restoring original backup...
copy /y "FTLGame_orig.exe" "FTLGame.exe"
if exist "FTLGame_orig.exe" (
    del "FTLGame_orig.exe" 2>nul
)

:exit
echo No patch applied. Exiting.

:end
popd
exit /b
