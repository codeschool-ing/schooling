---
title: Setting up Android Studio and an emulator
version: 1
---

**Android Studio is installed from developer.android.com, and everything else comes through it.**
It is a desktop program with windows and wizards, and it could not run on the machine this course
was recorded on, so the steps below are described rather than shown. The command-line tools it
installs could run there, and their transcripts are real.

## Android Studio and the SDK

1. Download Android Studio from developer.android.com/studio for your system and install it: an
   installer on Windows and macOS, an archive on Linux whose `bin/studio.sh` starts it.
2. The first start runs a setup wizard. Choose the *Standard* setup. It downloads the SDK, the
   emulator and a recent Android platform, a few gigabytes, into a folder it names at the end:
   `~/Android/Sdk` on Linux, `~/Library/Android/sdk` on a Mac, and `AppData\Local\Android\Sdk` in
   your user folder on Windows.
3. Open *Settings*, then *Languages & Frameworks › Android SDK*. Under *SDK Platforms*, tick
   **Android 15.0 (API 35)**, the version the app of section 05 was compiled against. Under *SDK
   Tools*, check that *Android SDK Platform-Tools* and *Android Emulator* are ticked.

The SDK's command-line tools are what this course types, so tell your terminal where they are. On
Linux, add these lines to `~/.bashrc` and open a new terminal (on a Mac, the same lines with the
Mac path, in `~/.zshrc`; on Windows, Android Studio's *SDK Manager* page shows the path to add to
the user `Path` variable):

```sh
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator
```

Two tools answer from there. **adb**, the Android Debug Bridge, is how your computer talks to any
device, emulator or phone: it installs apps, runs shell commands on the device, forwards ports and
collects logs. **emulator** starts virtual devices:

```
ana@laptop:~$ adb version
Android Debug Bridge version 1.0.41
Version 36.0.0-13206524
Installed as /home/ana/Android/Sdk/platform-tools/adb
Running on Linux 6.18.44-fc-v114 (x86_64)
ana@laptop:~$ emulator -version | head -1
Android emulator version 36.1.9.0 (build_id 13823996) (CL:N/A)
```

## A virtual device

An emulator runs an **AVD**, an Android Virtual Device: a description of a phone (screen, memory,
buttons) plus a system image, the Android it boots.

1. In Android Studio, open *Device Manager* and press *Create Virtual Device*.
2. Choose **Pixel 8** from the *Phone* list, or any phone with a screen around six inches.
3. Choose the system image **API 35**, *Google APIs*, for your processor: *x86_64* on an Intel or
   AMD computer, *arm64-v8a* on an Apple-silicon Mac. Download it when asked, about 1.5 GB.
4. Name it `Pixel_8_API_35` and finish. Press the play button beside it to start it.

The first boot takes a minute or two and later ones a few seconds. While it runs, adb lists it as a
device named `emulator-5554`, and the command line can start it without Android Studio:
`emulator -avd Pixel_8_API_35`.

On the recording machine there is no emulator and no device, so the two commands that would list
them come back empty. On yours, after the steps above, the first lists `emulator-5554` with the
word `device` beside it and the second lists `Pixel_8_API_35`:

```
ana@laptop:~$ adb devices
* daemon not running; starting now at tcp:5037
* daemon started successfully
List of devices attached

ana@laptop:~$ emulator -list-avds
```

## How the emulator reaches boxoffice

Inside the emulator, `localhost` is the emulator itself, not your computer. **The emulator gives your
computer a fixed address instead, `10.0.2.2`**, and a request from the app to
`http://10.0.2.2:8080` arrives at boxoffice on your computer's port 8080:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 240\" role=\"img\" aria-label=\"boxoffice runs on your computer and listens on localhost port 8080. Inside the emulator, localhost means the emulator itself. Tickets asks http://10.0.2.2:8080, and the emulator delivers that request to the computer it runs on, where boxoffice answers.\"><defs><marker id=\"f14addresses-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"300\" height=\"170\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"170\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">your computer</text><rect x=\"45\" y=\"120\" width=\"250\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">boxoffice</text><text x=\"170\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">localhost:8080</text><rect x=\"380\" y=\"30\" width=\"300\" height=\"170\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"530\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">the emulator</text><rect x=\"405\" y=\"120\" width=\"250\" height=\"50\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"530\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Tickets</text><text x=\"530\" y=\"153\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">http://10.0.2.2:8080</text><rect x=\"405\" y=\"62\" width=\"250\" height=\"44\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"530\" y=\"77\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">localhost</text><text x=\"530\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the emulator itself, not your computer</text><line x1=\"403\" y1=\"145\" x2=\"297\" y2=\"145\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f14addresses-ah)\"></line><text x=\"350\" y=\"137\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--phosphor)\">10.0.2.2</text><text x=\"350\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10.0.2.2 is the address the emulator gives to the computer it runs on</text></svg>", "caption": "Inside the emulator, localhost is the emulator; your computer is 10.0.2.2."}
```

A phone on a cable has no such address. `adb reverse tcp:8080 tcp:8080` makes the phone's own port
8080 lead to your computer's, and the app then uses `http://localhost:8080`; section 05 says which
line to change. That command was not run for this course, having no phone to run it against.
