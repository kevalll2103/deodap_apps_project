# Biometric Authentication Setup

To enable biometric authentication in the app lock feature, follow these steps:

## 1. Add Dependencies

Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  local_auth: ^2.1.6
```

## 2. Uncomment Biometric Code

In `lib/screens/home_screen.dart`, uncomment the following lines:

1. Line 14: Uncomment the import
   ```dart
   import 'package:local_auth/local_auth.dart';
   ```

2. Line 58: Uncomment the LocalAuthentication instance
   ```dart
   final LocalAuthentication _localAuth = LocalAuthentication();
   ```

3. In the `_authenticateWithBiometrics()` method, uncomment the actual implementation and remove the placeholder return false.

## 3. Platform Configuration

### Android

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.USE_FINGERPRINT" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```

### iOS

Add to `ios/Runner/Info.plist`:

```xml
<key>NSFaceIDUsageDescription</key>
<string>Why is my app authenticating using face id?</string>
```

## 4. Features Enabled

Once configured, the app lock will include:

- **Biometric First**: Attempts fingerprint/face recognition first
- **PIN Fallback**: Falls back to PIN if biometric fails
- **Security**: 3 failed attempts lockout for 30 seconds
- **Smart Timing**: Only locks when app is backgrounded for >2 seconds
- **No Multiple Dialogs**: Prevents duplicate lock screens

## 5. Testing

Test the following scenarios:
- App resume after 2+ seconds in background
- Failed PIN attempts (3 attempts = 30s lockout)
- Biometric authentication (if device supports it)
- App lifecycle transitions (pause/resume)