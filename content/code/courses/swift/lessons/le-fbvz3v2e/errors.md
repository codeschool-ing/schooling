---
title: Reading a decoding error
version: 1
---

A decoding error is a value of the enum **`DecodingError`**, and its cases say what kind of thing went
wrong; each carries a **context** that says where. Printed as it is, it is a long sentence. Caught by
case, it becomes something a log line or a support message can use. Three broken pieces of JSON, one
per kind:

```swift
// Errors.swift
import Foundation

struct StudySession: Codable {
    var minutes: Int
    var done: Bool
}

struct Course: Codable {
    var name: String
    var sessions: [StudySession]
}

let broken = [
    #"[{"name": "Swift", "sessions": [{"minutes": "45", "done": true}]}]"#,
    #"[{"name": "Swift", "sessions": [{"minutes": 45, "done": true}, {"done": false}]}]"#,
    #"[{"name": "Swift", "sessions": [{"minutes": 45, "done": true}]"#,
]

for text in broken {
    do {
        _ = try JSONDecoder().decode([Course].self, from: Data(text.utf8))
    } catch let DecodingError.typeMismatch(type, context) {
        print("wrong type: expected \(type) at \(path(context.codingPath))")
    } catch let DecodingError.keyNotFound(key, context) {
        print("missing key: \(key.stringValue) at \(path(context.codingPath))")
    } catch let DecodingError.dataCorrupted(context) {
        print("not JSON: \(context.debugDescription)")
    } catch {
        print("other:", error)
    }
}

func path(_ keys: [any CodingKey]) -> String {
    keys.map { $0.intValue.map { "[\($0)]" } ?? ".\($0.stringValue)" }.joined()
}
```

```
ana@vm:~/sw/l13$ swift Errors.swift
wrong type: expected Int at [0].sessions[0].minutes
missing key: minutes at [0].sessions[1]
not JSON: The given data was not valid JSON.
```

| case | what it means | here |
|---|---|---|
| `typeMismatch(type, context)` | the key is there, with a value of another type | `"45"` in quotes is a string where an `Int` was expected |
| `keyNotFound(key, context)` | a required key is absent | the second session has no `minutes` |
| `dataCorrupted(context)` | the bytes are not valid JSON, or a value cannot be read at all | the last `]` is missing |
| `valueNotFound(type, context)` | the key is there and its value is `null` | not in this program |

**The coding path is the useful half.** `context.codingPath` is the list of keys and indices from the
top of the document to the failure, and the small `path` function at the end of the program writes it
as `[0].sessions[1]`: the first course, its second session. In a file with two hundred sessions, that
path is the difference between finding the bad record and reading the file by eye.

Each `catch` uses the patterns of lesson 12, with `let` binding the values the case carries, and the
final `catch` handles anything else, since `decode` is declared with plain `throws`.

## Fail loudly, at the edge

The decoder refused all three documents rather than producing a planner with a wrong session in it,
and that is the behaviour to keep. **Catch decoding errors where the data comes in**, at the file read
or the network response, log the case and the path, and tell the student that the planner could not be
loaded. A `try?` there would turn a broken file into an empty planner, and the student into somebody
who believes they have no sessions.
