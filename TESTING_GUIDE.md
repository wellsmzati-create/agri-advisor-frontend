# Prototype Testing Guide

This guide explains how to test the `farmer_app` Flutter prototype on an Android device and how to test the dashboard experience on web.

> The prototype uses dummy/mock data and does not require a backend server to explore the current UI flows.

## Prerequisites

1. Install Flutter
   - Follow the official Flutter install guide for Windows: https://docs.flutter.dev/get-started/install/windows
   - Verify the install with:
     ```bash
     flutter doctor
     ```
   - Make sure `flutter doctor` reports no missing critical dependencies for Android and web.

2. Android SDK and device support
   - Install Android Studio and the Android SDK.
   - In Android Studio, install an Android SDK platform and a device emulator if needed.
   - Enable USB debugging on a real Android device if you want to test on physical hardware.
   - Connect the Android device with USB and allow debugging, or run an emulator.
   - Confirm Flutter can see the device/emulator:
     ```bash
     flutter devices
     ```

3. Chrome for web testing
   - Install Google Chrome.
   - Confirm Flutter web is available:
     ```bash
     flutter config --enable-web
     flutter devices
     ```

4. Project dependencies
   - Open a terminal in `c:\Users\User\Documents\farmer_app`.
   - Fetch packages:
     ```bash
     flutter pub get
     ```

## Testing on Android device

### Step 1: Start the app on Android

1. Connect the Android device or start an Android emulator.
2. Verify the device is visible with:
   ```bash
   flutter devices
   ```
3. Run the app:
   ```bash
   flutter run -d <deviceId>
   ```
   - Replace `<deviceId>` with the ID shown by `flutter devices`.
   - If only one Android device is connected, you can omit `-d <deviceId>`.

### Step 2: Validate main flows

Use the app and confirm these screens behave correctly:

- **Login screen**
  - Verify the pre-filled demo credentials appear.
  - Press `Sign In` to reach the dashboard.
- **Dashboard**
  - Confirm the home dashboard loads and displays recommendation cards, notifications, and summaries.
- **Crop list**
  - Open the crop list and verify each crop displays icon, category, and summary.
- **Recommendation details**
  - Tap a recommendation and confirm the detail screen shows advisor tips and action steps.
- **Chat**
  - Open an advisor chat, send a message, and confirm the app replies with auto-response text.
- **Notifications**
  - Open notifications and verify the sample alerts appear.
- **Tips / History**
  - Browse the farming tips and history screens to confirm data loads from dummy mock content.

### Step 3: Test edge behavior

- Rotate the device or emulator to verify the UI adapts.
- Use the Android back button to navigate backward.
- Type in the chat message field and verify the app accepts input.
- Tap buttons in the dashboard to confirm navigation works.

### Troubleshooting Android

- If the app fails to start, run:
  ```bash
  flutter clean
  flutter pub get
  flutter run -d <deviceId>
  ```
- If the device is not visible, ensure USB debugging is enabled and the device is authorized.
- If the Android emulator is not launching, recreate it in Android Studio AVD Manager.

## Testing the dashboard on web

### Step 1: Start Flutter web

1. Confirm Chrome is installed.
2. Run the web app from the project root:
   ```bash
   flutter run -d chrome
   ```
3. The app should open in Chrome and serve locally.

### Step 2: Validate web dashboard screens

The web version should support the same main flows as the Android prototype, including:

- Login and navigation into the dashboard shell.
- Displaying recommendations, crop cards, and notification panels.
- Opening chat/advisor screens.
- Showing farming tips and history content.

### Step 3: Inspect web layout and responsiveness

- Resize the browser window to confirm the layout adapts.
- Use Chrome DevTools (F12) to verify there are no console errors.
- Confirm clickable elements respond normally in the browser.

### Common web issues

- If Chrome does not open or the build fails, inspect the terminal output for missing web support or runtime errors.
- Restart the web server after any code changes.
  ```bash
  flutter pub get
  flutter run -d chrome
  ```

## Recommended validation checklist

- [ ] App launches successfully on Android
- [ ] Login screen accepts the demo credentials
- [ ] Dashboard loads without blank screens
- [ ] Crop list data appears correctly
- [ ] Recommendation detail views render steps and advisor info
- [ ] Chat messages can be entered and auto-reply is shown
- [ ] Notifications screen shows dummy notifications
- [ ] Web dashboard launches in Chrome
- [ ] Web layout remains usable at different browser widths
- [ ] No critical runtime errors appear in terminal or browser console

## Notes for testers

- The prototype uses local dummy data only; no backend server is needed.
- The screens are intended to demonstrate UI behavior, navigation, and content flow.
- If you want to test deeper state changes, look into `lib/data/mock_data.dart`, `lib/epa/epa_mock_data.dart`, and `lib/web/web_mock_data.dart`.

## Useful commands

- Fetch packages:
  ```bash
  flutter pub get
  ```
- Run on Android:
  ```bash
  flutter run -d <androidDeviceId>
  ```
- Run on Chrome web:
  ```bash
  flutter run -d chrome
  ```
- Clean build cache:
  ```bash
  flutter clean
  flutter pub get
  ```

---

This guide is designed for a tester to confirm the current prototype flows on both Android and web using the existing dummy/mock data.