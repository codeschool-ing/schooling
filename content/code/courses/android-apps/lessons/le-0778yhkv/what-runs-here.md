---
title: What this course runs, and the part that needs a phone
version: 1
---

**Almost everything in this course runs on a Linux computer with no phone attached**, and it is
better to know now which parts do not than to find out in lesson 18. An Android app is built,
tested and inspected by programs that run on your computer: the Android Gradle plugin, the
compilers, the test runners. Only *running* the app, and watching it on a screen you can touch,
needs an Android device, real or emulated.

The course was recorded on a computer that could not start an emulator. An emulator is a virtual
machine, and on Linux it needs the processor's virtualisation to be reachable through `/dev/kvm`.
On the recording machine it was not:

```
ana@vm:~$ ls -l /dev/kvm
ls: cannot access '/dev/kvm': No such file or directory
```

**Type the same command on your own computer.** If it prints a line starting with `crw`, your
processor's virtualisation is on and an emulator can run; section 03 says what to install for it.
If it prints what you see above, either the setting is off in your computer's firmware, or you are
inside a virtual machine that does not pass it through. A phone with a USB cable does the same job
and needs neither.

## How this course shows you a screen without a phone

Two tools draw a composable on your computer, with no device and no emulator, and this course uses
both:

- **Robolectric** runs Android's framework inside an ordinary JVM test, and **Roborazzi** saves what
  a composable drew there as a PNG. Every screenshot in this course is a PNG one of these tests
  wrote, and lesson 21 explains how they are kept honest.
- **`android preview render`**, a command of Google's Android CLI, renders a function marked
  `@Preview` to an image. Lesson 3 uses it.

**What these give you is the drawing, not the device.** They show the layout, the colours, the text
and what changes when a test clicks a button. They do not show how the app feels under a thumb, how
fast it starts on a cheap phone, or what the system does when it kills the process. Where that
difference matters, the lesson says so.

## Lesson by lesson

| lesson | what it needs beyond your computer |
|---|---|
| 1 to 17 | nothing: building, unit tests, Compose tests and screenshots all run on the JVM |
| 2 and 10, the process being killed | a device or emulator to watch it happen; the lessons show it in tests, and describe the real thing |
| 18, WorkManager | a device to see work survive a reboot; the lesson runs the work in tests |
| 19 and 20, notifications and permissions | a device or emulator to see the system's dialog and the notification shade |
| 21, instrumented tests | a device or emulator for `connectedAndroidTest`; the lesson runs the same tests on Robolectric |
| 22, the release | a Google Play developer account, which costs money, to upload; everything up to the signed bundle runs on your computer |

**Without a device you can still do every lesson.** The parts in the table are read as
material rather than practice, and each is marked where it appears with **not run**, the
documentation it comes from, and no transcript. Nothing in this course shows you an output that
was not produced by a machine.

## What this course could not run

To be exact about it, these steps were not run when the course was recorded, and are described from
Google's documentation:

- **the emulator**, for the reason above, and so nothing installed or launched on one;
- **a real phone over `adb`**, because the recording computer had none attached;
- **instrumented tests** with `./gradlew connectedAndroidTest`, which need one of the two;
- **Android Studio**, whose window is a desktop program; the course works in a terminal and an
  editor, and section 03 says how Studio fits in if you prefer it;
- **the Play Console**, which needs a paid account and a person to accept its terms.

Every other command in a transcript was run, and its output is pasted as it came back.
