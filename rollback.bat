@echo off
setlocal enabledelayedexpansion

:: Map each original FTLGame.exe SHA-1 to its BPS patch filename.
:: TODO: Add SHA-1 values for Origin and Microsoft versions once they are known.
:: Fallback to manual store selection if the SHA-1 is not found in this map.
set "PATCH_MAP[e32fcd46ac655e43befae8e5515d4bf7ce5c3c6a]=Steam-1.6.12.bps"
set "PATCH_MAP[66562b0cc44e843f6245e25fec33cc56ffe41736]=Steam-1.6.13.bps"
set "PATCH_MAP[c58e5283b2c1996fa36158265423f8c94f3a8954]=Steam-1.6.14.bps"
set "PATCH_MAP[aadfbb3d2597ed5b1b2bd01d19569334842210da]=Steam-1.6.22.bps"
set "PATCH_MAP[609ef1bd507097e2b41bd57b9e81e7f2061aadc2]=GOG-1.6.12.bps"
set "PATCH_MAP[73fd4bf0da14a3f43fe575015f69b896865dd49f]=GOG-1.6.13.bps"
set "PATCH_MAP[0db27c60ae7986cbeb19ffda3eee6470daf984db]=GOG-1.6.13b.bps"
set "PATCH_MAP[7b8c4d0657e16edc98b9978bd9a9f851a613573a]=Epic-1.6.12.bps"
set "PATCH_MAP[SHA1_ORIGIN_1_6_12_PLACEHOLDER]=Origin-1.6.12.bps"
set "PATCH_MAP[16c2d7936e9bb5c40672ad7593b5285860b2a5db]=EA-1.6.12.bps"
set "PATCH_MAP[SHA1_MICROSOFT_1_6_12_PLACEHOLDER]=Microsoft.1.6.12.bps"
set "PATCH_MAP[b4eae8d8690c8bc7b80def6e8224fb17d34a5083]=Humble-1.6.12.bps"

:: Change to the script's directory
pushd "%~dp0"

:: Check required files before doing anything that changes the game folder
if not exist "FTLGame.exe" (
    echo ERROR: FTLGame.exe not found in the current folder.
    goto :exit
)

if not exist "patch\bpsapply.exe" (
    echo ERROR: patch\bpsapply.exe not found.
    goto :exit
)

:: Calculate the SHA-1 of FTLGame.exe. The second line of certutil output is the hash on all supported Windows locales.
echo Calculating SHA-1 for FTLGame.exe...
set "GAME_SHA1="
set "HASH_OUTPUT=!TEMP!\ftl_rollback_sha1_!RANDOM!_!RANDOM!.tmp"
certutil -hashfile "FTLGame.exe" SHA1 > "!HASH_OUTPUT!" 2>&1
if errorlevel 1 (
    del "!HASH_OUTPUT!" 2>nul
    echo ERROR: Could not calculate the SHA-1 of FTLGame.exe.
    goto :exit
)

for /f "usebackq skip=1 delims=" %%H in ("!HASH_OUTPUT!") do (
    if not defined GAME_SHA1 set "GAME_SHA1=%%H"
)
del "!HASH_OUTPUT!" 2>nul
set "GAME_SHA1=!GAME_SHA1: =!"

if not defined GAME_SHA1 (
    echo ERROR: certutil did not return a SHA-1 hash.
    goto :exit
)

echo Detected SHA-1: !GAME_SHA1!

:: Use the SHA-1 as the key for the map defined at the top of this file.
set "PATCH_FILE="
for %%H in (!GAME_SHA1!) do set "PATCH_FILE=!PATCH_MAP[%%H]!"

set "PATCH_COUNT=0"
if defined PATCH_FILE (
    if not exist "patch\!PATCH_FILE!" (
        echo ERROR: The mapped patch was not found: patch\!PATCH_FILE!
        goto :exit
    )

    set "PATCH_COUNT=1"
    set "PATCHES[1]=!PATCH_FILE!"
    echo Selected patch by SHA-1: !PATCH_FILE!
) else (
    echo.
    echo SHA-1 is not registered. Falling back to store selection.
    echo.
    echo Select your game store:
    echo   1. Steam
    echo   2. GOG
    echo   3. Epic Games
    echo   4. Origin ^(Old^)
    echo   5. EA
    echo   6. Microsoft ^(Old^)
    echo   7. DRM Free ^(Includes Humble^)
    echo   0. Exit without patching
    echo.

    choice /c 12345670 /n /m "Enter your choice (1-7, 0 to exit): "
    set "STORE_CHOICE=!errorlevel!"

    if "!STORE_CHOICE!"=="8" goto :exit
    if "!STORE_CHOICE!"=="7" set "STORE=Humble"
    if "!STORE_CHOICE!"=="6" set "STORE=Microsoft"
    if "!STORE_CHOICE!"=="5" set "STORE=EA"
    if "!STORE_CHOICE!"=="4" set "STORE=Origin"
    if "!STORE_CHOICE!"=="3" set "STORE=Epic"
    if "!STORE_CHOICE!"=="2" set "STORE=GOG"
    if "!STORE_CHOICE!"=="1" set "STORE=Steam"

    if not defined STORE (
        echo ERROR: Invalid selection.
        goto :exit
    )

    echo Selected store: !STORE!
    for %%F in ("patch\!STORE!-*.bps") do (
        if exist "%%~fF" (
            set /a PATCH_COUNT+=1
            set "PATCHES[!PATCH_COUNT!]=%%~nxF"
        )
    )

    if "!PATCH_COUNT!"=="0" (
        echo ERROR: No patch files found for !STORE! in the patch folder.
        pause
        goto :exit
    )

    echo Found !PATCH_COUNT! patch^(es^). Each will be tried until one works.
)

:: Refuse to overwrite a backup from an earlier run
if exist "FTLGame_orig.exe" (
    echo ERROR: FTLGame_orig.exe already exists. No files were changed.
    goto :exit
)

echo Creating backup: FTLGame_orig.exe
copy "FTLGame.exe" "FTLGame_orig.exe" >nul
if errorlevel 1 (
    echo ERROR: Could not create FTLGame_orig.exe.
    goto :exit
)

set "SUCCESS=0"
for /L %%I in (1,1,!PATCH_COUNT!) do (
    set "CURRENT_PATCH=!PATCHES[%%I]!"
    copy /y "FTLGame_orig.exe" "FTLGame.exe" >nul
    echo Applying !CURRENT_PATCH! ...

    set "PATCH_OUTPUT=!TEMP!\ftl_rollback_patch_!RANDOM!_!RANDOM!.tmp"
    "patch\bpsapply.exe" "FTLGame.exe" "patch\!CURRENT_PATCH!" > "!PATCH_OUTPUT!" 2>&1
    set "PATCH_RESULT=!errorlevel!"

    if "!PATCH_RESULT!"=="0" (
        del "!PATCH_OUTPUT!" 2>nul
        set "SUCCESS=1"
        goto :patch_done
    ) else (
        echo Failed: !CURRENT_PATCH!
        del "!PATCH_OUTPUT!" 2>nul
    )
)

:patch_done
if "!SUCCESS!"=="0" (
    echo ERROR: No compatible patch could be applied.
    goto :restore
)

echo.
echo Patch applied successfully!
pause
goto :end

:restore
copy /y "FTLGame_orig.exe" "FTLGame.exe" >nul
if errorlevel 1 (
    echo ERROR: Automatic restore failed. Keep FTLGame_orig.exe as your backup.
) else (
    del "FTLGame_orig.exe" 2>nul
    echo Original executable restored.
)
pause
goto :end

:exit
echo No patch applied. Exiting.

:end
popd
exit /b
