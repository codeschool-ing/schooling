---
title: What the library declares
version: 1
---

`expo-notifications` does both local and push notifications. Install it:

```
ana@dev:~/planner$ npx expo install expo-notifications
Unable to fetch compatibility data from React Native Directory. Skipping check.
Dependency validation is unreliable in offline-mode
› Installing 1 SDK 58.0.0 compatible native module using npm
> npm install

added 6 packages, removed 1 package, and audited 1128 packages in 9s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

There are no sentences to write this time: neither platform shows the app's own words when it asks about
notifications. What the library declares can be read after a prebuild:

```
ana@dev:~/planner$ npx expo prebuild --clean --no-install > /dev/null 2>&1
ana@dev:~/planner$ grep uses-permission node_modules/expo-notifications/android/src/main/AndroidManifest.xml
  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
  <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
ana@dev:~/planner$ grep -A1 aps-environment ios/Studyplanner/Studyplanner.entitlements
    <key>aps-environment</key>
    <string>development</string>
```

- **`POST_NOTIFICATIONS`** is the Android 13 permission to show a notification at all. Before Android 13
  an app could show them by default; from 13 on, the person is asked, as for the camera.
- **`RECEIVE_BOOT_COMPLETED`** lets the library hear the phone start. Android forgets every scheduled
  notification when it restarts, so the library schedules them again at boot.
- **`aps-environment`** in the iOS *entitlements* is the push capability: a promise to Apple that the app
  will receive pushes, checked against the signing profile when the app is built. `development` is
  Apple's sandbox, which development builds use; a store build says `production`.

All three come from the library, through its manifest and its plugin; none is in `app.json`.
