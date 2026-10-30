---
title: The toolchain, its versions and its modes
version: 1
---

Three version numbers meet in every Swift build, and they are easy to confuse because two of them
look alike. **The toolchain version** is the compiler you installed, 6.4.2. **The tools version**
is the first line of a manifest, the oldest toolchain the package says it builds with. **The
language mode** is the set of rules the compiler applies to the source, Swift 5 or Swift 6, and it
is what changes how strict lesson 15's concurrency checks are.

```
ana@vm:~/sw/l19/planner$ swift --version
Swift version 6.4.2 (swift-6.4.2-RELEASE)
Target: x86_64-unknown-linux-gnu
ana@vm:~/sw/l19/planner$ swift package tools-version
6.2.0
ana@vm:~/sw/l19/planner$ touch Sources/PlannerCore/Week.swift
ana@vm:~/sw/l19/planner$ swift build -v 2>&1 | grep -o -e '-swift-version [0-9]*' | uniq -c
     31 -swift-version 6
```

The toolchain answers 6.4.2. The package says 6.2.0, which is section 03's first line. Neither of
those is the language mode, and `swift build -v` shows the commands it gives the compiler, where the
mode is one flag: `grep` keeps it and `uniq -c` counts it. **Every compile in this package used
`-swift-version 6`**, because a manifest with tools version 6.0 or later builds its targets in Swift
6 mode unless it says otherwise.

## The first line decides the mode

`swift package tools-version --set` rewrites that first line. Set it to 5.10, build, and set it back:

```
ana@vm:~/sw/l19/planner$ swift package tools-version --set 5.10
ana@vm:~/sw/l19/planner$ head -2 Package.swift
// swift-tools-version: 5.10
// Package.swift
ana@vm:~/sw/l19/planner$ touch Sources/PlannerCore/Week.swift
ana@vm:~/sw/l19/planner$ swift build -v 2>&1 | grep -o -e '-swift-version [0-9]*' | uniq -c
      7 -swift-version 5
ana@vm:~/sw/l19/planner$ swift package tools-version --set 6.2
ana@vm:~/sw/l19/planner$ head -2 Package.swift
// swift-tools-version: 6.2
// Package.swift
```

**The same toolchain compiled the same files in Swift 5 mode** once the manifest said 5.10, because
a package written for 5.10 was written before Swift 6's rules existed and is not held to them. The
counts are how many compiler commands carried the flag, and they differ because each build redid a
different amount of work; what matters is that within each build they all agreed. Note too that
`--set` kept the second line, the comment naming the file.

That is how lesson 1's `swiftc` and `swift Hello.swift` behaved: **a file compiled on its own is in
Swift 5 mode** unless `-swift-version 6` is given, and lesson 15 gave it. A package can also choose a
mode per target with `swiftSettings: [.swiftLanguageMode(.v5)]`, which is how a large project moves
to Swift 6 one module at a time, and the `ApproachableConcurrency` setting that `init` wrote in
section 02 is one of the **upcoming features**, single rules of a future mode turned on early.

## What the toolchain holds

```
ana@vm:~/sw/l19/planner$ ls ~/.local/share/swift-6.4.2-RELEASE-ubuntu24.04/usr/bin | wc -l
60
ana@vm:~/sw/l19/planner$ du -sh .build ~/.cache/org.swift.swiftpm
112M	.build
6.8M	/home/ana/.cache/org.swift.swiftpm
```

The `usr/bin` directory holds 60 programs, and a handful are the ones you use:
`swift` and `swiftc`, the drivers; `swift-build`, which `swift build` hands its work to; `lldb`,
the debugger; `sourcekit-lsp`, the language server that gives an editor completion and errors as
you type; `docc`, which builds documentation from comments; and `llvm-cov`, which lesson 18 used.
`clang` is there too, because a Swift package may contain C targets and Swift calls C directly.

Two other directories matter, and `du` measured both. `.build`, 112 MB here, belongs to the project
and can be deleted at any time: it is rebuilt, slowly once. `~/.cache/org.swift.swiftpm` belongs to your
account and holds a copy of every repository SwiftPM has fetched, 6.8 MB so far, so a second
project that depends on `swift-argument-parser` does not download it again.

## Changing toolchain, and swiftly

A toolchain is a directory, and lesson 1 put this one on `PATH` by hand. To try another release, or
a snapshot of the next one, the same steps unpack it beside the first and point `PATH` at it.
**`swiftly` is swift.org's tool for exactly that**: it downloads a toolchain, verifies it, and
switches between installed ones with `swiftly use`, and a project can name the version it expects
in a file called `.swift-version`, which `swiftly` then follows when you work inside it. swiftly was
not used to record this course, for the reason lesson 1 gave: a pinned archive and a signature you
check yourself make every version in the transcripts a line you can read. Its commands are shown on
swift.org's install page.

On a Mac, the toolchain arrives inside Xcode, and `xcode-select` chooses which Xcode's toolchain the
command line uses; lesson 20 says what else a Mac adds.
