---
title: Errors, with a 200
version: 1
---

**A GraphQL answer can hold data and errors at once, and its HTTP status is 200 either way.** The status
says the request reached the server and was understood as GraphQL. Whether the query worked is in the
body: a top-level `errors` list, present only when something went wrong, beside `data`. A client that
checks only `response.ok` treats every failed query as a success.

## Two kinds of failure

**A query the schema does not allow** is refused before anything runs. A typo in a field name is the
usual one:

```
ana@dev:~/planner$ node api/ask.mjs '{ course(id: "git") { titel } }'
{
  "errors": [
    {
      "message": "Cannot query field \"titel\" on type \"Course\". Did you mean \"title\"?",
      "locations": [
        {
          "line": 1,
          "column": 23
        }
      ]
    }
  ]
}
```

No `data` at all, because nothing was run, and an error that says where in the query the problem is and
suggests the field that exists. This is the kind the test at the end of the lesson catches before the
query ever leaves the computer.

**A field that fails while running** produces an error with a `path`, the field it happened in, and
whatever else the query asked for still comes back. Asking for a session in a course that does not exist
makes the server's `addSession` throw:

```
ana@dev:~/planner$ node api/ask.mjs 'mutation { addSession(input: { course: "rust", date: "2026-10-20", minutes: 30 }) { id } }'
{
  "errors": [
    {
      "message": "No course \"rust\"",
      "locations": [
        {
          "line": 1,
          "column": 12
        }
      ],
      "path": [
        "addSession"
      ]
    }
  ],
  "data": null
}
```

## Why `data` is `null`

The error was in `addSession`, yet the whole of `data` is `null`. That is the schema's `!` at work:
`addSession` returns `Session!`, which may never be null, so when it fails the null travels up to the
nearest field that is allowed to be null. There is none above it, so `data` itself becomes `null`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Where a failure&#x27;s null goes. On the left, addSession returns Session with an exclamation mark, so when it throws the null cannot stop there and travels up to data, which becomes null. On the right, markDone returns Session without one, so an unknown id makes markDone null and data keeps everything else.\"><rect x=\"20\" y=\"40\" width=\"280\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"160\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">may never be null</text><rect x=\"110\" y=\"56\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"160\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">data: null</text><rect x=\"70\" y=\"126\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"160\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">addSession: Session!</text><line x1=\"160\" y1=\"124\" x2=\"160\" y2=\"90\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></line><polygon points=\"160.0,90.0 163.1,97.4 156.9,97.4\" fill=\"var(--amber)\"></polygon><text x=\"160\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">throws, or finds nothing</text><rect x=\"420\" y=\"40\" width=\"280\" height=\"160\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">may be null</text><rect x=\"510\" y=\"56\" width=\"100\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">data</text><rect x=\"470\" y=\"126\" width=\"180\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"560\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">markDone: Session</text><line x1=\"560\" y1=\"124\" x2=\"560\" y2=\"90\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></line><text x=\"560\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">throws, or finds nothing</text><text x=\"168\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">the null travels up</text><text x=\"568\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the null stops here</text></svg>", "caption": "A failed field becomes null at the nearest place the schema allows a null; with a ! everywhere above it, the whole answer goes."}
```

The same rule runs the other way when a field is nullable. `markDone` returns `Session` without a `!`,
so an unknown id gives `{"markDone": null}` and keeps the rest of the answer. **Where a schema puts its
`!` decides how much of an answer one failure takes with it.**

## What the client does

The planner's client in a later section reads the body, and if `errors` is there it throws, with the
messages joined. It does not try to use half an answer: the planner has nothing to show with half its
sessions. An app with independent panels on one page may keep the parts that worked; both are choices,
and the wrong one is not looking at `errors` at all.
