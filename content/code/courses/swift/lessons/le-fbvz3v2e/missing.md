---
title: Keys that are missing
version: 1
---

JSON written by an older version of an app lacks the fields added since. A server leaves a field out
when it has nothing to say. **The decoder's rule is strict and simple: an optional property may be
missing, and any other property may not.**

```swift
// Missing.swift
import Foundation

struct StudySession: Codable {
    var minutes: Int
    var done: Bool
    var note: String?
}

let older = #"{"minutes": 45, "done": true}"#
let session = try JSONDecoder().decode(StudySession.self, from: Data(older.utf8))
print(session)

let planned = #"{"minutes": 30}"#
do {
    _ = try JSONDecoder().decode(StudySession.self, from: Data(planned.utf8))
} catch {
    print(error)
}
```

```
ana@vm:~/sw/l13$ swift Missing.swift
StudySession(minutes: 45, done: true, note: nil)
DecodingError.keyNotFound: Key 'done' not found in keyed decoding container. Debug description: No value associated with key CodingKeys(stringValue: "done", intValue: nil) ("done").
```

The first JSON has no `note`, and `note` is a `String?`, so it decoded with `note: nil`. The second has
no `done`, and `done` is a `Bool`: **`keyNotFound`**, with the key's name. The whole decode failed,
not just the one field, because a `StudySession` without `done` is not a `StudySession`.

That rule is right more often than it is annoying: it is the decoder refusing to invent a value. When
the app does have a sensible default, a planned session that is not done yet, the place to say so is
the initialiser the compiler would otherwise generate:

```schooling-example
{"language": "swift", "file": "Defaults.swift", "parts": [{"code": "// Defaults.swift\nimport Foundation\n\nstruct StudySession: Codable {\n    var minutes: Int\n    var done: Bool\n    var note: String?\n", "note": "The same struct as `Missing.swift`. Writing `init(from:)` replaces only that initialiser: the compiler still generates `CodingKeys` and `encode(to:)`."}, {"code": "    init(from decoder: any Decoder) throws {\n        let container = try decoder.container(keyedBy: CodingKeys.self)", "note": "A **keyed container** is the JSON object seen through `CodingKeys`. It throws if the JSON at this point is not an object at all."}, {"code": "        minutes = try container.decode(Int.self, forKey: .minutes)", "note": "`decode` for a key that must be there, exactly as the generated code does it: a missing `minutes` is still an error."}, {"code": "        done = try container.decodeIfPresent(Bool.self, forKey: .done) ?? false", "note": "`decodeIfPresent` returns `nil` for a missing key instead of throwing, and `?? false` (lesson 2) turns that into the default. A key that is present with the wrong type still throws."}, {"code": "        note = try container.decodeIfPresent(String.self, forKey: .note)\n    }\n}", "note": "`note` is optional, so the generated code would have used `decodeIfPresent` too. Once you write the initialiser, every property is yours to assign."}, {"code": "\nlet planned = #\"{\"minutes\": 30}\"#\nlet session = try JSONDecoder().decode(StudySession.self, from: Data(planned.utf8))\nprint(session)", "note": "The JSON a planned session arrives as, with no `done` key, now decodes."}]}
```

```
ana@vm:~/sw/l13$ swift Defaults.swift
StudySession(minutes: 30, done: false, note: nil)
```

**The default lives in the type**, written once, and every decoder that reads a `StudySession` gets it.
A property declared `var done: Bool = false` would not have done the same: the generated `init(from:)`
ignores the default value and still requires the key.

Making every property optional is the other way out, and it moves the problem to every line that
reads one, which then has to decide what `nil` means. Use an optional where absence means something,
like a note nobody wrote, and a default where it does not.
