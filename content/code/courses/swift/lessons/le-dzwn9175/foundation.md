---
title: Foundation on Linux, and the code that asks where it is
version: 1
---

The standard library is the same on every platform: `Int`, `String`, `Array`, optionals, `Codable`,
`async`/`await` and actors are compiled from one source for all of them. **Foundation is the layer
above it, and it is not one library everywhere.** On a Mac it is Apple's, part of the operating
system. On Linux and Windows it is the open-source **swift-corelibs-foundation**, rebuilt in recent
releases on top of a shared core written in Swift, and shipped inside the toolchain you unpacked in
lesson 1.

For most of what this course used, the two agree. `JSONEncoder`, `Date`, `ISO8601DateFormatter`,
`ProcessInfo` and `URL` all worked on Ubuntu in lessons 13 and 14. Three differences are worth
knowing before they surprise you:

- **Networking lives in a separate module on Linux**, `FoundationNetworking`, because it is built on
  `libcurl`, which is why lesson 1's `apt` line installed `libcurl4-openssl-dev`. On a Mac,
  `URLSession` is simply part of Foundation.
- **Apple's other frameworks are not there at all.** SwiftUI, UIKit, Combine, Core Data and
  SwiftData are Apple's and ship only with Apple's systems.
- **The C library underneath is different**: `Darwin` on Apple's systems, `Glibc` on most Linux
  distributions and `Musl` with the static SDK of section 05.

## Asking at compile time

Swift answers the question "where am I?" while compiling, not while running. `#if os(Linux)` keeps
or drops code depending on the target, and `#if canImport(Module)` asks whether a module exists for
that target, which is the better question most of the time: it is about what the code needs rather
than about a name for the system.

```swift
// Where.swift
import Foundation

#if os(Linux)
print("Compiled for Linux")
#elseif os(macOS)
print("Compiled for macOS")
#endif

#if canImport(Darwin)
print("Darwin: yes")
#else
print("Darwin: no, Glibc instead")
#endif

#if canImport(FoundationNetworking)
print("FoundationNetworking: yes, a separate module")
#else
print("FoundationNetworking: no, URLSession is in Foundation")
#endif

#if canImport(SwiftUI)
print("SwiftUI: yes")
#else
print("SwiftUI: no")
#endif

let start = ISO8601DateFormatter().date(from: "2026-11-02T09:00:00-03:00")!
print(start.addingTimeInterval(45 * 60).formatted(.iso8601))
print(ProcessInfo.processInfo.operatingSystemVersionString)
```

```
ana@vm:~/sw/l20$ swift Where.swift
Compiled for Linux
Darwin: no, Glibc instead
FoundationNetworking: yes, a separate module
SwiftUI: no
2026-11-02T12:45:00Z
Ubuntu 24.04 LTS
```

**The branches not taken are not compiled at all.** That is why `#elseif os(macOS)` can sit in a
file built on Linux: its line is dropped before the compiler checks it, so it could even call a
function Linux does not have. The same file on a Mac prints the other branch of each pair. That run
is described and not recorded, because the course has no Mac. The date line shows Foundation doing
the same arithmetic it does on a Mac: 09:00 in São Paulo plus 45 minutes, printed in UTC as
12:45, which is what `.iso8601` formats to by default.

## The one difference you will hit

Code written on a Mac that uses `URLSession` stops compiling on Linux, with an error that does not
mention the reason:

```swift
// Fetch.swift
import Foundation

let session = URLSession.shared
print(type(of: session))
```

```
ana@vm:~/sw/l20$ swiftc Fetch.swift -o fetch
Fetch.swift:4:26: error: type 'URLSession' (aka 'AnyObject') has no member 'shared'
2 | import Foundation
3 | 
4 | let session = URLSession.shared
  |                          `- error: type 'URLSession' (aka 'AnyObject') has no member 'shared'
5 | print(type(of: session))
6 | 

Fetch.swift:5:7: error: cannot convert 'type(of:)' metatype to non-metatype 'Any'
3 | 
4 | let session = URLSession.shared
5 | print(type(of: session))
  |       `- error: cannot convert 'type(of:)' metatype to non-metatype 'Any'
6 | 
```

**"`URLSession` (aka `AnyObject`)" is the clue.** On Linux, plain Foundation only knows the name
`URLSession` as a placeholder, so the compiler sees a type with no members. The second error follows
from the first: with no `shared`, `session` has no type the compiler can print, and fixing the first
removes both. The fix is one import,
written so that the same file still builds on a Mac, where `FoundationNetworking` does not exist:

```swift
// FetchFixed.swift
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

let session = URLSession.shared
print(type(of: session))
```

```
ana@vm:~/sw/l20$ swiftc FetchFixed.swift -o fetchfixed && ./fetchfixed
URLSession
```

You will see these three lines at the top of nearly every server-side Swift file that talks to the
network. **Write them once, at the top, and the file builds on both systems.** Section 04 uses them
in a client that talks to a server.
