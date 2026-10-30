---
title: async let, two things at once
version: 1
---

Each `await` in section 03 waited for the call before it, because the sessions of a course need the
course. **Work that does not depend on other work should not wait for it.** The planner loads three
courses' minutes for the week's summary, and none of the three needs another's answer:

```swift
// Week.swift
func loadMinutes(for course: String) async -> Int {
    try? await Task.sleep(for: .milliseconds(300))
    return course.count * 10
}

func milliseconds(_ d: Duration) -> Int64 {
    d.components.seconds * 1000 + d.components.attoseconds / 1_000_000_000_000_000
}

let clock = ContinuousClock()

var start = clock.now
let a = await loadMinutes(for: "Swift")
let b = await loadMinutes(for: "Kotlin")
let c = await loadMinutes(for: "SQL")
print("one after another:", a + b + c, "minutes in", milliseconds(clock.now - start), "ms")

start = clock.now
async let x = loadMinutes(for: "Swift")
async let y = loadMinutes(for: "Kotlin")
async let z = loadMinutes(for: "SQL")
let total = await x + y + z
print("all three at once:", total, "minutes in", milliseconds(clock.now - start), "ms")
```

```
ana@vm:~/sw/l14$ swift Week.swift
one after another: 140 minutes in 901 ms
all three at once: 140 minutes in 300 ms
```

Same three calls, same total, and a third of the time. **`async let` starts the call and does not
wait for it**; the line finishes at once and `x` is a value that will exist later. The program waits
only at `await x + y + z`, where it needs all three. By then the three loads had been running side by
side for 300 milliseconds and finished together.

`ContinuousClock` measures elapsed time, and `clock.now - start` is a `Duration`. The small function
`milliseconds` turns it into a whole number of milliseconds, because a `Duration` printed directly
shows nine decimal places of a second. The few milliseconds over 900 and 300 are the cost of
starting and switching tasks, and they differ from run to run; the ratio does not.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 285\" role=\"img\" data-fig=\"l14-async-let\" aria-label=\"Two timelines on one axis from 0 to 900 milliseconds. Above, three awaited loads of 300 milliseconds each run one after another and end at 901 milliseconds. Below, three async let loads start together and all end at 300 milliseconds, where a single await collects them.\"><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">one after another</text><text x=\"20\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">all three at once</text><rect x=\"170.0\" y=\"50\" width=\"161.0\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"250.5\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loadMinutes(\"Swift\")</text><rect x=\"335.0\" y=\"50\" width=\"161.0\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"415.5\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loadMinutes(\"Kotlin\")</text><rect x=\"500.0\" y=\"50\" width=\"161.0\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"580.5\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loadMinutes(\"SQL\")</text><text x=\"158\" y=\"64\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">await ×3</text><rect x=\"170\" y=\"145\" width=\"161.0\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250.5\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loadMinutes(\"Swift\")</text><text x=\"158\" y=\"157\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">async let x</text><rect x=\"170\" y=\"175\" width=\"161.0\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250.5\" y=\"187\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loadMinutes(\"Kotlin\")</text><text x=\"158\" y=\"187\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">async let y</text><rect x=\"170\" y=\"205\" width=\"161.0\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250.5\" y=\"217\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">loadMinutes(\"SQL\")</text><text x=\"158\" y=\"217\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">async let z</text><path d=\"M335.0 138 L335.0 234\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"343.0\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">await x + y + z</text><text x=\"343.0\" y=\"203\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper)\">waits once, for all three</text><path d=\"M170 262 L665.0 262\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M170.0 258 L170.0 266\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"170.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 ms</text><path d=\"M335.0 258 L335.0 266\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"335.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">300 ms</text><path d=\"M500.0 258 L500.0 266\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"500.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">600 ms</text><path d=\"M665.0 258 L665.0 266\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"665.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">900 ms</text><text x=\"665.0\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">901 ms measured</text><text x=\"665.0\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">300 ms measured</text></svg>", "caption": "The same three loads of section 05: awaited one at a time they add up, started with async let they overlap."}
```

## Child tasks, and what the scope promises

Each `async let` creates a **child task** of the code it is written in. A child task cannot outlive
its scope: if the scope ends without awaiting one, Swift cancels it and waits for it there. So the
`Forgotten.swift` of section 04 cannot happen with `async let`. Every child task either delivered its
value or was cancelled and waited for before the line after its scope ran.

That is the meaning of **structured concurrency**: the tasks form a tree that follows the shape of the
code, and a function's children are done when the function returns. Section 07 uses the same tree to
cancel work, from the top.

## When async let is the wrong tool

`async let` needs the number of tasks when you write the code: three names, three tasks. A list of
courses whose length you learn while the program runs needs a different construction, a **task
group**, which is section 06.
