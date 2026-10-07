---
title: The internal RFC
version: 1
---

**An RFC is a proposal with a process around it: anybody affected may comment, for a fixed time,
and then a named person decides and the outcome is recorded.** The document looks like a technical
proposal. What makes it an RFC is the process, and the process is what lets a change that affects
everybody be made without a meeting of everybody.

The name comes from the internet's own standards. In April 1969 Steve Crocker, a graduate student
working on the ARPANET, circulated the first of a series of notes and called it a *Request for
Comments*, because a more official name seemed presumptuous for students. The series now runs past
nine thousand documents and still carries the name. Companies borrowed it for the same reason: it
invites disagreement before the decision rather than after.

## When Marola uses one

An RFC is worth its overhead when the change **sets a rule other teams must follow** or **changes
something they depend on**. After the Friday incident, Lívia's proposal to give every service a
fixed share of database connections was an RFC, not a proposal, because it constrained all seven
teams, and each of them knew things about its own traffic that she did not.

## The life of an RFC

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Four steps left to right: draft, with the decider named; open, with a closing date set; revision, with every comment answered; decision, by one owner in writing. The decision leads to accepted or rejected, and an accepted RFC may later be superseded. Both outcomes stay where people can find them, because a rejected RFC answers why not.\"><defs><marker id=\"lifecycle-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"30\" width=\"152\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">draft</text><text x=\"90.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">decider named</text><path d=\"M168 60 L188 60\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></path><rect x=\"190\" y=\"30\" width=\"152\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"266.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">open</text><text x=\"266.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">closing date set</text><path d=\"M344 60 L364 60\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></path><rect x=\"366\" y=\"30\" width=\"152\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"442.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">revision</text><text x=\"442.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">every comment answered</text><path d=\"M520 60 L540 60\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></path><rect x=\"542\" y=\"30\" width=\"152\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"618.0\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">decision</text><text x=\"618.0\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one owner, in writing</text><rect x=\"452\" y=\"150\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">accepted</text><rect x=\"592\" y=\"150\" width=\"120\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"652\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">rejected</text><path d=\"M592 92 L512 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></path><path d=\"M642 92 L652 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#lifecycle-ah)\"></path><rect x=\"452\" y=\"210\" width=\"120\" height=\"32\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"512\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">superseded, later</text><path d=\"M512 192 L512 208\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\" marker-end=\"url(#lifecycle-ah)\"></path><text x=\"20\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">both outcomes stay where people can find them:</text><text x=\"20\" y=\"188\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a rejected RFC answers \"why don't we just…?\"</text></svg>", "caption": "What makes a proposal an RFC is this process: a fixed window for anybody affected, then one named decider, then a record that stays."}
```

1. **Draft.** The author writes it, usually with one or two people who will be affected most, and
   says who the decider is.
2. **Open for comment, with a closing date.** Announced where every affected team will see it. Two
   weeks is a common window inside a company; the Rust project, which runs its language changes
   through public RFCs, closes each one with a ten-day *final comment period* once the deciding team
   signals it is ready.
3. **Revision.** The author answers each comment: changed the design, explained why not, or
   recorded it as an open question. Every comment gets one of the three.
4. **Decision.** The named decider accepts or rejects it, in writing, with the reasons. **Not a
   vote and not unanimity**: the comments inform the decision, and one person or group owns it.
5. **Recorded.** The RFC keeps its final status (*accepted*, *rejected*, later *superseded* by a
   newer one) and stays where people can find it.

## Rejected RFCs are worth keeping

A rejected RFC is the cheapest documentation a company has. **It answers "why don't we just…?"
before anybody spends a week finding out.** Marola's list has an RFC from two years ago proposing
to split the orders database by region; it was rejected because two thirds of orders cross a
regional boundary. Every year somebody new has the same idea, finds the RFC, and reads the reason
in ten minutes.

## From RFC to decision record

An accepted RFC is long, and most of it is argument. What the next engineer needs is the decision.
Many teams keep a short **architecture decision record** for that, the format Michael Nygard
described in 2011: a title, the context, the decision, its consequences, and a status, in a page
or less, numbered and kept with the code.

::: track software-architecture
`architecture-role` lesson 5 argued why technology decisions are written down at all. The RFC is
the document that gets such a decision made with the people it affects, and the record is what
remains once it has been.
:::

::: track tech-lead
`tech-strategy`, the course after this one in your track, comes back to decision records in its
lesson 17, as the team's memory. The RFC is the document that gets a decision made; the record is
what remains once it has been.
:::

::: track *
The RFC is the document that gets a decision made with the people it affects; the record is what
remains once it has been.
:::
