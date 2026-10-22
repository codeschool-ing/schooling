---
title: Your machine, the same as in the java course
version: 1
---

**This course runs on the machine the `java` course built, and changes nothing about it.** Two
programs are all it needs: **OpenJDK 25**, which compiles and runs Java, and **Maven**, which
builds a project that uses somebody else's library. Both come from Ubuntu 24.04's own archive. The
`java` course installs them in lesson 1 section 02 and explains every step; this section gives
the same steps in brief, for anybody arriving from somewhere else, and then checks that each tool
answers. `java-back`, the course after this one, uses the same two at the same versions, so a
student who takes the three in order installs nothing twice.

## Three ways to have one

| path | what you get | what it costs your computer | the transcripts |
|---|---|---|---|
| **installed** (recommended) | the JDK and Maven on the Ubuntu you already use, or inside WSL on Windows | about 400 MB of disk | match as printed |
| a virtual machine | Ubuntu Server 24.04 in a window of its own | a few gigabytes of disk, and 2 GB of memory while it runs | match as printed |
| online | a Linux machine in a browser tab | nothing on your computer; hours from a monthly allowance | close, not exact |

**Install it on the computer you use.** On **Ubuntu 24.04**, or any Linux that carries the same
packages, the two commands below are the whole of it. On **Windows**, every command in this course
is typed in a Linux terminal: open PowerShell as administrator, run `wsl --install -d Ubuntu-24.04`,
restart, open Ubuntu from the Start menu and follow the Linux steps inside it. On a **Mac**,
Homebrew's `brew install openjdk@25 maven` gives the same versions; that path was not run for this
course, so a path in a transcript may differ from yours.

**A virtual machine** is the same steps inside a machine of its own: VirtualBox on Windows or Linux,
UTM on a Mac with an Apple chip, and Ubuntu Server 24.04 LTS as the guest. It is the machine this
course was recorded on, which is why the prompt in every transcript reads `ana@vm`.

**Online**, GitHub Codespaces and similar services give you a Linux machine with a terminal in a
browser tab. GitHub gives personal accounts a monthly allowance and charges past it, on terms it
sets and can change, so treat it as a fallback rather than a home. It was not run for this course.
`cat /etc/os-release` tells you which Linux you got before you start.

## The two packages

```sh
sudo apt update
sudo apt install openjdk-25-jdk maven
```

`openjdk-25-jdk` is the **JDK**, the kit for writing Java: the compiler `javac`, the launcher
`java`, and tools like `javap` that lesson 1 section 04 uses. The package called
`openjdk-25-jre` is only the runtime, and a machine with that alone runs Java and cannot compile it.
Ubuntu prints a few hundred lines while it installs, none of which this course needs. This asks
what it installed:

```
ana@vm:~$ apt-cache policy openjdk-25-jdk | head -n 5
openjdk-25-jdk:
  Installed: 25.0.4.1+1-1~24.04.4
  Candidate: 25.0.4.1+1-1~24.04.4
  Version table:
 *** 25.0.4.1+1-1~24.04.4 500
```

The line with `***` is the version on this machine. Ubuntu updates the package with security fixes,
so yours may end in a larger number; anything starting `25.` behaves the same throughout the course.

## Checking each tool answers

Open a new terminal and ask each of the three for its version:

```
ana@vm:~$ java -version
openjdk version "25.0.4.1" 2026-08-18
OpenJDK Runtime Environment (build 25.0.4.1+1-1-24.04.4-Ubuntu)
OpenJDK 64-Bit Server VM (build 25.0.4.1+1-1-24.04.4-Ubuntu, mixed mode, sharing)
ana@vm:~$ javac -version
javac 25.0.4.1
ana@vm:~$ mvn -B -v
Apache Maven 3.8.7
Maven home: /usr/share/maven
Java version: 25.0.4.1, vendor: Ubuntu, runtime: /usr/lib/jvm/java-25-openjdk-amd64
Default locale: en, platform encoding: UTF-8
OS name: "linux", version: "6.18.44-fc-v139", arch: "amd64", family: "unix"
```

- **`java -version`** prints three lines, and the first is the one to read: `25.0.4.1` is the
  feature release 25, the long-term-support release this course and the `java` course were
  written against;
- **`javac -version`** proves the compiler is there, which is what separates the JDK from the
  runtime alone;
- **`mvn -B -v`** is Maven. Read the third line before the first: **Maven runs on whichever Java
  it finds**, and `Java version: 25.0.4.1` says it found the right one. The `-B` asks for batch
  mode, which leaves out the colour codes Maven would otherwise print, and every Maven command in
  this course carries it.

## Where the work goes

Everything you write in this course goes under `~/fp`, one folder per subject. Make the first one,
`~/fp/lambdas`, and save this file in it as `Hello.java`:

```java
// Hello.java: the first program of the course, to prove the machine runs one
public class Hello {
    public static void main(String[] args) {
        System.out.println("Hello from Java " + Runtime.version().feature());
    }
}
```

```
ana@vm:~$ mkdir -p ~/fp/lambdas
ana@vm:~$ cd ~/fp/lambdas
ana@vm:~/fp/lambdas$ java Hello.java
Hello from Java 25
ana@vm:~/fp/lambdas$ ls
Hello.java
```

`java Hello.java` compiled the file in memory and ran it, without leaving a `.class` file behind.
That is the **source-file mode** the `java` course used for small programs, and it is how most
programs in this course run: one file, or a few in the same folder, each shown whole in the section
that uses it. From Java 22 on, a program run this way may use the other `.java` files beside it,
and lesson 6 leans on that. Lesson 21 is the one place a library from outside the JDK is needed,
and it builds a Maven project there.
