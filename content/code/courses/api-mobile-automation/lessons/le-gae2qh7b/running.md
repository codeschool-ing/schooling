---
title: Running the tests, and reading the report
version: 1
---

**There are two ways to run Espresso tests, and both end in the same command on the device.**
Android Studio is the one for writing a test; Gradle on the command line is the one for a pipeline.
Either way, the emulator has to be running and boxoffice with it, because `ListTest` and the second
test of `OfflineTest` read real shows.

## Before the first run: animations off

Espresso waits for the main thread, and an animation runs on it in small steps that Espresso does
not reliably wait out. Google's advice for every device that runs Espresso is to switch the
system's animations off. On the emulator, open *Settings › System › Developer options* (lesson 14
says how to make them appear) and set these three to *Animation off*:

- *Window animation scale*
- *Transition animation scale*
- *Animator duration scale*

The emulator remembers them. A test that passes only with animations off has not found a defect in
the app; one that fails only with them on has found a flaky test.

## In Android Studio

Open `ListTest.kt`. A green triangle sits in the margin beside the class and beside each test;
press the one by the class and choose *Run 'ListTest'*. Android Studio builds the app and the test
APK, installs both on the emulator, runs the tests, and lists them in the *Run* window with a tick
or a cross each. A failed test shows Espresso's message beside it, with the view hierarchy it
searched. Right-click the `example.tickets` folder under `androidTest` to run every test class at
once.

## With Gradle

From the `tickets` folder:

```sh
./gradlew connectedDebugAndroidTest
```

On Windows, in PowerShell, `.\gradlew.bat connectedDebugAndroidTest`. *Connected* means on every
device adb lists, and *Debug* is the build variant, the same one lesson 15's APK was. Gradle exits
with a non-zero code when a test fails, which is what a pipeline needs (lesson 6), and writes two
reports: an HTML page under `app/build/reports/androidTests/connected/`, which you open in a
browser, and JUnit XML files under `app/build/outputs/androidTest-results/connected/`, which a CI
server reads like the Newman file of lesson 6.

**Neither was run for this course**, for the reason section 03 gave. So no report is shown here,
and the two folders above are where the Android Gradle plugin writes them; inside each, the
plugin may add a folder for the variant before the files.

## What Gradle does on the device

Under both, the same request reaches the device: adb asks Android to start the test APK's
instrumentation. You can type it yourself once both APKs are installed, and it shows what an
instrumented test is better than any diagram. On the recording machine, which has no device:

```
ana@laptop:~/boxoffice$ adb shell am instrument -w example.tickets.test/androidx.test.runner.AndroidJUnitRunner
* daemon not running; starting now at tcp:5037
* daemon started successfully
adb: no devices/emulators found
```

`example.tickets.test` is the test APK, named after the app with `.test` added, and
`androidx.test.runner.AndroidJUnitRunner` is the runner of section 03. `-w` waits for the tests to
finish. adb started its server and found nothing to talk to, the same answer `adb devices` gave in
lesson 14. On your computer, with the emulator running and the APKs installed by a Gradle run, the
same command prints each test as it runs and a count at the end.
