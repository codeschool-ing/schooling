---
title: Deciding, in four questions
version: 1
---

The sections before this one gave the evidence. This one turns it into the questions to ask, in the
order they settle things, for a new HTTP service in Go. **Ask them in this order, because each one,
answered yes, makes the ones after it irrelevant.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Four questions down the left, asked in order. A yes to the first leads to: use the team's framework. A yes to the second: consider Fiber. A yes to the third: Echo or Gin. A yes to the fourth: add a router such as chi. Four noes lead to the bottom: the standard library plus small libraries.\"><defs><marker id=\"gb-l5-decide-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"15\" width=\"300\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1. the team already has one?</text><path d=\"M 315 35 L 408 35\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l5-decide-ah)\"></path><text x=\"360\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><rect x=\"410\" y=\"15\" width=\"270\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"35\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">use the team's framework</text><path d=\"M 165 55 L 165 71\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l5-decide-ah)\"></path><rect x=\"15\" y=\"73\" width=\"300\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"93\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2. HTTP measured as the bottleneck?</text><path d=\"M 315 93 L 408 93\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l5-decide-ah)\"></path><text x=\"360\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><rect x=\"410\" y=\"73\" width=\"270\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"93\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consider Fiber</text><path d=\"M 165 113 L 165 129\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l5-decide-ah)\"></path><rect x=\"15\" y=\"131\" width=\"300\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3. many people, many routes, one way?</text><path d=\"M 315 151 L 408 151\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l5-decide-ah)\"></path><text x=\"360\" y=\"142\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><rect x=\"410\" y=\"131\" width=\"270\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"151\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Echo or Gin</text><path d=\"M 165 171 L 165 187\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l5-decide-ah)\"></path><rect x=\"15\" y=\"189\" width=\"300\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"30\" y=\"209\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4. a routing feature ServeMux lacks?</text><path d=\"M 315 209 L 408 209\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l5-decide-ah)\"></path><text x=\"360\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">yes</text><rect x=\"410\" y=\"189\" width=\"270\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"545\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">add a router such as chi</text><path d=\"M 165 229 L 165 245\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#gb-l5-decide-ah)\"></path><text x=\"178\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">no</text><rect x=\"15\" y=\"248\" width=\"665\" height=\"40\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"347\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">four noes: the standard library, plus small libraries in the standard shape</text></svg>", "caption": "The four questions of this section. The first yes ends the search."}
```

**1. Does the team already have a framework?** If the services you will work beside use one, use it.
Section 06 ended on this reason, and it overrides everything below: a codebase in
one style beats a codebase of better choices in five.

**2. Has a measurement shown the HTTP layer is where the time goes?** Not a benchmark of "hello
world", but a profile of this service under its real load. If yes, Fiber, or `fasthttp` underneath
something, is a candidate, and its costs from lesson 4 section 05 are worth paying. For a service that
waits on a database, the answer is almost never yes.

**3. Will many people write many routes that must all look the same?** A large API, a large team, a
public contract with generated documentation. If yes, a framework's one way of doing things is worth
its dependencies, and Echo or Gin, both `net/http` underneath, keep the exit open.

**4. Does `ServeMux` lack a routing feature you need?** Regular expressions in a path, groups of routes
with their own middleware. If yes, add a router that keeps your handlers standard, such as `chi`.

**If all four are no, use the standard library**, and add small libraries in the standard shape for
the gaps section 02 listed, one at a time, when each is needed. That is what boxoffice does, and it is
the default this course recommends.

## How to tell you chose wrong

Every one of these choices can turn out wrong, and the signs are specific. **The standard library was
the wrong choice** if the same twenty lines of decoding and error handling are being pasted into every
handler and drifting apart; that is the moment to write the helper, or to adopt the framework that has
it. **A framework was the wrong choice** if half of the team's time with it goes into finding and
overriding its defaults, or if a major version upgrade is put off for a year because it touches every
handler. In both cases the fix is cheapest early, which is why it is worth knowing the signs before the
first line is written.

## Why this lesson was worth a lesson

Lesson 4 could have ended with "pick one". The reason it did not is that **the choice of framework is
one of the few decisions in a Go service that is expensive to reverse**: it is in the signature of every
handler. Lessons 6 to 17 build boxoffice on the standard library, and at each step where a framework
would have helped, the lesson says so. By lesson 17 you will have seen what the default costs in full,
and be able to make the opposite call with your eyes open.
