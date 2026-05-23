# Pocket DRS Pro - Android APK Compilation Guide

This document describes how to configure, build, and sign a release APK for **Pocket DRS Pro**.

---

## 1. Prerequisites
- **Flutter SDK**: Version `3.10.x` or higher installed and on your PATH.
- **Android Studio & SDK**: Android SDK Platform Level `33` or higher.
- **Java Development Kit (JDK)**: JDK 11 or 17.

---

## 2. Configuration & Android Permissions

To capture high-speed frames and record stump micro-audios, update `/android/app/src/main/AndroidManifest.xml` to request Camera and Microphone inputs.

Ensure the following permissions are added inside the `<manifest>` tag:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

Inside the `<application>` tag, declare camera features:
```xml
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.autofocus" />
```

---

## 3. Creating Release Signing Configuration (Optional)

To distribute the app, generate a keystore file to sign the APK.

1. Generate key using command line:
   ```bash
   keytool -genkey -v -keystore my-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias my-key-alias
   ```
2. Move `my-release-key.jks` into `/android/app/` folder.
3. Reference it in `/android/key.properties`:
   ```properties
   storePassword=yourKeystorePassword
   keyPassword=yourKeyPassword
   keyAlias=my-key-alias
   storeFile=my-release-key.jks
   ```
4. Configure `/android/app/build.gradle` to load this properties file and assign it under `signingConfigs.release`.

---

## 4. Build Command Execution

1. Open your terminal in the Flutter project directory (`/pocket_drs_pro`).
2. Fetch package dependencies:
   ```bash
   flutter pub get
   ```
3. Run the compiler:
   ```bash
   flutter build apk --release
   ```

*Note: To build target-specific architectures (e.g., 64-bit ARM to optimize OpenCV memory constraints), run:*
```bash
flutter build apk --split-per-abi
```

4. Locate your finished binary file at:
   `[project_root]/pocket_drs_pro/build/app/outputs/flutter-apk/app-release.apk`
