---
title: Status codes, and one client for every request
version: 1
---

**`URLSession` throws only when there is no answer. A `404` or a `500` is an answer, and it
arrives as success.** Section 03 showed it: the call returned a response and a body, and whether
that body is the list of courses or `{"error": "no course art"}` is for the code that reads it to
find out. Code that skips the check decodes an error message as data, and the failure surfaces
three functions later as a `DecodingError` about a key that was never going to be there.

So the planner gets one place that sends a request and turns every outcome into one of four
errors, or a value. Every later lesson calls it.

## The client

Save this as `Sources/PlannerCore/APIClient.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/APIClient.swift", "parts": [{"code": "// Sources/PlannerCore/APIClient.swift\nimport Foundation\n#if canImport(FoundationNetworking)\nimport FoundationNetworking\n#endif\n\npublic enum APIError: Error, Equatable, Sendable {\n    case offline(String)      // no answer: no network, no server, a timeout\n    case status(Int, String)  // an answer, and it was an error\n    case unreadable(String)   // a success whose body is not what was expected\n    case cancelled            // the caller stopped waiting\n}\n", "note": "Four outcomes, and a screen treats each differently: offline is worth a retry, a status is worth showing, unreadable is a bug to report, and cancelled is worth nothing at all, because nobody is waiting for it."}, {"code": "public struct APIClient: Sendable {\n    public let base: URL\n    let session: URLSession\n\n    public init(base: URL, session: URLSession = .shared) {\n        self.base = base\n        self.session = session\n    }\n", "note": "The base URL is given rather than written inside, so the same client talks to `127.0.0.1` in this course and to a real address in production, and a test can hand it a session of its own."}, {"code": "    public func courses() async throws(APIError) -> [Course] {\n        let wire: [WireCourse] = try await send(URLRequest(url: base.appending(path: \"courses\")))\n        return wire.map(\\.course)\n    }\n\n    public func sessions(course id: String) async throws(APIError) -> [StudySession] {\n        let url = base.appending(path: \"courses\").appending(path: id).appending(path: \"sessions\")\n        let wire: [WireSession] = try await send(URLRequest(url: url))\n        return wire.map(\\.session)\n    }\n\n    public func add(_ s: StudySession) async throws(APIError) -> StudySession {\n        var request = URLRequest(url: base.appending(path: \"sessions\"))\n        request.httpMethod = \"POST\"\n        request.setValue(\"application/json\", forHTTPHeaderField: \"Content-Type\")\n        request.httpBody = try? JSONEncoder().encode(WireSession(s))\n        let wire: WireSession = try await send(request)\n        return wire.session\n    }\n", "note": "The three requests the planner makes. Each says what it sends and what type comes back, and leaves everything else to `send`. `appending(path:)` escapes what it is given, so a course id with a space in it cannot change the path."}, {"code": "    func send<T: Decodable>(_ request: URLRequest) async throws(APIError) -> T {\n        let data: Data, response: URLResponse\n        do {\n            (data, response) = try await session.data(for: request)\n        } catch let error as URLError where error.code == .cancelled {\n            throw .cancelled\n        } catch is CancellationError {\n            throw .cancelled\n        } catch let error as URLError {\n            throw .offline(\"\\(error.code)\")\n        } catch {\n            throw .offline(\"\\(error)\")\n        }\n", "note": "The first stage: was there an answer at all? Cancelling arrives in two shapes, a `URLError` with code `cancelled` when a request in flight is stopped, and a `CancellationError` when the task was cancelled before it got that far. Both mean the same thing to a screen."}, {"code": "        guard let http = response as? HTTPURLResponse else { throw .offline(\"not HTTP\") }\n        guard (200..<300).contains(http.statusCode) else {\n            let message = (try? JSONDecoder().decode([String: String].self, from: data))?[\"error\"]\n            throw .status(http.statusCode, message ?? \"\")\n        }\n", "note": "The second stage: an answer, but was it a success? Anything outside 200 to 299 is an error, and the planner's server puts a sentence in `error` that is worth keeping. A server that sends no such body leaves the message empty rather than failing a second time."}, {"code": "        do {\n            return try JSONDecoder().decode(T.self, from: data)\n        } catch {\n            throw .unreadable(\"\\(error)\")\n        }\n    }\n}\n", "note": "The third stage: a success, in the shape the type expects? Only now is the body decoded, so a `DecodingError` here really is a mismatch between two programs, and never an error page read as data."}]}
```

**Three stages, in that order, and each one only runs if the last one passed.** That order is the
whole design. Decode first and an error page becomes a decoding error; check the status after
decoding and a `500` with an empty body becomes the same; skip the first stage and a phone with
no signal shows "unreadable answer".

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l12-stages\" aria-label=\"A request goes through three checks from left to right. First: was there an answer at all? If not, the error is offline, or cancelled if the caller stopped waiting. Second: is the status between 200 and 299? If not, the error is status with the code and the server&#x27;s message. Third: does the body decode as the expected type? If not, the error is unreadable. Only a request that passes all three becomes a value.\"><defs><marker id=\"l12-stages-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l12-stages-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-stages-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l12-stages-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"40\" width=\"96\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"64\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">request</text><rect x=\"150\" y=\"40\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"210\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">an answer?</text><text x=\"210\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stage 1</text><path d=\"M112 65 L148 65\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-stages-ah-wire)\"></path><path d=\"M210 92 L210 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-stages-ah-amber)\"></path><text x=\"224\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no</text><rect x=\"138\" y=\"160\" width=\"144\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"210\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">.offline / .cancelled</text><rect x=\"300\" y=\"40\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">200 to 299?</text><text x=\"360\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stage 2</text><path d=\"M270 65 L298 65\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-stages-ah-wire)\"></path><path d=\"M360 92 L360 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-stages-ah-amber)\"></path><text x=\"374\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no</text><rect x=\"288\" y=\"160\" width=\"144\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">.status(code, msg)</text><rect x=\"450\" y=\"40\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"510\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">decodes as T?</text><text x=\"510\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stage 3</text><path d=\"M420 65 L448 65\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-stages-ah-wire)\"></path><path d=\"M510 92 L510 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-stages-ah-amber)\"></path><text x=\"524\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no</text><rect x=\"438\" y=\"160\" width=\"144\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"510\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">.unreadable</text><path d=\"M570 65 L608 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-stages-ah-phosphor)\"></path><rect x=\"610\" y=\"40\" width=\"94\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"657\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">a value</text><text x=\"657\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">of type T</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">every outcome leaves as exactly one of these</text></svg>", "caption": "The order is the design: an answer before a status, a status before a decoding. A request reaches the value on the right only by passing all three."}
```

## Every outcome, once

Replace `Sources/fetch/main.swift` with a program that asks for one thing of each kind:

```swift
// Sources/fetch/main.swift
import Foundation
import PlannerCore

let api = APIClient(base: URL(string: "http://127.0.0.1:8012")!)
let nowhere = APIClient(base: URL(string: "http://127.0.0.1:8099")!)

do {
    for c in try await api.courses() { print("course", c.id, c.title) }
    print("sql", try await api.sessions(course: "sql").map(\.id))
    print("posted", try await api.add(StudySession(id: "s5", courseID: "mobile", date: "2026-10-22", minutes: 30)).id)
} catch {
    print("unexpected:", error)
}

let failures: [(String, () async throws(APIError) -> Void)] = [
    ("no such course", { () async throws(APIError) in
        _ = try await api.sessions(course: "art")
    }),
    ("post for no course", { () async throws(APIError) in
        _ = try await api.add(StudySession(id: "s6", courseID: "art", date: "2026-10-22", minutes: 30))
    }),
    ("no server", { () async throws(APIError) in
        _ = try await nowhere.courses()
    }),
]
for (name, attempt) in failures {
    do throws(APIError) {
        try await attempt()
    } catch {
        print(name, "->", error)
    }
}
```

`8099` is a port nothing listens on, which is what "the server is down" looks like from the
client. **A closure says its error type out loud**, `() async throws(APIError) in`, because the
compiler infers `any Error` for a closure that does not, and then refuses to put it in a list of
closures that throw `APIError`. `do throws(APIError)` does the same for the `catch`, so `error` there
has that type and not `any Error`.

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (1.77 secs)
ana@vm:~/planner$ .build/debug/fetch
course sql SQL Databases
course mobile Mobile Fundamentals
sql ["s1", "s3"]
posted s5
no such course -> status(404, "no course art")
post for no course -> status(422, "no course art")
no server -> offline("cannotConnectToHost")
```

The first three lines are the successes, and the post came back with the id it was given. Then
**two answers that were errors, and one that was no answer at all.** The server's own sentence
travelled all the way into the `status` case. `cannotConnectToHost` is the `URLError` code for a
refused connection, and a phone in a tunnel would print `notConnectedToInternet` or `timedOut`
instead, all three caught by the same `offline` case.

The server's terminal logged the same three requests from its side, `404`, `422` and nothing at
all for the third, which never reached it.
