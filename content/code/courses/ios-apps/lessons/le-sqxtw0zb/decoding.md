---
title: Decoding, and the type the server speaks
version: 1
---

**`JSONDecoder` turns bytes into Swift values, and it does it by reading the type you hand it.**
`swift` lesson 13 taught `Codable`: a struct that says it is `Decodable` gets its decoding written
by the compiler, one key per stored property. This section puts that to work on the server's
answer, and on the two ways that answer can be wrong.

## A type for the wire, not the model

The tempting move is to make lesson 1's `Course` and `StudySession` `Codable` and decode straight
into them. **This course keeps a separate type for what travels over the network**, and the reason
is visible in the first session the server sends: it says `courseId`, and Swift's naming says
`courseID`. More differences follow as an app grows: a server that sends a date as a timestamp, a
field the app does not keep, a field the app keeps and the server never sends. A wire type absorbs
all of them in one file, and the model the screens use stays the shape the app wants.

Save this as `Sources/PlannerCore/Wire.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/Wire.swift", "parts": [{"code": "// Sources/PlannerCore/Wire.swift\nimport Foundation\n\n/// A course as the server spells it.\npublic struct WireCourse: Codable, Sendable {\n    public let id: String\n    public let title: String\n}\n", "note": "A course arrives with the same two names the model uses, so the compiler's own decoding is enough."}, {"code": "/// A session as the server spells it: `courseId`, where Swift says `courseID`.\npublic struct WireSession: Codable, Sendable {\n    public let id: String\n    public let courseID: String\n    public let date: String\n    public let minutes: Int\n    public let done: Bool\n\n    enum CodingKeys: String, CodingKey {\n        case id, date, minutes, done\n        case courseID = \"courseId\"\n    }\n}\n", "note": "`CodingKeys` is the one place the two spellings meet. Each case is a property; its raw value is the key in the JSON. Leave a property out of the enum and the compiler refuses to synthesise the decoding, which is how you find out."}, {"code": "extension WireCourse {\n    public var course: Course { Course(id: id, title: title) }\n}\n\nextension WireSession {\n    public init(_ s: StudySession) {\n        self.init(id: s.id, courseID: s.courseID, date: s.date, minutes: s.minutes, done: s.done)\n    }\n    public var session: StudySession {\n        StudySession(id: id, courseID: courseID, date: date, minutes: minutes, done: done)\n    }\n}\n", "note": "The conversions both ways. Going out, section 05 encodes a `WireSession` made from a model session; coming in, every wire value becomes a model value before anything else sees it."}]}
```

## Reading the server's answer

Replace `Sources/fetch/main.swift`. It decodes the courses from the server, then decodes two
sessions written into the program by hand, each wrong in a way servers really are wrong:

```schooling-example
{"language": "swift", "file": "Sources/fetch/main.swift", "parts": [{"code": "// Sources/fetch/main.swift\nimport Foundation\n#if canImport(FoundationNetworking)\nimport FoundationNetworking\n#endif\nimport PlannerCore\n\nlet url = URL(string: \"http://127.0.0.1:8012/courses/sql/sessions\")!\nlet (data, _) = try await URLSession.shared.data(from: url)\nlet sessions = try JSONDecoder().decode([WireSession].self, from: data).map(\\.session)\nfor s in sessions {\n    print(s.id, s.courseID, s.date, s.minutes, s.done)\n}\n", "note": "`[WireSession].self` is the type to decode: an array of them. The decoder walks the JSON and the type together, and `map(\\.session)` turns every wire value into a model value."}, {"code": "let wrongType = Data(#\"{\"id\": \"s1\", \"courseId\": \"sql\", \"date\": \"2026-10-19\", \"minutes\": \"forty\", \"done\": true}\"#.utf8)\nlet wrongName = Data(#\"{\"id\": \"s1\", \"course_id\": \"sql\", \"date\": \"2026-10-19\", \"minutes\": 40, \"done\": true}\"#.utf8)\nfor body in [wrongType, wrongName] {\n    do {\n        _ = try JSONDecoder().decode(WireSession.self, from: body)\n    } catch {\n        print(error)\n    }\n}\n", "note": "`#\"…\"#` is a raw string, so the quotes inside need no backslashes. One body sends a number as text; the other spells a key in snake case, as many servers do. Neither is decoded halfway: the decoder throws, and nothing is half-built."}]}
```

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (1.74 secs)
ana@vm:~/planner$ .build/debug/fetch
s1 sql 2026-10-19 50 true
s3 sql 2026-10-23 60 false
DecodingError.typeMismatch: Expected value of type Int. Path: minutes. Debug description: Expected to decode Int but found a string instead.
DecodingError.keyNotFound: Key 'courseId' not found in keyed decoding container. Debug description: No value associated with key CodingKeys(stringValue: "courseId", intValue: nil) ("courseId").
```

**A `DecodingError` names the key and says what it expected, and that is everything you need to
find the mismatch.** `typeMismatch` is a value of the wrong type at a path; `keyNotFound` is a key
that the type requires and the JSON does not have. The second is the commoner one in practice,
because a server renamed a field or an app was written against documentation instead of an answer.

## Keeping it decoded with a test

The decoding is a promise between two programs, so it earns a test of its own. Save this as
`Tests/PlannerCoreTests/WireTests.swift`; it decodes a body copied from `curl` in section 02 and
checks the spelling `courseId` became `courseID`:

```swift
// Tests/PlannerCoreTests/WireTests.swift
import Foundation
import Testing
@testable import PlannerCore

@Test func aSessionFromTheServerBecomesAModelSession() throws {
    let body = Data(#"[{"id": "s1", "courseId": "sql", "date": "2026-10-19", "minutes": 50, "done": true}]"#.utf8)
    let sessions = try JSONDecoder().decode([WireSession].self, from: body).map(\.session)
    #expect(sessions == [StudySession(id: "s1", courseID: "sql", date: "2026-10-19", minutes: 50, done: true)])
}

@Test func aSessionEncodesWithTheServersSpelling() throws {
    let s = StudySession(id: "s5", courseID: "mobile", date: "2026-10-22", minutes: 30)
    let text = String(decoding: try JSONEncoder().encode(WireSession(s)), as: UTF8.self)
    #expect(text.contains(#""courseId":"mobile""#))
}
```

```
ana@vm:~/planner$ swift test 2>&1 | grep -E "✔|✘"
✔ Test aSessionEncodesWithTheServersSpelling() passed after 0.001 seconds.
✔ Test aSessionFromTheServerBecomesAModelSession() passed after 0.001 seconds.
✔ Test aSessionForNoCourseIsRefused() passed after 0.001 seconds.
✔ Test mondayIsTheStartOfTheWeek() passed after 0.002 seconds.
✔ Test run with 4 tests in 0 suites passed after 0.002 seconds.
```

The second test is the direction that is easy to forget. A `CodingKeys` enum decides how a value
is **encoded** as well, so the session section 05 posts goes out as `courseId`, which is the
spelling the server's `POST` handler reads.
