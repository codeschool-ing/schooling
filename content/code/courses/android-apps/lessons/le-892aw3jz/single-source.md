---
title: One source of truth, and why it is the database
version: 1
---

**A screen that reads from two places shows two answers.** Picture the planner's week screen asking
the server for sessions, and the database for the ones added offline, and merging them. Every
question about that screen now has two halves: which list is newer, what happens when a request
fails halfway, why the total briefly drops while the network answers. The usual cure is a rule you
can say in one sentence, and lessons 14 and 15 built the two pieces it needs.

> **The screen reads only the database. The network only writes into the database.**

That rule is the **single source of truth**. Room is the source, because it is the one store that is
always there: offline, on a slow train, a second after the app opened. The server is where the
truth *comes from*, and it reaches the screen by one road only, through a write into Room, which
section 06 of lesson 15 showed makes every `Flow` reading that table answer again.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Three boxes. On the left, the server. In the middle, the repository, which holds refresh and add. On the right, Room, the single source of truth. Below Room, the week screen. Arrows: the server's sessions go through refresh into Room. A new session goes through add into Room first, and from there to the server. The week screen reads only from Room, through a Flow, and never from the server.\"><rect x=\"0\" y=\"0\" width=\"720\" height=\"250\" fill=\"var(--ink)\"></rect><rect x=\"20\" y=\"40\" width=\"150\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"95\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">the server</text><text x=\"95\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">where truth comes from</text><rect x=\"260\" y=\"30\" width=\"190\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"355\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">SessionRepository</text><text x=\"355\" y=\"80\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">refresh()</text><text x=\"355\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">add()</text><rect x=\"540\" y=\"40\" width=\"160\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect><text x=\"620\" y=\"70\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Room</text><text x=\"620\" y=\"92\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the single source of truth</text><rect x=\"540\" y=\"170\" width=\"160\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"620\" y=\"203\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">the week screen</text><line x1=\"172\" y1=\"60\" x2=\"256\" y2=\"60\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"214\" y=\"52\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sessions</text><line x1=\"452\" y1=\"75\" x2=\"536\" y2=\"75\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"494\" y=\"67\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">writes</text><line x1=\"620\" y1=\"112\" x2=\"620\" y2=\"166\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></line><text x=\"628\" y=\"143\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">Flow</text><line x1=\"172\" y1=\"90\" x2=\"256\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><text x=\"214\" y=\"106\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">new sessions</text><text x=\"300\" y=\"205\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">no arrow from the server to the screen</text></svg>", "caption": "The server writes into Room through the repository, and the screen reads Room alone."}
```

**The repository is the class that holds the rule.** It is the only code that knows both the DAO and
the API, and everything above it asks it for a `Flow` of sessions and calls `refresh()` or `add()`.
Nothing in a ViewModel decides whether data comes from the network: lesson 10 kept the ViewModel
free of that, and this lesson gives it something to call. Lesson 12's Hilt is how the repository
reaches the ViewModel in a real app; here the tests build it by hand, which keeps every piece in
view.

## What this lesson does not do

The full offline-first design, with a queue of pending operations, retries with backoff and
conflicts between two devices, is the `mobile-offline` course, which comes after this one: its
lesson 7 is writing locally first and its lesson 8 is the outbox. Section 06 here does the first
step of that and says where it stops.
