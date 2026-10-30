---
title: What swift package init makes
version: 1
---

Lessons 17 and 18 used packages and said little about them. A **package** is a directory with a
`Package.swift` at the top, the **manifest**, and the source files in the places the manifest
expects. It is the unit Swift builds, tests and shares: every library you will ever add to a
project arrives as one, and the iOS app of `ios-apps` keeps its model in one too. **Swift Package
Manager**, SwiftPM for short, is the part of the toolchain that reads manifests, and it answers to
`swift build`, `swift test`, `swift run` and `swift package`.

The quickest way to see the shape is to have SwiftPM make an empty one:

```
ana@vm:~/sw/l19/hello$ swift package init --type executable
Creating executable package: hello
Creating Package.swift
Creating .gitignore
Creating Sources
Creating Sources/hello/hello.swift
Creating Tests/
Creating Tests/helloTests/
Creating Tests/helloTests/helloTests.swift
ana@vm:~/sw/l19/hello$ find . -path ./.build -prune -o -type f -print | sort
./.gitignore
./Package.swift
./Sources/hello/hello.swift
./Tests/helloTests/helloTests.swift
```

`swift package init` names the package after its directory unless told otherwise, and
`--type executable` asks for a program rather than a library. It made four files. The `find`
leaves out `.build`, where everything SwiftPM produces goes; `.gitignore` already lists that
directory, because nothing in it belongs in version control.

## The manifest is Swift

```
ana@vm:~/sw/l19/hello$ cat Package.swift
// swift-tools-version: 6.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "hello",
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "hello",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
        .testTarget(
            name: "helloTests",
            dependencies: ["hello"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ],
        ),
    ]
)
```

**The first line is not an ordinary comment.** `// swift-tools-version: 6.4` is read by SwiftPM
before anything else, and it says which version of the manifest format this file is written in.
A toolchain older than 6.4 refuses the file, and section 07 shows that the number also decides the
language mode the targets are compiled in. Below it, the manifest is a Swift program that imports
`PackageDescription` and builds one value, `package`, describing what is here.

Two **targets**: an executable named `hello`, whose sources are in `Sources/hello`, and a test
target `helloTests` in `Tests/helloTests` that depends on it. A target is a module, lesson 17's
unit of access. The `swiftSettings` turn on `ApproachableConcurrency`, an **upcoming feature**: a
change to the language that a future mode will make the default, switched on early for this
target. Toolchain 6.4's template adds it to every new package; lesson 15 is about what it changes.

## The program, and running it

The executable's one file is the standard first program:

```
ana@vm:~/sw/l19/hello$ cat Sources/hello/hello.swift
// The Swift Programming Language
// https://docs.swift.org/swift-book

@main
struct hello {
    static func main() {
        print("Hello, world!")
    }
}
```

`@main` marks the type whose static `main()` is where the program starts. That is the second way to
say where a program begins, beside lesson 1's top-level statements in `main.swift`: a target has one
or the other, and a file named `main.swift` cannot also contain an `@main` type. `swift run` builds
the package and runs its executable:

```
ana@vm:~/sw/l19/hello$ swift run 2>&1 | grep -v frontend
Building for debugging...
[Planning deferred tasks]
[18 / 22] hello-product
[19 / 22] hello-product
[23 / 23] hello-product
Build complete! (3.14 secs)
warning: safeExec: signal(32, SIG_DFL) failed: Invalid argument
warning: safeExec: signal(33, SIG_DFL) failed: Invalid argument
Hello, world!
```

`swift run` builds first, so the progress lines and `Build complete!` come before the greeting.
**The two `safeExec` warnings come from `swift run` itself**, just before it hands over to the
program: it tries to reset every signal to its default, and Linux reserves signals 32 and 33 for its
threads library, which refuses. They say nothing about your program, and they do not appear when
you run the executable directly, as every other section of this lesson does.
