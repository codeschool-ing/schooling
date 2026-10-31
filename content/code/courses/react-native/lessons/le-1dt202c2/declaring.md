---
title: Declaring location, and asking for less
version: 1
---

Install `expo-location`:

```
ana@dev:~/planner$ npx expo install expo-location
Unable to fetch compatibility data from React Native Directory. Skipping check.
Dependency validation is unreliable in offline-mode
› Installing 1 SDK 58.0.0 compatible native module using npm
> npm install

added 1 package, and audited 1123 packages in 7s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

Its plugin writes both platforms' declarations, and its options say what the planner will never ask
for. Add this entry to the `"plugins"` list in `app.json`:

```json
[
  "expo-location",
  {
    "locationWhenInUsePermission": "If you turn it on, the planner notes roughly where you study, to about a kilometre.",
    "locationAlwaysAndWhenInUsePermission": false,
    "locationAlwaysPermission": false,
    "locationFullAccuracyPermission": false,
    "motionUsagePermission": false,
    "isIosReducedAccuracyByDefault": true
  }
]
```

**`locationWhenInUsePermission` is the sentence iOS shows**, and it says the three things that matter: it
is optional, what it is for, and how precise. The `false` options remove the sentences for background
location, for a temporary request of full accuracy and for the motion sensors, so iOS has nothing to show
for any of them and the planner cannot ask. `isIosReducedAccuracyByDefault` is the iOS request for
approximate positions from the start.

```
ana@dev:~/planner$ grep -A10 "\"expo-location\"" app.json
        "expo-location",
        {
          "locationWhenInUsePermission": "If you turn it on, the planner notes roughly where you study, to about a kilometre.",
          "locationAlwaysAndWhenInUsePermission": false,
          "locationAlwaysPermission": false,
          "locationFullAccuracyPermission": false,
          "motionUsagePermission": false,
          "isIosReducedAccuracyByDefault": true
        }
      ]
    ]
ana@dev:~/planner$ npx expo prebuild --clean --no-install > /dev/null 2>&1
ana@dev:~/planner$ grep LOCATION android/app/src/main/AndroidManifest.xml
  <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
  <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
ana@dev:~/planner$ grep -A1 NSLocation ios/Studyplanner/Info.plist
    <key>NSLocationDefaultAccuracyReduced</key>
    <true/>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>If you turn it on, the planner notes roughly where you study, to about a kilometre.</string>
```

On iOS, `NSLocationDefaultAccuracyReduced` is the approximate default, and the sentence is the only
usage description for location. On Android, the manifest declares both `ACCESS_COARSE_LOCATION` and
`ACCESS_FINE_LOCATION`, because Android 12 shows the *precise or approximate* choice only to an app that
declares both: the person makes the choice, not the manifest. The planner works the same with either,
since it rounds what it gets.
