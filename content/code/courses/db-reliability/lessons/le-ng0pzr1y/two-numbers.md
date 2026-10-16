---
title: Two numbers, both measured in time
version: 1
---

Ask the people who depend on a database how much data they can afford to lose and how long they can
afford to be without it, and the first answer is nearly always **none and none**. That answer is not
a requirement. It is what somebody says before anybody has shown them the price, and it is the
reason most organisations have no real numbers at all: a target nobody can meet gets quietly
ignored, and the ignored target is the same as no target.

The two real numbers have names:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A time axis. In the middle, the incident. To its left, the last moment you can get back; the stretch between them is the RPO, data written there is lost. To its right, the moment people can work again; the stretch between is the RTO, when nobody can work.\"><defs><marker id=\"l8t-pa\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><defs><marker id=\"l8t-wi\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M20 100 L700 100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8t-wi)\"></path><text x=\"700\" y=\"88\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">time</text><path d=\"M170 70 L170 150\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"170\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">last moment you can get back</text><path d=\"M360 70 L360 150\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"360\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the incident</text><path d=\"M560 70 L560 150\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"560\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">working again</text><rect x=\"176\" y=\"112\" width=\"178\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"265\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">written here: lost</text><rect x=\"366\" y=\"112\" width=\"188\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"460\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">nobody can work</text><path d=\"M176 50 L354 50\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8t-pa)\" marker-start=\"url(#l8t-pa)\"></path><text x=\"265\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">RPO: how much loss</text><path d=\"M366 50 L554 50\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l8t-pa)\" marker-start=\"url(#l8t-pa)\"></path><text x=\"460\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">RTO: how long down</text></svg>", "caption": "The two objectives on one axis. The RPO reaches back from the incident to the last moment that can be recovered; the RTO reaches forward to the moment the system is usable again."}
```

- **RPO, the recovery point objective**, is how much data the business accepts losing, **measured
  as time**: "at most five minutes of orders". It points backwards from the incident to the last
  moment you can get back. Everything written after that moment is gone.
- **RTO, the recovery time objective**, is how long the business accepts being without the system:
  "back within two hours". It points forwards from the incident to the moment people can work again.

Both are in time because time is what the business can reason about. "We lose at most 300 MB of log"
means nothing to the person who runs the shop; "we lose at most the last five minutes of orders"
means a number of sales and an apology to that many customers.

## Three things they are not

- **They are not one pair per company.** The shop's orders and its weekly newsletter list do not
  deserve the same numbers, and paying for the strictest pair everywhere is how backup budgets
  explode. Each system gets its own, and a few tiers usually cover everything.
- **They are not what the setup achieves.** An RPO is a promise; what lesson 4's archive gives is a
  measurement. This lesson measures the second so the first can be checked against it.
- **They are not about one kind of failure.** A disk that dies, a region that goes dark, a `DELETE`
  with the wrong `WHERE` and a ransomware attack (lesson 10) each have their own RPO and RTO under
  the same setup. A replica gives almost no data loss for a dead disk and **no protection at all**
  for the `DELETE`, which it copies faithfully within a second. The numbers have to say which
  failure they are about.
