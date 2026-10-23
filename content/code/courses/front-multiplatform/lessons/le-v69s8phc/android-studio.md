---
title: Android Studio, the SDK and somewhere to run it
version: 1
---

**To build the Android project you need three things this course has not installed yet**: a Java
Development Kit, the Android SDK, and a place to run the app, either an emulator or a phone. Android
Studio brings the second and the means to the third, and Capacitor expects it.

*Nothing in this section after the JDK was run for this course. The machine it was recorded on could
not reach `dl.google.com`, where Google serves Android Studio, the SDK and the Android Gradle plugin,
so the steps come from Google's documentation at developer.android.com and Capacitor's at
capacitorjs.com, and the only output shown is what Capacitor printed without them.*

## The JDK

Gradle and the Android build tools run on Java, and the project Capacitor generated asks for Java
21 by name:

```
ana@dev:~/planner$ grep -A3 compileOptions android/app/capacitor.build.gradle
  compileOptions {
      sourceCompatibility JavaVersion.VERSION_21
      targetCompatibility JavaVersion.VERSION_21
  }
ana@dev:~/planner$ java -version
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
```

On Ubuntu that JDK is one package, `sudo apt install openjdk-21-jdk-headless`. Android Studio also
carries a JDK of its own, which it uses when you build from inside it; the one from `apt` is for
running Gradle from a terminal.

## What happens without the SDK

`npx cap run android` builds the app and puts it on a device. On a machine with no SDK it gets as far
as copying your files, then says what is missing:

```
ana@dev:~/planner$ npx cap run android
✔ Copying web assets from dist to android/app/src/main/assets/public in 5.96ms
✔ Creating capacitor.config.json in android/app/src/main/assets in 533.92μs
[info] Inlining sourcemaps
✔ copy android in 17.64ms
✔ Updating Android plugins in 1.27ms
✔ update android in 22.86ms
[error] native-run failed with error
        
        ERR_SDK_NOT_FOUND: No valid Android SDK root found.
        
        More details for this error may be available online: https://github.com/ionic-team/native-run/wiki/Android-Errors
        
```

**`native-run`** is the program Capacitor uses to talk to devices, and the **SDK root** is the folder
the SDK lives in, which it looks for in the `ANDROID_HOME` variable and in Android Studio's default
location. `npx cap open android`, which opens the project in Android Studio, fails the same way for
the same reason:

```
ana@dev:~/planner$ npx cap open android
[error] Unable to launch Android Studio. Is it installed?
        Attempted to open Android Studio at: /usr/local/android-studio/bin/studio.sh
        You can configure this with the CAPACITOR_ANDROID_STUDIO_PATH environment variable.
```

## Installing them, from Google's steps

1. **Download Android Studio** from developer.android.com/studio. On Linux it is a `.tar.gz`; unpack it
   and run `bin/studio.sh`. Capacitor looks for it at `/usr/local/android-studio`, as the message
   above says, so either unpack it there or set `CAPACITOR_ANDROID_STUDIO_PATH` to `studio.sh`
   wherever you put it. On Windows and macOS it is an installer, and Capacitor finds it unaided.
2. **Let the setup wizard install the SDK.** It downloads the SDK platform, the build tools and the
   platform tools, which include `adb`, into `~/Android/Sdk` on Linux. Then set the variable in your
   `~/.profile`, `export ANDROID_HOME="$HOME/Android/Sdk"`, and open a new terminal.
3. **Install the platform the project names.** `compileSdkVersion` was 36 in the last section; in
   Android Studio's SDK Manager, the "Android API 36" platform is that one.
4. **Make a device to run on.** In the Device Manager, create a virtual device from a phone and a
   system image. An emulator needs the processor's virtualisation: on Linux that is `/dev/kvm`, and
   your user in the `kvm` group.

**A real phone is the other way**, and often the faster one. In its settings, open "About phone" and
tap "Build number" seven times; a new "Developer options" menu appears, and in it "USB debugging". With
the phone connected by cable and the prompt on its screen accepted, `adb devices` lists it.

Then `npx cap run android` lists the emulators and phones it found and asks which to use, and `npx cap
open android` opens the project in Android Studio, where the green Run button does the same. **Use
Studio when something native is wrong**: its build window shows Gradle's errors in full, which a
terminal scrolls past.

On Windows with WSL, Android Studio and the emulator run on Windows, and lesson 1 put your terminal
in Linux. **Keep the project on one side of that line**: run `npm install`, the `cap` commands and
Gradle from the same system, so the files Gradle reads are the files npm wrote. That arrangement was
not run for this course either, and Capacitor's documentation for Windows is the one to follow.
