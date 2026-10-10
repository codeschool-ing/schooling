---
title: What an ADR is, and the question it answers
version: 1
---

Code answers *what* and almost never *why*. Open the reservation module in `coreto-core` and you can
read exactly how a seat hold works: a transaction opens, the seat's row is locked, and the lock stays
until the buyer pays or gives up. What you cannot read is why somebody chose that, what else they
considered, and what was true at Coreto when they did. **An architecture decision record keeps that
second half.** It is a short document, one per decision, written when the decision is taken and kept
beside the code it explains.

## Where the reasons usually go

Most teams believe the reasons are already kept somewhere. Ask, and they point at three places. Each
of them loses the reasons in its own way.

The first is **the people who were there**. That works until they leave, move team, or remember the
meeting differently from the colleague sitting next to them. The locking in the seat-hold code is
older than anybody on the new Reservations team, and the engineer who wrote it left Coreto years ago.
When Davi's diagnosis named that code as the cause of failed on-sales, nobody could say whether the
locks had been a considered choice or the first thing that worked.

The second is **the design document or the RFC**. `architect-communication` lesson 2 covers the
one-pager and the internal RFC, and they are the right tools for proposing a change and collecting
objections. They are written before the decision, they argue for one option, and they are rarely
updated when the discussion ends somewhere else. A year on, the RFC describes what somebody wanted,
and a reader cannot tell which parts were built.

The third is **the chat thread and the meeting**. The decision is reached somewhere in the middle of
a long thread, or said out loud in a room and never written down. Search will not find it, because
the word somebody types in a year is not a word anybody used at the time.

An ADR differs from all three in one property: **it records a decision that was taken, in the terms
of the moment it was taken**, and it sits where the next engineer to touch that code will find it.

## Nygard's format

Michael Nygard proposed the form in a short article, "Documenting Architecture Decisions" (2011). He
wanted a document that a team would actually write, so he kept it to five parts.

| part | what it holds |
|---|---|
| title | a short noun phrase naming the decision, after its number |
| status | proposed, accepted, deprecated or superseded |
| context | the forces at play: what is true, what constrains the choice, what pulls each way |
| decision | what the team will do, in full sentences and the active voice: "We will…" |
| consequences | what becomes true once the decision is in force, good, bad and neutral alike |

He asked for one or two pages, written as plain text in the project's repository and numbered in
sequence. Each of those choices does work. A short record gets written on the day; a long one is put
off until the context has gone. A text file in the repository is reviewed in the same pull request
as the code, and it is still there after the wiki has moved twice.

The format is also deliberately thin. There is no section for the people who approved it, no
diagram slot, no risk matrix. A team that adds them is free to, and **a team that adds too many stops
writing records at all**, which costs more than any missing field.

## The status is a life cycle

The one field that changes after a record is accepted is its status. Everything else stays as it was
written, and the next section of this lesson leans on that.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 284\" role=\"img\" aria-label=\"The life cycle of an ADR status. Proposed, under discussion, leads to Accepted, when the team commits and the text is fixed. Accepted ends either as Superseded, when a later ADR replaced it and both point at each other, or as Deprecated, when it no longer applies and nothing replaced it. After acceptance only the status line changes.\"><defs><marker id=\"adrst-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"160\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"100\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">Proposed</text><text x=\"100\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">under discussion;</text><text x=\"100\" y=\"144\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">nothing built yet</text><path d=\"M186 115 L224 115\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#adrst-ah)\"></path><rect x=\"230\" y=\"70\" width=\"180\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"320\" y=\"100\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">Accepted</text><text x=\"320\" y=\"126\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the team committed;</text><text x=\"320\" y=\"144\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the text is now fixed</text><path d=\"M416 104 L474 66\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#adrst-ah)\"></path><path d=\"M416 126 L474 172\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#adrst-ah)\"></path><rect x=\"480\" y=\"20\" width=\"220\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"48\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--amber)\">Superseded</text><text x=\"590\" y=\"72\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a later ADR replaced it,</text><text x=\"590\" y=\"90\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">and both point at each other</text><rect x=\"480\" y=\"136\" width=\"220\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"164\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--paper-dim)\">Deprecated</text><text x=\"590\" y=\"188\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">it no longer applies,</text><text x=\"590\" y=\"206\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">and nothing replaced it</text><rect x=\"20\" y=\"238\" width=\"680\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"258\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">after acceptance only the status line changes; a new decision is a new record</text></svg>", "caption": "The four statuses Nygard named. Only the status line moves after acceptance: a changed decision is a new record that supersedes the old one, never an edit."}
```

A record is proposed while the team argues and accepted when it commits. It ends in one of
two ways. **Superseded** means a later record replaced it, and the two point at each other.
Deprecated means the decision no longer applies and nothing took its place: when the old reporting
replica from lesson 5 is finally switched off, the record that chose it is deprecated rather than
superseded, because there is no successor to point at.

## Which decisions earn a record

Not every choice does. Nygard's phrase was "architecturally significant": decisions that affect the
structure of the system, its qualities such as performance and availability, its dependencies, its
interfaces, or the way it is built. Two plain tests work at Coreto.

- Is it expensive to reverse? Locking rows to hold seats is. So is buying a hosted search service
  (lesson 8), or the database a new service stores its data in.
- Will somebody ask "why" in a year and be unable to find out? If the answer depends on something
  true only now, such as a deadline, a vendor's licence or the size of a team, it belongs on paper.

A library upgrade, the name of a module, the test runner one team prefers: none of those needs a
record. **A team that writes one for every choice soon writes none**, because the log turns into noise, people stop reading it, and then they stop writing it.

Lesson 16 is a good source of records, too. A technical decision that is a product decision in
disguise, such as how long a seat hold lasts, is exactly the kind where a year later somebody asks
who agreed to it. The record's context is where that answer lives.
