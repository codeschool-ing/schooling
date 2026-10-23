---
title: One decision, one page
version: 1
---

**An architecture decision record, an ADR, is a short document that captures one significant
decision: the situation that required it, what was decided, and what follows from it.** It is
written when the decision is made, kept with the code, and never rewritten afterwards. The
collection of them, in order, is the system's decision log.

`architecture-role` lesson 5 showed a whole record and argued why the architect is responsible for
records existing at all. This lesson is about the craft of writing one: what goes in each part, how
to compare options honestly, and how a log stays readable for years as decisions change.

## The five parts, and what each is for

Michael Nygard's format from 2011 is still the one most teams start with:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l05-anatomy\" aria-label=\"The five parts of a decision record, stacked as on the page, each with the question it answers for a reader two years later. Title: what was decided? Status: does this still apply? Context: what was true, and what pulled each way? Decision: what exactly will be done? Consequences: what became true because of it, good and bad?\"><defs><marker id=\"l05-anatomy-am-fill-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"16.0\" width=\"300.0\" height=\"270.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><rect x=\"40.0\" y=\"26.0\" width=\"280.0\" height=\"30.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"38.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Title</text><text x=\"50.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">9. Hold seats in Redis…</text><path d=\"M330.0 41.0 L372.0 41.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l05-anatomy-am-fill-paper-dim)\"></path><text x=\"380.0\" y=\"41.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">what was decided?</text><rect x=\"40.0\" y=\"62.0\" width=\"280.0\" height=\"30.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"74.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Status</text><text x=\"50.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Accepted, 2025-05-12</text><path d=\"M330.0 77.0 L372.0 77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l05-anatomy-am-fill-paper-dim)\"></path><text x=\"380.0\" y=\"77.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">does this still apply?</text><rect x=\"40.0\" y=\"98.0\" width=\"280.0\" height=\"72.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"110.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Context</text><text x=\"50.0\" y=\"122.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">- 1,800 holds/min at peak…</text><path d=\"M330.0 134.0 L372.0 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l05-anatomy-am-fill-paper-dim)\"></path><text x=\"380.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">what was true, what pulled each way?</text><rect x=\"40.0\" y=\"176.0\" width=\"280.0\" height=\"44.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"188.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Decision</text><text x=\"50.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">We will hold each seat…</text><path d=\"M330.0 198.0 L372.0 198.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l05-anatomy-am-fill-paper-dim)\"></path><text x=\"380.0\" y=\"198.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">what exactly will be done?</text><rect x=\"40.0\" y=\"226.0\" width=\"280.0\" height=\"60.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"50.0\" y=\"238.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">Consequences</text><text x=\"50.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">- CPU falls below 60%…</text><path d=\"M330.0 256.0 L372.0 256.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l05-anatomy-am-fill-paper-dim)\"></path><text x=\"380.0\" y=\"256.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">what became true, good and bad?</text></svg>", "caption": "A record is short because each part answers one question a later reader will have, and nothing else."}
```

| part | the question it answers for a reader two years from now |
| --- | --- |
| **title** | *what was decided?*, in a phrase, after a number: `9. Hold seats in Redis with a ten-minute expiry` |
| **status** | *does this still apply?* proposed, accepted, deprecated or superseded |
| **context** | *what was true, and what pulled each way, when this was decided?* |
| **decision** | *what exactly will be done?*, in full sentences, in the active voice |
| **consequences** | *what became true because of it*, good and bad |

The reader is the important word. **A record is written for somebody who was not there**: a new
engineer, an auditor, the architect who replaces you, or you in two years having forgotten. Each
part answers a question that person will have, and a part that answers nothing for them is padding.

## Which decisions deserve one

Not every choice is architectural, and a log of two hundred records about library versions is a log
nobody reads. A decision deserves a record when it is **expensive to reverse** and **affects more
than the people who made it**. Four kinds pass that test reliably:

- **structure**: where a boundary goes, what talks to what, which component owns which data;
- **technology with a long tail**: a database, a message broker, a language for a new service;
- **quality trade-offs**: accepting slower writes for faster reads, or eventual consistency for
  availability;
- **things people keep asking about**: if the same question has been answered twice in chat, the
  third answer should be a link.

Carcará's log has twenty-three records in three years. Most of them are one page, and the longest is
three.

## A record is not a design document

A design document explores: it describes a system, a change, alternatives, open questions, and it
evolves while the design does. A record **closes**: it states one decision and stops. Long design
documents tend to produce several records as their conclusions settle, and the records link back to
the document for anybody who wants the whole exploration. Keeping the two apart is what keeps the
log short enough to read.
