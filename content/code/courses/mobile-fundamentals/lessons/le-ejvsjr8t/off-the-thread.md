---
title: Moving work off the main thread, in three spellings
version: 1
---

**Every platform's answer has the same three steps: hand the slow work to another thread, let the
main thread carry on drawing, and bring the result back to the main thread before it touches the
screen.** The third step is the one beginners drop. A result written to the screen from a worker
breaks Android's second rule, and Apple's toolkits make the same demand, so the way back is
as much a part of the pattern as the way out.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l06-two-threads\" aria-label=\"Two timelines. In the first, the main thread draws frames, then sorts the sessions, and no frame is drawn until the sort ends. In the second, the main thread sends go to a worker and keeps drawing a frame in every slot while the worker sorts; the worker sends the result back and the main thread shows it.\"><defs><marker id=\"l06-two-threads-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">the sort on the main thread</text><text x=\"20\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">main</text><text x=\"20\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">thread</text><rect x=\"100\" y=\"44\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"144\" y=\"44\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"164.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"188\" y=\"44\" width=\"340\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"358.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sort: no frame is drawn meanwhile</text><rect x=\"532\" y=\"44\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"552.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"576\" y=\"44\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"596.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"620\" y=\"44\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"640.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"664\" y=\"44\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"684.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><text x=\"20\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">the same sort on a worker</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">main</text><text x=\"20\" y=\"153\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">thread</text><rect x=\"100\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"144\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"164.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"188\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"208.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"232\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"252.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"276\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"296.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"320\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"340.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"364\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"384.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"408\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"428.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"452\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"472.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"496\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"516.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"540\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"560.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"584\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"604.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><rect x=\"628\" y=\"132\" width=\"40\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"648.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">frame</text><text x=\"20\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker</text><rect x=\"232\" y=\"212\" width=\"296\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sort</text><path d=\"M208 160 L208 226 L230 226\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-two-threads-ah-paper-dim)\"></path><text x=\"196\" y=\"194\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">go</text><path d=\"M530 226 L552 226 L552 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-two-threads-ah-paper-dim)\"></path><text x=\"560\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">result</text></svg>", "caption": "Moving the work does not make it faster. It makes it someone else's: the main thread keeps every slot, and only the result crosses back to it."}
```

What changes between platforms is how the hand-over is spelt. The three fragments below sort the
planner's week off the main thread and show it on the main thread. They are adapted from each
platform's documentation, and **they were not compiled or run for this course**; the frame counts
in the previous section are the evidence this lesson has, and they come from Node.js.

## Kotlin: coroutines and a dispatcher

```kotlin
// Sort on a background dispatcher; the caller resumes on the main thread
suspend fun sortedWeek(sessions: List<Session>): List<Session> =
    withContext(Dispatchers.Default) {
        sessions.sortedWith(compareBy({ it.date }, { it.minutes }))
    }

// In a ViewModel: the coroutine starts on the main thread
viewModelScope.launch {
    week = sortedWeek(sessions) // back on the main thread here
}
```

A coroutine is a function that can pause without holding its thread. **The dispatcher says which threads it runs on.** Android's documentation on coroutines names three: `Dispatchers.Main`
for the UI and quick work, `Dispatchers.IO` for disk and network, and `Dispatchers.Default` for
work that keeps the processor busy, with sorting a list and parsing JSON as its own examples.
`withContext` moves one block to another dispatcher and returns to the one it came from, so the
line after the call is on the main thread again. The `kotlin` course gives dispatchers their own
lesson, its lesson 14.

## Swift: async, await and the main actor

```swift
// Sort away from the main actor; the caller resumes on it
func sortedWeek(_ sessions: [Session]) async -> [Session] {
    await Task.detached(priority: .userInitiated) {
        sessions.sorted { ($0.date, $0.minutes) < ($1.date, $1.minutes) }
    }.value
}

@MainActor
func refresh() async {
    week = await sortedWeek(sessions) // back on the main actor here
}
```

**`@MainActor` marks code that must run on the main thread**; Apple's documentation describes the
main actor as one whose executor is the main dispatch queue. `Task.detached` starts work that
belongs to no actor, so it runs on the system's pool of threads, and `await` is the point where
`refresh` lets the main thread go and later takes it back with the result. An *actor* is the
general form of the same idea: an object whose state only one task touches at a time. The
`swift` course spends its lessons 14 and 15 on these.

## React Native: one JavaScript thread to protect

```tsx
// Sort once per change of the data, not on every render
const week = useMemo(
  () => [...sessions].sort((a, b) => a.date.localeCompare(b.date) || a.minutes - b.minutes),
  [sessions],
);

// The request waits outside the JavaScript thread; parsing the answer runs on it
useEffect(() => {
  fetch(COURSES_URL)
    .then((response) => response.json())
    .then(setCourses);
}, []);
```

**Here the thread to protect is the JavaScript thread**, and plain JavaScript has no
`withContext` to move a sort somewhere else. So the first tools are about doing less on it:
`useMemo` sorts again only when the data changes, and `fetch` does not hold the thread while the
network answers, though the JSON parse when it does answer runs on it. Work that is still too long
goes to native code. For animation, React Native's documentation points to its native driver,
`useNativeDriver: true`, which runs the animation without asking the JavaScript thread for each
frame. The `react-native` course, if you take that
route, has 60 frames a second off the JavaScript thread as its lesson 12.

## The same three steps

| step | Kotlin | Swift | React Native |
|---|---|---|---|
| hand the work off | `withContext(Dispatchers.Default)` | `Task.detached { … }` | native code, or do less on the JS thread |
| keep drawing | the main thread is free while the block runs | `await` frees the main actor | the UI thread draws; the JS thread must stay short |
| bring the result back | `withContext` returns to the caller's dispatcher | the caller is `@MainActor` | the result arrives as a callback on the JS thread |

Reading from a database on a background thread, the case where the list stutters because the rows
are fetched on the main thread, is `mobile-offline` lesson 6.
