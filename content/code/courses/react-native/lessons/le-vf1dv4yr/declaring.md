---
title: Declaring what the app may ask for
version: 1
---

**The declaration is native configuration, so in an Expo project it comes from a config plugin.** The
planner will use `expo-image-picker` to choose and take photos, and `expo-file-system` to keep them.
Install both with the versions SDK 58 expects:

```
ana@dev:~/planner$ npx expo install expo-image-picker expo-file-system
Unable to fetch compatibility data from React Native Directory. Skipping check.
Dependency validation is unreliable in offline-mode
› Installing 2 SDK 58.0.0 compatible native modules using npm
> npm install

added 3 packages, removed 1 package, and audited 1114 packages in 9s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

`expo-image-picker` ships a plugin, and its options are the declaration. Add it to the `"plugins"` list
in `app.json`, inside `"expo"`, as lesson 2 did with the week-start plugin:

```json
"plugins": [
  [
    "expo-image-picker",
    {
      "cameraPermission": "The planner uses the camera to photograph your notes for a course.",
      "photosPermission": false,
      "microphonePermission": false
    }
  ]
]
```

**`cameraPermission` is the sentence iOS shows in its dialog**, so it says what the camera is for, in
terms of what the person gets. *"This app needs camera access"* is the sentence Apple's review sends back.
The two `false` options take away what the planner never uses: it reads no photo library, since the
system picker needs no permission, and it records no video, so it needs no microphone.

Generate the native projects and read what the plugin wrote:

```
ana@dev:~/planner$ grep -A9 "\"plugins\"" app.json
    "plugins": [
      [
        "expo-image-picker",
        {
          "cameraPermission": "The planner uses the camera to photograph your notes for a course.",
          "photosPermission": false,
          "microphonePermission": false
        }
      ]
    ]
ana@dev:~/planner$ npx expo prebuild --clean --no-install > /dev/null 2>&1
ana@dev:~/planner$ grep uses-permission android/app/src/main/AndroidManifest.xml
  <uses-permission android:name="android.permission.INTERNET"/>
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" tools:replace="android:maxSdkVersion"/>
  <uses-permission android:name="android.permission.RECORD_AUDIO" tools:node="remove"/>
  <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>
  <uses-permission android:name="android.permission.VIBRATE"/>
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="32" tools:replace="android:maxSdkVersion"/>
ana@dev:~/planner$ grep -A1 UsageDescription ios/Studyplanner/Info.plist
    <key>NSCameraUsageDescription</key>
    <string>The planner uses the camera to photograph your notes for a course.</string>
    <key>NSLocalNetworkUsageDescription</key>
    <string>Expo Dev Launcher uses the local network to discover and connect to development servers running on your computer.</string>
```

On Android, **`CAMERA` is not in the list**, though the planner will ask for it. What the plugin did
write is `RECORD_AUDIO` with `tools:node="remove"`: an instruction to Android's build to delete that
permission even if a library asks for it, which is what `false` meant. `INTERNET`, `SYSTEM_ALERT_WINDOW`
and `VIBRATE` come from Expo's template, and the two storage permissions end at `maxSdkVersion="32"`,
Android 12.

On iOS, `NSCameraUsageDescription` carries the sentence, word for word, and there is no photo library
key at all. `NSLocalNetworkUsageDescription` belongs to the development build, which looks for Metro on
the local network.

## The manifest the phone receives

The Android file is the app's own manifest, and it is not the one that ships. **Every Android library
carries a manifest of its own, and Gradle merges them all into one** while it builds. Gradle can run just
that step, which takes a couple of minutes the first time. The merged file is long, so the second command
joins its lines and keeps only the name of each `<uses-permission>`:

```
ana@dev:~/planner/android$ ./gradlew :app:processDebugMainManifest -q > /dev/null 2>&1
ana@dev:~/planner/android$ tr '\n' ' ' < app/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml | grep -o '<uses-permission *android:name="[^"]*"' | cut -d'"' -f2 | sort
android.permission.ACCESS_LOCAL_NETWORK
android.permission.ACCESS_NETWORK_STATE
android.permission.ACCESS_WIFI_STATE
android.permission.CAMERA
android.permission.CHANGE_WIFI_MULTICAST_STATE
android.permission.INTERNET
android.permission.READ_EXTERNAL_STORAGE
android.permission.SYSTEM_ALERT_WINDOW
android.permission.VIBRATE
android.permission.WRITE_EXTERNAL_STORAGE
org.example.planner.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION
```

**There is `CAMERA`, from `expo-image-picker`'s own manifest**, which also declares the two old storage
permissions, so that nobody has to remember them. `ACCESS_NETWORK_STATE` and `ACCESS_WIFI_STATE` are
NetInfo's, from lesson 10, which reads the connection. `ACCESS_LOCAL_NETWORK` and
`CHANGE_WIFI_MULTICAST_STATE` come from debug-only manifests, React Native's and the development
build's, which look for Metro on the local network. `RECORD_AUDIO` is nowhere: that is the plugin's removal
working. The last line is not Android's at all but the app's own, named after its package, which a
library declares to protect a broadcast receiver.

**This is the debug build's list.** The development-only entries come from manifests that Gradle merges
into a debug build and not into a release; *lesson 20 builds a release, and this course did not compare
the two lists*. What a store shows under *this app can* is the release build's merged list, so that is
the list to read before publishing, never the one in the generated folder.

**The folders are generated, so none of this is edited by hand**: the next `prebuild --clean` would
undo it, as lesson 2 showed. A permission is added or removed in `app.json`, through a plugin's options.
