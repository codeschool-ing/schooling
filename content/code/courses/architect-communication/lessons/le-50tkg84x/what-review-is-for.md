---
title: What code review is actually for
version: 1
---

**Most teams say code review is for catching bugs, and the best study of what it actually does found
that it mostly does something else: it spreads knowledge.** That means
the review is the place where a team teaches itself, every day, at no extra cost, if the people
writing the comments treat it that way.

## The Microsoft study

In 2013 Alberto Bacchelli and Christian Bird published a study of code review at Microsoft. They
interviewed developers, surveyed hundreds more, and read the comments on hundreds of real reviews.
Developers said the main reason they reviewed code was to find defects. When the researchers
classified what the comments were about, defects were a minority; most comments concerned
readability, alternative solutions, and understanding what the change did. The authors concluded
that **knowledge transfer and team awareness** were among the most important outcomes of review,
whether anybody intended them or not.

It matches what Lívia sees at Marola. In
checkout's reviews from June, about one comment in seven pointed at something that would have been a
bug. The rest were questions, explanations, suggestions about naming and structure, and links to how
something had been done elsewhere.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Bars counting 140 review comments by subject. Readability and naming: 48. Questions about what the change does: 34. Alternative approaches: 26. Would have been a bug: 20. Praise: 12.\"><defs><marker id=\"reviewcomm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">readability and naming</text><rect x=\"300\" y=\"20\" width=\"336\" height=\"20\" rx=\"3\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"644\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">48</text><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">questions about what the change does</text><rect x=\"300\" y=\"60\" width=\"238\" height=\"20\" rx=\"3\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"546\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">34</text><text x=\"20\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">alternative approaches</text><rect x=\"300\" y=\"100\" width=\"182\" height=\"20\" rx=\"3\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"490\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">26</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">would have been a bug</text><rect x=\"300\" y=\"140\" width=\"140\" height=\"20\" rx=\"3\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"448\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">20</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">praise</text><rect x=\"300\" y=\"180\" width=\"84\" height=\"20\" rx=\"3\" fill=\"var(--paper-dim)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"392\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">12</text><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">140 comments on checkout's pull requests in June, by what they were about</text></svg>", "caption": "About one comment in seven caught something that would have been a bug. The other six were the team teaching itself, which is the same shape Bacchelli and Bird found at Microsoft."}
```

## Two consequences

**If review is mostly teaching, the comments are the curriculum.** A comment that says "fix this" fixes
one line. A comment that says why teaches the author, and everybody who reads the review afterwards,
something they will apply to the next hundred lines. The next section is about writing that kind of
comment.

**And the review is not only for the author.** Diego's development plan from lesson 10 had him
reviewing two pull requests a week from people outside his usual pairings. That activity was not
there to catch bugs in their code; it was there so that Diego would read code he did not write, ask
about decisions he would not have made, and see how other people break problems down. **Reviewing is
how a junior learns the parts of the system they do not work on.**

## What review is not for

- **Not for gatekeeping.** A review that exists to prove the reviewer is more senior teaches the
  author to send smaller, safer changes to somebody else.
- **Not for style the machine can check.** Formatting, import order and line length belong to a
  formatter and a linter in the pipeline. Every comment a human spends on them is a comment not spent
  on design.
- **Not the only defence.** Tests, types, staging and gradual rollouts catch most defects. A team that
  relies on reviewers to find bugs gets slow reviews and bugs anyway.
