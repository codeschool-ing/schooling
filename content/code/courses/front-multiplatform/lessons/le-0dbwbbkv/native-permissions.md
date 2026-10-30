---
title: The native side of each permission
version: 1
---

**Every permission the web asked for in this lesson has to be declared in the native projects too**,
or the phone refuses it, or on iOS closes the app. Some plugins declare their own. Gradle merges a
plugin's Android manifest into the app's when it builds, so a permission a plugin's manifest carries
needs nothing from you:

```
ana@dev:~/planner$ grep -c uses-permission node_modules/@capacitor/*/android/src/main/AndroidManifest.xml
node_modules/@capacitor/camera/android/src/main/AndroidManifest.xml:0
node_modules/@capacitor/filesystem/android/src/main/AndroidManifest.xml:0
node_modules/@capacitor/geolocation/android/src/main/AndroidManifest.xml:0
node_modules/@capacitor/local-notifications/android/src/main/AndroidManifest.xml:4
node_modules/@capacitor/preferences/android/src/main/AndroidManifest.xml:0
```

**Only `local-notifications` declares its own**, because it cannot work without them. Geolocation
does not, and its documentation tells you which lines to add, because only you know whether the app
needs a precise position or an approximate one. For the planner that is the two location lines, added
to `android/app/src/main/AndroidManifest.xml` under the `INTERNET` one.

**iOS declares nothing on a plugin's behalf.** Every question an app asks needs a key in `Info.plist`
with the sentence the dialog shows, and Apple's reviewers read those sentences: a vague one is a
common reason for a rejection, and a sentence saying what the person gets is the one to write. For the planner, the
camera, the photo library and the location while in use, added under the `<dict>` in
`ios/App/App/Info.plist`. Both files after the edits:

```
ana@dev:~/planner$ grep -n uses-permission android/app/src/main/AndroidManifest.xml
40:    <uses-permission android:name="android.permission.INTERNET" />
41:    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
42:    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
ana@dev:~/planner$ grep -A1 UsageDescription ios/App/App/Info.plist
	<key>NSCameraUsageDescription</key>
	<string>To take a photo of your notes for a session.</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>To attach a photo of your notes from your library.</string>
	<key>NSPhotoLibraryAddUsageDescription</key>
	<string>To save a photo of your notes to your library.</string>
	<key>NSLocationWhenInUseUsageDescription</key>
	<string>To show where you are studying, only when you ask.</string>
```

Local notifications need no key on iOS: the question is asked by the system with its own text. Then
build, sync, and commit the whole lesson:

```
ana@dev:~/planner$ npm run build > /dev/null && npx cap sync > /dev/null
ana@dev:~/planner$ git add .
ana@dev:~/planner$ git commit -q -m "Keep the plan, export it, remind, locate and photograph"
ana@dev:~/planner$ git log --oneline -1
3d224de Keep the plan, export it, remind, locate and photograph
```

| plugin | Android, in `AndroidManifest.xml` | iOS, in `Info.plist` |
|---|---|---|
| Preferences | nothing | nothing |
| Filesystem, in `Data` | nothing | nothing |
| Local notifications | brought by the plugin | nothing; the system asks |
| Geolocation | `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION` | `NSLocationWhenInUseUsageDescription` |
| Camera | nothing for a photo; storage lines for the gallery on old Android | `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription` |

*None of this could be tried on a phone for this course; lesson 3 says why. The lines are the ones
each plugin's documentation, in its `README.md` inside `node_modules`, gives for version 8.*
