---
title: Work that has to happen even if the app is gone
version: 1
---

**Some work must finish whether or not the student is still looking at the app.** The planner keeps
sessions on the phone, and lessons 13 and 16 send them to a server. If the student adds a session on the
underground with no signal, closes the app and puts the phone away, the sending still has to happen
some time later, when there is a network, with nobody watching.

The first idea most people have is a coroutine. Lesson 11 launched work in `viewModelScope`, and it
runs on a background thread, so it looks like background work. **It is not.** A coroutine lives in
the app's process, and the process is the system's to end: when the student swipes the app away,
when the phone needs memory for the camera, or at any moment after the app leaves the screen. When
the process ends, every coroutine in it ends too, half-finished, and nothing remembers it was
running. `mobile-fundamentals` lesson 15 describes the rules each platform applies; this lesson is
the Android tool that lives with them.

## What WorkManager does instead

WorkManager is the `androidx` library for **work that must be guaranteed to run eventually**. You
describe the work and the conditions it needs, and WorkManager writes that description into a small
SQLite database of its own, inside the app's private storage. Then it hands the timing to the system's
job scheduler, the part of Android that decides when apps may do background work. The process can
die at any moment after that and nothing is lost: the request is on disk, and the system knows it is
waiting.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l18-survive\" aria-label=\"Three lanes over time. In the app's process, the app calls enqueue, and WorkManager saves the request in its own database and registers a job with the system's scheduler. Then the process is killed. Later the network comes back, the system starts the process again, and WorkManager reads the request from its database and calls doWork, and saves the result.\"><defs><marker id=\"l18-survive-ah-scan\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--scan)\"></path></marker><marker id=\"l18-survive-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"12\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">your app's</text><text x=\"12\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">process</text><text x=\"12\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">WorkManager's</text><text x=\"12\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">database</text><text x=\"12\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the system's</text><text x=\"12\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">job scheduler</text><rect x=\"150\" y=\"22\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">enqueue(request)</text><rect x=\"150\" y=\"112\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"210.0\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">request saved</text><rect x=\"300\" y=\"202\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">job registered</text><rect x=\"300\" y=\"22\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">process killed</text><rect x=\"450\" y=\"202\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"510.0\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">network is back</text><rect x=\"450\" y=\"22\" width=\"120\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"510.0\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">process started</text><rect x=\"590\" y=\"22\" width=\"115\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"647.5\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">doWork()</text><rect x=\"590\" y=\"112\" width=\"115\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"647.5\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">result saved</text><path d=\"M210 58 L210 110\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-survive-ah-wire)\"></path><path d=\"M270 130 L360 130 L360 200\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-survive-ah-wire)\"></path><path d=\"M420 220 L448 220\" stroke=\"var(--scan)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-survive-ah-scan)\"></path><path d=\"M510 202 L510 60\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-survive-ah-wire)\"></path><path d=\"M570 40 L588 40\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-survive-ah-wire)\"></path><path d=\"M647 58 L647 110\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l18-survive-ah-wire)\"></path><path d=\"M270 40 L298 40\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path></svg>", "caption": "The request lives in WorkManager's database, not in the process, so killing the process loses nothing: the system starts it again when the constraints are met."}
```

When the conditions are met (here, a network), the system starts the app's process if it is not
running, WorkManager reads its database, finds the request and runs it. The result goes back into
the same database, which is how the app finds out later what happened. The same database is why work
survives a reboot: WorkManager declares a receiver for the boot broadcast and puts its jobs back.

## What it is not for

**Not for work the student is waiting to see.** A list loading on screen belongs to the screen's
coroutine; if the student leaves, nobody needs the answer. WorkManager would make it slower and
gain nothing.

**Not for work that must happen at an exact time.** WorkManager promises that work will run, not
when: the system batches background work to save battery, and a request can wait well past the
moment it became eligible. A reminder at 19:00 sharp is an alarm, and lesson 19's notification is
what it shows.

**Not for work that must keep running while the student watches it**, such as a long download with a
progress bar. That is a foreground service, which WorkManager can start for you, and which puts a
notification on screen for as long as it runs.

What is left is exactly what the planner needs: **send the sessions, some time soon, when there is
a network, and never twice by accident.** The rest of this lesson builds that, in four pieces: a
worker that does the sending, the conditions it waits for, the rules for when it is asked twice,
and the application class that gives WorkManager its workers.

## Nothing here needs a phone, and one thing does

Every piece of this lesson is tested on your computer with `work-testing`, a library that runs
WorkManager inside a Robolectric test and lets the test say "the network is back now" or "six hours
have passed". Section 07 describes what only a real phone can show: the system killing the process,
a reboot, and the battery rules that delay work. Those steps were **not run** for this course, for
the reason lesson 1 section 02 gives.
