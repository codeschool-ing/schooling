---
title: Hunting is not alerting
version: 1
---

An alert is a question somebody wrote **before** the event: "tell me when this happens". It catches what
its author imagined. **Threat hunting** is the opposite direction: a person starts from the assumption that
something the rules did not imagine is already in the environment, and goes looking for it in the data.

| | alerting | hunting |
|---|---|---|
| starts from | a rule, written in advance | a hypothesis, written today |
| runs | continuously, by machine | in a campaign, by a person |
| looks for | what somebody expected | what nobody wrote a rule for |
| ends | when the alert is closed | in a finding, a new rule, or a documented negative |

A common misunderstanding is that hunting means browsing logs until something looks odd. Browsing finds
whatever is visually loud, which is rarely what matters, and it cannot be repeated or measured. **A hunt has
a written hypothesis, a defined data set, a method and an outcome**, and each part is recorded so another
analyst could run it again.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"The hunting loop: a hypothesis leads to choosing the data, the data to a search, the search to validation, and validation to one of three outcomes: a finding handed to incident response, a new rule, or a documented negative. Each outcome feeds the next hypothesis.\"><rect x=\"20\" y=\"30\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"80.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hypothesis</text><path d=\"M140 52 L170 52\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M170 52 L162.0 48.0 L162.0 56.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"170\" y=\"30\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"230.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">data</text><path d=\"M290 52 L320 52\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M320 52 L312.0 48.0 L312.0 56.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"320\" y=\"30\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"380.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">search</text><path d=\"M440 52 L470 52\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M470 52 L462.0 48.0 L462.0 56.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"470\" y=\"30\" width=\"120\" height=\"44\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"530.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">validate</text><rect x=\"30\" y=\"140\" width=\"200\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"130.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">finding: to incident response</text><rect x=\"260\" y=\"140\" width=\"200\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a new rule</text><rect x=\"490\" y=\"140\" width=\"200\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a documented negative</text><path d=\"M530 74 L530 100 L130 100 L130 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M130 140 L134.0 132.0 L126.0 132.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M530 100 L360 100 L360 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M360 140 L364.0 132.0 L356.0 132.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M530 100 L590 100 L590 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M590 140 L594.0 132.0 L586.0 132.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M690 160 L705 160 L705 15 L80 15 L80 30\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M80 30 L84.0 22.0 L76.0 22.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path></svg>", "caption": "A hunt ends in one of three ways, and all three are results."}
```

The three outcomes on the bottom row are all results. A **finding** goes to incident response as an
escalation (lesson 7). A **new rule** means this question never has to be hunted by hand again. And a
**documented negative**, "we looked for X in these data with this method, and it is not there", is
information the next person can rely on, as long as it says exactly what was searched.
