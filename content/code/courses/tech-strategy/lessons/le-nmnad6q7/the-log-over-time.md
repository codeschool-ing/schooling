---
title: The log over time
version: 1
---

One record explains one decision. **The log explains how the system came to be the way it is.**
That only works if the log is kept by three rules: records are numbered in sequence, an accepted
record is never edited, and the log lives beside the code. Each rule exists because the obvious
alternative destroys something.

## Superseded, never edited

The wrong idea is that an ADR is documentation and should be kept current. When the decision
changes, somebody opens the file and rewrites it to match the new design. The file is accurate
again, and the reasoning that was right at the time has disappeared.

ADR-0002 shows why that matters. Coreto wrote it in February, years after the fact, to record a
decision it already lived with: seat holds lock rows in the database. Its context says what was true
when the locking was written. Coreto had a handful of venues, on-sales were small, and a row lock was
the simplest way to stop two buyers taking one seat. **For that company, the decision was correct.**
Rewriting ADR-0002 in April to describe holds without locks would erase that, and a future engineer
would see only that somebody once built something foolish.

So when ADR-0006 replaced it, ADR-0002 changed in one line, its status, which now reads "Superseded
by ADR-0006". ADR-0006 opens with "Supersedes ADR-0002". Each points at the other, and a reader who
lands on either can follow the decision forwards or backwards.

An append-only log can be trusted because nobody can tidy it. A log whose entries are edited to match the present is a
second copy of the code, and a worse one.

## Numbers in sequence, never reused

Records are numbered in the order they are written: 0001, 0002, 0003. A number is never given to a
second record, even when the first is superseded or deprecated. **The number is the record's
identity**, the thing other records, pull requests and incident reports cite. A title can be
improved; if numbers moved, every citation would quietly start pointing at the wrong decision.

The order also carries information. Reading Coreto's log from the top gives the year as it happened.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 354\" role=\"img\" aria-label=\"Coreto’s ADR log as a list of eight rows in number order, January to October. 0001 Record architecture decisions, accepted. 0002 Seat holds lock rows in the database, superseded by 0006. 0003 No deploys to the hold path 24 hours before an on-sale, superseded by 0009. 0004 Replay an on-sale before changing the hold path, accepted. 0005 Buy a hosted search service, accepted. 0006 Hold seats without row locks, accepted. 0007 and 0008, two decisions outside this story. 0009 Replace the freeze with a load-test gate, accepted. Arrows on the right run from 0006 back to 0002 and from 0009 back to 0003.\"><defs><marker id=\"adrlog-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"20\" y=\"16\" width=\"610\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"37\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">0001</text><text x=\"100\" y=\"37\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Jan</text><text x=\"144\" y=\"37\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Record architecture decisions</text><text x=\"618\" y=\"37\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">accepted</text><rect x=\"20\" y=\"54\" width=\"610\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"75\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0002</text><text x=\"100\" y=\"75\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Feb</text><text x=\"144\" y=\"75\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Seat holds lock rows in the database</text><text x=\"618\" y=\"75\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">superseded by 0006</text><rect x=\"20\" y=\"92\" width=\"610\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"32\" y=\"113\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0003</text><text x=\"100\" y=\"113\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Feb</text><text x=\"144\" y=\"113\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">No deploys to the hold path 24 h before an on-sale</text><text x=\"618\" y=\"113\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">superseded by 0009</text><rect x=\"20\" y=\"130\" width=\"610\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"151\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">0004</text><text x=\"100\" y=\"151\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Mar</text><text x=\"144\" y=\"151\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Replay an on-sale before changing the hold path</text><text x=\"618\" y=\"151\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">accepted</text><rect x=\"20\" y=\"168\" width=\"610\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"189\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">0005</text><text x=\"100\" y=\"189\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Apr</text><text x=\"144\" y=\"189\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Buy a hosted search service</text><text x=\"618\" y=\"189\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">accepted</text><rect x=\"20\" y=\"206\" width=\"610\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"227\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">0006</text><text x=\"100\" y=\"227\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Apr</text><text x=\"144\" y=\"227\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Hold seats without row locks</text><text x=\"618\" y=\"227\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">accepted</text><rect x=\"20\" y=\"244\" width=\"610\" height=\"32\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"2 4\"></rect><text x=\"32\" y=\"265\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper-dim)\">0007–8</text><text x=\"144\" y=\"265\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">two decisions outside this story</text><rect x=\"20\" y=\"282\" width=\"610\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"303\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">0009</text><text x=\"100\" y=\"303\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">Oct</text><text x=\"144\" y=\"303\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Replace the freeze with a load-test gate</text><text x=\"618\" y=\"303\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">accepted</text><path d=\"M632 222.0 C672 222.0, 672 70.0, 636 70.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#adrlog-ah)\"></path><path d=\"M632 298.0 C706 298.0, 706 108.0, 636 108.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#adrlog-ah)\"></path><path d=\"M24 336 L60 336\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#adrlog-ah)\"></path><text x=\"70\" y=\"340\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">supersedes: the newer record points at the one it replaced</text></svg>", "caption": "Coreto’s log from January to October. The superseded records stay in place, dimmed, with their reasoning intact; the arrows run from each new decision back to the one it replaced."}
```

ADR-0003 is the deploy freeze from lesson 1's fourth action: no deploys to the reservation module in
the 24 hours before a big on-sale. It was the right rule while nobody could measure a change to the
hold path. ADR-0004 built that measurement, and by October the load test had run against enough
changes that the team trusted it more than the calendar. ADR-0009 replaced the freeze with a gate: a
change to the hold path merges only with a passing load-test run, whatever the date. Lesson 1 said
the load test would make the freeze less necessary over time, and the log shows when that happened
and why.

## Beside the code

Coreto keeps its log in `docs/adr/` inside `coreto-core`, one Markdown file per record, named after
its number and title, as in `0006-hold-seats-without-row-locks.md`. That placement buys three things.

**A record is reviewed with the change it explains.** The pull request that started the move to
holds without locks carried ADR-0006 in it, and reviewers argued with the context before the code
merged. An objection raised there costs a comment. The same objection raised after a quarter of work
costs the quarter.

**A record is found where it is needed.** An engineer reading the hold code can search the repository
for "hold" and land on ADR-0006, with no wiki login and no guessing which space it was filed under.

And a record moves with the code. When the reservation module leaves the monolith one day, its
records go with it in the same commit.

A decision that spans several systems needs one home, and the choice is less important than making
it once. Coreto's ADR-0001 says that a decision belongs in the repository of the system it changes
most, and a decision about the whole platform goes in `coreto-core`.

## Records written late

ADR-0002 was written about a decision made long before anybody kept records. That is worth doing for
one class of decision in particular: **the ones you are about to change.** A superseding record needs
something to point at, and the honest context of the old decision is the best argument that the
change is not just a new team disliking old code. Write it plainly as reconstructed, and say who it
was reconstructed from.

Writing late records for every old decision is not worth it. Start the log on the day you read this,
backfill only what you are about to touch, and let the rest stay unwritten until somebody asks.

## How a log dies

A log fails in predictable ways, and all of them can be seen in the file listing.

- It stops at a number: the engineer who cared moved on, and nobody else was asked to write records.
- Its records are written after the code merged, as paperwork, so their contexts argue for what was
  already built.
- Its records grow into RFCs, several pages each, and writing one becomes a project nobody starts.

Coreto keeps the cost low on purpose. A template sits in `docs/adr/`, and the pull-request checklist
for the reservation module asks whether the change needs a record. When Davi presents the strategy
in lesson 20, the log is the trail behind it: what was decided under the guiding policy, when, and
what each decision cost.
