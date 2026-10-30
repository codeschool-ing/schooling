---
title: One request, with async/await
version: 1
---

**`URLSession` is how an Apple app talks HTTP, and since iOS 15 asking it for something is one
line with `await` in front of it.** The line suspends the function until the answer has arrived,
and the rest of the app carries on meanwhile. `swift` lesson 14 is where `async` and `await` were
taught; this section uses them on a real request.

The same `URLSession` exists on Linux, in a module of its own. On Apple systems it is part of
Foundation. In the open-source Foundation that ships with the Swift toolchain on Linux it lives in
`FoundationNetworking`, because it needs `libcurl` underneath and a program that never touches the
network should not have to link it. So every file of this course that uses it starts with the same
four lines, and on a Mac the `#if` is simply false.

## A target for it

The planner's package gains a second program, `fetch`, beside lesson 1's `week`. Replace
`Package.swift` in `~/planner` with this, which is lesson 1's with one line added:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Planner",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PlannerCore", targets: ["PlannerCore"]),
    ],
    targets: [
        .target(name: "PlannerCore"),
        .executableTarget(name: "week", dependencies: ["PlannerCore"]),
        .executableTarget(name: "fetch", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

## Forgetting the import first

This is the first version most people write, with Foundation and nothing else. Save it as
`Sources/fetch/main.swift`:

```swift
// Sources/fetch/main.swift
import Foundation

let url = URL(string: "http://127.0.0.1:8012/courses")!
let (data, response) = try await URLSession.shared.data(from: url)
print(response, data.count)
```

On a Mac it compiles. On Linux it does not, and the message is worth recognising, because it does
not say "import FoundationNetworking":

```
ana@vm:~/planner$ swift build 2>&1 | grep error:
error: SwiftCompile normal x86_64 failed with a nonzero exit code. Command line:     cd /home/ana
/home/ana/planner/Sources/fetch/main.swift:5:45: error: type 'URLSession' (aka 'AnyObject') has no member 'shared'
  |                                             `- error: type 'URLSession' (aka 'AnyObject') has no member 'shared'
error: Build failed
```

**`URLSession` is found, but as an empty placeholder**, which is why the compiler calls it
`AnyObject` and finds no `shared` on it. When you see that sentence about any networking type on
Linux, the import is what is missing.

## The request

With the import, and with the answer read properly. Replace `Sources/fetch/main.swift`:

```schooling-example
{"language": "swift", "file": "Sources/fetch/main.swift", "parts": [{"code": "// Sources/fetch/main.swift\nimport Foundation\n#if canImport(FoundationNetworking)\nimport FoundationNetworking\n#endif\n", "note": "`canImport` asks whether the module exists on the system being compiled for. On Linux it does, and is imported; on a Mac it does not, and the line disappears."}, {"code": "let url = URL(string: \"http://127.0.0.1:8012/courses\")!\nlet (data, response) = try await URLSession.shared.data(from: url)\n", "note": "`data(from:)` sends a `GET` and suspends until the whole body has arrived. It hands back two things: the bytes, and a `URLResponse` describing the answer. A top-level `await` is allowed in `main.swift`, which runs as an asynchronous function."}, {"code": "guard let http = response as? HTTPURLResponse else { fatalError(\"not HTTP\") }\nprint(http.statusCode, http.value(forHTTPHeaderField: \"Content-Type\") ?? \"\")\nprint(String(decoding: data, as: UTF8.self))\n", "note": "For an `http` URL the response is an `HTTPURLResponse`, which carries the status code and the headers. The body is printed as text here only to see it; section 04 turns it into Swift values."}]}
```

With the server from section 02 running in its own terminal:

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (5.76 secs)
ana@vm:~/planner$ .build/debug/fetch
200 application/json
[{"id": "sql", "title": "SQL Databases"}, {"id": "mobile", "title": "Mobile Fundamentals"}]
```

**The status, the type and the body arrive separately, and only the code decides which of them to
trust.** `URLSession` threw nothing here, and it would have thrown nothing for a `404` either: an
HTTP error is still an answer, and only a missing answer is an error to `URLSession`. Section 05
is built on that difference.

## On a Mac, the same call inside an app

Nothing changes in the call. What changes is where it runs: in an app, a function that awaits a
request is started from a view, and SwiftUI's `task` modifier is the usual place, because it
cancels the work when the view goes away. This was not run, as nothing from Xcode was:

```swift
// CourseListView.swift
import SwiftUI

struct CourseListView: View {
    @State private var count = 0

    var body: some View {
        Text("\(count) bytes")
            .task {
                let url = URL(string: "http://127.0.0.1:8012/courses")!
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    count = data.count
                }
            }
    }
}
```

The `try?` throws the error away, which is fine for the first line of a screen and wrong for the
last one. Section 06 replaces it with a state the screen can draw.
