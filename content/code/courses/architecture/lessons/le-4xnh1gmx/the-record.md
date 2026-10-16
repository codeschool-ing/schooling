---
title: What a record contains
version: 1
---

Nygard's format has five parts, and its strength is that it is short enough to write while the decision
is fresh, in about twenty minutes:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"The five parts of an architecture decision record, as five stacked boxes: a numbered title; the status, such as proposed, accepted or superseded; the context, the forces at play; the decision, in full sentences; and the consequences, good and bad.\"><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"40\" y=\"30\" width=\"300\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"54\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\"># 5. Keep a copy of the stock</text><text x=\"370\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a number and a title</text><rect x=\"40\" y=\"73\" width=\"300\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"54\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">## Status</text><text x=\"370\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">proposed, accepted, superseded</text><rect x=\"40\" y=\"116\" width=\"300\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"54\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">## Context</text><text x=\"370\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the forces: load, outages, needs</text><rect x=\"40\" y=\"159\" width=\"300\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"54\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">## Decision</text><text x=\"370\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what we will do, in full sentences</text><rect x=\"40\" y=\"202\" width=\"300\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"54\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">## Consequences</text><text x=\"370\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what gets better and what gets worse</text></svg>", "caption": "Nygard's template: short enough to write in twenty minutes, complete enough to answer \"why\" a year later."}
```

- **Title**, numbered: a short phrase naming the decision, not the problem. "Keep a copy of the stock",
  not "Stock performance".
- **Status**: proposed, accepted, deprecated, or superseded by a later record. The status is the one part
  that changes after acceptance.
- **Context**: the forces at the time, technical, political, financial, described neutrally. This is the
  part that ages, and the part a reader a year later needs most: it says what was true then.
- **Decision**: what we will do, in full sentences, in the active voice. "We will…", not "it was decided".
- **Consequences**: everything that follows, the good and the bad. A record with only good consequences
  has not been thought through; every lesson in this course found a cost.

Variants add what a team finds itself missing. **MADR**, Markdown Architectural Decision Records, adds
the **options considered** and the **criteria** they were judged by, which is what a reviewer asks for
first. Others add who decided, or a date to review the decision again. Whatever the format, two habits
matter more than the template: **write it when the decision is made**, not after, and **keep it in the
repository**, reviewed in the same pull request as the change it explains, so that it is found where
the code is.
