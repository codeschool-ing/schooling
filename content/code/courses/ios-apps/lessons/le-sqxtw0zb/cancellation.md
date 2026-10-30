---
title: Cancelling, and waiting less
version: 1
---

**A request somebody stopped waiting for should stop.** A person opens a course, the sessions start
loading, and they go back before the answer arrives. If the request carries on, it uses the
network for nothing, and when it finishes it writes its result into a screen that has already
gone, or worse, into the one that replaced it. Swift's concurrency has a word for this, and
`URLSession` listens to it.

## Cancelling a task

A `Task` can be cancelled from outside with `cancel()`. Cancelling does not stop anything by
force: it sets a flag, and the code inside the task is expected to notice and stop. `URLSession`'s
`async` methods notice. Replace `Sources/fetch/main.swift`:

```schooling-example
{"language": "swift", "file": "Sources/fetch/main.swift", "parts": [{"code": "// Sources/fetch/main.swift\nimport Foundation\n#if canImport(FoundationNetworking)\nimport FoundationNetworking\n#endif\nimport PlannerCore\n\nlet slow = APIClient(base: URL(string: \"http://127.0.0.1:8012/?delay=3\")!)\n", "note": "`?delay=3` makes the server wait three seconds before every answer: long enough to change your mind."}, {"code": "let load = Task { try await slow.courses() }\ntry await Task.sleep(for: .milliseconds(300))\nload.cancel()\ndo {\n    print(\"loaded\", try await load.value)\n} catch {\n    print(\"cancelled task ->\", error)\n}\n", "note": "The task starts the request, the program waits 300 milliseconds and cancels it. `load.value` waits for the task to finish and hands back its result or rethrows its error. A `Task` forgets the typed throw and keeps only `any Error`, so this `catch` is untyped; printing the error still shows which case it is."}, {"code": "let config = URLSessionConfiguration.default\nconfig.timeoutIntervalForRequest = 1\nlet impatient = APIClient(base: slow.base, session: URLSession(configuration: config))\ndo throws(APIError) {\n    print(\"loaded\", try await impatient.courses())\n} catch {\n    print(\"one second ->\", error)\n}\n", "note": "The other way to stop waiting: a timeout. `timeoutIntervalForRequest` is how long the session waits for data before giving up, sixty seconds unless you set it. A session made with a configuration of its own is how a client gets a different one."}]}
```

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (1.12 secs)
ana@vm:~/planner$ .build/debug/fetch
cancelled task -> cancelled
one second -> offline("timedOut")
```

**Both requests stopped, and they stopped as two different errors.** The cancelled one is
`cancelled`, which a screen draws as nothing, because whoever asked has gone. The one that ran out
of time is `offline("timedOut")`, which a screen draws as a message with a retry button, because the
person is still there and still waiting. The client's first stage in section 05 is what turned
`URLError`'s `cancelled` code into its own case so that these two never look alike.

**Neither of them stopped the server.** The log at the end of section 02 shows the other side: both
slow requests were answered three seconds later, and both times the server found that the client
had gone. Cancelling saves the phone's battery, its data and its screen from a stale answer. It does
not undo a request that has already reached the server, which matters the day the request is a
`POST`: lesson 14 is where a write that may or may not have happened gets handled.

## In SwiftUI, the cancelling is done for you

The `task` modifier from section 03 starts its work when the view appears and **cancels it when the
view disappears**. That is the whole reason to prefer it over starting a `Task` in `onAppear`, which
nothing cancels. Its other form, `task(id:)`, cancels and starts again whenever the value changes,
which fits a screen whose content depends on a selection. This listing follows Apple's
documentation for `task(id:priority:_:)` and **was not run**:

```swift
// CourseDetailView.swift
import SwiftUI
import PlannerCore

struct CourseDetailView: View {
    let api: APIClient
    let courseID: String
    @State private var state: Loadable<[StudySession]> = .loading

    var body: some View {
        List {
            if case .loaded(let sessions) = state {
                ForEach(sessions) { s in
                    Text("\(s.date)  \(s.minutes) min")
                }
            }
        }
        .task(id: courseID) {
            state = .loading
            let loaded = await Loadable.run { () async throws(APIError) in
                try await api.sessions(course: courseID)
            }
            if case .failed(.cancelled) = loaded { return }
            state = loaded
        }
    }
}
```

The last check is the rule from section 06 made concrete: **a cancelled load writes nothing.** When
`courseID` changes, the old load is cancelled and the new one starts, and the old one must not land
its sessions on top of the new course's.
