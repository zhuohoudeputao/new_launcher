# Minimum SDK Version Fix

## Overview

Fixed the Android minimum SDK version requirement to support the `torch_light` plugin.

## Issue

The `torch_light` plugin requires a minimum Android SDK version of 23 (Android 6.0 Marshmallow). The original configuration used `flutter.minSdkVersion` which could be lower than required.

**Build Error:**
```
The plugin torch_light requires a higher Android SDK version.
```

## Solution

Updated `android/app/build.gradle` to explicitly set `minSdkVersion 23`:

```gradle
defaultConfig {
    applicationId "Ind.zhuohoudeputao.new_launcher"
    minSdkVersion 23
    targetSdk 35
    versionCode 1
    versionName "1.0"
}
```

## Impact

- App now requires Android 6.0 (API 23) or higher
- This covers ~99% of active Android devices (as of 2024)
- Enables flashlight functionality through the torch_light plugin

## Related

- Flashlight provider: `lib/providers/provider_flashlight.dart`
- Plugin: `torch_light: ^1.0.0` in pubspec.yaml