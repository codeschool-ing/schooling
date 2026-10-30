---
title: Dates, and the number nobody expected
version: 1
---

A study session happens at a time, and `Date` is `Codable`. The surprise is **how** it is encoded
when nobody says:

```swift
// Dates.swift
import Foundation

struct StudySession: Codable {
    var date: Date
    var minutes: Int
}

let session = StudySession(date: Date(timeIntervalSince1970: 1_793_041_200), minutes: 45)

let plain = try JSONEncoder().encode(session)
print(String(decoding: plain, as: UTF8.self))

let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
let iso = try encoder.encode(session)
print(String(decoding: iso, as: UTF8.self))

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
let back = try decoder.decode(StudySession.self, from: iso)
print(back.date, back.date == session.date)

do {
    _ = try JSONDecoder().decode(StudySession.self, from: iso)
} catch {
    print(error)
}
```

```
ana@vm:~/sw/l13$ swift Dates.swift
{"date":814734000,"minutes":45}
{"date":"2026-10-26T19:00:00Z","minutes":45}
2026-10-26 19:00:00 +0000 true
DecodingError.typeMismatch: Expected value of type Double. Path: date. Debug description: Expected to decode Double but found a string instead.
```

The session's date is 26 October 2026, 19:00 UTC, which is 16:00 in São Paulo. With no strategy set,
**the encoder wrote `814734000`**: the number of seconds since 1 January 2001, which is the reference
date Apple's `Date` counts from. No server outside Apple's own expects that number, and nothing in it
says what it is.

`dateEncodingStrategy = .iso8601` writes the same instant as **`"2026-10-26T19:00:00Z"`**, the ISO
8601 form most APIs use: a date, a `T`, a time, and `Z` for UTC. A decoder set to the same strategy
reads it back, and `back.date == session.date` is `true`, the same instant to the second. Printing a
`Date` shows it in UTC, `+0000`, whatever the machine's time zone.

The last block is the mistake in its natural habitat: an ISO string decoded **without** the strategy.
The default decoder expects the 2001 number, finds a string, and says so: `typeMismatch`, `Expected to
decode Double but found a string instead`, at the path `date`. Section 06 reads errors like this one
in detail.

## Pick one strategy and keep it everywhere

Dates are where an app and its server most often disagree, because both sides work in testing and
fail only when they meet. **Decide the format once, ISO 8601 unless the server says otherwise, and
set it on every encoder and decoder that touches the type**, or write it in one place both use. The
strategies also include `.secondsSince1970`, for servers that send a Unix timestamp, and `.formatted`,
for a fixed pattern of your own.
