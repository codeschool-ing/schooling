---
title: The six knowledge areas
version: 1
---

**BABOK groups the tasks of business analysis into six knowledge areas.** They are areas of work, not
phases: on a real change they overlap and repeat, and an analyst may be in four of them in the same
week.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l07-knowledge-areas\" aria-label=\"The six BABOK knowledge areas. Business Analysis Planning and Monitoring sits across the top and governs the others. Below it, Elicitation and Collaboration, and Requirements Life Cycle Management, work across all of the rest. Strategy Analysis, Requirements Analysis and Design Definition, and Solution Evaluation follow the change from its strategy, through its requirements and design, to whether it delivered value.\"><defs><marker id=\"l07-knowledge-areas-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"30.0\" y=\"12.0\" width=\"660.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Business Analysis Planning and Monitoring</text><rect x=\"35.0\" y=\"71.0\" width=\"320.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"195.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Elicitation and Collaboration</text><rect x=\"365.0\" y=\"71.0\" width=\"320.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"525.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Requirements Life Cycle Management</text><rect x=\"25.0\" y=\"146.0\" width=\"210.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"130.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Strategy Analysis</text><text x=\"130.0\" y=\"181.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">current and future state</text><rect x=\"255.0\" y=\"146.0\" width=\"210.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Requirements Analysis and</text><text x=\"360.0\" y=\"181.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">Design Definition</text><rect x=\"485.0\" y=\"146.0\" width=\"210.0\" height=\"58.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Solution Evaluation</text><text x=\"590.0\" y=\"181.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">did the value arrive?</text><path d=\"M235.0 175.0 L255.0 175.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-knowledge-areas-am-fill-paper)\"></path><path d=\"M465.0 175.0 L485.0 175.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l07-knowledge-areas-am-fill-paper)\"></path><text x=\"360.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">strategy → requirements and design → evaluation</text></svg>", "caption": "Areas of work, not phases. On a real change they overlap and repeat, and an analyst may be in four of them in one week."}
```

| knowledge area | what it covers | for the reconciliation |
| --- | --- | --- |
| **Business Analysis Planning and Monitoring** | deciding how the analysis will be done: approach, stakeholders to involve, how decisions get made, how changes to requirements are handled | a two-week analysis, Joana as the business owner, the finance director approving |
| **Elicitation and Collaboration** | drawing information out of stakeholders and other sources, confirming it, and keeping stakeholders engaged | interviews, a day watching Joana match files, a workshop with Payments |
| **Requirements Life Cycle Management** | tracing, maintaining, prioritising and approving requirements, and assessing changes to them | the requirement list, its ids, MoSCoW, who signs off |
| **Strategy Analysis** | understanding the current state, defining the future state, assessing risks, and choosing a change strategy | today's manual process, the target daily match, the risk of the file format changing |
| **Requirements Analysis and Design Definition** | structuring and modelling requirements, verifying and validating them, and defining design options | a process model, a data model of a settlement line, two design options |
| **Solution Evaluation** | measuring whether a solution, once in use, delivers the value expected, and why not | after three months: hours spent, mismatches found, audit findings |

## Where the architect overlaps

Two of the six are territory the architect shares:

- **Strategy Analysis** is close to the enterprise architect's current and target states, which
  TOGAF in lesson 8 calls *baseline* and *target*. A business analyst does it for one change; an
  enterprise architect does it for the portfolio.
- **Requirements Analysis and Design Definition** includes *defining design options* and
  *analysing potential value*. That is the point where a requirement turns into an architecture
  decision, and where lesson 5's options table comes in.

## Solution Evaluation, the forgotten one

Most projects stop at delivery. BABOK insists on going back to ask **whether the value arrived**,
which is the same move as lesson 5's consequences checked later and lesson 6's verification column.
For the reconciliation, the measure is simple and was agreed before the work started: *Finance closes
the month within one working day of the gateway's last file, and fewer than five unexplained
mismatches reach the auditors per quarter*. Three months after go-live, somebody checks.
