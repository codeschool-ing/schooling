---
title: What stays out of a ticket
version: 1
---

A ticket is a document other people read, and some things do not belong in one:

- **Opinions about the person.** *"User doesn't know how to use a computer"* helps nobody and can be
  read by them, their manager, or anybody who asks for their personal data under the LGPD, lesson 13.
  Write what happened: *the default printer was set to PDF*.
- **Passwords and secrets**, including ones the user told you to "make it quicker". A ticket is kept
  for years and read by many.
- **Personal data you saw and did not need**: a file's contents, an e-mail on the screen. Lesson 13 is
  about what a technician sees; the ticket records the fault, not what else was on the computer.

The ticket also moves through states, and they are worth using exactly:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"The life of a ticket in five states. New, in progress, waiting on user, resolved, closed. Waiting on user goes back to in progress when they answer. From resolved, a ticket closes once the user has confirmed, or it is reopened if the problem came back, rather than starting a new ticket.\"><defs><marker id=\"lf-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"50\" width=\"122\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">new</text><path d=\"M144 70 L158 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\"></path><rect x=\"160\" y=\"50\" width=\"122\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">in progress</text><path d=\"M284 70 L298 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\"></path><rect x=\"300\" y=\"50\" width=\"122\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">waiting on user</text><path d=\"M424 70 L438 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\"></path><rect x=\"440\" y=\"50\" width=\"122\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"450\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">resolved</text><path d=\"M564 70 L578 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\"></path><rect x=\"580\" y=\"50\" width=\"122\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">closed</text><path d=\"M 321 48 C 321 22, 221 22, 221 46\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\" stroke-dasharray=\"3 3\"></path><text x=\"271\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">they answer</text><path d=\"M 461 92 C 461 150, 241 150, 241 94\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lf-ah)\" stroke-dasharray=\"4 3\"></path><text x=\"351\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">it came back: reopen, do not start a new one</text></svg>", "caption": "Resolved and closed are two states on purpose: resolved is the technician's claim, closed is the user's agreement. A problem that comes back reopens the same ticket, so its history stays whole."}
```

**Waiting on user** stops the clock on the support team's side, lesson 6, which is why it is only for
when the next step really is theirs. **Resolved** is the technician's claim, and **closed** is the
user's agreement, lesson 1's confirm step.
