---
title: Stages 1 to 3, the business and the system
version: 1
---

The first three stages build the context everything else is judged against. At Vereda they took a
morning, with daniel in the room for the first one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l04-first-stages\" aria-label=\"What PASTA’s first three stages produced at Vereda. Stage 1, objectives: about 60% of bookings come through the portal, and health data is sensitive under the LGPD. Stage 2, technical scope: what is modelled and what is not, such as the clinics’ Wi-Fi and laptops. Stage 3, decomposition: the DFD of lesson 2, with the use cases beside it.\"><defs><marker id=\"l04-first-stages-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"210.0\" height=\"180.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1 · objectives</text><text x=\"125.0\" y=\"100.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">60% of bookings</text><text x=\"125.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">via the portal</text><text x=\"125.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">health data is</text><text x=\"125.0\" y=\"139.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sensitive (LGPD)</text><path d=\"M230.0 110.0 L255.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-first-stages-tm-ah-paper-dim)\"></path><rect x=\"255.0\" y=\"20.0\" width=\"210.0\" height=\"180.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2 · technical scope</text><text x=\"360.0\" y=\"100.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">what is modelled,</text><text x=\"360.0\" y=\"113.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">and what is not:</text><text x=\"360.0\" y=\"126.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the clinics’ Wi-Fi</text><text x=\"360.0\" y=\"139.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">and laptops</text><path d=\"M465.0 110.0 L490.0 110.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-first-stages-tm-ah-paper-dim)\"></path><rect x=\"490.0\" y=\"20.0\" width=\"210.0\" height=\"180.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"42.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3 · decomposition</text><text x=\"595.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the DFD of lesson 2</text><text x=\"595.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">and the use cases</text><text x=\"595.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">beside it</text><text x=\"360.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">the business first, then the system</text></svg>", "caption": "Stage 1 is the one STRIDE never asks for, and it is the one that later decides which threats are expensive."}
```

### Stage 1: define the objectives

**What is the system for, and what would hurt if it stopped doing it?** The output is a short list
of business objectives, the security and compliance requirements that come with them, and a first
statement of impact: what failing each objective costs.

| objective | why it matters | compliance |
|---|---|---|
| patients book and pay online | about 60% of bookings come through the portal; the rest by phone | consumer protection, payment card rules through the gateway |
| clinical data stays private | patients share what they would tell nobody else | the **LGPD**: health data is *sensitive personal data* (art. 5, II and art. 11) |
| reminders reach patients | a missed session is an empty slot nobody pays for | none of its own |
| Vereda meets the LGPD | the ANPD can fine and order a stop to processing | the law itself |

The table is where daniel earns a place in the workshop. A developer would not have written that 60% of bookings
come through the portal, and that number is what makes T01 and T10 expensive in stage 7.

### Stage 2: define the technical scope

**What exactly is being modelled, and what is it built from?** The components, the infrastructure
they run on, the third parties, and the dependencies that come with each. At Vereda: the portal,
the staff console and the worker, the cloud account they run in, the managed database, the
object storage, the SMS provider and the payment gateway, and the libraries each process imports.
The PDF library the console uses to show exams is on this list, which is how T14 got a name.

Stage 2 also writes down **what is out of scope**: the clinics' own Wi-Fi and laptops, which bruno
looks after separately. Out of scope is a decision, and writing it down stops the model being
blamed later for something it never covered.

### Stage 3: decompose the application

**How does data move, and where does trust change?** This is lesson 2: the DFD at level 1, the
trust boundaries, the actors, and the entry points. PASTA adds a list of **use cases** beside the
drawing, because stage 6 will need them: "a patient books and pays", "a physiotherapist opens an
exam", "the worker sends tomorrow's reminders". Each use case is a path through the DFD, and each
will be read backwards in stage 6 as the route somebody could abuse.

Vereda already had stage 3 done when it started PASTA. That is the common case: a team that has
been drawing DFDs can adopt PASTA by adding stages around the work it already does.
