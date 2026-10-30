---
title: Decoding it back
version: 1
---

Decoding is the same conversion in the other direction, and **the type you ask for is the whole
specification**: `JSONDecoder().decode([Course].self, from: data)` reads an array of courses, and
checks every value it reads against the property it is meant for.

```swift
// Decode.swift
import Foundation

struct StudySession: Codable {
    var minutes: Int
    var done: Bool
}

struct Course: Codable {
    var name: String
    var sessions: [StudySession]
}

let data = try Data(contentsOf: URL(fileURLWithPath: "planner.json"))
let planner = try JSONDecoder().decode([Course].self, from: data)
for course in planner {
    let done = course.sessions.filter(\.done).map(\.minutes).reduce(0, +)
    print("\(course.name): \(course.sessions.count) sessions, \(done) minutes done")
}
```

```
ana@vm:~/sw/l13$ swift Decode.swift
Swift: 2 sessions, 45 minutes done
Kotlin: 0 sessions, 0 minutes done
```

The program reads the `planner.json` that section 01 wrote, in the same directory, and gets back two
courses with their sessions, as real Swift values: `course.sessions.filter(\.done)` keeps the sessions
whose `done` is `true`, and `map(\.minutes)` takes their minutes (lesson 4). The Swift course has two
sessions and 45 minutes done; Kotlin has none.

`[Course].self` is how Swift writes **the type itself as a value**, the thing being asked for, rather
than a course. The decoder needs it because it cannot infer the type from the JSON: the same bytes
could be meant as a `[Course]`, a `[[String: Any]]` or something else, and only the caller knows.

## What the compiler wrote for you

`Codable` is two protocols, `Encodable` and `Decodable`, and conforming to it asks the compiler to
generate three things in the struct: an `encode(to:)` method, an `init(from:)` initialiser, and a
nested enum called **`CodingKeys`** with one case per stored property. None of it appears in the
source, and all of it is there. Sections 03 and 05 write parts of it by hand, which is how you change
what the compiler would have done.

A struct that needs only one direction can conform to only one protocol. A response from a server
that is only ever read can be `Decodable`, and the compiler then generates no encoding code for it.
