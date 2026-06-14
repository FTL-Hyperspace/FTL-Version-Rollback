# FTL-Version-Rollback

A collection of patches used to rollback the Windows binary of FTL: Faster Than Light to a version supported by [FTL Hyperspace](https://github.com/FTL-Hyperspace/FTL-Hyperspace)

## Supported rollbacks
- Steam: 1.6.14, 1.6.22, 1.6.13  -> 1.6.9
- Epic Games: 1.6.12  -> 1.6.9
- Origin: 1.6.12  -> 1.6.9
- Microsoft (Old): 1.6.12  -> 1.6.9

<sub>Rollbacks marked with (Old) might not work with the latest copies, since Microsoft introduced write protection rules</sub>

## How to use

1. Code > [Download ZIP](https://github.com/FTL-Hyperspace/FTL-Version-Rollback/archive/refs/heads/main.zip), then extract it.
2. Copy the contents into your FTL folder (where `FTLGame.exe` is).
3. Run `rollback.bat`.

The original `FTLGame.exe` is backed up as `FTLGame_orig.exe`. To undo, delete the patched `FTLGame.exe` and rename `FTLGame_orig.exe` back.
