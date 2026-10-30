---
title: Numbers and dates, the two kinds of typing that go wrong
version: 1
---

**Minutes and a date are the two fields of `SessionForm`, and each fails in a way the other does not.**
The minutes fail loudly: somebody types a word, or a decimal, and the draft says so. The date fails
silently: the picker always holds a valid moment, and the mistake is in which day that moment is
taken to be.

## The day a moment falls on

A `DatePicker` binds to a `Date`, and Apple's documentation for `Date` is plain about what that is: a
point in time, with no calendar and no time zone. A picker showing only the date still hands over an
instant, the start of the day or the time it held before, in the phone's own zone. Lesson 1 stores a
session's day as text, `2026-10-21`, so somewhere the instant has to become a day, and **the calendar
that does it has to be the one the person was looking at**.

Lesson 1's `mondayOf` pins a calendar to UTC, and that is right there: it reads a day that is already
text. Reading a picked instant in UTC is the mistake. This program shows both, and then puts seven
things a person might type through the draft. Save it as `Sources/draft/main.swift`:

```swift
// Sources/draft/main.swift
import Foundation
import PlannerCore

var saoPaulo = Calendar(identifier: .gregorian)
saoPaulo.timeZone = TimeZone(identifier: "America/Sao_Paulo")!
var utc = Calendar(identifier: .gregorian)
utc.timeZone = TimeZone(identifier: "UTC")!

// 23:30 on Wednesday 21 October in São Paulo, as a DatePicker hands it over
let picked = ISO8601DateFormatter().date(from: "2026-10-21T23:30:00-03:00")!
print("instant      ", picked)
print("São Paulo day", day(of: picked, in: saoPaulo))
print("UTC day      ", day(of: picked, in: utc))

for typed in ["45", " 45 ", "", "forty", "1.5", "0", "600"] {
    let draft = SessionDraft(courseID: "sql", date: picked, minutesText: typed)
    let result = draft.session(id: "s6", calendar: saoPaulo).map { "\($0.date) \($0.minutes) min" }
    print("\"\(typed)\"".padding(toLength: 9, withPad: " ", startingAt: 0), draft.problems, result ?? "no session")
}
```

Build it and run it:

```
ana@vm:~/l10$ swift build
Building for debugging...
[Pre-planning 1 / 124]
Build complete! (0.63 secs)
ana@vm:~/l10$ .build/debug/draft
instant       2026-10-22 02:30:00 +0000
São Paulo day 2026-10-21
UTC day       2026-10-22
"45"      [] 2026-10-21 45 min
" 45 "    [] 2026-10-21 45 min
""        [PlannerCore.DraftProblem.noMinutes] no session
"forty"   [PlannerCore.DraftProblem.minutesNotWhole("forty")] no session
"1.5"     [PlannerCore.DraftProblem.minutesNotWhole("1.5")] no session
"0"       [PlannerCore.DraftProblem.minutesOutOfRange(0)] no session
"600"     [PlannerCore.DraftProblem.minutesOutOfRange(600)] no session
```

**Half past eleven on Wednesday night in São Paulo is already Thursday in UTC.** The instant is the
same one, printed by `print` in UTC as `02:30:00 +0000` on the 22nd; read in the person's calendar it
is the 21st, which is the day they picked. A planner that used UTC here would file every late-evening
session under tomorrow, for everybody west of Greenwich, and only after nine at night in São Paulo, so
nobody testing at lunchtime would see it. In the app the calendar is `Calendar.current`, which follows
the phone's settings; the program names São Paulo so that its output does not depend on the machine
it runs on.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l10-day\" aria-label=\"Two timelines, one above the other, covering the evening of 21 October to the morning of 22 October. The upper one is the São Paulo calendar, whose midnight falls three hours later than the lower one, the UTC calendar. A vertical line marks one instant, 23:30 in São Paulo, which is 02:30 in UTC: on the upper line it falls in the day 2026-10-21, on the lower line in 2026-10-22.\"><defs><marker id=\"l10-day-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l10-day-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-day-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l10-day-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">São Paulo calendar</text><rect x=\"40\" y=\"42\" width=\"360\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"220.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">2026-10-21</text><rect x=\"400\" y=\"42\" width=\"280\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">2026-10-22</text><text x=\"406\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">midnight</text><text x=\"40\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">UTC calendar</text><rect x=\"40\" y=\"144\" width=\"240\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"160.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">2026-10-21</text><rect x=\"280\" y=\"144\" width=\"400\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"480.0\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">2026-10-22</text><text x=\"280\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">midnight</text><path d=\"M380.0 30 L380.0 40\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M380.0 86 L380.0 140\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M380.0 188 L380.0 206\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"380.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">the picked instant: 23:30 here, 02:30 UTC</text></svg>", "caption": "One instant, two calendars. Read in the calendar the person was looking at, it is the day they picked; read in UTC, it is the next one."}
```

## What `Int` accepts

The minutes column is the draft's rules made visible:

- ` 45 ` is accepted, because the draft trims spaces first. A keyboard's autocorrection puts a space
  after a word more often than anybody notices.
- `forty` and `1.5` are both `minutesNotWhole`: `Int` reads digits and nothing else, so a decimal is
  refused rather than rounded. Rounding would turn a mistyped `1.5` hours into two minutes.
- `0` and `600` are numbers, and out of range, which is a different message.
- the empty field is `noMinutes`, not `minutesNotWhole("")`: "enter the minutes" is a kinder thing to
  say than "that is not a number" to somebody who has not typed yet.

**`Int` does not read a localised number**, and for minutes that is fine: nobody writes thousands of
minutes with a separator. For a field that does need it, Foundation's `IntegerFormatStyle` parses text
the way the person's locale writes it, and section 03's `TextField(value:format:)` uses that kind of
style.
