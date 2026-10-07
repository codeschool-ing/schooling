---
title: FAIR
version: 1
---

Lesson 9 multiplied two numbers per risk. **FAIR, Factor Analysis of Information Risk**, is what
that multiplication becomes when it is taken seriously. It brings a standard vocabulary for the
quantities involved, a way to break each one down when it is too hard to estimate directly, and the
habit of working with ranges rather than single values. It was created by Jack Jones in the
mid-2000s and is maintained by The Open Group as two standards, the risk taxonomy (O-RT) and the
risk analysis method (O-RA).

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l10-fair-tree\" aria-label=\"The FAIR taxonomy as a tree. Risk splits into loss event frequency and loss magnitude. Loss event frequency splits into threat event frequency, how often somebody tries, and vulnerability, the chance that a try becomes a loss. Threat event frequency splits into contact frequency and probability of action. Vulnerability splits into threat capability and resistance strength. Loss magnitude splits into primary loss, borne directly, and secondary loss, caused by how others react.\"><rect x=\"300.0\" y=\"10.0\" width=\"120.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">risk</text><rect x=\"90.0\" y=\"80.0\" width=\"200.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"190.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">loss event frequency</text><rect x=\"475.0\" y=\"80.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"560.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">loss magnitude</text><rect x=\"15.0\" y=\"154.0\" width=\"170.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"100.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">threat event</text><text x=\"100.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">frequency</text><rect x=\"215.0\" y=\"154.0\" width=\"150.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"290.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">vulnerability</text><rect x=\"420.0\" y=\"154.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"490.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">primary loss</text><rect x=\"570.0\" y=\"154.0\" width=\"140.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"640.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">secondary loss</text><rect x=\"4.0\" y=\"234.0\" width=\"96.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"52.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">contact</text><text x=\"52.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">frequency</text><rect x=\"104.0\" y=\"234.0\" width=\"96.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"152.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">probability</text><text x=\"152.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">of action</text><rect x=\"202.0\" y=\"234.0\" width=\"96.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"250.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">threat</text><text x=\"250.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">capability</text><rect x=\"302.0\" y=\"234.0\" width=\"96.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"350.0\" y=\"246.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">resistance</text><text x=\"350.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">strength</text><path d=\"M360.0 46.0 L190.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M360.0 46.0 L560.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M190.0 116.0 L100.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M190.0 116.0 L290.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M560.0 116.0 L490.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M560.0 116.0 L640.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M100.0 190.0 L52.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M100.0 190.0 L152.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M290.0 190.0 L250.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M290.0 190.0 L350.0 234.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"560.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">six forms of loss: productivity, response,</text><text x=\"560.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">replacement, fines, competitive advantage,</text><text x=\"560.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reputation</text></svg>", "caption": "Lesson 9 estimated the top two boxes directly. FAIR lets you estimate any box lower down when the top one is too hard to guess."}
```

### The taxonomy

At the top, the same two halves as lesson 9, with FAIR's names:

- **loss event frequency**: how often a loss happens per year, lesson 9's "events per year";
- **loss magnitude**: what one loss costs, lesson 9's "cost per event".

Each breaks down further, and the breakdown is the useful part, because **sometimes a lower box is
easier to estimate than the one above it.** T02, patient accounts taken over, is a good example.
"How many accounts are taken over a year?" was answered from complaints, but the complaints only
count the patients who noticed. FAIR splits the question:

| box | the question | Vereda's evidence |
|---|---|---|
| **threat event frequency** | how often does somebody try? | the sign-in log: bursts of failed logins most weeks |
| **vulnerability** | what fraction of tries become a loss? | how many of the tried passwords were in breach lists, and how many accounts used them |

Each box has evidence of its own, and the product is a better estimate than a number pulled from a
complaints inbox.

Loss magnitude splits into **primary loss**, borne directly when the event happens (the
investigation, the staff time), and **secondary loss**, caused by how others react (the patients
who leave, the regulator, the lawyers). FAIR also names **six forms of loss**, which work as a
checklist for lesson 9's impact tables: productivity, response, replacement, fines and judgements,
competitive advantage, and reputation.

### What FAIR asks of you

Ranges. Every box is estimated as a range, as lesson 9 recommended, because the method's output is
a distribution, not a point. And honesty about the units: frequencies per year, losses in money. A
FAIR analysis that writes "high" in a box has stopped being one.

What it does not ask is that you fill every box. Most real analyses estimate at the highest level
where there is evidence, and break down only the boxes where a direct estimate would be a guess.
Vereda broke down T02 and estimated the other eight directly.
