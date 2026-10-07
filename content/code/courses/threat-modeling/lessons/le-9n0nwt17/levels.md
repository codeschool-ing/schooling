---
title: Levels, from context to detail
version: 1
---

A DFD of a whole system with every function in it is unreadable, and a DFD with one circle in it
finds nothing. The way out is to draw **levels**: the same system at increasing detail, each level
opening one process of the level above.

### Level 0: the context diagram

The first drawing shows **the whole system as one process**, every external entity it talks to,
and the flows between them. Nothing inside is shown.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l02-context\" aria-label=\"The context diagram of the portal: the whole system as one process in the middle, called Vereda patient portal, and the four external entities around it. Patients send bookings, payments and exams and receive pages. Clinic staff manage the agenda and records. The payment gateway receives charges and sends confirmations. The SMS provider receives reminders.\"><defs><marker id=\"l02-context-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><circle cx=\"360.0\" cy=\"140.0\" r=\"62\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"360.0\" y=\"133.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Vereda</text><text x=\"360.0\" y=\"146.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">patient portal</text><rect x=\"25.0\" y=\"50.0\" width=\"130.0\" height=\"40.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Patient</text><rect x=\"25.0\" y=\"195.0\" width=\"130.0\" height=\"40.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Clinic staff</text><rect x=\"565.0\" y=\"50.0\" width=\"130.0\" height=\"40.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Payment gateway</text><rect x=\"565.0\" y=\"195.0\" width=\"130.0\" height=\"40.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"630.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SMS provider</text><path d=\"M155.0 62.0 L305.0 112.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-context-tm-ah-paper-dim)\"></path><path d=\"M303.0 128.0 L155.0 80.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-context-tm-ah-paper-dim)\"></path><text x=\"212.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">bookings, exams</text><text x=\"236.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">pages</text><path d=\"M155.0 215.0 L305.0 168.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-context-tm-ah-paper-dim)\"></path><text x=\"212.0\" y=\"216.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">agenda, notes</text><path d=\"M418.0 118.0 L565.0 66.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-context-tm-ah-paper-dim)\"></path><path d=\"M565.0 80.0 L420.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-context-tm-ah-paper-dim)\"></path><text x=\"480.0\" y=\"62.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">charges</text><text x=\"500.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">webhook</text><path d=\"M418.0 165.0 L565.0 212.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-context-tm-ah-paper-dim)\"></path><text x=\"500.0\" y=\"205.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">reminders</text><text x=\"360.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Level 0: one process, every outsider, every flow that crosses into the system.</text></svg>", "caption": "The context diagram answers one question: what does the system talk to? It is the first drawing and the one an executive reads."}
```

The context diagram is cheap and finds real things. It is where somebody says "the SMS provider
receives the patient's name and the clinic's address, did we agree that with them?", and that is
a question about personal data leaving the company, which lesson 5's LINDDUN would ask again. It is
also the drawing to show daniel, who runs the clinics: it fits on one slide and every box is
something daniel recognises.

### Level 1: the main parts

Level 1 opens the single process into the parts that matter: the portal, the staff console, the
reminder worker, and the two data stores. The external entities and their flows stay the same;
what is new is the flows between the parts, and the boundaries between them. **Most threat models
live at level 1**, because it is where the trust boundaries inside the system appear. The next
section draws it.

### Level 2 and further: only where it pays

A level 2 opens one process of level 1, such as the portal into its sign-in, booking, upload and
payment functions. It is worth drawing **for a part that is both complex and exposed**: the
portal's upload, which takes files from anybody, might deserve one. The reminder worker, which
reads a table and calls one API, does not. Opening every process "for completeness" is how a model
becomes more detailed than the design it describes, which lesson 1 named as a sign of having gone
past useful.

### Keeping levels consistent

A level must not contradict the one above. Every flow that enters a process at level 0 has to
enter one of its parts at level 1, with the same label. When it does not, either the higher level
is missing a flow or the lower level invented one, and both are worth knowing. This is called
**balancing** the diagram, and it is one of the few checks a DFD can have without a person
reading it.
