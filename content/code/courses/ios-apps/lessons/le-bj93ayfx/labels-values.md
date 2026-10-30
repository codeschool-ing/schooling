---
title: A label says what it is, a value says how it is
version: 1
---

**VoiceOver reads the screen aloud, one element at a time, and what it says for each element is
something the app decides.** SwiftUI gives every control a sensible default from what it can see:
a `Text` is read as its string, a `Button` as its title followed by *button*. What it cannot see is
meaning. A row that draws `SQL Databases`, `50`, `min` and a tick mark is four things to the eye
and, read in order with no help, four fragments to the ear. This lesson's SwiftUI was not run for
the course; it is written from Apple's documentation for SwiftUI's accessibility modifiers, read on
30 October 2026. The text the planner gives VoiceOver is plain Swift, and that part ran.

Three pieces of text describe an element, and they are not interchangeable:

| | what it answers | for a session row |
|---|---|---|
| **label** | what is this? | `SQL Databases, 50 minutes, Monday 19 October` |
| **value** | what state is it in? | `done` |
| **hint** | what happens if I act on it? | `Double-tap to mark as done` |

The commonest mistake is to put the state in the label. **A label is read every time the element is
reached; a value is what changes.** Keep them apart and VoiceOver announces a change of value on its
own, and a person moving down a list hears the course first, which is what they are scanning for.
A hint is read after a pause, and people who know the app turn hints off; anything the person must
hear goes in the label.

## The words, as plain Swift

The sentence VoiceOver says is a function of the session, so it belongs in the package, where a test
can hold it. A day read aloud is `Monday 19 October`, not `2026-10-19`: VoiceOver would read the
digits. Copy lesson 1's package with `cp -r ~/planner ~/l19`, and save this as
`Sources/PlannerCore/SpokenLabels.swift` in the copy:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/SpokenLabels.swift", "parts": [{"code": "// Sources/PlannerCore/SpokenLabels.swift\nimport Foundation\n\n/// \"2026-10-19\" as \"Monday 19 October\", the way a voice reads a day.\npublic func spokenDay(_ day: String, locale: Locale = Locale(identifier: \"en_GB\")) -> String {\n    let parse = DateFormatter()\n    parse.calendar = Calendar(identifier: .gregorian)\n    parse.timeZone = TimeZone(identifier: \"UTC\")\n    parse.locale = Locale(identifier: \"en_US_POSIX\")\n    parse.dateFormat = \"yyyy-MM-dd\"\n    guard let date = parse.date(from: day) else { return day }\n    let say = DateFormatter()\n    say.timeZone = parse.timeZone\n    say.locale = locale\n    say.setLocalizedDateFormatFromTemplate(\"EEEEdMMMM\")\n    return say.string(from: date)\n}\n", "note": "Two formatters: one reads the stored day in a fixed, locale-free format, and the other writes it the way the reader's language says a date. `setLocalizedDateFormatFromTemplate` picks the order and the commas for the locale, so Portuguese gets its own. A day that does not parse is read as it is rather than dropped."}, {"code": "extension StudySession {\n    /// What the row is: the course, the length and the day.\n    public func spokenLabel(courseTitle: String) -> String {\n        let length = minutes == 1 ? \"1 minute\" : \"\\(minutes) minutes\"\n        return \"\\(courseTitle), \\(length), \\(spokenDay(date))\"\n    }\n\n    /// How the row is: the one thing that changes.\n    public var spokenValue: String { done ? \"done\" : \"not done\" }\n}\n", "note": "The label never mentions done, and the value is nothing else. `min` becomes `minutes`, because an abbreviation that is obvious on a screen is read letter by letter or as a word that is not one. A real app translates these strings like any other text it shows, through its string catalogue."}]}
```

And a test that pins what a person hears. Save it as `Tests/PlannerCoreTests/SpokenLabelTests.swift`:

```swift
// Tests/PlannerCoreTests/SpokenLabelTests.swift
import Foundation
import Testing
@testable import PlannerCore

@Test func aRowIsReadAsOneSentence() {
    let s = StudySession(id: "s1", courseID: "sql", date: "2026-10-19", minutes: 50, done: true)
    #expect(s.spokenLabel(courseTitle: "SQL Databases") == "SQL Databases, 50 minutes, Monday 19 October")
    #expect(s.spokenValue == "done")
}

@Test func oneMinuteIsSingular() {
    let s = StudySession(id: "s9", courseID: "sql", date: "2026-10-25", minutes: 1)
    #expect(s.spokenLabel(courseTitle: "SQL Databases").hasSuffix("1 minute, Sunday 25 October"))
    #expect(s.spokenValue == "not done")
}

@Test func theDayFollowsTheLanguage() {
    #expect(spokenDay("2026-10-19", locale: Locale(identifier: "pt_BR")) == "segunda-feira, 19 de outubro")
}
```

```
ana@vm:~/l19$ swift test 2>&1 | grep -E "^(✔|✘|◇ Test run|Expectation)|passed after|failed after"
◇ Test run started.
✔ Test aSessionForNoCourseIsRefused() passed after 0.001 seconds.
✔ Test mondayIsTheStartOfTheWeek() passed after 0.001 seconds.
✔ Test oneMinuteIsSingular() passed after 0.005 seconds.
✔ Test aRowIsReadAsOneSentence() passed after 0.005 seconds.
✔ Test theDayFollowsTheLanguage() passed after 0.005 seconds.
✔ Test run with 5 tests in 0 suites passed after 0.005 seconds.
```

Lesson 1's two tests run beside the three new ones. **The Portuguese line is the reason the day is formatted rather than assembled.** Concatenating
`Monday` and `19` and `October` would give a Portuguese reader `segunda-feira 19 outubro`; the
formatter knows the language puts *de* in front of the month.

## The SwiftUI half

The row gives VoiceOver those strings. This was not run:

```swift
// SessionRow.swift
import SwiftUI
import PlannerCore

struct SessionRow: View {
    let session: StudySession
    let courseTitle: String

    var body: some View {
        HStack {
            Text(courseTitle)
            Spacer()
            Text("\(session.minutes) min")
            Image(systemName: session.done ? "checkmark.circle.fill" : "circle")
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(session.spokenLabel(courseTitle: courseTitle))
        .accessibilityValue(session.spokenValue)
    }
}
```

`accessibilityElement(children: .ignore)` makes the row one element and drops what its children
would have said; section 04 is about that choice and its two alternatives.
