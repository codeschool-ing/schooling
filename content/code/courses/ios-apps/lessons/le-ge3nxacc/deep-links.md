---
title: Deep links, parsed and tested
version: 1
---

**A deep link is a URL that opens the app on a particular screen**, and with the path as an array of
routes, handling one is turning a URL into an array. `planner://course/sql/session/s3` asks for the
SQL course with session `s3` on top. An app declares the `planner` scheme in its target's *URL
Types*, and SwiftUI hands each URL to an `onOpenURL` closure. Neither was run; they are written from
Apple's documentation for `onOpenURL(perform:)` and *Defining a custom URL scheme for your app*.

```swift
// in CourseListView's body, on the NavigationStack
.onOpenURL { url in
    guard let asked = Route.path(from: url) else { return }
    model.path = Route.stillValid(asked, in: model.plan)
}
```

**A link comes from outside the app, so it is input, and input is checked.** Anybody can type a URL
with your scheme into a browser or put one in a message, and section 05's `stillValid` is the second
check. The first is the parser, which refuses anything that is not exactly a sequence of kind and
value. Save it as `Sources/PlannerCore/RouteLinks.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/RouteLinks.swift", "parts": [{"code": "// Sources/PlannerCore/RouteLinks.swift\nimport Foundation\n\nextension Route {\n    /// The path a link such as planner://course/sql/session/s3 asks for, or nil.\n    public static func path(from url: URL) -> [Route]? {\n        guard url.scheme == \"planner\", let host = url.host() else { return nil }\n        var words = [host] + url.pathComponents.filter { $0 != \"/\" }\n", "note": "In `planner://course/sql/session/s3` the host is `course` and the path is `/sql/session/s3`. Joining them gives the words `course`, `sql`, `session`, `s3`. Any other scheme is refused before anything else is read."}, {"code": "        var path: [Route] = []\n        while words.count >= 2 {\n            let kind = words.removeFirst(), value = words.removeFirst()\n            switch kind {\n            case \"course\": path.append(.course(id: value))\n            case \"session\": path.append(.session(id: value))\n            case \"week\": path.append(.week(day: value))\n            default: return nil\n            }\n        }\n        return words.isEmpty && !path.isEmpty ? path : nil\n    }\n}\n", "note": "Words are read in pairs. A kind the planner does not have refuses the whole link, and so does a word left over at the end, which is a link that was cut short. Refusing is `nil`, and the caller's `guard` leaves the app where it was."}]}
```

The tests say what the parser accepts and what it refuses. Save them as
`Tests/PlannerCoreTests/RouteLinkTests.swift`:

```swift
// Tests/PlannerCoreTests/RouteLinkTests.swift
import Foundation
import Testing
@testable import PlannerCore

@Test func aSessionLinkOpensItsCourseFirst() {
    let url = URL(string: "planner://course/sql/session/s3")!
    #expect(Route.path(from: url) == [.course(id: "sql"), .session(id: "s3")])
}

@Test func aWeekLinkOpensTheWeek() {
    let url = URL(string: "planner://week/2026-10-19")!
    #expect(Route.path(from: url) == [.week(day: "2026-10-19")])
}

@Test(arguments: [
    "planner://course/sql/session",
    "planner://teacher/ana",
    "https://example.com/course/sql",
])
func aLinkThatIsNotARouteIsRefused(link: String) {
    #expect(Route.path(from: URL(string: link)!) == nil)
}
```

```
ana@vm:~/navigate$ swift test --filter Link
Building for debugging...
[Constructing description]
[Planning deferred tasks]
Build complete! (0.69 secs)
◇ Test run started.
↳ Testing Library Version: 6.4.2 (288a2328ff84644)
↳ Target Platform: x86_64-unknown-linux-gnu
◇ Test aLinkThatIsNotARouteIsRefused(link:) started.
◇ Test aSessionLinkOpensItsCourseFirst() started.
◇ Test aWeekLinkOpensTheWeek() started.
◇ Test case passing 1 argument link → "planner://course/sql/session" to aLinkThatIsNotARouteIsRefused(link:) started.
◇ Test case passing 1 argument link → "planner://teacher/ana" to aLinkThatIsNotARouteIsRefused(link:) started.
◇ Test case passing 1 argument link → "https://example.com/course/sql" to aLinkThatIsNotARouteIsRefused(link:) started.
✔ Test aSessionLinkOpensItsCourseFirst() passed after 0.001 seconds.
✔ Test aWeekLinkOpensTheWeek() passed after 0.001 seconds.
✔ Test aLinkThatIsNotARouteIsRefused(link:) with 3 test cases passed after 0.001 seconds.
✔ Test run with 3 tests in 0 suites passed after 0.001 seconds.
```

**`@Test(arguments:)` runs one test once per argument**, and the report names each run by its
argument. The three refused links are a link cut short, a kind the planner has no screen for, and a
web address that merely looks similar. Lesson 20 is about parameterised tests in general.

A link with the `https` scheme that opens the app instead of Safari is a **universal link**, and it
needs the website to publish a file naming the app, which Apple's documentation on supporting
associated domains describes. It was not set up for this course: it needs a domain and a signed app,
lesson 21.
