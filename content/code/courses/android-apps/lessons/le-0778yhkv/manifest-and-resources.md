---
title: The manifest, and resources a phone chooses between
version: 1
---

**The manifest is what the phone reads before it runs a line of your code.** It says what the app
is called, which activity opens when somebody taps the icon, which permissions it wants, and which
Android versions it accepts. The phone, the Play Store and every tool that inspects an app read it,
and none of them reads your Kotlin.

## The manifest you wrote, and the one that ships

The file in section 05 has one `<application>` with one `<activity>`. Two attributes carry it:

- `android:exported="true"` says another app may start this activity. The launcher is another app,
  so the activity the icon opens has to be exported; every other activity should say `false`.
  Since Android 12 the attribute is compulsory on any activity with an `<intent-filter>`, and the
  build refuses a manifest without it.
- The `<intent-filter>` with `MAIN` and `LAUNCHER` is what puts an icon on the home screen. An app
  can have several activities; only the ones with this filter get an icon.

**What ships is not the file you wrote.** Every library can carry a manifest of its own, and the
build merges them all with yours. The merged one is in the build directory:

```
ana@vm:~/planner$ sed -n 1,20p app/build/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml
<?xml version="1.0" encoding="utf-8"?>
<!-- app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.planner"
    android:versionCode="1"
    android:versionName="0.1.0" >

    <uses-sdk
        android:minSdkVersion="26"
        android:targetSdkVersion="36" />

    <permission
        android:name="com.example.planner.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"
        android:protectionLevel="signature" />

    <uses-permission android:name="com.example.planner.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION" />

    <application
        android:appComponentFactory="androidx.core.app.CoreComponentFactory"
        android:debuggable="true"
```

Three things arrived that you did not write. `<uses-sdk>` carries `minSdk` and `targetSdk` from the
build file, which is where they belong now. `package` is the `namespace`. And a permission named
after your own app, `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, came from `androidx.core`, which uses
it to keep its broadcast receivers private. **Read the merged manifest whenever a library is added**:
it is where a dependency asks for a permission you never meant to request.

## Resources, and the `R` class

Text, colours, images and dimensions live in `res/`, outside the code, so that the phone can choose
between versions of them. `values/strings.xml` holds the strings in the default language. Add a
folder with a **qualifier** in its name, and the same names get other values under the conditions
the qualifier states:

```xml
<!-- app/src/main/res/values-pt/strings.xml -->
<resources>
    <string name="welcome">Nenhum curso ainda. Adicione o primeiro.</string>
</resources>
```

`values-pt` is chosen on a phone whose language is Portuguese. `app_name` is not in it, so a
Portuguese phone falls back to the default, `Planner`, one string at a time. The build compiles
both into the app, and the phone picks at run time:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleDebug 2>&1 | grep -E "^BUILD"
BUILD SUCCESSFUL in 2s
ana@vm:~/planner$ $ANDROID_HOME/build-tools/36.1.0/aapt2 dump resources app/build/outputs/apk/debug/app-debug.apk | grep -A2 "string/welcome"
    resource 0x7f080063 string/welcome
      () "No courses yet. Add the first one."
      (pt) "Nenhum curso ainda. Adicione o primeiro."
ana@vm:~/planner$ grep -E "string (app_name|welcome)" app/build/intermediates/runtime_symbol_list/debug/processDebugResources/R.txt
int string app_name 0x7f080003
int string welcome 0x7f080063
```

`aapt2 dump resources` shows the one resource with its two values and the configuration each
belongs to: `()` is the default and `(pt)` is Portuguese. The number `0x7f...` is the resource's
**id**, and the build writes one constant per resource into a generated class, `R`. That is what
`R.string.welcome` in `MainActivity.kt` names: an integer, resolved to a string on the phone.

**The same mechanism picks by much more than language.** `values-night` holds colours for dark mode
(lesson 7), `drawable-xxhdpi` holds images for dense screens, and `values-sw600dp` holds dimensions
for screens at least 600 dp wide, which is a tablet. The phone checks its own configuration against
every folder and takes the most specific match.

**A string in code is a string nobody can translate.** `Text("No courses yet")` compiles and
works, and stays in English on every phone. This course writes the planner's text in
`strings.xml` from here on.
