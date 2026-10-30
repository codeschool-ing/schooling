---
title: Your computer, set up for this course
version: 1
---

**Everything in this course runs on your own computer, and this section sets it up.** You need
three things: **Node.js 22**, which runs the course's TypeScript; **a Java development kit**, for
the key tools Android signing uses; and **Android's command-line build tools**, which sign and
check a package without Android Studio. One folder, `~/planner`, holds the course's programs.
None of it needs a phone or an emulator.

## Three ways to have one

| path | what you get | what it costs your computer | the transcripts |
|---|---|---|---|
| **installed** (recommended) | the tools on the computer you already use | about 1 GB of disk: 205 MB for Node.js, 330 MB for the JDK, 450 MB for the Android tools | match as printed on Linux; close on Windows and macOS |
| a virtual machine | Ubuntu Server 24.04, apart from your own system | 5 GB of disk or more, and 2 GB of memory while it runs | match as printed |
| online | a Linux machine in a browser tab | nothing on your computer; hours from a monthly allowance | close, not exact |

**Install it on the computer you use.** Node and the Android tools go into folders in your home
directory and touch nothing else. On **Linux** the commands below work as printed. On **Windows**,
every command is typed in WSL, the Linux that Windows ships with: `wsl --install -d Ubuntu-24.04`
in a PowerShell opened as administrator, a restart, then Ubuntu from the Start menu. On a **Mac**,
take Node.js 22 from nodejs.org, a JDK 21 from Adoptium (the Temurin build), and the macOS zip of
the Android command-line tools; the rest is typed in the Terminal app. The Windows and Mac paths
were not run for this course, so a path in a transcript may differ from yours.

**A virtual machine** is the same Linux steps inside a machine of its own: VirtualBox on Windows or
Linux, UTM on a Mac with an Apple chip, and Ubuntu Server 24.04 LTS as the guest. Nothing here
opens a window, so a server with no desktop is enough.

**Online**, GitHub Codespaces gives you a Linux machine with a terminal in a browser tab. GitHub
gives personal accounts a monthly allowance of hours and charges past it, on terms it sets and can
change. It was not run for this course.

## Node.js and the JDK

The `javascript` course installs Node.js in its lesson 1, and this course uses that installation:
version 22.22.0, from nodejs.org, in `~/.local/node`. If you took `kotlin` or `android-apps`, you
already have the JDK; otherwise Ubuntu's package is the one used here:

```sh
sudo apt install openjdk-21-jdk-headless unzip
```

## The Android command-line tools

Google publishes the tools as a zip. Unpack it into `~/android`, under the folder name the tools
expect, then let its `sdkmanager` fetch the two packages this course uses: the build tools, which
carry `apksigner`, `zipalign` and `aapt2`, and one platform, which `aapt2` needs to read. The last
line fetches `bundletool`, the program Google Play itself uses to turn an app bundle into APKs:

```sh
mkdir -p ~/android/cmdline-tools && cd ~/android/cmdline-tools
curl -fLO https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip
unzip -q commandlinetools-linux-13114758_latest.zip && mv cmdline-tools latest
~/android/cmdline-tools/latest/bin/sdkmanager --licenses
~/android/cmdline-tools/latest/bin/sdkmanager "build-tools;36.0.0" "platforms;android-36"
curl -fL -o ~/android/bundletool.jar \
  https://github.com/google/bundletool/releases/download/1.18.3/bundletool-all-1.18.3.jar
```

`--licenses` shows Google's licence terms and waits for you to type `y` to each. Then add two lines
to the end of `~/.profile`, so every new terminal finds the tools, and open a new terminal:

```sh
export ANDROID_HOME="$HOME/android"
PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/build-tools/36.0.0:$PATH"
```

Now ask each tool to answer:

```
ana@dev:~$ node --version
v22.22.0
ana@dev:~$ java -version
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@dev:~$ apksigner --version
0.9
ana@dev:~$ java -jar ~/android/bundletool.jar version
1.18.3
ana@dev:~$ sdkmanager --list_installed
Installed packages:
  Path                 | Version | Description                | Location            
  -------              | ------- | -------                    | -------             
  build-tools;36.0.0   | 36.0.0  | Android SDK Build-Tools 36 | build-tools/36.0.0  
  platforms;android-36 | 2       | Android SDK Platform 36    | platforms/android-36
```

`apksigner` reports its own version, 0.9, rather than the build tools' 36.0.0; both are right.

## The planner's folder

The course's example is a **study planner**, the app the `frontend` track builds and the platform
courses build again on a phone: a person lists their courses, adds study sessions with a date and
a length, ticks them off, and sees the week's total. Here you ship it, so its code matters less
than everything around it. Make the folder and give it a `package.json`. `private` stops npm ever
offering to publish it, and `"type": "module"` lets every file use `import`. Save this as
`package.json`:

```json
{
  "name": "planner",
  "private": true,
  "type": "module"
}
```

Save this as `check.ts`. It asks for the database library lessons 16 and 17 use, and for the two
signing tools:

```typescript
// check.ts: does every tool this course uses answer?
import Database from "better-sqlite3";
import { execFileSync } from "node:child_process";

const db = new Database(":memory:");
const row = db.prepare("select sqlite_version() as version").get() as { version: string };
console.log("node     ", process.version);
console.log("sqlite   ", row.version);
for (const [name, args] of [["keytool", ["-help"]], ["apksigner", ["--version"]]] as const) {
  try {
    execFileSync(name, args, { stdio: "ignore" });
    console.log(name.padEnd(9), "answers");
  } catch {
    console.log(name.padEnd(9), "MISSING");
  }
}
```

Install the library with `-E`, which writes the exact version into `package.json` instead of a
range, and run the check. Node 22 runs a `.ts` file directly by removing its type annotations, so
there is no build step:

```
ana@dev:~/planner$ npm install -E better-sqlite3@13.0.3

added 2 packages in 1s
ana@dev:~/planner$ node check.ts
node      v22.22.0
sqlite    3.53.4
keytool   answers
apksigner answers
```
