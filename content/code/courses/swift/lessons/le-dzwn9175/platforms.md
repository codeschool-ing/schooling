---
title: One language, many targets
version: 1
---

The common picture is that Swift is the iPhone's language and runs where Apple's devices run. **That
is where it began, and it is now one target among several.** The compiler is an open-source project,
and every release is published for Apple's systems and for others at the same time, from the same
source, with the same version number.

The machine this course was recorded on can say what was published for its own release. swift.org
keeps the list as a file, and three commands are enough to read it:

```
ana@vm:~/sw/l20$ swift --version
Swift version 6.4.2 (swift-6.4.2-RELEASE)
Target: x86_64-unknown-linux-gnu
ana@vm:~/sw/l20$ curl -s https://www.swift.org/api/v1/install/releases.json | python3 -c 'import json, sys; r = [x for x in json.load(sys.stdin) if x["name"] == "6.4.2"][0]; print("\n".join(p["name"] for p in r["platforms"]))'
Ubuntu 22.04
Ubuntu 24.04
Ubuntu 26.04
Debian 12
Debian 13
Fedora 41
Amazon Linux 2023
Red Hat Universal Base Image 9
Red Hat Universal Base Image 10
Windows 10
Static SDK
Wasm SDK
Android SDK
ana@vm:~/sw/l20$ swift sdk list
No Swift SDKs are currently installed.
```

The first command is lesson 1's check, unchanged after nineteen lessons. The second fetches the
release list and prints the platforms published for 6.4.2. The third asks which **Swift SDKs** are
installed, and the answer is none yet. Read the middle list in three groups.

| group | what it is | in this course |
|---|---|---|
| **Linux and Windows** | a full toolchain for each named system: compiler, standard library, Foundation, package manager and test runners | Ubuntu 24.04, lessons 1 to 20 |
| **Static SDK, Wasm SDK, Android SDK** | not toolchains, but bundles that let a Linux or Mac toolchain build for another target | the static SDK, section 05 |
| **Apple's platforms** | not on the list: iOS, iPadOS, macOS, watchOS, tvOS and visionOS get their Swift inside Xcode | described in section 06, not run |

## What the list says and what it does not

**Every one of those platforms runs the same language**: the code of lessons 1 to 19 compiles on all
of them. What differs between them is the libraries above the language, which section 03 is about,
and the way a program is packaged and started.

Two targets on the list need a sentence each, because they are newer than most material about
Swift. **WebAssembly** lets Swift compile to the bytecode browsers run, so the same model code can run
in a web page. **Android** is published by swift.org as an SDK for building Android libraries from
Swift; it is not a way to write an Android app's screens, which stay in Kotlin, and this course does
not build for it. Neither was run for this course.

There is also **Embedded Swift**, a restricted mode of the same compiler for microcontrollers with a
few kilobytes of memory, which drops the parts of the language that need a runtime, such as the
`any` existentials of lesson 9. It is a compiler setting rather than a list entry, and it is named here so
that the word is not a surprise.

## Where the course stands

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" data-fig=\"l20-platforms\" aria-label=\"One Swift source compiled for three groups of targets. Apple’s platforms get Swift inside Xcode and can import SwiftUI and UIKit; that column was not run in this course. Linux and Windows get a toolchain from swift.org with the open-source Foundation and no Apple frameworks; this course ran on Ubuntu 24.04. SDKs for other targets, the static Linux SDK, WebAssembly and Android, are bundles a toolchain builds with; section 05 runs the static one.\"><defs><marker id=\"l20-platforms-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l20-platforms-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l20-platforms-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"250\" y=\"14\" width=\"220\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">one Swift source</text><text x=\"360\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">Sources/*.swift</text><path d=\"M360 54 L130 84\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-platforms-ah-wire)\"></path><rect x=\"20\" y=\"86\" width=\"220\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"130\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Apple’s platforms</text><text x=\"130\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Swift inside Xcode</text><text x=\"130\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">iOS, macOS, watchOS</text><text x=\"130\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tvOS, visionOS</text><text x=\"130\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">SwiftUI and UIKit importable</text><text x=\"130\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">described, not run here</text><path d=\"M360 54 L360 84\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-platforms-ah-wire)\"></path><rect x=\"250\" y=\"86\" width=\"220\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Linux and Windows</text><text x=\"360\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">toolchain from swift.org</text><text x=\"360\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">open-source Foundation</text><text x=\"360\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">no Apple frameworks</text><text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">this course: Ubuntu 24.04</text><path d=\"M360 54 L590 84\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-platforms-ah-wire)\"></path><rect x=\"480\" y=\"86\" width=\"220\" height=\"170\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">SDKs for other targets</text><text x=\"590\" y=\"134\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">static Linux, with musl</text><text x=\"590\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">WebAssembly</text><text x=\"590\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Android libraries</text><text x=\"590\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">section 05 runs the first</text><text x=\"360\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the same language in every column</text></svg>", "caption": "The language is the same in every column. What changes is what can be imported and what a binary needs to run."}
```

**The language is the same in every column; the difference is what can be imported and what a
binary needs to run.** On Apple's systems the platform's frameworks are there to import, and SwiftUI
is one of them. On Linux they are not, and Foundation is the open-source one. Section 03 shows that
difference at compile time, section 04 uses Linux for the thing it is most used for, a server, and
section 05 builds a program that runs on a Linux machine with no Swift installed at all.
