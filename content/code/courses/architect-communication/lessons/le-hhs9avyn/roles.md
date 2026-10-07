---
title: Who talks, who fixes, who decides
version: 1
---

**During an incident, the people fixing it should not also be the people explaining it.** Every
minute an engineer spends answering "what's going on?" in a chat is a minute not spent finding out,
and every update written by somebody in the middle of debugging is written in the language of the
debugging. Splitting the roles is the single change that most improves incident communication.

## Friday 6 March

At 19:09 on a Friday, Marola's busiest hour, checkout started failing for almost every customer. It
lasted until 19:41: **32 minutes, and about 1,350 failed checkouts.** Lesson 15 is about what caused it
and what was learnt. This lesson is about what was said, to whom, while it was happening and in the
days after.

## The roles

The idea comes from firefighting. In the 1970s, after wildfires in California where several agencies
fought the same fire without a shared structure, the fire services developed the **Incident Command
System**: one person in command, with clearly separated roles under them. Software operations borrowed
it, and Google's *Site Reliability Engineering* book made the borrowed version widely known.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"An incident commander, Bruna, who coordinates and decides, above three roles: the operations lead, Lucas, who diagnoses and fixes; the communications lead, Lívia, who writes every update; and the scribe, Diego, who keeps the timeline.\"><defs><marker id=\"incroles-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"250\" y=\"20\" width=\"220\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">incident commander</text><text x=\"360\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Bruna: coordinates, decides</text><rect x=\"20\" y=\"150\" width=\"200\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"120\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">operations lead</text><text x=\"120\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Lucas: diagnoses, fixes</text><path d=\"M360 78 L120 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#incroles-ah)\"></path><rect x=\"260\" y=\"150\" width=\"200\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">communications lead</text><text x=\"360\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Lívia: every update</text><path d=\"M360 78 L360 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#incroles-ah)\"></path><rect x=\"500\" y=\"150\" width=\"200\" height=\"56\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"600\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">scribe</text><text x=\"600\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Diego: the timeline</text><path d=\"M360 78 L600 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#incroles-ah)\"></path><text x=\"20\" y=\"240\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the one combination to avoid: operations and communications in the same person</text></svg>", "caption": "The roles on 6 March. The commander does not debug, and the person fixing the system is not the person explaining it."}
```

| role | does | at Marola on 6 March |
|---|---|---|
| **incident commander** | coordinates, decides, keeps everybody pointed at the same goal; does not debug | Bruna, the on-call engineer, who declared the incident at 19:19 |
| **operations lead** | works on the system: diagnoses, mitigates, fixes | Lucas, from the platform team |
| **communications lead** | writes every update, internal and external, on a schedule | Lívia, who joined at 19:22 |
| **scribe** | keeps the timeline: what was seen, what was tried, when | Diego, who was in the channel anyway |

In a small incident one person may hold two roles. **The one combination to avoid is operations and
communications in the same person**: the updates stop when the problem is hardest, which is when
people most want them.

::: track tech-lead
`delivery-metrics` lessons 13 and 14, earlier in your track, set up severity levels, the incident
commander and the timeline as a team's process. This lesson takes the communications lead's seat and
stays in it.
:::

::: track *
`process-management` lesson 8 covers incident management as ITIL describes it, as a process. This
lesson takes one seat in that process, the communications lead's, and stays in it.
:::

## One channel

At 19:19 Bruna opened a dedicated incident channel and posted one line in the engineering channel:
"Checkout incident, all discussion in #inc-0306." **Everything about the incident goes in one place**,
so the timeline is complete, the people working on it are not reading four threads, and anybody who
wants to know what is happening knows where to look without asking.
