---
title: The decision record, written for one real decision
version: 1
---

You met the architecture decision record in the `architecture` course, lesson 20, as a way of
recording a choice and defending it. This section looks at it from the other side: **as the
architect, you are responsible for the decisions that cross team lines being recorded at all**, and
for the records being good enough that somebody who was not in the room can follow them in two
years. That is easier to show than to describe, so here is one, whole.

## The format, briefly

Michael Nygard proposed the form in 2011, in a short article called "Documenting Architecture
Decisions". A record is one decision, a page or two of plain text, kept in the repository and
numbered in sequence, with five parts:

| part | what it holds |
|---|---|
| title | the decision, as a short phrase after its number |
| status | where it is in its life: proposed, accepted, superseded or deprecated |
| context | the forces at play: what is true, what constrains the choice, what pulls each way |
| decision | what will be done, in full sentences and the active voice |
| consequences | what becomes true once it is in force, good and bad alike |

Many teams add a list of the options they considered, and Carreto's template does, inside the
context. `architecture-modeling` lesson 5 spends time on options and how to compare them; here they
are part of the context because they explain the decision.

## One record, whole

The decision is the one lesson 4 left open: how Payments learns that a delivery was proved, so it
can pay the driver within 24 hours. Bruno Farias from Payments wrote it, with the Tracking team's
tech lead, after the working session Renata ran. It lives in the Payments repository because that
is the system it changes most.

```
# 7. Payments learns that a delivery was proved from an event

Status: Accepted

## Context

Carreto will pay drivers within 24 hours of delivery. Today Payments
pays once a week, from a batch that reads the deliveries table in the
monolith's database.

A delivery is proved when Tracking holds the driver's photo, the
receiver's signature and a GPS position near the destination. Tracking
owns that rule and its own database.

Forces:
- A delivery must be paid once: never twice, and never missed.
- The payout budget leaves 7 of its 24 hours as slack.
- Proof can reach Tracking up to 4 hours after unloading.
- Tracking deploys several times a day; Payments twice a week.
- Payments must not read Tracking's database.
- Both teams already use the company's message broker.

Options considered:
1. Payments asks Tracking's API every 5 minutes for new proofs.
2. Tracking calls a Payments endpoint when a delivery is proved.
3. Tracking publishes a DeliveryProved event; Payments consumes it.

## Decision

Tracking will publish a DeliveryProved event to the broker for every
proved delivery, carrying the delivery id, the CT-e key and the time
of proof. Payments will consume it, store it keyed by delivery id, so
that a repeated event changes nothing, and schedule the payout for the
end of the contest window.

Payments will also check Tracking's API every night for proved
deliveries it has not received, and alert if it finds one.

## Consequences

- Tracking finishes a proof whether or not Payments is up.
- Payments must accept events that arrive late, twice or out of order.
- The event's fields are a contract between two teams. Changing them
  needs both teams and a new version of the event.
- The nightly check is a second path to maintain. It is also the only
  way we will notice an event that was lost.
- Option 1 was rejected: it adds up to 5 minutes of delay and a steady
  load on Tracking's API for every open delivery.
- Option 2 was rejected: Tracking's proof step would fail whenever
  Payments was down, and Tracking would need to know about Payments.
```

## What makes it a good record

**The context is written as forces, with numbers.** "Payments must not read Tracking's database"
and "proof can arrive up to 4 hours late" are facts a reader can check, and each one rules
something out. A context that said "we want a robust, decoupled design" would rule out nothing,
and a future reader could not tell whether the forces had changed.

**The decision is a sentence somebody can be held to.** "Tracking will publish", "Payments will
consume", "store it keyed by delivery id". Each names who does what. A decision written in the
passive ("an event-driven approach will be adopted") leaves the reader asking who adopts it, and in
a cross-team record that question is the whole point.

**The consequences include the costs.** Bruno's team now has to handle duplicates and late
arrivals, and has taken on a nightly job. Writing that down is not pessimism. **A record that lists
only benefits reads as a sales pitch**, and the reader who later finds the costs on their own
stops trusting the rest of the log.

**The rejected options stay, with their reason.** In a year somebody will propose polling again,
because it is simpler, and the record will show it was considered and why it lost. If the reason
no longer holds, that is a reason to write a new record, which is the next part of this section.

**It is short.** About 360 words. Bruno wrote it in an afternoon, and the review in the pull request
took the two teams a day. A record that takes a week to write gets written after the code, as
paperwork, and stops recording anything.

## The status, and why an accepted record is not edited

A record starts as **proposed** while the teams argue about it, and becomes **accepted** when they
commit. After that, **the text does not change**. If the decision changes, a new record is written
that **supersedes** the old one: the new one says which it replaces, and the old one's status line
is the only line edited, to point at its successor. A record whose decision simply stops applying,
with nothing to replace it, is marked **deprecated**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Two records side by side. On the left, record 3, payouts run as a weekly batch from the monolith's database, written late, its status changed to superseded by 7. On the right, record 7, Payments learns that a delivery was proved from an event, status accepted, with a line saying it supersedes 3. An arrow runs from 7 back to 3. Underneath, the four statuses in a row: proposed, accepted, then superseded or deprecated.\"><defs><marker id=\"adr7-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"adr7-bh\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"300\" height=\"120\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"36\" y=\"46\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--paper-dim)\">3</text><text x=\"56\" y=\"46\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">Payouts run as a weekly batch</text><text x=\"56\" y=\"64\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">from the monolith's database</text><text x=\"36\" y=\"94\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">written late, from what people remembered</text><text x=\"36\" y=\"122\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">Status: superseded by 7</text><rect x=\"400\" y=\"20\" width=\"300\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"416\" y=\"46\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\">7</text><text x=\"436\" y=\"46\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">Payments learns that a delivery</text><text x=\"436\" y=\"64\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">was proved from an event</text><text x=\"416\" y=\"94\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Supersedes 3</text><text x=\"416\" y=\"122\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">Status: accepted</text><path d=\"M396 80 L326 80\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#adr7-ah)\"></path><rect x=\"20\" y=\"180\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90\" y=\"205\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">proposed</text><path d=\"M162 200 L196 200\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#adr7-bh)\"></path><rect x=\"200\" y=\"180\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"270\" y=\"205\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">accepted</text><path d=\"M342 200 L376 200\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#adr7-bh)\"></path><rect x=\"380\" y=\"180\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"205\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">superseded</text><text x=\"540\" y=\"205\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">or</text><rect x=\"560\" y=\"180\" width=\"140\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630\" y=\"205\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">deprecated</text></svg>", "caption": "Record 7 replaced record 3. The old one keeps its text, and its status line is the only thing that changed; the new one says what it replaced. A reader who lands on either can follow the decision in both directions."}
```

Carreto's record 3 shows why. When Renata started the log, she asked Bruno to write down the
weekly batch as it was, reconstructed from what the people who built it remembered. It said why a
weekly batch had been right when Carreto was small: one finance person reconciled payouts by hand on
Fridays, and the monolith's database was the only source of deliveries. **For that company, the
decision was correct**, and record 3 says so. When record 7 replaced it, Bruno changed one line in
record 3, its status. Rewriting it to describe events would have erased the reason the batch
existed, and the next person to read the code would have concluded that somebody once did something
foolish.

`tech-strategy` lesson 17 follows a log like this over a whole year, numbering and all. What you
need from this lesson is the rule and the reason: **an accepted record is a statement of what was
decided and why, at a moment, and the moment does not change afterwards.**

## Your part as architect

Renata did not write record 7, and that was deliberate. **The architect makes sure the record
exists, that the people affected reviewed it, and that it is findable**; who types it is less
important, and records written by the teams teach the teams to think in decisions, which lesson 11
comes back to. What she did do was ask, at the end of the working session, "who is writing this
down, and by when?", and read the draft in the pull request with one question in mind: could
somebody who was not here follow it?
