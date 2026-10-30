---
title: A binary that needs no toolchain
version: 1
---

Lesson 1 compiled `hello` to a 17 KB file and warned that it would not start on a machine without
the toolchain. Every executable built so far has the same property: **it is dynamically linked
against the Swift runtime**, `libswiftCore.so` and its neighbours, and finds them in the toolchain's
directory each time it starts. That is fine on the machine that built it, and it is the wrong shape
for a server, a container image or a tool you hand to somebody else.

The answer on Linux is the **static Linux SDK**. A Swift SDK is a bundle of libraries and settings
for building for a target other than the machine you are on, and this one targets Linux itself,
with everything linked into the executable: the Swift runtime, Foundation, and **musl**, a small C
library written to be linked statically, in place of Ubuntu's `glibc`. swift.org publishes one per
release, next to the toolchain, with a checksum.

## Installing the SDK

The program is a command-line version of the week's total, in a package of its own called `week`:

```swift
// swift-tools-version: 6.2
// Package.swift
import PackageDescription

let package = Package(
    name: "week",
    targets: [
        .executableTarget(name: "week"),
    ]
)
```

```swift
// Sources/week/main.swift
let goal = 300
let minutes = CommandLine.arguments.dropFirst().compactMap { Int($0) }
let total = minutes.reduce(0, +)
print("\(total) of \(goal) minutes in \(minutes.count) sessions")
```

`CommandLine.arguments` is the list of words the program was started with, its own path first, so
`dropFirst()` skips that and `compactMap` keeps the words that are numbers, as lesson 2 did with
`Int?`. The program imports nothing, not even Foundation.

`swift sdk install` takes the URL and the checksum that swift.org lists for this release, downloads
the bundle, refuses it if the checksum differs, and unpacks it under `~/.swiftpm`. While it downloads
it prints a line for every few per cent, and the `grep -v` drops those:

```
ana@vm:~/sw/l20/week$ swift sdk install https://download.swift.org/swift-6.4.2-release/static-sdk/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE_static-linux-0.1.0.artifactbundle.tar.gz --checksum 3786b179936d9cc9e266dd506bd1654176358d7b25288e243359f4d17cc4dc5a | grep -v '%: Downloading'
Downloading a Swift SDK bundle archive from `https://download.swift.org/swift-6.4.2-release/static-sdk/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE_static-linux-0.1.0.artifactbundle.tar.gz`...
Downloading
Swift SDK bundle archive successfully downloaded from `https://download.swift.org/swift-6.4.2-release/static-sdk/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE_static-linux-0.1.0.artifactbundle.tar.gz`.
Verifying if checksum of the downloaded archive is valid...
Downloaded archive has a valid checksum.
Swift SDK bundle at `https://download.swift.org/swift-6.4.2-release/static-sdk/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE_static-linux-0.1.0.artifactbundle.tar.gz` is assumed to be an archive, unpacking...
Swift SDK bundle at `https://download.swift.org/swift-6.4.2-release/static-sdk/swift-6.4.2-RELEASE/swift-6.4.2-RELEASE_static-linux-0.1.0.artifactbundle.tar.gz` successfully installed as swift-6.4.2-RELEASE_static-linux-0.1.0.artifactbundle.
ana@vm:~/sw/l20/week$ swift sdk list
swift-6.4.2-RELEASE_static-linux-0.1.0
```

The bundle is about 285 MB. **The checksum is the same check as lesson 1's signature**, in a
different form: a SHA-256 of the file, which swift.org publishes on its install page and in the
release list section 02 read. A static SDK has to match the toolchain exactly, 6.4.2 with 6.4.2,
which is why the version is in its name.

## The same program, linked two ways

```
ana@vm:~/sw/l20/week$ swift build -c release 2>&1 | tail -1
Build complete! (2.38 secs)
ana@vm:~/sw/l20/week$ swift build -c release --swift-sdk x86_64-swift-linux-musl 2>&1 | tail -1
Build complete! (2.28 secs)
ana@vm:~/sw/l20/week$ ls -l .build/out/Products/*/week
-rwxr-xr-x 1 ana ana    41744 Oct 30 15:37 .build/out/Products/Release-linux-x86_64/week
-rwxr-xr-x 1 ana ana 39072128 Oct 30 15:37 .build/out/Products/Release-staticlinux-x86_64/week
```

**41,744 bytes against 39,072,128.** The second build named the SDK by its target triple,
`x86_64-swift-linux-musl`, and everything else was the same command. The products land in two
directories, one per platform, and the static one is nearly a thousand times larger, because it
carries everything the small one borrows:

```
ana@vm:~/sw/l20/week$ file -b .build/out/Products/Release-linux-x86_64/week | cut -d, -f1-4
ELF 64-bit LSB pie executable, x86-64, version 1 (SYSV), dynamically linked
ana@vm:~/sw/l20/week$ file -b .build/out/Products/Release-staticlinux-x86_64/week | cut -d, -f1-4
ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked
ana@vm:~/sw/l20/week$ ldd .build/out/Products/Release-staticlinux-x86_64/week
	not a dynamic executable
ana@vm:~/sw/l20/week$ strip -o week-static .build/out/Products/Release-staticlinux-x86_64/week && ls -l week-static
-rwxr-xr-x 1 ana ana 7019888 Oct 30 15:37 week-static
```

`file` says it in two words, **dynamically linked** against **statically linked**, and `ldd`, which
lists the shared libraries a program asks for, finds none to list. Most of the 39 MB is debugging
information, which `strip` removes; what is left, about 7 MB, is the program, the Swift runtime and
the C library it runs on.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l20-linking\" aria-label=\"Two builds of the same program. The dynamically linked one is 41,744 bytes and asks for the Swift runtime in the toolchain’s usr/lib directory every time it starts, so on a machine with no toolchain it does not start. The statically linked one is 39,072,128 bytes, about 7 MB once stripped, and carries your code, the Swift runtime and the musl C library inside it, so it runs on a machine with no toolchain.\"><defs><marker id=\"l20-linking-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l20-linking-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l20-linking-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"230\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">week, dynamically linked</text><text x=\"135\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">41,744 bytes</text><path d=\"M250 48 L318 48\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-linking-ah-wire)\"></path><rect x=\"320\" y=\"20\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"420\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the Swift runtime</text><text x=\"420\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">in the toolchain’s usr/lib</text><text x=\"135\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">asks for it at every start</text><text x=\"620\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">no toolchain: does not start</text><rect x=\"20\" y=\"124\" width=\"500\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">week, statically linked</text><text x=\"270\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">39,072,128 bytes, 7 MB stripped</text><rect x=\"40\" y=\"184\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">your code</text><rect x=\"200\" y=\"184\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Swift runtime</text><rect x=\"360\" y=\"184\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"430\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">musl C library</text><text x=\"620\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">no toolchain: runs</text></svg>", "caption": "A static binary carries what the dynamic one borrows, which is why it is a thousand times larger and runs where Swift is not installed."}
```

## On a machine with no Swift

The proof is a computer that has never seen Swift. The machine below is the Ubuntu 24.04 of lesson 1
before anything was installed: no toolchain, no `apt` line. Both binaries were copied into Ana's home
directory there, as `scp` would put them on a server:

```
ana@vm:~$ which swift; ls ~
week-dynamic
week-static
ana@vm:~$ ./week-dynamic 45 30 60
./week-dynamic: error while loading shared libraries: libswiftCore.so: cannot open shared object file: No such file or directory
ana@vm:~$ ./week-static 45 30 60
135 of 300 minutes in 3 sessions
```

`which swift` prints nothing, because there is no Swift. The dynamic binary fails before its first
line, with the same **dynamic loader** message lesson 1 section 03 met, naming `libswiftCore.so`.
The static one runs and prints the week. **Copy one file, and it runs.** That is the whole reason to
build this way: a container image built `FROM scratch` with one file in it, a tool a colleague can
download, a server with nothing installed.

The server of section 04 builds the same way, with the same flag:

```
ana@vm:~/sw/l20/server$ swift build -c release --swift-sdk x86_64-swift-linux-musl 2>&1 | tail -1
Build complete! (506.09 secs)
ana@vm:~/sw/l20/server$ ls -l .build/out/Products/Release-staticlinux-x86_64/PlannerServer
-rwxr-xr-x 1 ana ana 176852520 Oct 30 15:46 .build/out/Products/Release-staticlinux-x86_64/PlannerServer
```

Minutes of compiling again, because every one of its twenty-four packages is compiled anew for the
new target, and a binary of 177 MB before `strip`. Stripping it is the
step to add before putting it in an image.

## What the static SDK does not do

**It builds for Linux and nothing else.** The binary runs on any x86-64 Linux, whatever its
distribution, and on no Mac, no Windows and no phone. An `aarch64` server needs the
`aarch64-swift-linux-musl` target from the same bundle. And it changes nothing about the code: a
program that needs `FoundationNetworking` still imports it the way section 03 showed, and gets it
statically.
