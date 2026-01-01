# Summary: Fix GitHub Actions CI

## Objective

Fix iOS build failure in GitHub Actions CI where macOS build passed but iOS build failed with simulator runtime version mismatch.

## Fix Applied

Added iOS simulator runtime download step before the iOS build in `.github/workflows/build.yml`:

```yaml
- name: Install iOS Simulator Runtime
  run: xcodebuild -downloadPlatform iOS
```

This command downloads and installs the iOS simulator runtime that matches the selected Xcode version (16.2), resolving the SDK/runtime version mismatch.

## Root Cause

The GitHub Actions `macos-15` runner with Xcode 16.2 has the iOS SDK installed (version 22C146) but does not have a matching iOS simulator runtime pre-installed. The available runtimes (22E238, 22F77, 22G86, 23A8464, 23B86) did not match the SDK version, causing the build to fail when trying to target the iOS Simulator.

## Discoveries About GitHub Actions macOS Runners

1. **Xcode without simulator runtimes**: The macos-15 runners have Xcode installed but may not include all simulator runtimes by default to save disk space
2. **`xcodebuild -downloadPlatform iOS`**: This command reliably downloads the correct iOS simulator runtime for the selected Xcode version
3. **Download time**: The iOS simulator runtime download adds approximately 3-4 minutes to the CI run

## Final CI Status

- **Status**: Success
- **Run ID**: 20625958912
- **Run URL**: https://github.com/mbarnson/buzzword_bingo/actions/runs/20625958912
- **build-macos**: Passed in 45s
- **build-ios**: Passed in 4m32s
- **Total time**: ~4m36s (acceptable given runtime download)

## Commit

- **Hash**: 6e0759f
- **Message**: `fix(ci): add iOS simulator runtime download for GitHub Actions`

## Files Modified

- `.github/workflows/build.yml` - Added iOS simulator runtime download step
