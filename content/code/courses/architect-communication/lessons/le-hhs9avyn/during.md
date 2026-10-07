---
title: Updates during the incident
version: 1
---

**An update during an incident says what is affected, what is being done, and when the next update
will come, and it comes when it said it would, even if nothing has changed.** The content can be
thin. The rhythm cannot. Silence during an incident is read as either "nobody is working on it" or
"it is worse than they are saying", and neither helps.

## The four lines

Every update Lívia wrote on 6 March, internal or public, had the same four parts:

1. **Impact**, in the reader's terms: "Most customers cannot complete checkout."
2. **What is being done**: "Engineers are working on it." Later, specific: "We have found the cause
   and are stopping it."
3. **What is known and not known**, separately: "Browsing and baskets work. We do not yet know the
   cause."
4. **The next update**, with a time: "Next update by 19:45."

The first public update, at 19:27:

> **Investigating.** Since about 19:10, most customers cannot complete checkout. Browsing and baskets
> are not affected; items in your basket are kept. We are working on it and will update here by 19:45.

## The rhythm

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A timeline from 19:00 to 20:00 with two lanes. What happened: the job starts at 19:05, the alert at 19:16, the incident is declared at 19:19, the job is stopped at 19:38, checkout recovers at 19:41; checkout was failing for 32 minutes from 19:09. What was said: the support line at 19:26, investigating at 19:27, identified at 19:40, resolved at 19:56.\"><defs><marker id=\"inctimelin-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M60 150 L690 150\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><text x=\"60.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">19:00</text><text x=\"217.5\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">19:15</text><text x=\"375.0\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">19:30</text><text x=\"532.5\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">19:45</text><text x=\"690\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">20:00</text><polygon points=\"154.5,112 490.5,112 490.5,140 154.5,140\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></polygon><text x=\"322.5\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">checkout failing: 32 min</text><text x=\"14\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what</text><text x=\"14\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">happened</text><path d=\"M112.5 38 L112.5 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"112.5\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">job starts</text><path d=\"M228.0 68 L228.0 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"228.0\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">alert</text><path d=\"M259.5 98 L259.5 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"259.5\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">incident declared</text><path d=\"M459.0 38 L459.0 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"459.0\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">job stopped</text><path d=\"M490.5 68 L490.5 110\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></path><text x=\"490.5\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">recovers</text><text x=\"14\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what</text><text x=\"14\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">was said</text><path d=\"M333.0 152 L333.0 186\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><text x=\"327.0\" y=\"190\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">support line</text><path d=\"M343.5 152 L343.5 216\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><text x=\"343.5\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">investigating</text><path d=\"M480.0 152 L480.0 186\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><text x=\"480.0\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">identified</text><path d=\"M648.0 152 L648.0 216\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></path><text x=\"648.0\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">resolved</text><text x=\"60\" y=\"285\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Friday 6 March, Recife time; the leadership channel also got an update every fifteen minutes</text></svg>", "caption": "Two lanes of one evening. The first public word came eighteen minutes after the failure began; from then on, leadership heard something every fifteen minutes and the public at least every twenty."}
```

Lívia posted to the status page at 19:27, 19:40 and 19:56, and internally to the leadership channel
every fifteen minutes. The public labels followed a common convention, the one most status page
services use: **investigating, identified, monitoring, resolved.** Each label tells the reader where the
incident is without reading the text.

| time | public update |
|---|---|
| 19:27 | **Investigating.** Most customers cannot complete checkout; working on it; next update by 19:45. |
| 19:40 | **Identified.** We have found the cause, a background job overloading a database, and stopped it. Checkout is starting to recover. Next update by 20:00. |
| 19:56 | **Resolved.** Checkout has worked normally since 19:41. If a payment failed between 19:10 and 19:41, you were not charged; please try again. We will publish a summary on Monday. |

## What does not go in an update

- **A guess at the cause.** At 19:31 Lucas suspected the backfill. Lívia did not write "we think a
  batch job"; she waited until it was confirmed at 19:38. A wrong cause, published, has to be
  corrected publicly, and the correction is remembered longer than the incident.
- **An estimate of when it will be fixed**, unless somebody is confident. "Next update by 19:45" is a
  promise Lívia can keep; "fixed in 15 minutes" is one she cannot.
- **Internal names, systems and blame.** "A background job overloading a database" is accurate,
  complete and names nobody.
- **"Some customers", when it is most.** Understating the impact is noticed by every customer who is
  affected, and they are the ones reading.
