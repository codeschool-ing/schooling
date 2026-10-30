---
title: Three ways to get Swift
version: 1
---

From section 04 of this lesson to the end of lesson 20, this course asks you to type programs,
compile them and read what comes back. You need one thing for that: **the Swift toolchain**, which
is the compiler, the standard library, the package manager and the test runners, shipped together
as one archive. The platform gives you no machine to type at, so the first job is to have one of
your own.

**There are three places to put it, and the course recommends the first**: installed on an Ubuntu
24.04 system, your own computer or a virtual machine running on it.

| path | what you get | what it costs your computer | the course's transcripts |
|---|---|---|---|
| **installed on Ubuntu 24.04** (recommended) | the Swift 6.4.2 toolchain from swift.org, unpacked in your home directory, and the libraries it needs from Ubuntu's archive | about 110 MB from Ubuntu and 1.1 GB from swift.org, and about 3.5 GB of disk once unpacked | run as printed, byte for byte |
| **a virtual machine** | the same Ubuntu, inside a window on Windows or macOS | a whole operating system's disk, and memory held while it runs | run as printed, byte for byte, once Ubuntu is in it |
| **online** | a development environment in a browser tab | nothing on your computer, but an account and a monthly allowance with somebody | close, with different paths and perhaps a different Swift |

## What this course can and cannot show you

**Every program in these twenty lessons runs on Linux, and you can reproduce every transcript.**
Swift is Apple's language, and it is also an open-source project that publishes the same compiler
for Linux and Windows. Optionals, structs, protocols, generics, `Codable`, `async`/`await`, actors,
both test frameworks and the package manager all work on Linux exactly as they do on a Mac.

What does not exist on Linux is **Apple's platform**: Xcode, the iOS simulator, SwiftUI and UIKit.
Three lessons meet that wall, and each says so where it does. Lesson 11's search for a memory leak
describes the memory graph that Xcode draws, and does the search with the compiler's own tools
instead. Lesson 16 shows how SwiftUI uses property wrappers and result builders by building small
versions of both, since SwiftUI itself is not there to import. Lesson 20 describes what changes on a
Mac without running it. Nothing in those three is a transcript of something that was not run.

The course after this one on the path, `ios-apps`, builds the study planner as an iPhone app, and
that course needs a Mac with Xcode from its first lesson. **The wall falls between the two
courses**, and this one is entirely on the side you can practise on any computer.

## Installed: the recommended path

The version is pinned, and the course was recorded with exactly this one: **Swift 6.4.2**, the
release swift.org published on 29 October 2026, which is also the Swift inside Xcode 27.2. Ubuntu
does not package Swift, so it arrives as an archive from `download.swift.org`. What Ubuntu does
provide is the set of system libraries the toolchain links against, and swift.org's install page
lists them per distribution. Ana, the student whose prompt you will see in every transcript, started
on a fresh Ubuntu 24.04 that had never seen Swift:

```
ana@vm:~$ swift --version; echo $?
bash: line 1: swift: command not found
127
ana@vm:~$ sudo apt install -y binutils git gnupg2 libc6-dev libcurl4-openssl-dev libedit2 libgcc-13-dev libncurses-dev libpython3-dev libsqlite3-0 libstdc++-13-dev libxml2-dev libz3-dev pkg-config tzdata unzip zlib1g-dev curl 2>&1 | grep -E '^(Need to get|After this operation|Setting up (git|gnupg2|curl|binutils|libz3-dev)[: ])'
Need to get 111 MB of archives.
After this operation, 345 MB of additional disk space will be used.
Setting up libz3-dev:amd64 (4.8.12-3.1build1) ...
Setting up curl (8.5.0-2ubuntu10.16) ...
Setting up gnupg2 (2.4.4-2ubuntu17.6) ...
Setting up binutils (2.42-4ubuntu2.10) ...
Setting up git (1:2.43.0-1ubuntu7.4) ...
```

`apt` prints a few hundred lines while it works. The `grep` keeps the two that say what it costs and
five of the lines that say what arrived, so you can compare your screen with this one. **On your
own machine, type the command without the pipe and without `-y`**, so that `apt` stops and asks
before it downloads anything. The list is long because the compiler is built on LLVM and links
programs with the system's own tools. `binutils` is the linker; `libc6-dev` and the two `-13-dev`
packages are the C and C++ libraries every Swift program on Linux ends up calling; and `git` is what
the package manager fetches dependencies with in lesson 19.

Then the toolchain itself. Make a directory for the download, fetch the archive and the signature
published beside it, and check one against the other before unpacking anything:

```
ana@vm:~$ mkdir -p ~/downloads ~/.local/share && cd ~/downloads
ana@vm:~/downloads$ curl -fsSLO https://download.swift.org/swift-6.4.2-release/ubuntu2404/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE-ubuntu24.04.tar.gz
ana@vm:~/downloads$ curl -fsSLO https://download.swift.org/swift-6.4.2-release/ubuntu2404/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE-ubuntu24.04.tar.gz.sig
ana@vm:~/downloads$ curl -fsSL https://www.swift.org/keys/all-keys.asc | gpg --import -
gpg: directory '/home/ana/.gnupg' created
gpg: keybox '/home/ana/.gnupg/pubring.kbx' created
gpg: /home/ana/.gnupg/trustdb.gpg: trustdb created
gpg: key D441C977412B37AD: public key "Swift Automatic Signing Key #1 <swift-infrastructure@swift.org>" imported
gpg: key 9F597F4D21A56D5F: public key "Swift 2.2 Release Signing Key <swift-infrastructure@swift.org>" imported
gpg: key 63BC1CFE91D306C6: public key "Swift 3.x Release Signing Key <swift-infrastructure@swift.org>" imported
gpg: key EF5430F071E1B235: public key "Swift 4.x Release Signing Key <swift-infrastructure@swift.org>" imported
gpg: key 7638F1FB2B2B08C4: public key "Swift Automatic Signing Key #2 <swift-infrastructure@swift.org>" imported
gpg: key 925CC1CCED3D1561: public key "Swift 5.x Release Signing Key <swift-infrastructure@swift.org>" imported
gpg: key FAF6989E1BC16FEA: public key "Swift Automatic Signing Key #3 <swift-infrastructure@swift.org>" imported
gpg: key 925CC1CCED3D1561: "Swift 5.x Release Signing Key <swift-infrastructure@swift.org>" 1 new signature
gpg: key F167DF1ACF9CE069: public key "Swift Automatic Signing Key #4 <swift-infrastructure@forums.swift.org>" imported
gpg: key 925CC1CCED3D1561: "Swift 5.x Release Signing Key <swift-infrastructure@swift.org>" 1 new signature
gpg: key F167DF1ACF9CE069: "Swift Automatic Signing Key #4 <swift-infrastructure@forums.swift.org>" 1 new signature
gpg: key EF80A866B47A981F: public key "Swift 6.x Release Signing Key <swift-infrastructure@forums.swift.org>" imported
gpg: key F167DF1ACF9CE069: "Swift Automatic Signing Key #4 <swift-infrastructure@forums.swift.org>" 1 new signature
gpg: key EF80A866B47A981F: "Swift 6.x Release Signing Key <swift-infrastructure@forums.swift.org>" 1 new signature
gpg: Total number processed: 14
gpg:               imported: 9
gpg:         new signatures: 5
ana@vm:~/downloads$ gpg --verify swift-6.4.2-RELEASE-ubuntu24.04.tar.gz.sig swift-6.4.2-RELEASE-ubuntu24.04.tar.gz
gpg: Signature made Wed Oct 28 11:36:39 2026 -03
gpg:                using RSA key EF80A866B47A981F
gpg: Good signature from "Swift 6.x Release Signing Key <swift-infrastructure@forums.swift.org>" [unknown]
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: 52BB 7E3D E28A 71BE 22EC  05FF EF80 A866 B47A 981F
ana@vm:~/downloads$ ls -lh
total 1.1G
-rw-r--r-- 1 ana ana 1.1G Oct 30 14:42 swift-6.4.2-RELEASE-ubuntu24.04.tar.gz
-rw-r--r-- 1 ana ana  819 Oct 30 14:42 swift-6.4.2-RELEASE-ubuntu24.04.tar.gz.sig
```

swift.org **signs** each archive rather than publishing a checksum. `gpg --import` reads the
project's public keys from `swift.org/keys/all-keys.asc`; `gpg --verify` then checks that the
archive is exactly the one the holder of the matching private key signed. **`Good signature` is the
only answer that lets you carry on.** The warning below it says that you have not personally
certified the key, which is true and expected: you trusted it because it came from swift.org over
HTTPS. What you can check is the name on the signature, `Swift 6.x Release Signing Key`, which is
the key for this release family and was one of the nine just imported. Section 03 shows what a
damaged download looks like.

Unpack it into `~/.local/share`, and put its `usr/bin` directory on your `PATH` so the shell finds
`swift` without a full path:

```
ana@vm:~/downloads$ tar -xzf swift-6.4.2-RELEASE-ubuntu24.04.tar.gz -C ~/.local/share
ana@vm:~/downloads$ echo 'export PATH="$HOME/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin:$PATH"' >> ~/.bashrc
ana@vm:~/downloads$ source ~/.bashrc
ana@vm:~/downloads$ ls ~/.local/share
swift-6.4.2-RELEASE-ubuntu24.04
ana@vm:~/downloads$ du -sh ~/.local/share/swift-6.4.2-RELEASE-ubuntu24.04
3.5G	/home/ana/.local/share/swift-6.4.2-RELEASE-ubuntu24.04
```

The `echo` appends one line to `~/.bashrc`, which every new terminal reads. `source` reads it into
the terminal you already have. **Type the line exactly, with single quotes outside and double quotes
inside**: the single quotes keep `$HOME` and `$PATH` as text until a terminal reads the file. The
archive in `~/downloads`, 1.1 GB of it, can be deleted once the next check passes.

## Check that it answers

```
ana@vm:~$ swift --version
Swift version 6.4.2 (swift-6.4.2-RELEASE)
Target: x86_64-unknown-linux-gnu
ana@vm:~$ which swift swiftc
/home/ana/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin/swift
/home/ana/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin/swiftc
```

**If `swift --version` answers, the lab is built.** The first line names the release, and the second
the **target**: the processor and operating system the compiler produces programs for. `which`
shows that `swift` and `swiftc` come from the directory you just unpacked, and not from anywhere
else on the machine.

swift.org's own install page offers a tool called `swiftly`, which downloads a toolchain and keeps
several side by side. It is a good way to install Swift and lesson 19 comes back to it. The course
pins the archive instead because the version and the signature check are then lines you can read,
and the result is the same toolchain in a different directory.

## A virtual machine

If your computer runs Windows or macOS, run Ubuntu 24.04 inside it and follow the installed path
there. Every transcript then matches what you see, prompt and all.

- **On Windows**, WSL is the Linux that Windows itself can run. In a PowerShell window opened as
  administrator, `wsl --install -d Ubuntu-24.04` installs it, and the Ubuntu terminal it opens is
  where you type everything above.
- **On Windows, macOS or Linux**, Multipass starts Ubuntu virtual machines from one command. After
  installing it from its website, `multipass launch 24.04 --name swift --memory 4G --disk 20G`
  creates one and `multipass shell swift` opens a terminal in it.

Neither command was run for this course, because the recording machine was itself a container and
cannot start another. The numbers in the second are a recommendation rather than a measurement: the
toolchain unpacks to about 3.5 GB, a package build in lesson 19 adds a few hundred megabytes of
caches, and four gigabytes of memory keeps the compiler from swapping. A virtual machine holds its
memory while it runs, so stop it with `multipass stop swift` when you finish.

**On a Mac you can also skip the virtual machine.** Installing Xcode, or the Command Line Tools on
their own, gives you a Swift compiler, and swift.org publishes a macOS package of the same release.
Every program in this course then runs on the Mac itself. What differs is everything around the
programs: paths, the `file` output in section 04, and a few lines of the package manager's output.
Lesson 20 is about what else differs, and none of it touches lessons 1 to 19.

## Online

A cloud development environment opens a Linux machine in a browser tab, with an editor and a
terminal. Several companies offer one and they change their terms often, so this course depends on
none of them. **It costs your computer nothing and costs you an account**, a monthly allowance of
hours, and a network connection for every minute you study. Some come with a Swift already
installed, at whatever version the company chose; type `swift --version` before anything else, and
if it is not 6.4.2, install this one as above.

So: **install it on Ubuntu if you can, use a virtual machine when your computer is not Ubuntu, and
keep the browser for a computer that is not yours.**

## Why not Xcode

On a Mac, most Swift is written in Xcode, and `ios-apps` installs it on its first day. This course
types commands instead, for two reasons. The commands work on every computer, so the course works
for every student. And when a build fails inside an IDE, the message you need is the one these
commands print, which is easier to read once you have seen it on its own.
