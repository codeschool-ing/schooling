---
title: Goodhart's law, and what to report to whom
version: 1
---

The economist Charles Goodhart observed in 1975 that a statistical regularity collapses once it is
used for control. The anthropologist Marilyn Strathern later put it in the form everybody quotes:
**when a measure becomes a target, it ceases to be a good measure.** Security metrics are a clean
case of it, because every number in this lesson can be improved in two ways, by doing the work or
by changing what gets counted, and the second is always cheaper.

### A team that looks best

```
ana@vm:~/metrics$ python3 measure.py teams
team      closed fixed wont_fix median
links        129   108       4%     26
payments     135    71      41%      7
platform      95    80       6%     33
web           91    79       4%     22
```

Judged by the median days to close a finding, `payments` is the best team in the company by a long
way: 7 days, against 22 to 33 for the other three. Judged by the second column, it closed 135
findings, the most of anybody.

The third column says how. **41% of the findings `payments` closed were closed as "won't fix"**,
against 4 to 6% for the others. Of its 135 closed findings, 71 were fixed. The generator planted
this, so here the cause is known: the line in `outcome()` that closes nearly half of the team's
medium and low findings within five days. On real data the cause would have to be found the same
way, by putting a second number beside the first.

Nothing in that pattern requires bad faith. A team told that its median is reviewed every month,
with a backlog of medium findings in libraries it does not control, will find that "won't fix,
accepted risk" is a legitimate resolution, and use it. Each decision can be defended. The sum is a
median that says the team is fast, about work it did not do.

### The same report, counted the other way

The time to remediate in this lesson counts only `fixed`. Counting every way off the list instead is
the change one word away, and `ttr-any` makes it:

```
ana@vm:~/metrics$ python3 measure.py ttr-any
severity  closed  mean median  p90 in SLA
critical      25   7.8      4   11    72%
high         116  20.9     15   46    78%
medium       195  34.9     22   86    90%
low          114  54.6     43  126    96%
```

Put it beside the fixed-only table from earlier in this lesson. The medium median falls from 34.5
days to 22, and low from 57 to 43; the share within SLA rises for both. **Nothing was fixed faster.**
The only difference is that 61 medium findings that left the list without a fix now count as
remediations. A report that does not say which resolutions it counts is a report anybody can move
by changing a filter.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"sp-l20-goodhart\" aria-label=\"Each team as a point: across, the share of its closed findings closed as won't fix; up, its median days to close a finding by any route. links 4% and 26 days, web 4% and 22, platform 6% and 33, payments 41% and 7. payments has the best median and by far the highest share of won't fix.\"><defs><marker id=\"sp-l20-goodhart-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"80\" y1=\"240.0\" x2=\"660\" y2=\"240.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></line><text x=\"72\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"80\" y1=\"192.5\" x2=\"660\" y2=\"192.5\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></line><text x=\"72\" y=\"192.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><line x1=\"80\" y1=\"145.0\" x2=\"660\" y2=\"145.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></line><text x=\"72\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><line x1=\"80\" y1=\"97.5\" x2=\"660\" y2=\"97.5\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></line><text x=\"72\" y=\"97.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">30</text><line x1=\"80\" y1=\"50.0\" x2=\"660\" y2=\"50.0\" stroke=\"var(--wire)\" stroke-width=\"0.6\"></line><text x=\"72\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">40</text><text x=\"80.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0%</text><text x=\"196.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10%</text><text x=\"312.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20%</text><text x=\"428.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">30%</text><text x=\"544.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">40%</text><text x=\"660.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">50%</text><text x=\"370.0\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">closed as “won't fix”, share of the team's closed findings</text><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">median days to close</text><circle cx=\"126.4\" cy=\"116.5\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"134.4\" y=\"106.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">links 4% · 26</text><circle cx=\"555.5999999999999\" cy=\"206.75\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"545.5999999999999\" y=\"192.75\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">payments 41% · 7</text><circle cx=\"149.6\" cy=\"83.25\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"157.6\" y=\"79.25\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">platform 6% · 33</text><circle cx=\"126.4\" cy=\"135.5\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"134.4\" y=\"147.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">web 4% · 22</text><path d=\"M650 120 L650 200\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l20-goodhart-ah-paper-dim)\"></path><text x=\"642\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a better median</text></svg>", "caption": "The team with the best median is the team that fixes least of what it closes. Either number alone would rank it first or last; the pair says why."}
```

### The ways a security number gets gamed

Each of these improves a number without reducing risk, and each is a decision that can be defended
one finding at a time:

- **Closing as "won't fix" or "accepted"**, as above. It moves time to remediate and debt at once.
- **Splitting findings.** One problem reported as several findings, each closed quickly, improves
  the count closed and the median. Merging duplicates before counting (the unit, in the first section
  of this lesson) is the defence.
- **Lowering the severity.** A high finding reclassified as medium gets 90 days instead of 30, and
  the SLA is met without a change to the code.
- **Scanning less.** Turning off a noisy scanner, or leaving a target out of the inventory, lowers
  every count of findings and debt. Only coverage notices.
- **Closing and reopening.** Where a tracker dates a finding from its latest opening, one closed the
  day before the report and raised again the day after starts at age zero, and the `181+` bucket
  empties.

### Defences that work

**Report numbers in pairs that pull against each other.** The median time to remediate with the
share of "won't fix"; the debt with the coverage; the findings closed with the findings reopened.
Gaming one number of a pair moves the other, and that is visible on the same page.

**Make a non-fix a decision with a name on it.** Lesson 7's exceptions have an owner, a reason and
an expiry date. A "won't fix" recorded the same way is not a way around the metric: it is a risk
somebody accepted and has to revisit, and it stays in the debt until the date passes.

**Do not turn a measure into a personal target.** A team's numbers are for the team to see where its
work is. Ranking teams by median, or tying a bonus to it, is exactly the arrangement in which the
numbers stop meaning anything.

### What to report to whom

| reader | what they need | the numbers |
|---|---|---|
| the team | what to work on next | the open list, sorted by SLA and age; their own time to remediate |
| the engineering lead | where help is needed | time to remediate and debt per team, with the "won't fix" share beside each |
| whoever answers for risk | what is unknown, and what was promised and not done | coverage per scanner, debt past SLA by severity, the trend |

The third row is the one most often reported wrong, as a single count of findings found this
quarter. That count says how busy the scanners were. Coverage and the debt past SLA say how much is
unknown and how much is late, which are the two things somebody accountable for risk can act on.
