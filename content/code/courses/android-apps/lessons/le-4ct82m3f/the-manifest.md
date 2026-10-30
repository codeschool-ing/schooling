---
title: The permission, and the plain HTTP Android refuses
version: 1
---

**Every test in this lesson ran on the JVM, where nothing asks whether the app may use the network.
A phone asks.** An Android app may open a socket only if its manifest declares the `INTERNET`
permission. The planner's own manifest has never declared it, and yet the merged manifest of lesson 1
section 07 has it. The merger's report says where it came from:

```
ana@vm:~/planner$ grep -A2 '^uses-permission#android.permission.INTERNET' app/build/outputs/logs/manifest-merger-debug-report.txt
uses-permission#android.permission.INTERNET
ADDED from [com.squareup.okhttp3:okhttp-android:5.5.1] /home/ana/.gradle/caches/9.8.2/transforms/58ebe4428bd93930cdb1773341c39660/transformed/okhttp/AndroidManifest.xml:8:5-67
	android:name
```

**OkHttp brought it.** OkHttp 5 is published for Android as a library with a manifest of its own,
`okhttp-android`, and that manifest asks for `INTERNET` on the app's behalf. It is exactly the case
lesson 1 section 07 warned about, a dependency asking for a permission, and this time it is the one
the app needs. Declare it yourself anyway: the app's own manifest should say what the app uses, and
the day a library stops asking, an app that relied on it fails on its first request with a
`SecurityException`. **Not run**: that failure needs a device. A permission declared twice is merged
into one, and the report then lists both sources. The line goes at the top of the manifest:

```xml
<!-- app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:label="@string/app_name"
        android:theme="@android:style/Theme.Material.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
```

`INTERNET` is a **normal** permission: the system grants it at install time and never shows the
student a dialog. Lesson 20 is about the other kind, the ones the student is asked about.

## Plain HTTP is refused by default

From `targetSdk` 28 on, Android refuses **cleartext** traffic, `http://` rather than `https://`,
unless the app says otherwise. The planner targets 36 and its server is `https://`, so nothing needs
saying. The case where it does is development: a server running on your own computer, reached from
the emulator at `10.0.2.2`, usually speaks plain HTTP. The narrow way to allow it is a **network
security configuration** that names that one address, in the `debug` source set, so that it cannot
reach a release build:

```xml
<!-- app/src/debug/res/xml/network_security_config.xml -->
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">10.0.2.2</domain>
    </domain-config>
</network-security-config>
```

```xml
<!-- app/src/debug/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:networkSecurityConfig="@xml/network_security_config" />
</manifest>
```

A file under `src/debug/` takes part in the debug build only, and the second manifest is merged over
the main one, adding one attribute. Lesson 22 says more about source sets. Both changes, in the
merged debug manifest:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^BUILD"
BUILD SUCCESSFUL in 9s
ana@vm:~/planner$ grep -E 'android.permission.INTERNET|networkSecurityConfig' app/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml
    <uses-permission android:name="android.permission.INTERNET" />
        android:networkSecurityConfig="@xml/network_security_config"
```

The blunt alternative, `android:usesCleartextTraffic="true"` on the application, allows plain HTTP
to every address in every build, release included. It is what most answers on the web suggest,
because it works at once, and it is the setting that lets a café's Wi-Fi read what the app sends.

**Not run**: reaching `10.0.2.2` from an emulator needs the emulator and a server on the computer;
Google's documentation for the network security configuration is the source for both files.
