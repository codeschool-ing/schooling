---
title: Four classes of requirement
version: 1
---

**BABOK classifies requirements into four kinds, by whose need they express and what they describe.**
The classification is useful because it stops a list from mixing levels, which is how a business
goal ends up next to a column width and nobody can tell which matters.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l07-classes\" aria-label=\"BABOK's four classes of requirement as a chain. Business requirements, the organisation's goals, are met by stakeholder requirements, the needs of stakeholders, which are met by solution requirements, split into functional and non-functional. Beside the chain, transition requirements, needed only to move from the current state to the future one.\"><defs><marker id=\"l07-classes-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"100.0\" y=\"17.0\" width=\"300.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"33.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Business requirements</text><text x=\"250.0\" y=\"46.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">goals of the organisation</text><rect x=\"100.0\" y=\"102.0\" width=\"300.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"118.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Stakeholder requirements</text><text x=\"250.0\" y=\"131.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">needs of stakeholders</text><rect x=\"100.0\" y=\"187.0\" width=\"300.0\" height=\"46.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"250.0\" y=\"203.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Solution requirements</text><text x=\"250.0\" y=\"216.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">what the solution does and how well</text><rect x=\"100.0\" y=\"249.0\" width=\"140.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">functional</text><rect x=\"260.0\" y=\"249.0\" width=\"140.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"330.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">non-functional</text><path d=\"M250.0 102.0 L250.0 63.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-classes-am-fill-paper)\"></path><path d=\"M250.0 187.0 L250.0 148.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-classes-am-fill-paper)\"></path><text x=\"258.0\" y=\"82.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">meets ↑</text><text x=\"258.0\" y=\"167.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">meets ↑</text><rect x=\"470.0\" y=\"80.0\" width=\"220.0\" height=\"90.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\"></rect><text x=\"580.0\" y=\"111.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Transition requirements</text><text x=\"580.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">only to move from now</text><text x=\"580.0\" y=\"138.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.0\" fill=\"var(--paper-dim)\">to the future state</text><path d=\"M470.0 125.0 L400.0 125.0\" stroke=\"var(--amber)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path></svg>", "caption": "The chain says why each solution requirement exists. Transition requirements sit beside it because they disappear once the change is made, which is why they are the ones forgotten."}
```

| class | what it describes | the reconciliation |
| --- | --- | --- |
| **business requirements** | the goals and outcomes of the organisation | *Finance closes the month within one working day of the last settlement file.* |
| **stakeholder requirements** | the needs of a stakeholder or group, which the solution must meet | *Joana can see, each morning, every unmatched transaction with the reason it did not match.* |
| **solution requirements** | the capabilities and qualities of the solution itself | functional: *the job matches card and Pix payments by transaction id and refunds by original id*; non-functional: *the daily match completes by 07:00 for a day of São João volume* |
| **transition requirements** | what is needed to move from the current state to the future, and only for that time | *the 214 known exceptions are imported from Joana's spreadsheet before the first run*; *for one month, the manual and the automatic match run in parallel* |

## Reading the classes as a chain

The classes trace downward: a business requirement is met by stakeholder requirements, which are met
by solution requirements. So the chain from the top of this table to the bottom says **why** each
solution requirement exists. *Match refunds by original id* exists because Joana needs to see the
reason for every mismatch, which exists because Finance must close in a day.

Lesson 6's split is inside this one: BABOK's solution requirements are lesson 6's functional
requirements and quality attributes. The constraints of lesson 6 usually come from the context, the
sixth core concept.

## Transition requirements are the ones forgotten

Every list has business, stakeholder and solution requirements. **Transition requirements are the
class that is missing, and the one that decides whether go-live works.** Importing the 214 exceptions,
running both processes in parallel for a month, training Joana's colleague who covers her holidays,
switching off the old export: none of these is a capability of the new system, and each is a reason
it could fail on its first day. They disappear once the transition is over, which is exactly why
they need writing down before it starts.
