---
title: Detection, and declaring an incident
version: 1
---

An incident is not a technical event; it is a decision. Errors rise, an alarm fires, a customer
writes in, and at some point somebody says **"this is an incident"**, and from that moment the way the
team works changes: one person in charge, one place to talk, updates on a clock. The commonest failure
is not slow repair. It is **slow declaration**: forty minutes of three people investigating in private
chats, each assuming somebody else is telling the customers.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A line of six stages of an incident: impact starts, detected, declared, mitigated, resolved, reviewed. Above the line, the gap from impact to detection is labelled time to detect, and from detection to declaration time to declare. Below, the span from impact to mitigation is labelled time to mitigate, what customers feel. Under reviewed: the next incident starts here.\"><defs><marker id=\"lc-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"84\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">impact starts</text><path d=\"M121 110 L135 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lc-ah)\"></path><rect x=\"136\" y=\"84\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"186.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">detected</text><path d=\"M237 110 L251 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lc-ah)\"></path><rect x=\"252\" y=\"84\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"302.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">declared</text><path d=\"M353 110 L367 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lc-ah)\"></path><rect x=\"368\" y=\"84\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"418.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">mitigated</text><path d=\"M469 110 L483 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lc-ah)\"></path><rect x=\"484\" y=\"84\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"534.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">resolved</text><path d=\"M585 110 L599 110\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lc-ah)\"></path><rect x=\"600\" y=\"84\" width=\"100\" height=\"52\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"650.0\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reviewed</text><path d=\"M70 60 L186 60\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"128.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">time to detect</text><path d=\"M186 60 L302 60\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"244.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">time to declare</text><path d=\"M70 162 L418 162\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"244.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">time to mitigate: what customers feel</text><text x=\"650\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the next incident</text><text x=\"650\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">starts here</text></svg>", "caption": "Customers feel the time to mitigation. Resolution and review come after the graph is green."}
```

## Who noticed first

The first question of every review is how the incident was detected, and the honest answers fall in
three groups, from best to worst:

1. **an alert on a symptom** (lesson 10's composite, lesson 12's burn rate) paged the person on call;
2. **a person on the team** noticed a graph, a log line, a failed deploy;
3. **a customer** reported it.

The time from the start of the impact to its detection is the **time to detect**, and the third group is
where it is longest and where trust is lost. Every incident a customer reported first is a gap in the
alerting, and closing it is an action from the review.

## Severity, decided fast

A severity scale lets the person who declares say how big it is without a meeting. Keep it short and
define it by impact on customers, never by the component that broke:

| severity | the impact | what follows |
|---|---|---|
| SEV1 | checkout or sign-in down for most customers, or data at risk | page the incident commander, status page within 15 minutes |
| SEV2 | a feature down, or the whole service degraded | page the on-call, status page if customers notice |
| SEV3 | a minor feature broken, a workaround exists | a ticket, fixed in working hours |

**When unsure, declare the higher one**: downgrading costs a message, while an under-declared incident
costs the hour in which nobody was in charge.

## Declare in a fixed place

Declaration is one message in one agreed place: an incident channel created for it, with a name that says
what and when. Everything about the incident happens there, so the person who joins at minute forty reads
the channel instead of interrupting the people fixing it.
