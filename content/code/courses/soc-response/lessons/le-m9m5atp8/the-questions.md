---
title: The questions triage asks
version: 1
---

**Triage** is the first look at an alert: deciding, in minutes, whether it is noise to close or something
to escalate. It is not the investigation. A triage analyst who spends an hour on one alert has stopped
triaging, and the queue behind them is growing.

The week, seen as a funnel:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"The week as a funnel, top to bottom: 382 events in the table; 150 failed logins; 5 alerts from lesson 4's first rule; 2 of them true; 1 incident, which is everything that address did that night.\"><rect x=\"40.0\" y=\"12\" width=\"640\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"54.0\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">382</text><text x=\"100.0\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">events in the table</text><rect x=\"100.0\" y=\"53\" width=\"520\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"114.0\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">150</text><text x=\"160.0\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">failed logins</text><rect x=\"160.0\" y=\"94\" width=\"400\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"174.0\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">5</text><text x=\"220.0\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">alerts, rule v1</text><rect x=\"220.0\" y=\"135\" width=\"280\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"234.0\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2</text><text x=\"280.0\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">true alerts</text><rect x=\"280.0\" y=\"176\" width=\"160\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"294.0\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1</text><text x=\"340.0\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">incident</text></svg>", "caption": "Each step down is a decision somebody made. Triage is the third and fourth."}
```

Every level is a decision. The rule decided which of 150 failures deserved a person; triage decides which
of the alerts are true, and which true ones belong together as one incident. Getting the funnel's shape
right matters more than speed: **closing a true alert is the costliest mistake in a SOC**, because nothing
downstream will ever look at it again.

Five questions, in order, for every alert:

1. **What fired, and on what?** The rule, its fields, the events it matched. Read them; do not trust the
   title.
2. **Is it real?** Do the events say what the rule claims? A parsing error or a test can produce a perfect
   alert about nothing.
3. **Is it expected?** Does the history or the business explain it: a known user from a known place, a
   scheduled job, an approved test?
4. **How bad would it be?** If it is what it looks like, which assets, data and people are involved?
5. **What next?** Close with a reason, escalate with what you found, or ask for one specific piece of
   information.

Questions 2 and 3 are where most alerts end. Question 4 is what makes a true alert urgent or not.
