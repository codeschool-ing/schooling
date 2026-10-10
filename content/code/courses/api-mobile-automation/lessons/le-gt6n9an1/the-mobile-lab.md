---
title: The lab for the second half
version: 1
---

**Lessons 14 to 22 need an Android device to test on, and the course gives you none**: you either
run an emulator on your own computer, plug in a phone you own, or borrow a device somewhere online.
This section compares the three, says what each costs, and recommends one. The next section sets
the recommended one up, and the one after the app says what to do when it fails.

Whatever the device, three things go on your own computer:

- **Android Studio**, Google's development environment for Android, free. It brings the **SDK**,
  the libraries and tools an Android build needs, and the **emulator**. You will use it to build
  and install the app, to look at its screens, and in lesson 16 to run Espresso;
- **boxoffice**, from lesson 1, running as before: the app asks it for the shows;
- **Node 22**, from lesson 1, which Appium in lesson 15 and Detox in lesson 17 run on.

## Three ways to have a device

| path | what you get | what it costs | what it cannot do |
|---|---|---|---|
| **an emulator on your computer** (recommended) | a virtual Pixel phone in a window, any Android version | 8 GB of memory at least, 16 GB to be comfortable; about 10 GB of disk; a processor with virtualisation switched on | tell you how the app behaves on a real model's hardware (lesson 19) |
| **a phone of your own, over USB** | the real thing: its screen, its sensors, its manufacturer's quirks | nothing, if you have an Android phone from the last five or six years | run the Android version or the screen size you did not happen to buy |
| **online** | an emulator on a cloud machine with virtualisation, or a device in a device cloud | an account; time from a free allowance, then money | be at hand: each run waits for a machine, and some lessons need you to touch the device |

**The emulator is the recommended path.** It can be any phone and any Android version you ask for,
it resets in a second, and it is what every Android tester uses daily, real devices or not. Its
cost is your computer. The figures in that table are what Google publishes for Android Studio at
the time of writing; on 8 GB of memory it runs, slowly, if you close the browser while it does.

The emulator is a virtual machine itself, so it needs your processor's virtualisation support:
Intel VT-x or AMD-V, switched on in the computer's firmware, and on Windows the *Windows
Hypervisor Platform* feature. That is also why the virtual-machine path of lesson 1 does not
carry over: an emulator inside a virtual machine needs nested virtualisation, which most laptops
do not offer. **If you followed lesson 1 in a virtual machine, install Android Studio on your own
system now**, and keep boxoffice where it is or run it on your system too.

**A phone of your own** is the right path for a computer that cannot run an emulator. Switch on
*Developer options* (tap *Build number* in *About phone* seven times), then *USB debugging*, and
connect it with a cable; Android asks on the phone whether to trust the computer. Two things differ
from the emulator, and the next sections say where: the phone reaches your computer through
`adb reverse` rather than through the emulator's special address, and anything that depends on a
particular Android version, such as the notification permission of lesson 21, depends on the one
your phone runs. This path was not run for this course.

**Online**, two routes exist and neither was run for this course. GitHub's hosted Linux machines
for Actions allow hardware virtualisation, so a workflow can start an emulator and run tests on it;
public repositories have run on them for free, on terms GitHub sets and can change. And the device
clouds of lesson 20 give you a real phone over the network, with a trial measured in minutes. Both
are good for running a suite and poor for learning, because you cannot sit in front of the device.

## On Windows and on a Mac

Android Studio runs on Windows, macOS and Linux, and the emulator with it. **On Windows, install
Android Studio and Node on Windows itself, not inside WSL**, and type this half's commands in
PowerShell: `adb`, `emulator` and `npx appium` are the same commands there, and an emulator cannot
be reached easily from inside WSL. boxoffice can stay in WSL; Windows reaches a server in WSL at
`localhost`. On a Mac with Apple silicon, the emulator runs ARM system images natively and is fast.
Every transcript in this half was recorded on Ubuntu 24.04, so a path or a prompt will look
different on yours.
