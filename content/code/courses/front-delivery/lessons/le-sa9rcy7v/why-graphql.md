---
title: Why GraphQL
version: 1
---

**GraphQL is a language for asking a server for data, in which the client names every field it wants and
the answer has exactly that shape.** A server that speaks it publishes a **schema**, the list of types and
fields it can answer for, and takes every question at one address. The client writes a **query**, the
server checks it against the schema, runs it, and sends back JSON laid out like the query.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"A query against its schema. On the left, the schema&#x27;s Course type has the fields id, title, sessions and minutesPlanned, and Session has id, course, date, minutes and done. In the middle, a query asks for course git with its title and its sessions&#x27; date and minutes; those fields are marked in the schema. On the right, the answer has exactly those fields, nested the same way.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the schema</text><text x=\"260\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the query</text><text x=\"490\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the answer</text><rect x=\"20\" y=\"34\" width=\"210\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"30\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">type Course {</text><text x=\"42\" y=\"65\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">id: ID!</text><text x=\"42\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">title: String!</text><text x=\"42\" y=\"95\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">sessions: [Session!]!</text><text x=\"42\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">minutesPlanned: Int!</text><text x=\"30\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">}</text><text x=\"30\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">type Session {</text><text x=\"42\" y=\"155\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">id: Int!</text><text x=\"42\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">course: Course!</text><text x=\"42\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">date: String!</text><text x=\"42\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">minutes: Int!</text><text x=\"42\" y=\"215\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">done: Boolean!</text><text x=\"30\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">}</text><rect x=\"250\" y=\"34\" width=\"210\" height=\"210\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">{</text><text x=\"272\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">course(id: \"git\") {</text><text x=\"284\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">title</text><text x=\"284\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">sessions {</text><text x=\"296\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">date</text><text x=\"296\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">minutes</text><text x=\"284\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">}</text><text x=\"272\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">}</text><text x=\"260\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">}</text><rect x=\"480\" y=\"34\" width=\"220\" height=\"210\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"490\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{\"data\": {</text><text x=\"502\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">\"course\": {</text><text x=\"514\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">\"title\": \"Git\",</text><text x=\"514\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">\"sessions\": [</text><text x=\"526\" y=\"126\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">{\"date\": \"2026-10-08\",</text><text x=\"532\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">\"minutes\": 30}</text><text x=\"514\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">]</text><text x=\"502\" y=\"180\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">}</text><text x=\"490\" y=\"198\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">}}</text><line x1=\"232\" y1=\"140\" x2=\"248\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"462\" y1=\"140\" x2=\"478\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><polygon points=\"478.0,140.0 470.6,143.1 470.6,136.9\" fill=\"var(--paper-dim)\"></polygon><text x=\"355\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">checked against the schema</text></svg>", "caption": "The client names the fields; the server checks them against the schema and answers in the same shape, with nothing more."}
```

## What it changes for a front-end

The planner reads `courses.json`, one file with everything in it. A REST API usually splits the same data
into addresses, one per kind of thing: `/courses`, `/courses/git`, `/courses/git/sessions`. A page that
shows a course with its sessions asks two or three of them, and each answer carries every field the
server decided to put in it, whether the page shows it or not.

A GraphQL client asks once, for exactly what the page draws:

```
{
  course(id: "git") {
    title
    sessions {
      date
      minutes
    }
  }
}
```

The two problems this removes have names: **over-fetching**, receiving fields nobody uses, and
**under-fetching**, needing a second request for what the first one left out. On a phone on a slow
network, both cost seconds.

## What it costs

None of this is free, and a team should know the bill before it chooses:

- **Caching gets harder.** Every query goes to the same address, usually as a `POST`, so the HTTP caches
  a browser and a CDN already have do not help; lesson 10's clients cache by object instead.
- **The server does more work per request.** A query can ask for courses, their sessions, each session's
  course, its sessions, and so on. A public GraphQL server limits how deep and how large a query may be,
  and checks permissions on each field, not once per address.
- **Errors arrive with a 200.** The section on errors shows what that means for the code that reads the
  answer.

GraphQL was made at Facebook for its mobile apps and published as an open specification in 2015; it is
now kept by the GraphQL Foundation. REST is not obsolete because of it. This lesson is about the client
side, and the `apis` course in the backend track builds the server side in depth.
