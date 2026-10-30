---
title: The planner as a small server
version: 1
---

Swift on a server is not a curiosity. Apple runs Swift services in production, and the community
maintains the networking library underneath most of them, **SwiftNIO**, and two web frameworks built
on it, Vapor and Hummingbird. A study planner on a phone eventually talks to a server that
stores the sessions, and that server can be written in the language the app is written in.

This section builds the smallest useful one with Hummingbird 2: two routes, `/week` and
`/sessions`, answering with text and with JSON. It is a package, as lesson 19 taught, with one
dependency fetched from GitHub. Make a directory `server`, and two files in it:

```swift
// swift-tools-version: 6.2
// Package.swift
import PackageDescription

let package = Package(
    name: "PlannerServer",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.28.0"),
    ],
    targets: [
        .executableTarget(
            name: "PlannerServer",
            dependencies: [.product(name: "Hummingbird", package: "hummingbird")]
        ),
    ]
)
```

`platforms` matters only on a Mac: Hummingbird needs macOS 14 or later, and the line says so. On
Linux it is ignored, because there is no older Linux API to rule out.

```schooling-example
{"language": "swift", "file": "Sources/PlannerServer/main.swift", "parts": [
 {"code": "// Sources/PlannerServer/main.swift\nimport Hummingbird", "note": "One import. Hummingbird brings SwiftNIO and the HTTP types with it."},
 {"code": "struct Session: ResponseCodable {\n    let course: String\n    let date: String\n    let minutes: Int\n}", "note": "`ResponseCodable` is `Codable` plus Hummingbird's promise to send the value as JSON. Lesson 13 did the rest of the work: the compiler writes the encoding."},
 {"code": "let sessions = [\n    Session(course: \"Swift\", date: \"2026-11-02\", minutes: 45),\n    Session(course: \"Swift\", date: \"2026-11-03\", minutes: 30),\n    Session(course: \"SQL\", date: \"2026-11-04\", minutes: 60),\n]", "note": "Three sessions held in memory. A real server would read them from a database; this one keeps the example to one file."},
 {"code": "let router = Router()\nrouter.get(\"sessions\") { _, _ in sessions }\nrouter.get(\"week\") { _, _ in \"\\(sessions.map(\\.minutes).reduce(0, +)) of 300 minutes\\n\" }", "note": "A route is a path and a closure, with a trailing closure from lesson 3. The closure receives the request and a context, ignored here with `_`, and returns whatever can become a response: an array of `Session` becomes JSON, a `String` becomes text."},
 {"code": "let app = Application(router: router, configuration: .init(address: .hostname(\"127.0.0.1\", port: 8090)))\ntry await app.runService()", "note": "Listen on port 8090 of this machine only, and run until stopped. `runService` is `async` and `throws`, so it is called with `try await` at the top level of `main.swift`, as lesson 14 allowed."}
]}
```

```
ana@vm:~/sw/l20/server$ swift build 2>&1 | tail -2
[740 / 740] PlannerServer-product
Build complete! (214.89 secs)
ana@vm:~/sw/l20/server$ ls .build/checkouts | wc -l
24
```

The first build downloads Hummingbird and everything it depends on, and compiles all of it. `tail -2`
keeps the last lines of a long list of compile steps, and `ls .build/checkouts` counts what was
fetched: twenty-four packages, Hummingbird and the twenty-three below it, most of them SwiftNIO and
its relatives. That first build takes minutes rather than seconds, and the line above says how many it
took on the machine this course was recorded on; every build after it takes seconds.

## Two terminals

A server runs until it is stopped, so it needs a terminal of its own. **Start it in one terminal**:

```
ana@vm:~/sw/l20/server$ .build/debug/PlannerServer
2026-10-30T15:47:37-0300 info Hummingbird: [HummingbirdCore] Server started and listening on 127.0.0.1:8090
```

`.build/debug/PlannerServer` is the executable `swift build` just wrote, and `.build/debug` is the
debug build's directory. `swift run PlannerServer` would build and run in one step, printing its build
progress first. The line the server printed is its own log, through `swift-log`, the logging
package most server-side Swift uses. Leave that
terminal alone, and **open a second one** for the requests:

```
ana@vm:~/sw/l20/server$ curl -s -i localhost:8090/week
HTTP/1.1 200 OK
Content-Type: text/plain; charset=utf-8
Content-Length: 19
Date: Fri, 30 Oct 2026 18:47:38 GMT

135 of 300 minutes
ana@vm:~/sw/l20/server$ curl -s localhost:8090/sessions; echo
[{"date":"2026-11-02","course":"Swift","minutes":45},{"date":"2026-11-03","course":"Swift","minutes":30},{"date":"2026-11-04","course":"SQL","minutes":60}]
ana@vm:~/sw/l20/server$ curl -s -i localhost:8090/semana
HTTP/1.1 404 Not Found
Content-Length: 0
Date: Fri, 30 Oct 2026 18:47:39 GMT
```

`-s` keeps `curl` quiet about its own progress, and the `echo` after the second request adds the
line break the JSON does not end with. The first request returns text, with the headers `curl -i`
asks to see: status `200 OK`, a
`Content-Type` of plain text and a length of 19 bytes. The second returns the three sessions as
JSON, and the order of the keys inside each object is not the order of the struct's
properties, and was not the same from one run of the server to the next.
JSON objects have no order, `JSONEncoder` does not promise one, and lesson 13 showed
`.sortedKeys` for the day the order matters to a person. The third asks for a path no route
handles and gets **`404 Not Found` with an empty body**, which Hummingbird sends without a line of
code from you.

## The other side of the wire

The same language can be the client. This script asks the server for the sessions with
`URLSession`, the API an iPhone app uses, and decodes them with the `Decodable` half of lesson 13:

```swift
// Client.swift
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct Session: Decodable {
    let course: String
    let date: String
    let minutes: Int
}

let url = URL(string: "http://localhost:8090/sessions")!
let (data, response) = try await URLSession.shared.data(from: url)
let status = (response as? HTTPURLResponse)?.statusCode ?? 0
let sessions = try JSONDecoder().decode([Session].self, from: data)
print("HTTP \(status), \(sessions.count) sessions")
for session in sessions {
    print(session.date, session.course, session.minutes)
}
```

```
ana@vm:~/sw/l20/server$ swift Client.swift
HTTP 200, 3 sessions
2026-11-02 Swift 45
2026-11-03 Swift 30
2026-11-04 SQL 60
```

**The struct is declared twice**, once on each side, and nothing checks that the two agree. A
renamed property on the server is a `keyNotFound` on the client, as lesson 13 showed. Sharing one
definition is what a package is for: a library target with the models, depended on by the server
and by the app. Lesson 19 built exactly that shape, with `PlannerCore`.

Stop the server with Ctrl+C in its terminal.

## Where a Swift server is deployed

On Linux, almost always, and usually in a container. The toolchain's archive is 1.1 GB, and nobody
wants that inside an image that only has to run one program. Section 05 builds a binary that needs
none of it.
