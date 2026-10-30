---
title: What is inside an APK
version: 1
---

**An APK is a zip file**, and it is worth opening one before you trust any number about it. The
debug build of section 06 is 12 MB for one sentence on a screen, and that size has a reason you
can see:

```
ana@vm:~/planner/app/build/outputs/apk/debug$ unzip -l app-debug.apk | tail -1
 29821170                     120 files
ana@vm:~/planner/app/build/outputs/apk/debug$ unzip -l app-debug.apk | grep -E "classes[0-9]*\.dex|AndroidManifest|resources.arsc"
 18634372  1981-01-01 01:01   classes.dex
    41316  1981-01-01 01:01   classes2.dex
     7348  1981-01-01 01:01   classes3.dex
   119604  1981-01-01 01:01   classes4.dex
 10370792  1981-01-01 01:01   classes5.dex
     5772  1981-01-01 01:01   AndroidManifest.xml
   474184  1981-01-01 01:01   resources.arsc
```

Five files called `classes*.dex` hold the code, nearly all of it not yours. **Dex** is Android's
bytecode. The build compiles Kotlin to JVM classes as any Kotlin build does, and then a tool called
**D8** converts them into dex, which Android's runtime executes. One dex file holds at most 65,536
method references, so a build with more spreads them over several; that is why there are five.
`resources.arsc` is the compiled table of section 07's resources, and `AndroidManifest.xml` is the
merged manifest in a binary form.

`aapt2`, from the build tools, reads what the phone would read first:

```
ana@vm:~/planner/app/build/outputs/apk/debug$ $ANDROID_HOME/build-tools/36.1.0/aapt2 dump badging app-debug.apk | head -5
package: name='com.example.planner' versionCode='1' versionName='0.1.0' platformBuildVersionName='17' platformBuildVersionCode='37' compileSdkVersion='37' compileSdkVersionCodename='17'
minSdkVersion:'26'
targetSdkVersion:'36'
uses-permission: name='com.example.planner.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION'
application-label:'Planner'
```

The package name, the two versions from `defaultConfig`, the SDK numbers, and the label. Every
store and every installer starts here.

The Android CLI reads the whole thing and says what it thinks of it:

```
ana@vm:~/planner/app/build/outputs/apk/debug$ android analyze app-debug.apk 2>&1 | sed -e "s/.*\r//" | grep -v "^Downloading"
Basic info:
 - Package Name: com.example.planner
 - Version Name: 0.1.0
 - Version Code: 1

Optimization info:
 Warnings:
    * This app has an extremely low rate of dex optimization, with at least one key optimization type enabled on less than 25% of its dex code.

 - AGP Version: 9.5.0
 - Uncompressed Dex Size: 29173432 bytes (27.82 MB)
 - Dex Marker Metadata: R8 Enabled=false, D8 Enabled=true, Full Mode=false
 - Dex Heuristic Obfuscation: 0.80%
```

**"An extremely low rate of dex optimization"** is accurate and expected. `R8 Enabled=false` says
why: a debug build skips the optimiser so that it builds quickly and a debugger can see every line.
The 27.82 MB of uncompressed dex is the whole of every library the app depends on, used or not.
Lesson 22 turns R8 on for the release build and measures the same file again.

## The debug signature

A phone installs only a signed APK, and this one is signed although you never made a key. The first
debug build creates `~/.android/debug.keystore`, a key with a well-known password, and signs every
debug build with it. **A debug key is the same on every machine that builds with it, by design, and
it is never what you publish with.** Lesson 22 makes the real one, and explains why losing it means
never updating your app again.

## Installing it

**Not run.** With a phone connected by USB and its developer options turned on, or an emulator
started, Google's documentation installs the debug build with `./gradlew installDebug`, or with
`adb install app/build/outputs/apk/debug/app-debug.apk`, and the icon labelled Planner appears with
the others. The Android CLI's `android run` builds, installs and starts it in one step. None of the
three could run on the recording machine, which had no device; section 02 says why.
