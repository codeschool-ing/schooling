---
title: The error state is a screen too
version: 1
---

**A screen that loads something has at least three states, and the one most apps forget to draw
is the third.** While the request is out, the screen is loading. When it comes back, the screen
has the courses. And when it does not, the screen has an error, and the person holding the phone
has to be told something they can act on. An app that draws only the first two shows a spinner
for ever, or an empty list that looks exactly like a planner with no courses in it.

The fix is to make the three states one type, so that a screen cannot hold "loading" and "an error"
at the same time, and so that the compiler insists every state is drawn.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l12-states\" aria-label=\"Three states of a screen. It starts in loading. From loading it goes either to loaded, with the courses, or to failed, with an APIError. From failed, an arrow labelled try again goes back to loading, and it is drawn only when the error can be retried.\"><defs><marker id=\"l12-states-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l12-states-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-states-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l12-states-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"60\" y=\"80\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"135\" y=\"102\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">.loading</text><text x=\"135\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the request is out</text><rect x=\"470\" y=\"20\" width=\"190\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"565\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">.loaded(courses)</text><text x=\"565\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">draw the list</text><rect x=\"470\" y=\"140\" width=\"190\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"565\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">.failed(error)</text><text x=\"565\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">draw the message</text><path d=\"M212 98 L466 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-states-ah-phosphor)\"></path><path d=\"M212 122 L466 168\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-states-ah-amber)\"></path><path d=\"M470 192 C 330 228, 200 214, 140 144\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-states-ah-paper-dim)\"></path><text x=\"320\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">try again, if canRetry</text></svg>", "caption": "One value, three states that exclude each other. The way back from an error exists only where trying again can give a different answer."}
```

## Three states, one value

Save this as `Sources/PlannerCore/Loadable.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/Loadable.swift", "parts": [{"code": "// Sources/PlannerCore/Loadable.swift\npublic enum Loadable<Value: Sendable>: Sendable {\n    case loading\n    case loaded(Value)\n    case failed(APIError)\n\n    public static func run(_ work: () async throws(APIError) -> Value) async -> Loadable {\n        do throws(APIError) {\n            return .loaded(try await work())\n        } catch {\n            return .failed(error)\n        }\n    }\n}\n\nextension Loadable: Equatable where Value: Equatable {}\n", "note": "An enum, because the three states exclude each other. `run` does the work and folds the outcome into a state: whatever happens, a `Loadable` comes back, and a screen has something to draw."}, {"code": "extension APIError {\n    /// The sentence a screen shows.\n    public var message: String {\n        switch self {\n        case .offline: \"You are offline, or the planner's server is not answering.\"\n        case .status(404, _): \"That is not in the planner any more.\"\n        case .status(let code, let detail): \"The server answered \\(code). \\(detail)\"\n        case .unreadable: \"The server's answer could not be read. This is a bug in the app.\"\n        case .cancelled: \"\"\n        }\n    }\n", "note": "Each error says what happened in words the person can use. A `404` for a course means it was deleted somewhere else; a `500` is the server's fault and says so; an unreadable answer is ours, and saying so is more honest than \"something went wrong\"."}, {"code": "    /// Whether trying again could give a different answer.\n    public var canRetry: Bool {\n        switch self {\n        case .offline: true\n        case .status(let code, _): code >= 500\n        case .unreadable, .cancelled: false\n        }\n    }\n}\n", "note": "A retry button only where a retry can work. Asking again for a course that is gone gives the same `404`, and asking again for an answer the app cannot read gives the same bug."}]}
```

`cancelled` has an empty message on purpose. A load is cancelled when the screen that started it
has gone, so there is nobody to show anything to; section 07 is about that case.

## Drawing it, on a Mac

This is `CourseListView` with the three states drawn. It was written from Apple's documentation for
`ProgressView`, `List` and `ContentUnavailableView`, which iOS 17 introduced for exactly this
screen, and **it was not run**:

```swift
// CourseListView.swift
import SwiftUI
import PlannerCore

struct CourseListView: View {
    let api: APIClient
    @State private var state: Loadable<[Course]> = .loading

    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView()
            case .loaded(let courses):
                List(courses) { course in
                    Text(course.title)
                }
            case .failed(let error):
                ContentUnavailableView {
                    Label("No courses", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error.message)
                } actions: {
                    if error.canRetry {
                        Button("Try again") { Task { await load() } }
                    }
                }
            }
        }
        .task { await load() }
    }

    func load() async {
        state = .loading
        state = await .run { () async throws(APIError) in try await api.courses() }
    }
}
```

**The `switch` is the guarantee.** Add a fourth case to `Loadable` and this view stops compiling
until it draws it, which is the compiler doing the job a checklist would otherwise do.

## The states, without the screen

What the view draws is decided entirely by the `Loadable` it holds, and that part runs anywhere.
Replace `Sources/fetch/main.swift` with a program that produces each state and prints what the
screen would say:

```swift
// Sources/fetch/main.swift
import Foundation
import PlannerCore

let api = APIClient(base: URL(string: "http://127.0.0.1:8012")!)
let broken = APIClient(base: URL(string: "http://127.0.0.1:8012/?fail")!)
let nowhere = APIClient(base: URL(string: "http://127.0.0.1:8099")!)

let attempts: [(String, () async throws(APIError) -> [Course])] = [
    ("working server", { () async throws(APIError) in try await api.courses() }),
    ("failing server", { () async throws(APIError) in try await broken.courses() }),
    ("no server", { () async throws(APIError) in try await nowhere.courses() }),
]
for (name, work) in attempts {
    switch await Loadable.run(work) {
    case .loading:
        print(name, "-> still loading")
    case .loaded(let courses):
        print(name, "-> \(courses.count) courses")
    case .failed(let error):
        print(name, "-> \(error.message) retry: \(error.canRetry)")
    }
}
```

`?fail` on the base URL is the server's switch from section 02, carried onto every path the client
appends:

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (2.31 secs)
ana@vm:~/planner$ .build/debug/fetch
working server -> 2 courses
failing server -> The server answered 500. The server failed on purpose. retry: true
no server -> You are offline, or the planner's server is not answering. retry: true
```

**The failing server and the missing server read differently, and both offer a retry**, because
both can be fixed by waiting. `Loadable.run` never threw, in all three: whatever came back, the
screen got a state to draw.
