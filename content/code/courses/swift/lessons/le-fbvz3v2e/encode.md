---
title: Encoding a planner to JSON
version: 1
---

A planner that forgets everything when it closes is not a planner. Its courses and sessions have to
be written somewhere, a file on the phone or a request to a server, and read back later, and JSON is
the format nearly every server and file in this course speaks. **Writing the conversion by hand, one
property at a time in each direction, is how a field gets saved and never loaded.** Swift's answer is
to let the compiler write it.

A type that conforms to **`Codable`** can be turned into JSON and back. For a struct whose properties
are all `Codable` themselves, as `Int`, `Bool`, `String`, arrays and other `Codable` structs are, the
conformance is the word and nothing else: the compiler generates the code that reads and writes each
property, by name.

```swift
// Encode.swift
import Foundation

struct StudySession: Codable {
    var minutes: Int
    var done: Bool
}

struct Course: Codable {
    var name: String
    var sessions: [StudySession]
}

let planner = [
    Course(name: "Swift", sessions: [StudySession(minutes: 45, done: true),
                                     StudySession(minutes: 30, done: false)]),
    Course(name: "Kotlin", sessions: []),
]

let encoder = JSONEncoder()
let compact = try encoder.encode(planner)
print(String(decoding: compact, as: UTF8.self))
print(compact.count, "bytes")

encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
let pretty = try encoder.encode(planner)
try pretty.write(to: URL(fileURLWithPath: "planner.json"))
print("wrote planner.json,", pretty.count, "bytes")
```

```
ana@vm:~/sw/l13$ swift Encode.swift
[{"name":"Swift","sessions":[{"minutes":45,"done":true},{"minutes":30,"done":false}]},{"name":"Kotlin","sessions":[]}]
118 bytes
wrote planner.json, 242 bytes
ana@vm:~/sw/l13$ cat planner.json; echo
[
  {
    "name" : "Swift",
    "sessions" : [
      {
        "done" : true,
        "minutes" : 45
      },
      {
        "done" : false,
        "minutes" : 30
      }
    ]
  },
  {
    "name" : "Kotlin",
    "sessions" : [

    ]
  }
]
```

`import Foundation` brings in `JSONEncoder` and `JSONDecoder`, which are not part of the standard
library; on Linux, the toolchain carries its own Foundation (lesson 20 is about what it has and what
it does not). `encoder.encode(planner)` returns **`Data`**, a buffer of bytes, which is what a file or
a network request holds; `String(decoding:as:)` reads those bytes as UTF-8 text so that `print` can
show them. The encoder can throw, if a value cannot be represented, so the call takes `try` (lesson
12), and at the top level of a script nothing more is needed.

The first line is **compact** JSON, 118 bytes with no spaces, which is what goes over a network. Then
two formatting options: `.prettyPrinted` breaks lines and indents, and `.sortedKeys` writes the keys
of each object in alphabetical order. `write(to:)` puts the 242 bytes in `planner.json`, and `cat`
shows the file. Two details in it: the encoder writes `" : "` with a space on each side, and the file
does not end with a newline, which is why the command adds an `echo`.

## Why sort the keys

In that run the compact line put `name` first, as it was declared, and `minutes` before `done`.
**A JSON object has no order, and the encoder promises none.** Run the same program three times:

```
ana@vm:~/sw/l13$ for run in 1 2 3; do swift Encode.swift | head -1; done
[{"name":"Swift","sessions":[{"minutes":45,"done":true},{"minutes":30,"done":false}]},{"name":"Kotlin","sessions":[]}]
[{"name":"Swift","sessions":[{"done":true,"minutes":45},{"done":false,"minutes":30}]},{"name":"Kotlin","sessions":[]}]
[{"sessions":[{"done":true,"minutes":45},{"done":false,"minutes":30}],"name":"Swift"},{"sessions":[],"name":"Kotlin"}]
```

Three runs, three arrangements of the same data: `minutes` before `done` in the first and after it
in the other two, `name` first in two runs and last in the third. The encoder keeps each object's keys
in a dictionary, and Swift seeds its hashing afresh in every process, so the order changes between
runs of an unchanged program. `.sortedKeys` makes the output the same on every run, which matters the moment a file is
compared with an older copy of itself, in version control or in a test that checks what was written.
A program that reads the JSON never cares, and section 02 reads it back.
