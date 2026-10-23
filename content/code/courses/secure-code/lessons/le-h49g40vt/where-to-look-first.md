---
title: Where to look first
version: 1
---

A code review has a fixed budget of attention, usually less than half an hour, and a diff of a few
hundred lines. Read it top to bottom and the attention goes on whatever comes first, which is
usually imports and naming. **A security review spends the budget in order of what a mistake
would cost**, and it has a short list of places to look before anything else.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l18-order\" aria-label=\"Where a security review looks first, as five questions in order of priority, each with the lesson of this course that teaches it. One: who may do this, the authorisation of every new route, lessons 1, 12 and 13. Two: what comes in, and is it validated at the boundary, lessons 2 and 3. Three: where does it go out, and is it encoded for that place, lesson 4. Four: what secrets and settings changed, lesson 16. Five: what dependencies changed, lesson 17. Style and naming come last, and the diagram leaves them off.\"><rect x=\"20\" y=\"20\" width=\"40\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"40.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">1</text><rect x=\"80\" y=\"20\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">who may do this?</text><text x=\"400\" y=\"33\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">every new route</text><text x=\"400\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">lessons 1, 12, 13</text><rect x=\"20\" y=\"74\" width=\"40\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"40.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">2</text><rect x=\"80\" y=\"74\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">what comes in?</text><text x=\"400\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">validated at the boundary</text><text x=\"400\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">lessons 2, 3</text><rect x=\"20\" y=\"128\" width=\"40\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"40.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">3</text><rect x=\"80\" y=\"128\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">where does it go out?</text><text x=\"400\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">encoded for that place</text><text x=\"400\" y=\"157\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">lesson 4</text><rect x=\"20\" y=\"182\" width=\"40\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"40.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">4</text><rect x=\"80\" y=\"182\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">which secrets and settings changed?</text><text x=\"400\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nothing secret in the diff</text><text x=\"400\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">lesson 16</text><rect x=\"20\" y=\"236\" width=\"40\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"40.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">5</text><rect x=\"80\" y=\"236\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">which dependencies changed?</text><text x=\"400\" y=\"249\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pinned, audited</text><text x=\"400\" y=\"265\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">lesson 17</text></svg>", "caption": "Five questions, in this order. A diff that passes the first one badly is not saved by passing the others well."}
```

### The five questions

1. **Who may do this?** Every new route, every new action on an existing one. Is there a check
   that the caller is signed in, and a check that the thing they are acting on is theirs? Lesson
   1's cancel button failed the second half, and lessons 12 and 13 are about it entirely. This
   comes first because a missing check is invisible in the code that is there: the reviewer has to
   ask about the line that is absent.
2. **What comes in?** Every value from a request, a file, a header or another service. Is it
   validated once, at the boundary, against an allowlist, and is the record built from known
   fields only? Lessons 2 and 3.
3. **Where does it go out?** Every place a value is written: HTML, an attribute, a script, a URL,
   a log line, a query. Is it encoded for that place, by the tool made for it? Lesson 4.
4. **Which secrets and settings changed?** A key in the code, a debug switch turned on, a cookie
   flag removed, a timeout lengthened. Lesson 16 is about secrets.
5. **Which dependencies changed?** A new package, a loosened pin, a version moved backwards.
   Lesson 17.

Errors, logs and tests come right after, and naming and style last. Style matters, and a linter
can usually catch it without a person.

### Read the change, then the context

A diff shows the lines that changed and three lines around each. The flaw is often in how a
changed line meets an unchanged one: a new route that calls a helper written last year, which
never checked what the new route assumes. **When a new line relies on old code, open the old
code.** The review tool's "expand" button exists for exactly that.

### And read the description last

The description says what the author meant to do. The diff says what they did. Reading the
description first makes it easier to see the intention in the code instead of the code itself,
which is the one thing a reviewer is there to avoid.
