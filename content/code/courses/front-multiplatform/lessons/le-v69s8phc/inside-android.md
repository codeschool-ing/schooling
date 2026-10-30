---
title: Inside the Android project
version: 1
---

**An Android app is described by one file, `AndroidManifest.xml`, and built by Gradle from the files
around it.** Capacitor's project is small enough to read in full, and reading it once tells you where
every later change goes: a permission in lesson 4, an icon in lesson 13, a version in lesson 15. The
manifest first:

```
ana@dev:~/planner$ cat android/app/src/main/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/AppTheme">

        <activity
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|smallestScreenSize|screenLayout|uiMode|navigation|density"
            android:name=".MainActivity"
            android:label="@string/title_activity_main"
            android:theme="@style/AppTheme.NoActionBarLaunch"
            android:launchMode="singleTask"
            android:exported="true">

            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>

        </activity>

        <provider
            android:name="androidx.core.content.FileProvider"
            android:authorities="${applicationId}.fileprovider"
            android:exported="false"
            android:grantUriPermissions="true">
            <meta-data
                android:name="android.support.FILE_PROVIDER_PATHS"
                android:resource="@xml/file_paths"></meta-data>
        </provider>
    </application>

    <!-- Permissions -->

    <uses-permission android:name="android.permission.INTERNET" />
</manifest>
```

- **`<application>`** is the app: its icon, its name (`@string/app_name`, a reference to a string
  defined in another file) and its theme.
- **`<activity>`** is a screen. This app has one, `MainActivity`, and the `intent-filter` with
  `MAIN` and `LAUNCHER` is what puts it on the home screen. `exported="true"` lets the launcher, which
  is another app, start it.
- **`<provider>`** lets the app share a file with another app without giving away its own storage;
  the camera plugin of lesson 4 uses it.
- **`<uses-permission>`** lists what the app may do. Capacitor asks for one, `INTERNET`, which even
  an app that only loads its own files needs, because the WebView is a network client. Every plugin
  that reaches further adds a line here, and lesson 4 adds them.

The one screen is one line of Java:

```
ana@dev:~/planner$ cat android/app/src/main/java/com/example/studyplanner/MainActivity.java
package com.example.studyplanner;

import com.getcapacitor.BridgeActivity;

public class MainActivity extends BridgeActivity {}
ana@dev:~/planner$ grep -E "applicationId|versionCode|versionName" android/app/build.gradle
        applicationId "com.example.studyplanner"
        versionCode 1
        versionName "1.0"
ana@dev:~/planner$ head -n 5 android/variables.gradle
ext {
    minSdkVersion = 24
    compileSdkVersion = 36
    targetSdkVersion = 36
    androidxActivityVersion = '1.11.0'
```

**`BridgeActivity` is Capacitor's.** It opens the WebView, loads your files and starts the bridge, so
the app's own activity has nothing to add. Lesson 5 is the first time anything goes inside those
braces. The other lines are the app's identity and version: `applicationId` is the `appId` of lesson 2,
and `versionCode` and `versionName` are what lesson 15 is about. `variables.gradle` holds the Android
versions the app is built for: **`minSdkVersion = 24`** is the oldest Android it installs on, Android
7.0, and `compileSdkVersion` and `targetSdkVersion` are the newest it is built and tested against.
Google Play raises its minimum for `targetSdkVersion` every year, so an app that is not rebuilt with a
newer Capacitor eventually cannot publish an update.
