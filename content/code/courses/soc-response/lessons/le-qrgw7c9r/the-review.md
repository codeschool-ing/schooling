---
title: The review, and when to hold it
version: 1
---

The last phase of incident response is the one most often skipped, and for an understandable reason: by the
time recovery ends, the systems work, the people involved are tired, and the incident feels finished. It is
not. **The lessons-learned phase is where an incident stops being a cost and starts being an investment**,
and without it the same weakness waits for the next intruder.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"The six phases of incident response in a row: preparation, identification, containment, eradication, recovery, lessons learned. An arrow runs from lessons learned back to preparation: what the review finds becomes the next incident's preparation.\"><rect x=\"6\" y=\"40\" width=\"106\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"59\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">preparation</text><path d=\"M112 65 L124 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M124 65 L116.0 61.0 L116.0 69.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"124\" y=\"40\" width=\"106\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"177\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">identification</text><path d=\"M230 65 L242 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M242 65 L234.0 61.0 L234.0 69.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"242\" y=\"40\" width=\"106\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"295\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">containment</text><path d=\"M348 65 L360 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M360 65 L352.0 61.0 L352.0 69.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"360\" y=\"40\" width=\"106\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"413\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">eradication</text><path d=\"M466 65 L478 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M478 65 L470.0 61.0 L470.0 69.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"478\" y=\"40\" width=\"106\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"531\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">recovery</text><path d=\"M584 65 L596 65\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M596 65 L588.0 61.0 L588.0 69.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"596\" y=\"40\" width=\"106\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"649\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lessons learned</text><path d=\"M653 90 L653 150 L59 150 L59 90\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M59 90 L55.0 98.0 L63.0 98.0 Z\" fill=\"var(--amber)\" stroke=\"none\"></path><text x=\"356\" y=\"170\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">actions with an owner and a date</text></svg>", "caption": "The last phase writes the first one. A review whose actions never reach preparation was a meeting."}
```

The heart of it is one meeting, the **review**, also called the **postmortem**. NIST SP 800-61 recommends
holding it **within several days** of the end of the incident: soon enough that people remember what they
did and why, late enough that recovery is not still under way. For Thursday, recovery closed on 2 October, and
the review is on 6 October.

Who comes:

| who | why |
|---|---|
| everybody who worked the incident | they know what happened, including what is not in the record |
| the owners of the systems involved | they decide what changes on their systems |
| a **facilitator** who did not work it | somebody whose only job is to keep the meeting on questions, not answers |
| the executive sponsor, at least for the actions | some actions cost money, and only the sponsor can approve that |

The questions NIST suggests are a good agenda, in this order: what exactly happened, and when; how well the
team and its procedures did; what information was needed sooner; whether any step made recovery harder;
what the team would do differently; and what would prevent a similar incident, or catch it earlier.

**The meeting has one rule that makes all the others work: it looks for causes, not for culprits.** The third
section of this lesson is about why, and what that changes in practice.
