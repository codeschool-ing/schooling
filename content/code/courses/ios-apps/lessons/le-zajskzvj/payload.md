---
title: The payload, and the limit APNs enforces
version: 1
---

**A remote notification is a small JSON document, and APNs refuses one that is too big.** Apple's
documentation for generating a remote notification gives both halves: the keys Apple defines, inside a
dictionary called `aps`, and the limit, "for all other remote notifications, the maximum payload size is
4 KB (4096 bytes)", with 5 KB for voice-over-IP calls. Building that document and measuring it is plain
Swift, so this section runs on Linux. Sending it to APNs needs Apple's servers, a key from a paid
developer account and a real device, and was not done for the course.

The planner sends one when a session is added on another of the student's devices, so this phone can
say so. Add a program to the package from section 04: replace `Package.swift` with this one, which adds
`push`:

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
        .executableTarget(name: "remind", dependencies: ["PlannerCore"]),
        .executableTarget(name: "push", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

Save this as `Sources/PlannerCore/Push.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/Push.swift", "parts": [{"code": "// Sources/PlannerCore/Push.swift\nimport Foundation\n\n/// What the planner's server sends through APNs when a session is added on another device.\npublic struct PushPayload: Codable, Equatable, Sendable {\n    public struct Alert: Codable, Equatable, Sendable {\n        public var title: String\n        public var body: String\n    }\n\n", "note": "The alert is what the person reads: a title and a body. Apple's documentation for generating a remote notification names `title` and `body` as keys of `alert`."}, {"code": "    public struct APS: Codable, Equatable, Sendable {\n        public var alert: Alert\n        public var sound: String?\n        public var threadID: String?\n\n        enum CodingKeys: String, CodingKey {\n            case alert, sound\n            case threadID = \"thread-id\"\n        }\n    }\n\n", "note": "Everything Apple defines goes inside a dictionary called `aps`. `thread-id` groups notifications on the lock screen, here by course. Swift names it `threadID` and `CodingKeys` spells it as APNs does, the same move lesson 12 makes for `courseId`."}, {"code": "    public var aps: APS\n    public var sessionID: String\n\n    enum CodingKeys: String, CodingKey {\n        case aps\n        case sessionID = \"session-id\"\n    }\n\n    public init(title: String, body: String, sessionID: String, courseID: String) {\n        aps = APS(alert: Alert(title: title, body: body), sound: \"default\", threadID: courseID)\n        self.sessionID = sessionID\n    }\n}\n\n", "note": "`session-id` is the planner's own key, outside `aps`, where the documentation says custom keys go. It tells the app which session to open when the notification is tapped; the init fills in the rest."}, {"code": "/// APNs refuses a payload over this many bytes (Apple's documentation, for all but VoIP).\npublic let maximumPushBytes = 4096\n\npublic func encoded(_ payload: PushPayload) throws -> Data {\n    let encoder = JSONEncoder()\n    encoder.outputFormatting = [.sortedKeys]\n    return try encoder.encode(payload)\n}\n", "note": "The limit is a published number, and checking it is a comparison. `sortedKeys` makes the output the same on every run, which is what lets a capture be compared byte for byte."}]}
```

And this as `Sources/push/main.swift`. It encodes a payload, measures it, decodes it back as the app
would, and then tries a body that carried the session's whole note:

```swift
// Sources/push/main.swift
import Foundation
import PlannerCore

let added = PushPayload(title: "Mobile Fundamentals", body: "45 min on Tue 27 Oct",
                        sessionID: "s4", courseID: "mobile")
let data = try encoded(added)
print(String(decoding: data, as: UTF8.self))
print(data.count, "bytes of", maximumPushBytes)

// The same payload back, as the app receives it
let back = try JSONDecoder().decode(PushPayload.self, from: data)
print(back == added, back.aps.threadID ?? "no thread")

// A body that carried the session's whole note instead of a summary
let note = String(repeating: "Read chapter 4 again and redo the exercises. ", count: 100)
let long = try encoded(PushPayload(title: "Mobile Fundamentals", body: note, sessionID: "s4", courseID: "mobile"))
print(long.count, "bytes:", long.count > maximumPushBytes ? "APNs refuses it" : "fits")
```

```
ana@vm:~/l17$ swift build
Building for debugging...
[Constructing description]
[Planning deferred tasks]
[10 / 26] PlannerCore
[21 / 36] remind-product
[23 / 37] remind-product
[32 / 41] week-product
[41 / 41] push-product
Build complete! (1.59 secs)
ana@vm:~/l17$ .build/debug/push
{"aps":{"alert":{"body":"45 min on Tue 27 Oct","title":"Mobile Fundamentals"},"sound":"default","thread-id":"mobile"},"session-id":"s4"}
136 bytes of 4096
true mobile
4616 bytes: APNs refuses it
```

**136 bytes is what a notification needs, and 4,616 is what a careless one becomes.** The first payload
is the whole message: who, what and when, with the session's id for the app to open. The second put a
note of a hundred sentences in the body, and APNs would refuse it, so the server's request fails and the
student never hears that a session was added. The rule that follows is the planner's: **a notification
carries a summary and an id, never the data.** The app opens, reads the id and fetches the session
through lesson 14's repository, which has the whole note.

`true mobile` is the round trip: what was sent decodes to an equal value, and `thread-id` arrived as
`threadID`. In the app, the payload reaches the delegate of section 05 as the notification's `userInfo`,
a dictionary, and the planner decodes it the same way after turning that dictionary back into JSON.
