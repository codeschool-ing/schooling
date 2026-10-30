---
title: Three ways to get Kotlin
version: 1
---

From section 04 of this lesson to the end of lesson 20, this course asks you to type programs,
compile them and read what comes back. You need three things on one machine: a **JDK**, because
Kotlin on a computer compiles to the same bytecode Java does and runs on the same virtual machine;
the **Kotlin compiler**, `kotlinc`; and **Gradle**, the build tool every Android project and most
Kotlin projects use, which this course needs from lesson 14 on. The platform gives you no machine
to type at, so the first job is to have one of your own.

**There are three places to put them, and the course recommends the first**: installed on an
Ubuntu 24.04 system, your own computer or a virtual machine running on it.

| path | what you get | what it costs your computer | the course's transcripts |
|---|---|---|---|
| **installed on Ubuntu 24.04** (recommended) | OpenJDK 21 from Ubuntu's archive, and Kotlin 2.4.21 and Gradle 9.8.2 unpacked in your home directory | about 140 MB from Ubuntu and 230 MB from the two projects, and about 600 MB of disk once unpacked | run as printed, byte for byte |
| **a virtual machine** | the same Ubuntu, inside a window on Windows or macOS | a whole operating system's disk, and memory held while it runs | run as printed, byte for byte, once Ubuntu is in it |
| **online** | a development environment in a browser tab | nothing on your computer, but an account and a monthly allowance with somebody | close, with a different JDK and different paths |

## What this course can and cannot show you

**Every program in this course runs on a computer, and none of it needs a phone.** Kotlin is a
language first, and everything from `val` to `StateFlow` runs on the JVM exactly as it will inside
an Android app. So every transcript in these twenty lessons was produced on the machine described
below, and you can reproduce all of them.

What this course does not do is build an Android app. That needs the Android SDK, Android Studio
and an emulator, and it is the next course on this path, `android-apps`, that installs them. The
machine you build here is the one that course starts from.

One more thing is described and not run: lesson 20's native build, which compiles Kotlin to a Linux
executable with no JVM. Its compiler arrives from Maven Central like everything else, but the C
toolchain it links with is downloaded from `download.jetbrains.com`, and the machine these lessons were
recorded on could not reach that address. Lesson 20 shows the build file and says where its transcript
would have been.

## Installed: the recommended path

The versions are pinned, and the course was recorded with exactly these: **OpenJDK 21** from the
package `openjdk-21-jdk-headless` in Ubuntu 24.04's own archive, **Kotlin 2.4.21** from the Kotlin
project's releases on GitHub, and **Gradle 9.8.2** from `services.gradle.org`. Ubuntu packages the
JDK; it does not package a current Kotlin or Gradle, so those two arrive as zip files you unpack
yourself. Ana, the student whose prompt you will see in every transcript, started on a fresh
Ubuntu 24.04 that had never seen Java:

```
ana@vm:~$ java -version; echo $?
bash: line 1: java: command not found
127
ana@vm:~$ sudo apt install -y openjdk-21-jdk-headless unzip curl 2>&1 | grep -E "^(Need to get|After this operation|Setting up (openjdk-21|unzip|curl))"
Need to get 137 MB of archives.
After this operation, 321 MB of additional disk space will be used.
Setting up unzip (6.0-28ubuntu4.1) ...
Setting up curl (8.5.0-2ubuntu10.16) ...
Setting up openjdk-21-jre-headless:amd64 (21.0.12.1+1-1~24.04.4) ...
Setting up openjdk-21-jdk-headless:amd64 (21.0.12.1+1-1~24.04.4) ...
```

`apt` prints a few hundred lines while it works. The `grep` keeps the two that say what it costs
and the lines that say what arrived, so you can compare your screen with this one. **On your own
machine, type the command without the pipe**: `sudo apt install openjdk-21-jdk-headless unzip
curl`. Without `-y`, `apt` stops to ask before it downloads anything, and that question is where
the size is first shown to you.

`-headless` means the JDK without the libraries for windows and graphics. Nothing in this course
draws a window, and Android draws its own.

Then the two downloads. Make a directory for them, fetch each zip, and check it before unpacking:

```
ana@vm:~$ mkdir -p ~/downloads ~/.local/share && cd ~/downloads
ana@vm:~/downloads$ curl -fsSLO https://github.com/JetBrains/kotlin/releases/download/v2.4.21/kotlin-compiler-2.4.21.zip
ana@vm:~/downloads$ curl -fsSLO https://github.com/JetBrains/kotlin/releases/download/v2.4.21/kotlin-compiler-2.4.21.zip.sha256
ana@vm:~/downloads$ echo "$(cat kotlin-compiler-2.4.21.zip.sha256)  kotlin-compiler-2.4.21.zip" | sha256sum -c
kotlin-compiler-2.4.21.zip: OK
ana@vm:~/downloads$ curl -fsSLO https://services.gradle.org/distributions/gradle-9.8.2-bin.zip
ana@vm:~/downloads$ sha256sum gradle-9.8.2-bin.zip
21bd5da2de49b642904077f38c0efdc7778e92b3ed0889392dca61b97e389607  gradle-9.8.2-bin.zip
ana@vm:~/downloads$ ls -lh
total 231M
-rw-r--r-- 1 ana ana 145M Oct 30 03:00 gradle-9.8.2-bin.zip
-rw-r--r-- 1 ana ana  86M Oct 30 03:00 kotlin-compiler-2.4.21.zip
-rw-r--r-- 1 ana ana   64 Oct 30 03:00 kotlin-compiler-2.4.21.zip.sha256
```

The Kotlin project publishes a SHA-256 checksum beside every zip. `sha256sum -c` recomputes the
checksum of the file on disk and compares it with the published one, and **`OK` is the only answer
that lets you carry on**. For Gradle, `sha256sum` prints the checksum of what you downloaded, and
you compare it by eye with the value Gradle publishes for 9.8.2 on its page of release checksums,
`gradle.org/release-checksums`. That comparison was not run when this course was recorded, because
the recording machine could not reach the address Gradle serves its checksum files from; the value
above is the one the recording machine computed. Section 03 shows what a damaged download looks
like.

Unpack both into `~/.local/share`, and put their `bin` directories on your `PATH` so the shell can
find `kotlinc` and `gradle` without a full path:

```
ana@vm:~/downloads$ unzip -q kotlin-compiler-2.4.21.zip -d ~/.local/share
ana@vm:~/downloads$ unzip -q gradle-9.8.2-bin.zip -d ~/.local/share
ana@vm:~/downloads$ echo 'export PATH="$HOME/.local/share/kotlinc/bin:$HOME/.local/share/gradle-9.8.2/bin:$PATH"' >> ~/.bashrc
ana@vm:~/downloads$ source ~/.bashrc
ana@vm:~/downloads$ ls ~/.local/share
gradle-9.8.2
kotlinc
ana@vm:~/downloads$ du -sh ~/.local/share/kotlinc ~/.local/share/gradle-9.8.2 /usr/lib/jvm/java-21-openjdk-amd64
94M	/home/ana/.local/share/kotlinc
165M	/home/ana/.local/share/gradle-9.8.2
286M	/usr/lib/jvm/java-21-openjdk-amd64
```

The `echo` appends one line to `~/.bashrc`, which every new terminal reads. `source` reads it into
the terminal you already have. **Type the line exactly, with single quotes outside and double
quotes inside**: the single quotes keep `$HOME` and `$PATH` as text until a terminal reads the file.

## Check that each tool answers

```
ana@vm:~$ java -version
openjdk version "21.0.12.1" 2026-08-18
OpenJDK Runtime Environment (build 21.0.12.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 21.0.12.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@vm:~$ javac -version
javac 21.0.12.1
ana@vm:~$ kotlinc -version
info: kotlinc-jvm 2.4.21 (JRE 21.0.12.1+1-1-24.04.4-Ubuntu)
ana@vm:~$ gradle --version

Welcome to Gradle 9.8.2!

Here are the highlights of this release:
 - Java 27 support
 - Maven mirror settings reuse
 - Linked problem locations in build output

For more details see https://docs.gradle.org/9.8.2/release-notes.html


------------------------------------------------------------
Gradle 9.8.2
------------------------------------------------------------

Build time:    2026-10-19 16:29:26 UTC
Revision:      8de7bcf76e785507ad92f0741ab9235a430c95e6

Kotlin:        2.4.10
Groovy:        4.0.33
Ant:           Apache Ant(TM) version 1.10.17 compiled on April 6 2026
Launcher JVM:  21.0.12.1 (Ubuntu 21.0.12.1+1-1-24.04.4-Ubuntu)
Daemon JVM:    /usr/lib/jvm/java-21-openjdk-amd64 (no Daemon JVM specified, using current Java home)
OS:            Linux 6.18.44-fc-v185 amd64
```

**If all four answer, the lab is built.** `java` runs programs and `javac` compiles Java;
`kotlinc` compiles Kotlin and says which JVM it found, 21, the one just installed; `gradle`
greets you on its first run and then lists itself and the JVM it runs on. The `OS` line names the
kernel of the machine the course was recorded on, and yours will differ; nothing in the course
depends on it.

One line looks like a contradiction: `Kotlin: 2.4.10`, beside a compiler that just said 2.4.21.
Gradle carries a Kotlin of its own, to read its build scripts, which are written in Kotlin. The
Kotlin your programs are compiled with in lesson 14 onwards is chosen by each project, and lesson
19 is about exactly that difference. The zips in `~/downloads`, 231 MB of them, can be deleted
once both tools answer.

## A virtual machine

If your computer runs Windows or macOS, run Ubuntu 24.04 inside it and follow the installed path
there. Every transcript then matches what you see, prompt and all.

- **On Windows**, WSL is the Linux that Windows itself can run. In a PowerShell window opened as
  administrator, `wsl --install -d Ubuntu-24.04` installs it, and the Ubuntu terminal it opens is
  where you type everything above.
- **On Windows, macOS or Linux**, Multipass starts Ubuntu virtual machines from one command. After
  installing it from its website, `multipass launch 24.04 --name kotlin --memory 4G --disk 15G`
  creates one and `multipass shell kotlin` opens a terminal in it.

Neither command was run for this course, because the recording machine was itself a container and
cannot start another. The numbers in the second are a recommendation rather than a measurement:
Gradle and the Kotlin compiler are two JVMs that can run at once, and four gigabytes keeps them
from swapping. A virtual machine holds its memory while it runs, so stop it with
`multipass stop kotlin` when you finish.

## Online

A cloud development environment opens a Linux machine in a browser tab, with an editor and a
terminal. Several companies offer one and they change their terms often, so this course depends
on none of them. **It costs your computer nothing and costs you an account**, a monthly allowance
of hours, and a network connection for every minute you study. Its JDK is a different build in a
different directory, so the paths in this lesson will differ; the Kotlin and Gradle steps above
work there as written.

So: **install it on Ubuntu if you can, use a virtual machine when your computer is not Ubuntu, and
keep the browser for a computer that is not yours.**

## Why not an IDE

IntelliJ IDEA and Android Studio compile Kotlin with the same compiler and build with the same
Gradle. They are worth installing, and `android-apps` installs Android Studio on its first day.
This course types the commands instead, for one reason: when a build fails inside an IDE, the
message you need is the one these commands print, and it is easier to read once you have seen it
on its own.
