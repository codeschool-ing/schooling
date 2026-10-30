---
title: When the JSON's names are not yours
version: 1
---

The generated code uses each property's name as its key. That works while you choose both sides.
**A server written by somebody else, often in another language, names its fields its own way**:
`study_minutes` and `is_done`, in the snake case that Python and SQL use, where Swift writes
`minutes` and `done`. Rename your properties to match and every line of Swift that uses them reads
wrongly; leave them, and decoding fails on the first missing key.

The bridge is the `CodingKeys` enum section 02 described. Write it yourself, and the compiler uses
yours instead of generating one:

```swift
// Keys.swift
import Foundation

struct StudySession: Codable {
    var minutes: Int
    var done: Bool

    enum CodingKeys: String, CodingKey {
        case minutes = "study_minutes"
        case done = "is_done"
    }
}

let fromServer = #"[{"study_minutes": 45, "is_done": true}, {"study_minutes": 30, "is_done": false}]"#
let sessions = try JSONDecoder().decode([StudySession].self, from: Data(fromServer.utf8))
print(sessions)
let back = try JSONEncoder().encode(sessions[0])
print(String(decoding: back, as: UTF8.self))
```

```
ana@vm:~/sw/l13$ swift Keys.swift
[Keys.StudySession(minutes: 45, done: true), Keys.StudySession(minutes: 30, done: false)]
{"study_minutes":45,"is_done":true}
```

`CodingKeys` is an enum with a `String` raw value (lesson 7) that conforms to `CodingKey`. **Each case
is a property, and its raw value is the key in the JSON.** Both directions use it: the sessions were
decoded from `study_minutes` and `is_done`, and encoding one back writes the server's names, not the
Swift ones. The JSON in the program is a raw string, `#"…"#`, in which quotes need no backslash.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 160\" role=\"img\" data-fig=\"l13-keys\" aria-label=\"Three columns. Left, the Swift struct StudySession with properties minutes and done. Middle, the enum CodingKeys with case minutes = \"study_minutes\" and case done = \"is_done\". Right, the JSON object with keys study_minutes: 45 and is_done: true. Arrows join each property to its case and each case to its key, in both directions.\"><defs><marker id=\"l13-keys-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-keys-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l13-keys-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"110.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the Swift struct</text><rect x=\"20\" y=\"38\" width=\"180\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">var minutes: Int</text><text x=\"110.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">var done: Bool</text><text x=\"360.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">CodingKeys</text><rect x=\"250\" y=\"38\" width=\"220\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">case minutes = \"study_minutes\"</text><text x=\"360.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">case done = \"is_done\"</text><text x=\"610.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the JSON from the server</text><rect x=\"520\" y=\"38\" width=\"180\" height=\"104\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"610.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">\"study_minutes\": 45</text><text x=\"610.0\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">\"is_done\": true</text><path d=\"M202 70 L248 70\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-keys-ah-amber)\"></path><path d=\"M472 70 L518 70\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-keys-ah-amber)\"></path><path d=\"M202 112 L248 112\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-keys-ah-amber)\"></path><path d=\"M472 112 L518 112\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l13-keys-ah-amber)\"></path></svg>", "caption": "CodingKeys sits between the two names: each case is a property, and its raw value is the key in the JSON. The same enum is used to decode and to encode."}
```

Two rules hold the enum to the struct. Every stored property that is to be encoded needs a case, and a
property left out of a hand-written `CodingKeys` is not encoded or decoded at all, so it must have a
default value. And a case that names no property does not compile.

## When the rule is mechanical

When every key is simply the snake-case form of the property name, a decoder can do the conversion
for all of them:

```swift
// Snake.swift
import Foundation

struct StudySession: Codable {
    var studyMinutes: Int
    var isDone: Bool
}

let fromServer = #"{"study_minutes": 45, "is_done": true}"#
let decoder = JSONDecoder()
decoder.keyDecodingStrategy = .convertFromSnakeCase
let session = try decoder.decode(StudySession.self, from: Data(fromServer.utf8))
print(session)
```

```
ana@vm:~/sw/l13$ swift Snake.swift
StudySession(studyMinutes: 45, isDone: true)
```

`keyDecodingStrategy = .convertFromSnakeCase` turns `study_minutes` into `studyMinutes` before
matching, and `JSONEncoder` has the mirror, `.convertToSnakeCase`. It saves writing the enum, and it
moves the mapping out of the type and into whoever configures the decoder, so **every decoder that
reads this type must remember to set it**. A `CodingKeys` enum travels with the struct, which is why
it is the safer choice when one type is decoded in several places.
