---
title: What a list redraws, counted
version: 1
---

**When a list's collection changes, SwiftUI works out what changed by comparing ids, and the amount of
work that follows depends on how many rows it decides changed.** Identity that follows the data turns
an insertion into one insertion. Identity that follows the position turns it into a change of every
row below it. That count can be shown without SwiftUI. Save this as `diff.swift` in `~/rows`:

```schooling-example
{"language": "swift", "file": "diff.swift", "parts": [{"code": "// diff.swift: what changed, asked by id and by position\nlet before = [\"SQL, joins\", \"Mobile, lifecycle\", \"SQL, indexes\", \"SQL, views\"]\nlet after = [\"Mobile, offline\"] + before          // one session added at the top\n", "note": "Four rows, then the same four with one added above them, the commonest change a list sees: a new item at the top."}, {"code": "let byID = after.difference(from: before)\nprint(\"by id: \\(byID.count) change(s)\")\nfor change in byID {\n    if case let .insert(offset, element, _) = change {\n        print(\"  insert \\\"\\(element)\\\" at \\(offset)\")\n    }\n}\n", "note": "`difference(from:)` is the standard library's, and it compares elements by equality, which here is the same as by id: the strings are the identities. It is the question SwiftUI asks of a `ForEach`."}, {"code": "var byPosition: [String] = []\nfor position in 0..<max(before.count, after.count) {\n    let old = position < before.count ? before[position] : nil\n    let new = position < after.count ? after[position] : nil\n    if old != new {\n        byPosition.append(\"  row \\(position): \\(old ?? \"nothing\") -> \\(new ?? \"nothing\")\")\n    }\n}\nprint(\"by position: \\(byPosition.count) change(s)\")\nbyPosition.forEach { print($0) }\n", "note": "The same question asked by position: row 0 was this and is now that. This is what a list keyed by offset has to conclude."}]}
```

```
ana@vm:~/rows$ swift diff.swift
by id: 1 change(s)
  insert "Mobile, offline" at 0
by position: 5 change(s)
  row 0: SQL, joins -> Mobile, offline
  row 1: Mobile, lifecycle -> SQL, joins
  row 2: SQL, indexes -> Mobile, lifecycle
  row 3: SQL, views -> SQL, indexes
  row 4: nothing -> SQL, views
```

**One change by id, five by position, for the same edit.** By id, a row was inserted at 0 and the
four others are the rows they were, so SwiftUI can slide them down and redraw nothing in them. By
position, every row's content changed, and the last row is new: each of the five is rebuilt, and no
row animates, because as far as identity goes nothing moved.

The rest of a list's speed is in the rows themselves, and four habits cover most of it. Apple's
WWDC session *Demystify SwiftUI performance*, from 2023, is where they are argued at length; none
of them was measured for this course.

- **Keep `body` cheap.** No sorting, filtering or date formatting of the whole plan inside a row's
  `body`; do it once, above the list, or in the model.
- **Pass a row what it draws.** A row that takes a `StudySession` redraws when that session changes.
  A row that takes the whole model and reads `model.plan` redraws when anything in the plan changes,
  which lesson 7 section 03 measured.
- **Keep ids stable across loads.** An id made fresh each time data arrives, `UUID()` in a decoder,
  makes every row new on every refresh. Lesson 12's ids come from the server for this reason.
- **Measure before changing anything,** on a device. Instruments' SwiftUI template, section 07,
  counts how often each view's `body` runs; a slow list is found there and not by guessing.
