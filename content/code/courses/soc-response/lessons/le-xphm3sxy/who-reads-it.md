---
title: Who reads it, and what it is for
version: 1
---

Lesson 15's postmortem was written for the people who run the systems, to change things. The **incident report**
is written for everybody else, to explain: the managing partner and the partners, the clients whose data may be
involved, the insurer, the auditor, and if it comes to that, the ANPD or a court. It is the document that outlives
the incident, and in a year it will be the only account of Thursday that most of its readers ever see.

That sets three requirements:

- **It stands alone.** A reader who was not there, and has never heard the words `gw` or SIEM, can follow it.
  Technical detail goes into appendices, where a specialist can check it.
- **Every claim can be checked.** A fact has a source a reader could ask to see; a number has the query that
  produced it. The report is written on the assumption that somebody will ask.
- **It says how sure it is.** What is confirmed, what is likely, what is not known. The uncertainty is not a
  weakness of the report; leaving it out is.

The body of it follows a chain, and each link rests only on the one before:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Four boxes joined left to right: facts, each with a source; impact, what the facts mean for the company and for people; cause, why it was possible; recommendation, what would stop it happening again. Each box rests only on the one before it.\"><rect x=\"10\" y=\"40\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">facts</text><text x=\"90.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each with a source</text><path d=\"M170 75 L190 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M190 75 L182.0 71.0 L182.0 79.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"190\" y=\"40\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"270.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">impact</text><text x=\"270.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what the facts mean</text><path d=\"M350 75 L370 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M370 75 L362.0 71.0 L362.0 79.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"370\" y=\"40\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"450.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cause</text><text x=\"450.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">why it was possible</text><path d=\"M530 75 L550 75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M550 75 L542.0 71.0 L542.0 79.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"550\" y=\"40\" width=\"160\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">recommendation</text><text x=\"630.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what stops it next time</text></svg>", "caption": "A recommendation with no cause behind it, or an impact with no fact, is an opinion."}
```

Facts, then what they mean, then why it happened, then what to do. A recommendation with no cause behind it is a
wish; an impact with no fact under it is a fear. The rest of this lesson takes the four links in order, for
Thursday.
