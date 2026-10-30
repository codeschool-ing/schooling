---
title: Three ways to get the Android SDK
version: 1
---

**This course starts from the machine the `kotlin` course built**, and adds one thing to it: the
**Android SDK**, the libraries and tools that turn Kotlin into something a phone installs. Lesson 1
of `kotlin` set up Ubuntu 24.04 with OpenJDK 21, Kotlin 2.4.21 and Gradle 9.8.2, and every command in
this course assumes them. Check that each one answers before going further:

```
ana@vm:~$ java -version 2>&1 | head -1; kotlinc -version; gradle --version | grep ^Gradle
openjdk version "21.0.12.1" 2026-08-18
info: kotlinc-jvm 2.4.21 (JRE 21.0.12.1+1-1-24.04.4-Ubuntu)
Gradle 9.8.2
```

If one of those prints `command not found` or a different version, go back to lesson 1 of `kotlin`,
sections 02 and 03, and build that machine first. Everything below is added on top of it.

## Three paths, and the one this course recommends

| path | what you get | what it costs your computer | the course's transcripts |
|---|---|---|---|
| **the command-line tools on Ubuntu 24.04** (recommended) | the SDK in `~/Android/Sdk`, driven from a terminal | about 520 MB for the SDK and 160 MB for the Android CLI, plus Gradle's cache, which passes 2 GB by lesson 22 | run as printed, byte for byte |
| **Android Studio**, on Linux, Windows or macOS | the same SDK, plus an editor, previews in the window and the emulator manager | Google lists the memory and disk on its download page; it is the largest of the three | the Gradle commands work as printed; the window is not shown in this course |
| **online**, a cloud development environment | a Linux machine in a browser tab | nothing on your computer, but an account and a monthly allowance with somebody | close, with no emulator, and paths that differ |

**The course recommends the command-line tools**, on the same Ubuntu the `kotlin` course built, and
records everything that way. They are the smallest download, they work the same inside a virtual
machine, and every step is a command you can read. Android Studio installs exactly the same SDK into
exactly the same directory, `~/Android/Sdk` on Linux, and runs the same Gradle build; if you prefer
an editor that previews composables as you type, install it as well, or instead. Its installer and
its window were not run for this course.

**A virtual machine** works for everything except the emulator, which is itself a virtual machine
and needs `/dev/kvm` from section 02. Inside VirtualBox or UTM it usually does not get it, so a
phone over USB is the way to see the app run.

**Online**, GitHub Codespaces and similar services give you a Linux machine in a browser tab. The
build and every test in this course run there; there is no emulator and no USB port. Each service
gives personal accounts a monthly allowance and charges past it, on terms it sets and can change. It
was not run for this course.

## The command-line tools

Google publishes the SDK's command-line tools as one zip for Linux. The file name carries a build
number, and this course pins the one it was recorded with: **version 23.0, build 16111833**.

```
ana@vm:~$ mkdir -p ~/Android/Sdk/cmdline-tools && cd ~/downloads
ana@vm:~/downloads$ curl -fsSLO https://dl.google.com/android/repository/commandlinetools-linux-16111833_latest.zip
ana@vm:~/downloads$ sha256sum commandlinetools-linux-16111833_latest.zip
0877a1d048fe4a24efe2eff536ca4223f7adeb58648bb81909d33c446918cfa8  commandlinetools-linux-16111833_latest.zip
ana@vm:~/downloads$ ls -lh commandlinetools-linux-16111833_latest.zip
-rw-r--r-- 1 ana ana 173M Oct 30 15:41 commandlinetools-linux-16111833_latest.zip
ana@vm:~/downloads$ unzip -q commandlinetools-linux-16111833_latest.zip -d ~/Android/Sdk/cmdline-tools
ana@vm:~/downloads$ mv ~/Android/Sdk/cmdline-tools/cmdline-tools ~/Android/Sdk/cmdline-tools/latest
ana@vm:~/downloads$ ls ~/Android/Sdk/cmdline-tools/latest/bin
android
apkanalyzer
avdmanager
d8
lint
profgen
r8
resourceshrinker
retrace
screenshot2
sdkmanager
```

`sha256sum` prints the checksum of what arrived. Google prints the SHA-256 of each download on the
Android Studio download page, under *Command line tools only*; **compare the two by eye before
unpacking anything**. That comparison was not made when the course was recorded, because the
page is a browser form the recording machine could not open; the value above is the one it
computed. Section 04 shows what a damaged download does.

**The rename is not optional.** The zip unpacks to a folder called `cmdline-tools`, and the tools
inside expect to live in `<sdk>/cmdline-tools/latest`. Skip the `mv` and they cannot work out where
the SDK is; section 04 shows that message too.

Two lines in `~/.bashrc` tell every new terminal where the SDK is. **`ANDROID_HOME` is the variable
the Android Gradle plugin reads**, and the `PATH` line makes the tools in `cmdline-tools/latest/bin`
and, once it is installed, `adb` in `platform-tools` answer by name:

```
ana@vm:~$ echo 'export ANDROID_HOME="$HOME/Android/Sdk"' >> ~/.bashrc
ana@vm:~$ echo 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"' >> ~/.bashrc
ana@vm:~$ source ~/.bashrc
ana@vm:~$ echo $ANDROID_HOME
/home/ana/Android/Sdk
```

## The Android CLI, and what it asks the first time

The first tool to run is `android`, the **Android CLI**. In version 23.0 of the command-line tools
it is the replacement for `sdkmanager`, as the end of this section shows, and the zip carries only a
small launcher: the first time it runs, it downloads its own latest version and shows you two
things to read.

```
ana@vm:~$ android --version
Downloading Android CLI...
Unpacking embedded installation...

Terms of Service and License Agreement for the Android Software Development Kit

https://developer.android.com/studio/terms

Google collects usage data for the Android CLI, such as commands, sub-commands, and flags used. This data does not include custom parameters or identifiable information. This information helps improve the tool and is collected in accordance with Google's Privacy Policy.

https://policies.google.com/privacy

Disable Android CLI metrics collection by using the --no-metrics flag.

Tip: For the best experience using Android CLI with agents, we strongly recommend running android init to install the necessary skills and resources.
1.1.16717390
Oct 30, 2026 3:41:51 PM java.util.prefs.FileSystemPreferences setupUserRoot
INFO: Created user preferences directory.
ana@vm:~$ ls ~/.android/cli
analytics
bundles
last_update_check
tos_displayed
```

Read the two links before carrying on. The first is the licence for the SDK, which you accept by
using it. The second says Google collects usage data from the CLI, and how to turn that off: add
`--no-metrics` to a command. The `java.util.prefs` line at the end comes from the JVM, not from
the CLI, and appears once.

**The CLI is the one thing on this machine that cannot be pinned.** The launcher always downloads
the latest version, and this course was recorded with 1.1.16717390, the one it found on 30 October
2026. If yours prints a later number, the commands below should still work; if one does not, its
`--help` says what replaced it.

Now the SDK itself. Three packages: the **platform** for Android 37, which is the API the compiler
checks your code against; the **build tools** that package and sign an app; and the **platform
tools**, which hold `adb`, the program that talks to a phone.

```
ana@vm:~$ android sdk install platforms/android-37.0 build-tools/36.1.0 platform-tools
...om/android/repository/platform-37.0_r02.zip [##########] 100% (  64.2 MB/  64.2 MB) ETA: ----- 
...roid/repository/build-tools_r36.1_linux.zip [##########] 100% (  61.2 MB/  61.2 MB) ETA: ----- 
...repository/platform-tools_r37.0.1-linux.zip [##########] 100% (   8.6 MB/   8.6 MB) ETA: ----- 
Unzipping platforms/android-37.0... [#####################] 100% ( 119.2 MB/ 119.2 MB) ETA: ----- 
Unzipping build-tools/36.1.0... [#########################] 100% ( 149.2 MB/ 149.2 MB) ETA: ----- 
Unzipping platform-tools... [#############################] 100% (  21.2 MB/  21.2 MB) ETA: ----- 
ana@vm:~$ android sdk list
Installed packages:
  build-tools/36.1.0             36.1.0                      Android SDK Build-Tools 36.1           
  cmdline-tools/latest           unknown   ->        23.0.0  Android SDK Command-line Tools (latest)
  platform-tools                 37.0.1                      Android SDK Platform-Tools             
  platforms/android-37.0         2.0.0                       Android SDK Platform 37.0              
```

`android sdk list` shows what is installed, and `android sdk list --all` shows everything the
repository offers. `cmdline-tools` shows `unknown` as its installed version because it was unpacked
by hand rather than installed by the CLI; it works the same. Here is what it all costs:

```
ana@vm:~$ du -sh ~/Android/Sdk/* ~/.android/cli
150M	/home/ana/Android/Sdk/build-tools
174M	/home/ana/Android/Sdk/cmdline-tools
8.0K	/home/ana/Android/Sdk/licenses
22M	/home/ana/Android/Sdk/platform-tools
165M	/home/ana/Android/Sdk/platforms
160M	/home/ana/.android/cli
ana@vm:~$ adb version | head -2
Android Debug Bridge version 1.0.41
Version 37.0.1-15733141
```

About 520 MB in the SDK and 160 MB for the CLI in `~/.android/cli`. `adb` answers, and will have
nothing to talk to until a phone or an emulator is attached.

## The emulator, if your computer can run one

**Not run.** The recording machine had no `/dev/kvm`, so these commands were not typed for this
course. Google's documentation for the Android CLI installs an emulator and a system image as SDK
packages like the three above, the `emulator` package and an image under `system-images/`, and
creates and starts a virtual device with `android emulator`; `android emulator --help` lists its
commands. With Android Studio, the Device Manager does the same from a window.

## `sdkmanager`, which you will see everywhere

Most tutorials written before 2026 say `sdkmanager`, and the zip still carries it. It now prints a
warning and hands its work to the CLI:

```
ana@vm:~$ sdkmanager --list_installed 2>&1 | head -2
WARNING: The SDK Manager CLI tool (sdkmanager) is deprecated. Android CLI will be used instead.
The 'android' binary can also be found in the cmdline-tools directory, and 'android sdk' is the replacement for 'sdkmanager'.
```

**Its package names use a semicolon where the CLI uses a slash**: `"platforms;android-37.0"` against
`platforms/android-37.0`. When a tutorial shows the old form, the translation is that one character.
