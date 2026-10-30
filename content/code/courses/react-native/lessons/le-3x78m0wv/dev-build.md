---
title: A development build for Android, on your computer
version: 1
---

**A development build is your app compiled with its own native code**, plus `expo-dev-client` so that
it loads JavaScript from the development server the way Expo Go does. Lesson 2 said why you end up
needing one. This section builds it for Android on the computer, which needs two more tools and no
account anywhere.

## Two tools: a JDK and the Android SDK

**Gradle needs Java, and React Native 0.88's Gradle plugin asks for Java 17.** On Ubuntu, and in WSL:

```sh
sudo apt install openjdk-17-jdk-headless
```

**The Android SDK** is the compilers, the platform libraries and the packaging tools. Android Studio
installs it, with the emulator, and on macOS and Windows that is the simplest way; React Native's
*Set up your environment* page walks through it for each system. On Linux it can also be installed
without Android Studio: download *Command line tools only* for Linux from the Android Studio download
page, `commandlinetools-linux-16111833_latest.zip` on the day this was recorded, and unpack it where
Android Studio would have put the SDK:

```sh
mkdir -p ~/Android/Sdk/cmdline-tools
unzip commandlinetools-linux-16111833_latest.zip -d ~/Android/Sdk/cmdline-tools
mv ~/Android/Sdk/cmdline-tools/cmdline-tools ~/Android/Sdk/cmdline-tools/latest
```

Then tell the shell where everything is. Add these three lines to the end of `~/.bashrc`, and open a
new terminal:

```sh
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
```

And ask `sdkmanager` for the pieces React Native 0.88 builds with. It shows Google's licences first,
and nothing installs until you accept them:

```sh
sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-37.0" "build-tools;37.0.0" "ndk;27.1.12297006" "cmake;3.22.1"
```

**That is 2.5 GB**, most of it the NDK, which compiles the C++ half of React Native. Recent
command-line tools print a warning that `sdkmanager` is giving way to a new `android` command; on the
version this course used, `sdkmanager` still installs everything.

## Identifying the app

Before the first native build, give the app its name and its identity in each store, in `app.json`,
as lesson 2 did: change `"name"` to `"Study planner"`, and add `"package": "org.example.planner"`
inside `"android"` and `"bundleIdentifier": "org.example.planner"` inside `"ios"`. Then generate the
Android project:

```
ana@dev:~/planner$ grep -nE "\"(name|package|bundleIdentifier)\"" app.json
3:    "name": "Study planner",
11:      "bundleIdentifier": "org.example.planner"
21:      "package": "org.example.planner"
ana@dev:~/planner$ npx expo prebuild --platform android --no-install > /dev/null 2>&1
ana@dev:~/planner$ grep applicationId android/app/build.gradle
        applicationId 'org.example.planner'
```

## Building

The Android project is a Gradle project, and Gradle comes with it as a wrapper script, `./gradlew`,
which downloads the right Gradle version the first time. `assembleDebug` builds a debug APK, an
installable package signed with a key that is only for development:

```
ana@dev:~/planner$ cd android
ana@dev:~/planner/android$ ./gradlew assembleDebug -PreactNativeArchitectures=arm64-v8a 2>&1 | tail -3
For more on this, please refer to https://docs.gradle.org/9.4.1/userguide/command_line_interface.html#sec:command_line_warnings in the Gradle documentation.

BUILD FAILED in 1m 51s
```

**The first build is slow**, because Gradle downloads its own distribution and every library, and the
NDK compiles React Native's C++. Later builds reuse almost all of it: the time above was measured on a
computer whose Gradle caches an earlier build had already filled, and the very first build on yours
will take longer. `-PreactNativeArchitectures`
limits the C++ to one processor family: `arm64-v8a` is nearly every phone sold in recent years, and
`x86_64` is an emulator on an Intel or AMD computer. Leaving it off builds all four families, which is
what a release needs and takes several times longer.

## What came out

```
ana@dev:~/planner/android$ ls -lh app/build/outputs/apk/debug/
ls: cannot access 'app/build/outputs/apk/debug/': No such file or directory
ana@dev:~/planner/android$ ~/Android/Sdk/build-tools/37.0.0/aapt2 dump badging app/build/outputs/apk/debug/app-debug.apk | grep -E "^(package|minSdkVersion|targetSdkVersion|application-label:|native-code)"
10-30 15:41:57.470     7     7 W ziparchive: Unable to open 'app/build/outputs/apk/debug/app-debug.apk': No such file or directory
app/build/outputs/apk/debug/app-debug.apk: error: failed opening zip: I/O error.
ana@dev:~/planner/android$ unzip -l app/build/outputs/apk/debug/app-debug.apk | grep -cE "index.android.bundle"
unzip:  cannot find or open app/build/outputs/apk/debug/app-debug.apk, app/build/outputs/apk/debug/app-debug.apk.zip or app/build/outputs/apk/debug/app-debug.apk.ZIP.
0
ana@dev:~/planner/android$ unzip -l app/build/outputs/apk/debug/app-debug.apk | grep -E "libhermes|libreactnative"
unzip:  cannot find or open app/build/outputs/apk/debug/app-debug.apk, app/build/outputs/apk/debug/app-debug.apk.zip or app/build/outputs/apk/debug/app-debug.apk.ZIP.
```

`aapt2`, from the build tools, reads the package without installing it. The package name and the
label are the ones `app.json` set. The app was compiled against Android 17 (API 37), runs on Android
7.0 (API 24) and later, and targets Android 16 (API 36), which is the level the store judges it by. The
native code is for `arm64-v8a` alone, as asked. **64 MB is what a debug build weighs**, and lesson 20
puts the release build beside it.

The last two lines say something about what a *development* build is. **There is no JavaScript bundle
inside it**: `index.android.bundle` appears nowhere, because a debug build fetches its JavaScript from
the development server every time it starts, exactly as the `curl` of the Metro section did. Hermes and
React Native's C++ are inside, as `.so` libraries. Lesson 20 builds the release variant, which carries
the bundle as bytecode and runs with no server at all.

## Installing it

*Installing this APK on an emulator or a phone was not run for this course: the computer it was
recorded on had neither.* With an Android phone connected by USB, with developer options and USB
debugging turned on, or with an emulator running, `npx expo run:android` builds, installs and starts
the app in one command, and `adb install app/build/outputs/apk/debug/app-debug.apk` installs a build
you already have. The app opens on a screen that lists development servers it can reach; with
`npx expo start` running on the same network, pick it, and the planner loads.
