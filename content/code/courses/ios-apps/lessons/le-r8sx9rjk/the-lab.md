---
title: Two machines, and three ways to get each
version: 1
---

This course uses two environments, and you may have one or both. **The Swift toolchain** builds
and tests the planner's package; it is what every transcript in the course was recorded with, and
it runs on Linux and on macOS. **Xcode on a Mac** builds the SwiftUI app and runs it in the
simulator; nothing in the course was recorded with it. The platform gives you neither, so this
section is about having your own.

## The Swift toolchain: three paths

The toolchain is the one the `swift` course installs, and its lesson 1 does it in full. This is the
same install in brief, so that this course stands on its own:

| path | what you get | what it costs your computer | the course's transcripts |
|---|---|---|---|
| **installed on Ubuntu 24.04** (recommended without a Mac) | Swift 6.4.2 from swift.org, unpacked in your home directory | about 110 MB of packages from Ubuntu and a 1.1 GB download, 3.5 GB of disk once unpacked | run as printed, byte for byte |
| **a virtual machine** | the same Ubuntu inside a window on Windows or macOS | a whole operating system's disk, and memory held while it runs | run as printed, once Ubuntu is in it |
| **online** | a development environment in a browser tab, with a container you can install into | nothing on your computer, but an account and a monthly allowance with somebody | close, with different paths |

**On a Mac with Xcode you already have this toolchain**, in a version that matches the Xcode, and
`swift build` and `swift test` work in Terminal exactly as they do here. The transcripts will differ
in their paths and in the version line, and nothing else in the course depends on either.

Ana, whose prompt is in every transcript, started on a fresh Ubuntu 24.04 that had never seen Swift.
The packages are the ones swift.org lists for Ubuntu 24.04: the linker, the C library headers and
the libraries the compiler itself links against.

```
ana@vm:~$ swift --version; echo $?
bash: line 1: swift: command not found
127
ana@vm:~$ sudo apt install -y binutils git gnupg2 libc6-dev libcurl4-openssl-dev libedit2 libgcc-13-dev libncurses-dev libpython3-dev libsqlite3-0 libstdc++-13-dev libxml2-dev libz3-dev pkg-config tzdata unzip zlib1g-dev curl 2>&1 | grep -E '^(Need to get|After this operation)'
Need to get 110 MB of archives.
After this operation, 340 MB of additional disk space will be used.
```

`apt` prints a few hundred lines while it works, and the `grep` keeps the two that say what it costs.
**On your own machine, type the command without the pipe and without `-y`**, so that `apt` stops and
shows you those two lines before downloading anything.

Then the toolchain itself, and the signature that proves who made it:

```
ana@vm:~$ mkdir -p ~/downloads ~/.local/share && cd ~/downloads
ana@vm:~/downloads$ curl -fsSLO -C - --retry 5 --retry-all-errors https://download.swift.org/swift-6.4.2-release/ubuntu2404/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE-ubuntu24.04.tar.gz
ana@vm:~/downloads$ curl -fsSLO https://download.swift.org/swift-6.4.2-release/ubuntu2404/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE-ubuntu24.04.tar.gz.sig
ana@vm:~/downloads$ ls -lh
total 1.1G
-rw-r--r-- 1 ana ana 1.1G Oct 30 15:03 swift-6.4.2-RELEASE-ubuntu24.04.tar.gz
-rw-r--r-- 1 ana ana  819 Oct 30 15:03 swift-6.4.2-RELEASE-ubuntu24.04.tar.gz.sig
```

`-C -` and `--retry 5 --retry-all-errors` are there because the file is over a gigabyte. If the
connection drops halfway, `curl` tries again and carries on from the byte where it stopped rather
than from the start. The `.sig` file is a signature made with the Swift project's release key.

```
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
ana@vm:~/downloads$ gpg --verify swift-6.4.2-RELEASE-ubuntu24.04.tar.gz.sig
gpg: assuming signed data in 'swift-6.4.2-RELEASE-ubuntu24.04.tar.gz'
gpg: Signature made Wed Oct 28 11:36:39 2026 -03
gpg:                using RSA key EF80A866B47A981F
gpg: Good signature from "Swift 6.x Release Signing Key <swift-infrastructure@forums.swift.org>" [unknown]
gpg: WARNING: This key is not certified with a trusted signature!
gpg:          There is no indication that the signature belongs to the owner.
Primary key fingerprint: 52BB 7E3D E28A 71BE 22EC  05FF EF80 A866 B47A 981F
```

**`Good signature` is the only answer that lets you carry on.** The first command imports the
Swift project's public keys from swift.org; the second checks the archive against the signature
with them. The `WARNING` underneath says that you have not personally certified that key belongs
to the Swift project, which is true and normal: you trusted it because you fetched it from
`swift.org` over HTTPS. Section 04 shows what a damaged archive gets instead.

Unpack it into `~/.local/share` and put its `usr/bin` on your `PATH`, so that the shell finds
`swift` without a full path:

```
ana@vm:~/downloads$ tar xzf swift-6.4.2-RELEASE-ubuntu24.04.tar.gz -C ~/.local/share
ana@vm:~/downloads$ echo 'export PATH="$HOME/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin:$PATH"' >> ~/.bashrc
ana@vm:~/downloads$ source ~/.bashrc
ana@vm:~/downloads$ du -sh ~/.local/share/swift-6.4.2-RELEASE-ubuntu24.04
3.5G	/home/ana/.local/share/swift-6.4.2-RELEASE-ubuntu24.04
```

The `echo` appends one line to `~/.bashrc`, which every new terminal reads, and `source` reads it
into the terminal you already have. **Type the line exactly, single quotes outside and double quotes
inside**: the single quotes keep `$HOME` and `$PATH` as text until a terminal reads the file. Then
ask the toolchain who it is:

```
ana@vm:~$ swift --version
Swift version 6.4.2 (swift-6.4.2-RELEASE)
Target: x86_64-unknown-linux-gnu
ana@vm:~$ which swift
/home/ana/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin/swift
```

`Swift version 6.4.2` is the answer every transcript in this course was recorded with. The
`Target` line says what it compiles for by default, this machine's processor and system. On an ARM
computer it says `aarch64`, and on a Mac it names `apple-macosx`.

## Xcode: three paths, none free

| path | what you need | what it costs |
|---|---|---|
| **a Mac, installed** (recommended) | a Mac recent enough for the current macOS, and Xcode from the Mac App Store | the Mac; Xcode itself is free, and needs tens of gigabytes of disk with one simulator |
| **a virtual machine** | macOS inside a virtual machine, on a Mac | Apple's licence allows macOS in a virtual machine only on Apple hardware, so this is a second Mac inside the first, for keeping a clean or older setup |
| **online** | a Mac rented in a data centre and reached by remote desktop | an hourly or monthly fee to whichever company you rent from |

None of this was run for the course. What each costs comes from Apple's pages for Xcode and for
the macOS licence, read on 30 October 2026, and the Mac App Store page gives the current size. **If
you have a Mac, install Xcode before lesson 2**: it is a large download, and the first launch
installs more components and asks which simulators you want.

Paying is not part of this lesson. Xcode builds and runs an app in the simulator, and on your own
iPhone for a few days at a time, with a free Apple Account. Lesson 21 says what the paid membership
adds and what it costs, before anything in the course asks for it.
