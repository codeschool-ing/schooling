---
title: Three ways to get a JDK
version: 1
---

From section 05 of this lesson to the last section of lesson 40, this course asks you to type
commands and read what comes back. You need a **JDK**, a Java Development Kit: the compiler that
turns your source into something runnable, the `java` program that runs it, and some thirty tools
around the two. From lesson 18 on you also need **Maven**, the build tool most Java projects use.
The platform gives you no machine to type at, so the first job is to have one of your own.

**There are three places to put a JDK, and the course recommends the first**: installed on an
Ubuntu 24.04 system, your own computer or a virtual machine running on it.

| path | what you get | what it costs your computer | the course's transcripts |
|---|---|---|---|
| **installed on Ubuntu 24.04** (recommended) | OpenJDK 25 and Maven from Ubuntu's own archive, with `apt` | about 290 MB to download and just under 1 GB of disk | run as printed, byte for byte |
| **a virtual machine** | the same Ubuntu, inside a window on Windows or macOS | a whole operating system's disk, and memory held while it runs | run as printed, byte for byte, once Ubuntu is in it |
| **online** | a development environment in a browser tab | nothing on your computer, but an account and a monthly allowance with somebody | close, with a different JDK build and different paths |

## Installed: the recommended path

The JDK this course was recorded with is **OpenJDK 25**, from the package `openjdk-25-jdk` in
Ubuntu 24.04's own archive, and Maven is the package `maven` from the same place. One line installs
both. Ana, the student whose prompt you will see in every transcript, typed it on a fresh Ubuntu
24.04 that had never seen Java:

```
ana@vm:~$ java -version; echo $?
bash: line 1: java: command not found
127
ana@vm:~$ sudo apt install -y openjdk-25-jdk maven 2>&1 | grep -E "^(Need to get|After this operation|Setting up openjdk-25|Setting up maven)"
Need to get 290 MB of archives.
After this operation, 964 MB of additional disk space will be used.
Setting up openjdk-25-jre-headless:amd64 (25.0.4.1+1-1~24.04.4) ...
Setting up maven (3.8.7-2) ...
Setting up openjdk-25-jre:amd64 (25.0.4.1+1-1~24.04.4) ...
Setting up openjdk-25-jdk-headless:amd64 (25.0.4.1+1-1~24.04.4) ...
Setting up openjdk-25-jdk:amd64 (25.0.4.1+1-1~24.04.4) ...
```

`apt` prints a few hundred lines while it works. The `grep` keeps the two that say what it costs
and the five that say what arrived, so you can compare your screen with this one. **On your own
machine, type the command without the pipe**: `sudo apt install openjdk-25-jdk maven`. Without
`-y`, `apt` stops to ask before it downloads anything, and that question is where the 290 MB is
first shown to you.

Then ask each tool what it is:

```
ana@vm:~$ java -version
openjdk version "25.0.4.1" 2026-08-18
OpenJDK Runtime Environment (build 25.0.4.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 25.0.4.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@vm:~$ javac -version
javac 25.0.4.1
ana@vm:~$ mvn -v
Apache Maven 3.8.7
Maven home: /usr/share/maven
Java version: 25.0.4.1, vendor: Ubuntu, runtime: /usr/lib/jvm/java-25-openjdk-amd64
Default locale: en, platform encoding: UTF-8
OS name: "linux", version: "6.18.44-fc-v139", arch: "amd64", family: "unix"
```

**If all three answer, the lab is built.** `java` runs programs, `javac` compiles them, and `mvn`
is Maven, which says which Java it found: 25, the one just installed. Section 04 shows why that last
line is worth reading every time. The kernel version on the `OS name` line belongs to the machine
the course was recorded on, and yours will differ; nothing in the course depends on it.

Two things decide the versions, and neither is your choice once you pick the path. The archive
carries the JDK release Ubuntu has packaged, here 25.0.4.1, and the security updates it receives
from `apt upgrade` move it forward inside version 25. Maven is 3.8.7, which is older than the 3.9
series the Maven project releases today. Lesson 18 pins the version of every Maven plugin a
project uses, and that pin is what makes the old Maven build exactly what a new one would.

## A virtual machine

If your computer runs Windows or macOS, run Ubuntu 24.04 inside it and follow the installed path
there. Every transcript then matches what you see, prompt and all.

- **On Windows**, WSL is the Linux that Windows itself can run. In a PowerShell window opened as
  administrator, `wsl --install -d Ubuntu-24.04` installs it, and the Ubuntu terminal it opens is
  where you type the `apt` line above.
- **On Windows, macOS or Linux**, Multipass starts Ubuntu virtual machines from one command. After
  installing it from its website, `multipass launch 24.04 --name java --memory 2G --disk 10G`
  creates one and `multipass shell java` opens a terminal in it.

Neither command was run in this lab, which is itself a virtual Ubuntu and cannot start another.
The numbers in the second one are a recommendation rather than a measurement. Two gigabytes of
memory is room for the JVM and Maven at once, and ten of disk is Ubuntu plus the 964 MB above with
space to spare. A virtual machine holds its memory for as long as it runs, so an older laptop with
8 GB feels it; stop it with `multipass stop java` when you finish.

## Online

A cloud development environment opens a Linux machine in a browser tab, with an editor and a
terminal. Several companies offer one and they change their terms often, so this course does not
depend on any of them. **It costs your computer nothing and it costs you an account**, a monthly
allowance of hours, and a network connection for every minute you study.

Its JDK will not be Ubuntu's `openjdk-25-jdk`. It is usually a build from another vendor, in
another directory, and `java -version` prints a different second line. The language and every
program in this course are the same, because Java SE 25 is one specification and every JDK that
implements it runs the same programs. What changes is the paths in sections 03 and 04.

So: **install it on Ubuntu if you can, use a virtual machine when your computer is not Ubuntu, and
keep the browser for a computer that is not yours.**
