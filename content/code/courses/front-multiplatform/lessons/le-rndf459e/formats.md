---
title: What a package is, on each system
version: 1
---

**A package is the one file a person downloads, and each system has its own kinds.** Until now the
planner ran from a project folder: `npx cap run`, `npm start`, `npx tauri dev`. Nobody else has that
folder. What they get is a package, and the package decides how the app is installed, where its files
go, how it is removed, and who has vouched for it.

| system | package | what it is | who installs it |
|---|---|---|---|
| Android | `.apk` | the app, ready to install on a phone | the person, from a file, or a store |
| Android | `.aab` | an **Android App Bundle**: the app in pieces, for Google Play to cut into APKs per device | only Google Play |
| iOS | `.ipa` | the app, signed, in an archive | the App Store, TestFlight, or a company's own system |
| Windows | `.exe` (NSIS), `.msi` | an installer program, or a package Windows' own installer reads | the person, or a company's tools |
| macOS | `.dmg` holding an `.app` | a disk image with the app inside, dragged into Applications | the person |
| Linux | `.deb`, `.rpm` | a package the system's package manager installs, with its dependencies | `apt`, `dnf` and their friends |
| Linux | AppImage | one file that runs where it is, with everything inside | nobody: it is made executable and run |

**Two rows deserve a second look.** An **AAB is not something a person can install**: it is what Google
Play asks a developer to upload, and Play builds from it the APK each phone receives, with only that
phone's screen density and processor in it. An APK is still what you hand to a tester or put on your own
site. And **an `.ipa` cannot be handed out at all** in the ordinary way: an iPhone installs only an app
signed for it, so the file leaves through Apple, which is lesson 14's subject.

## What this course builds, and what it describes

| package | built here | from |
|---|---|---|
| `.deb`, `.rpm`, AppImage from Tauri | yes, in lesson 12 | `npx tauri build` |
| `.deb` and AppImage from Electron | yes, in this lesson | `electron-builder` |
| icons for every system | yes, in this lesson | `tauri icon`, `@capacitor/assets` |
| `.apk` and `.aab` | **no** | Android Studio or Gradle, which the recording machine could not install |
| `.ipa` | **no** | Xcode, on a Mac |
| `.exe`, `.msi`, `.dmg` | **no** | the same tools, run on Windows or a Mac |

**Each desktop installer is built on its own system.** Electron's tool can build some Windows formats on
Linux with extra programs installed, and Tauri can try the same, but signing and testing still want the
real system, and both tools' documentation builds each system's packages on that system. That is why a
project that ships to three systems builds on three machines, usually three runners of a CI service, which
lesson 15 comes back to.
