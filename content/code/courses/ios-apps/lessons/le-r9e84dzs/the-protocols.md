---
title: Two protocols, a source and a store
version: 1
---

**A protocol says what something can do and nothing about how.** The repository needs a source that
can list courses, list a course's sessions and add a session, and a store that can load and save
what the device knows. This section writes both, and the one implementation of each this lesson
uses. Everything here runs on Linux, in the planner's package from lesson 12.

## The source

Save this as `Sources/PlannerCore/PlanSource.swift`:

```swift
// Sources/PlannerCore/PlanSource.swift
/// Where the planner's data comes from when it is online.
public protocol PlanSource: Sendable {
    func courses() async throws(APIError) -> [Course]
    func sessions(course id: String) async throws(APIError) -> [StudySession]
    func add(_ s: StudySession) async throws(APIError) -> StudySession
}

extension APIClient: PlanSource {}
```

**The protocol is lesson 12's client with its body removed.** `APIClient` already has those three
methods with exactly those signatures, so the empty extension is all it takes for it to conform. The
errors stay `APIError`, which means a fake source has to fail the way the real one does, with
`offline`, `status` or `unreadable`, and cannot invent a fourth kind the repository has never heard
of.

## The store

Save this as `Sources/PlannerCore/PlanStore.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/PlanStore.swift", "parts": [{"code": "// Sources/PlannerCore/PlanStore.swift\nimport Foundation\n\n/// What the planner keeps on the device: the last plan it saw, and the\n/// sessions added here that the server has not confirmed yet.\npublic struct Snapshot: Codable, Sendable {\n    public var courses: [WireCourse] = []\n    public var sessions: [WireSession] = []\n    public var pending: [WireSession] = []\n    public init() {}\n}\n", "note": "Everything the device keeps, as one value. It reuses lesson 12's wire types, which are already `Codable`, so saving it is one call to an encoder. `pending` is the half that matters offline: sessions that exist here and not yet on the server."}, {"code": "/// Where the planner keeps it.\npublic protocol PlanStore: Sendable {\n    func load() throws -> Snapshot\n    func save(_ snapshot: Snapshot) throws\n}\n", "note": "Two operations, both synchronous and both allowed to fail. A store that has never saved anything answers `load` with an empty snapshot rather than an error: a first launch is not a failure."}, {"code": "/// A store that is one JSON file.\npublic struct FileStore: PlanStore {\n    let url: URL\n    public init(url: URL) { self.url = url }\n\n    public func load() throws -> Snapshot {\n        guard FileManager.default.fileExists(atPath: url.path) else { return Snapshot() }\n        return try JSONDecoder().decode(Snapshot.self, from: Data(contentsOf: url))\n    }\n\n    public func save(_ snapshot: Snapshot) throws {\n        let encoder = JSONEncoder()\n        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]\n        try encoder.encode(snapshot).write(to: url, options: .atomic)\n    }\n}\n", "note": "`.atomic` writes to a temporary file and renames it over the old one, so an app killed mid-write leaves the old file whole rather than half of the new one. Pretty-printed and sorted so that you can read it, which section 05 does."}]}
```

On an iPhone the file would go in the app's Application Support directory, which
`URL.applicationSupportDirectory` names, and nowhere a person browses. Here it goes beside the
program, as `planner.json`, so that you can open it.

## A program to drive it

The package gains a third program, `repo`, which section 04 runs. Replace `Package.swift` with this,
lesson 12's with one more line:

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
        .executableTarget(name: "repo", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```
