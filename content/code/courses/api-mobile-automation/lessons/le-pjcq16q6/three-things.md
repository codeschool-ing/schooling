---
title: An emulator, a simulator and a device are three different things
version: 1
---

**An emulator imitates a phone's hardware and runs the real operating system on it; a simulator
imitates the operating system and runs on the computer's own hardware; a device imitates nothing
and is true only for itself.** The words are used loosely, often as if they meant the same, and
that habit hides exactly what this lesson is about: each of the three is wrong in a different
place, so a defect that one of them cannot show is a defect the other may show perfectly well.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 290\" role=\"img\" aria-label=\"Three columns, each with three layers: the app, the system and the hardware. Android emulator: the app is the same APK a phone gets and Android is Google's real image, booted, both real; the hardware is made up, property by property. iOS Simulator: the app is built for the Mac's processor, iOS is simulator frameworks on macOS, and the hardware is the Mac's own, with no phone at all, all three imitated or different. A real device: the build a user installs, the maker's own build of the system, and one real model of hardware, all real.\"><text x=\"120\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Android emulator</text><rect x=\"20\" y=\"62\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the app</text><text x=\"120\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the same APK a phone gets</text><rect x=\"20\" y=\"124\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Android</text><text x=\"120\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Google's image, booted</text><rect x=\"20\" y=\"186\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"120\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the hardware</text><text x=\"120\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">made up, property by property</text><text x=\"350\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">iOS Simulator</text><rect x=\"250\" y=\"62\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"350\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the app</text><text x=\"350\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">built for the Mac's processor</text><rect x=\"250\" y=\"124\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"350\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">iOS</text><text x=\"350\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">simulator frameworks on macOS</text><rect x=\"250\" y=\"186\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"350\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the hardware</text><text x=\"350\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the Mac's own: no phone at all</text><text x=\"580\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a real device</text><rect x=\"480\" y=\"62\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the app</text><text x=\"580\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the build a user installs</text><rect x=\"480\" y=\"124\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the system</text><text x=\"580\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">the maker's own build</text><rect x=\"480\" y=\"186\" width=\"200\" height=\"48\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"580\" y=\"203\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">the hardware</text><text x=\"580\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">one real model</text><rect x=\"150\" y=\"262\" width=\"26\" height=\"16\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"184\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">the real thing</text><rect x=\"370\" y=\"262\" width=\"26\" height=\"16\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"404\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">imitated, or a different build</text></svg>", "caption": "The emulator imitates the hardware, the simulator imitates the system, and a device is real in every layer, for one model only."}
```

## The Android emulator

The emulator of lesson 14 is a virtual machine. It **boots Android**, a real system image built by
Google, with its own kernel, on hardware the emulator makes up: a processor, memory, a screen, a
battery, a GPS, cameras and sensors. The processor is real, borrowed from your computer through the
virtualisation lesson 14 asked you to switch on, which is why the image must match it, x86_64 on a
PC and arm64 on an Apple-silicon Mac. Everything else is imitated, and the imitation is declared,
property by property, in a list the emulator ships with. Three of them, read from the SDK on the
recording machine:

```
ana@laptop:~$ grep -A4 -E '^name += hw\.(gps|battery|accelerometer)$' ~/Android/Sdk/emulator/lib/hardware-properties.ini
name        = hw.gps
type        = boolean
default     = yes
abstract    = GPS support
description = Whether there is a GPS in the device.
--
name        = hw.battery
type        = boolean
default     = yes
abstract    = Battery support
description = Whether the device can run on a battery.
--
name        = hw.accelerometer
type        = boolean
default     = yes
abstract    = Accelerometer
description = Whether there is an accelerometer in the device.
```

**A battery is a yes-or-no**: the virtual phone has one or it does not, and its charge is a number
you set in the emulator's *Extended controls* window. So is a GPS, whose position is whatever you
type there. The APK is the very file a phone receives, and Android runs it with the same code a
phone would; what differs is everything underneath Android.

## The iOS simulator

The iOS Simulator of lesson 18 is not a virtual machine and boots nothing. **The app is compiled
for the Mac's own processor and runs as a process on macOS**, linked against versions of Apple's
frameworks built for the simulator. It looks like an iPhone because it draws one. There is no phone
hardware underneath it at all: memory, processor, disk and network are the Mac's, which is why
`localhost` inside it reached boxoffice in lesson 18 without the `10.0.2.2` an emulator needs.

That makes it fast to start and quick to run, and it means the binary you test is not the binary
an iPhone runs: the one for the phone is compiled again, for the phone's processor, and signed.

## A real device

A phone in your hand runs the manufacturer's build of the operating system on its own hardware,
with the owner's settings, the owner's other apps and whatever network the room has. **Nothing is
imitated, and nothing generalises**: a test that passes on a Samsung on Android 14 says nothing
certain about a Motorola on Android 12. Lesson 20 is about choosing which few devices to trust, and
renting the rest.
