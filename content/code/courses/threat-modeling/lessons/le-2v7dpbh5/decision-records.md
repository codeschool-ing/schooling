---
title: Decision records
version: 1
---

The format for writing decisions down that software teams already use is the **architecture
decision record (ADR)**: a short file per decision, with its context, the decision, and its
consequences, kept in the repository and never edited after the fact. A new decision that changes
an old one is a new record that says which one it replaces. The `architecture-modeling` course
(lesson 5) teaches ADRs for design decisions; security decisions fit the same shape with three
additions.

| an ADR has | a security decision record adds |
|---|---|
| a title and an id | the threat or risk it decides, by id |
| the context | the estimate, and the decision: mitigate, eliminate, transfer or accept |
| the decision | the owner, by name |
| the consequences | a review date, and the triggers that bring it forward |

Vereda keeps two kinds, with two prefixes so they can be told apart in a list: **RA** for a risk
acceptance, **DR** for any other decision. The prefix is for people reading the folder; nothing in
the program that reads them depends on it.

### Front matter for the machine, prose for people

Each record starts with a few lines of **front matter**, the fields a program needs, between two
lines of `---`. The rest is prose for whoever reads it next:

```
---
id: RA-001
threat: T14
decision: accept
owner: daniel
decided: 2026-10-01
review by: 2027-04-01
---
```

The front matter makes the register queryable: a program can list every acceptance, every
decision by daniel, every review due this month, without anybody keeping a separate list in step.
The prose is what makes the decision understandable in a year, by somebody who was not in the room.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l12-two-readers\" aria-label=\"A decision record has two readers. Its front matter, the lines between the two --- markers with id, threat, decision, owner, decided and review by, is read by a program, acceptances.py, which lists what is due. Its prose, the risk, why it is accepted, what is in place instead and when it is looked at again, is read by a person a year later who was not in the room.\"><defs><marker id=\"l12-two-readers-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l12-two-readers-tm-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"240.0\" y=\"20.0\" width=\"240.0\" height=\"220.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"252.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">RA-001-crafted-pdf.md</text><text x=\"256.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">---</text><text x=\"256.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">id: RA-001</text><text x=\"256.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">threat: T14</text><text x=\"256.0\" y=\"98.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">decision: accept</text><text x=\"256.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">owner: daniel</text><text x=\"256.0\" y=\"126.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">review by: 2027-04-01</text><text x=\"256.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">---</text><text x=\"256.0\" y=\"168.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">## The risk</text><text x=\"256.0\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">## Why it is accepted</text><text x=\"256.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">## What is in place instead</text><text x=\"256.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">## When this is looked at again</text><rect x=\"20.0\" y=\"60.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">acceptances.py</text><text x=\"105.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what is due, and when</text><path d=\"M240.0 85.0 L190.0 85.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-readers-tm-ah-phosphor)\"></path><rect x=\"530.0\" y=\"160.0\" width=\"170.0\" height=\"50.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"615.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a person, a year later</text><text x=\"615.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">who was not in the room</text><path d=\"M480.0 185.0 L530.0 185.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-readers-tm-ah-paper-dim)\"></path></svg>", "caption": "The machine reads the dates so nobody has to remember them; the person reads the reasons so nobody has to reconstruct them."}
```

### Never edited, only superseded

A decision record describes what was decided on a date, with what was known then. **Editing it
later rewrites history**: the record no longer says what daniel signed. So a changed decision is a
new record, with a line saying *supersedes RA-001*, and the old one stays. The one field allowed to
change in place is a status, if the team keeps one, because it describes the present rather than
the decision.

git makes this cheap to check: `git log` on a decision file shows whether it was edited after it was
first committed, and by whom.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l12-supersede\" aria-label=\"A changed decision is a new record. The old record, say RA-001 as daniel signed it, stays exactly as it was. The new record says, in its front matter, that it supersedes RA-001, and carries the new decision, owner and review date. The only field a team may change in place is a status, because it describes the present.\"><defs><marker id=\"l12-supersede-tm-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"40.0\" y=\"50.0\" width=\"240.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"160.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">RA-001</text><text x=\"160.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as signed, never edited</text><text x=\"160.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">status: superseded</text><rect x=\"440.0\" y=\"50.0\" width=\"240.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"560.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the new record</text><text x=\"560.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">supersedes: RA-001</text><text x=\"560.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">new decision, owner, date</text><path d=\"M440.0 95.0 L280.0 95.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-supersede-tm-ah-phosphor)\"></path><text x=\"360.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">git log shows that the old file was never touched after its commit</text></svg>", "caption": "The history stays true: anybody can still read what was decided in October, and with what was known then."}
```
