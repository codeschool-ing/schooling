---
title: When the setup fails
version: 1
---

**Each failure below has one cause, and the message names it** if you read it to the end. The
first three were produced on purpose, on a fresh copy of the `kotlin` course's machine, and the
fourth is described. They are the four this setup meets most: a terminal that has not read `~/.bashrc`, a folder in the wrong place,
a build that cannot find the SDK, and a download that did not finish.

## `android: command not found`, right after unpacking it

The tool is on disk and the shell cannot find it. A terminal reads `~/.bashrc` **when it starts**,
so one that was already open before the two `echo` lines of section 03 still has the old `PATH`:

```
ana@vm:~$ android --version; echo $?
bash: line 1: android: command not found
127
ana@vm:~$ ls ~/Android/Sdk/cmdline-tools/latest/bin/android
/home/ana/Android/Sdk/cmdline-tools/latest/bin/android
```

**127 is the shell's own number for "no such command"**, so the message comes from `bash` and not
from Android. The `ls` proves the file is where section 03 put it. Open a new terminal, or type
`source ~/.bashrc` in this one. If a new terminal still cannot find it, `tail -2 ~/.bashrc` shows the
two lines, and they should read exactly as section 03 typed them, single quotes outside.

## `Could not determine SDK root`

The zip unpacks to a folder called `cmdline-tools` with `bin` and `lib` straight inside it. Unpack
it into `~/Android/Sdk` and stop there, and the tools sit one level higher than they expect:

```
ana@vm:~$ ls ~/Android/Sdk ~/Android/Sdk/cmdline-tools
/home/ana/Android/Sdk:
cmdline-tools

/home/ana/Android/Sdk/cmdline-tools:
NOTICE.txt
bin
lib
source.properties
ana@vm:~$ ANDROID_HOME=~/Android/Sdk ~/Android/Sdk/cmdline-tools/bin/sdkmanager --list_installed 2>&1 | tail -2
Error: Could not determine SDK root.
Error: Either specify it explicitly with --sdk_root= or move this package into its expected location: <sdk>/cmdline-tools/latest/
```

The second line of the error is the fix, in Google's words: the package belongs in
`<sdk>/cmdline-tools/latest/`. The tools work out where the SDK is from where they are, two
directories up, and from `ANDROID_HOME`; here the two disagree, and they refuse rather than guess.
Move the folder:

```sh
mkdir -p ~/Android/Sdk/cmdline-tools/latest
mv ~/Android/Sdk/cmdline-tools/{bin,lib,NOTICE.txt,source.properties} ~/Android/Sdk/cmdline-tools/latest/
```

## `SDK location not found`

The SDK is installed and the build cannot find it. The Android Gradle plugin looks in two places,
and the message lists both:

```
ana@vm:~/planner$ env -u ANDROID_HOME ./gradlew --console=plain assembleDebug 2>&1 | sed -n "/What went wrong/,/^$/p"
* What went wrong:
Could not determine the dependencies of task ':app:compileDebugJavaWithJavac'.
> SDK location not found. Define a valid SDK location with an ANDROID_HOME environment variable or by setting the sdk.dir path in your project's local properties file at '/home/ana/planner/local.properties'.
```

This one was made by running the build without `ANDROID_HOME` in its environment, which is what a
terminal opened before section 03's `export` line looks like. The first place is the variable; the
second is a file called `local.properties` in the project, with one line, `sdk.dir=` and the path.
**Prefer the variable.** `local.properties` names a path on your computer, so it must never go into
version control, and Android Studio writes one for you, which is why every Android `.gitignore`
lists it.

## A download that stopped halfway

A connection that drops can leave a zip with the right name and the wrong size. Nothing about the
name tells you, and `unzip` finds out late, after it has written part of the tools to disk. The
check is the one section 03 made: **`sha256sum`, compared with the value Google publishes**, before
unpacking. A file of 173 MB that is shorter than it should be has a different checksum from the
first wrong byte, and a different size in `ls -lh`. Delete it and download again; `curl -fsSLO` writes
over the old file.

## What to do when none of these is your message

Read the message to the end, and look for the name of a program, a file or a variable in it: the
three messages above each named theirs. Then check the three things this setup depends on, in this
order, each with one command: `echo $ANDROID_HOME` should print `/home/` and your name and
`/Android/Sdk`; `android sdk list` should show the four packages of section 03; `java -version`
should say 21. If all three answer and a build still fails, the next lesson to read is this one's
section 06, which is about the build.
