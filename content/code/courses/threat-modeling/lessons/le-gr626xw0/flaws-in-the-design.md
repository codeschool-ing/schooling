---
title: Flaws live in the design
version: 1
---

Security defects come in two kinds, and the tools that find one are blind to the other. **A bug is
code that does not do what the design says.** A query built by joining strings when the design
said parameterised, a session cookie missing `HttpOnly`: the design was right and the
implementation slipped. **A flaw is a design that is wrong**, implemented faithfully. Every line
does what it was asked to do, and what it was asked to do is unsafe.

| | a bug | a flaw |
|---|---|---|
| where it was born | the implementation | the requirement or the design |
| example at the portal | the booking search concatenates the patient's text into SQL | the payment webhook marks a booking paid for any request that says so, from anybody |
| what finds it | code review, static analysis, tests, a scanner | reading the design and asking what can go wrong |
| what fixing it means | changing some lines | changing the design, and then the lines |

The `secure-code` course (lesson 1) draws the same line from the developer's side. This course
lives on the right-hand column.

### Why scanners walk past a flaw

The webhook example is worth following through. The handler receives a request, reads a booking
id and a status from the body, and updates the row. It uses a parameterised query. It validates
that the id is a number. A static analyser has nothing to report, because there is no dangerous
call. A dynamic scanner sends malformed input and gets clean errors back. The code is correct. What
is missing is a step nobody designed: **checking that the request came from the payment gateway**,
by verifying the signature the gateway puts on every call. Without it, anybody who learns the
webhook's address can mark their own booking as paid.

Nothing in the code points at the missing step, because a missing step leaves no line to flag. It
is found by somebody looking at the drawing, seeing an arrow from outside into the portal that
changes money, and asking: *who is allowed to send this?*

### What it costs to find it late

The usual argument for doing this early quotes a multiplier: a defect costs ten, or a hundred, times
more to fix in production than in design. **Be careful with that number.** It is repeated
everywhere and traced to studies from the 1970s and 1980s whose data is hard to find, and the
specific figures do not survive a close look at their sources. The argument does not need them,
because the mechanism is visible on its own:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l01-where-found\" aria-label=\"One design flaw, found at five moments. At the requirement or in design, fixing it means changing a drawing in a meeting. In code, it means rewriting the module that was built on it. In testing, the rewrite plus the tests built around the old shape. In production, the rewrite, migrating the data already stored the wrong way, and possibly an incident to answer for.\"><defs><marker id=\"l01-where-found-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"128.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"84.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">requirement</text><rect x=\"34.0\" y=\"175.0\" width=\"100.0\" height=\"30.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"84.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">change a sentence</text><path d=\"M148.0 58.0 L158.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-where-found-tm-ah-paper-dim)\"></path><rect x=\"158.0\" y=\"40.0\" width=\"128.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"222.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">design</text><rect x=\"172.0\" y=\"153.0\" width=\"100.0\" height=\"52.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"222.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">change a drawing</text><text x=\"222.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">in a meeting</text><path d=\"M286.0 58.0 L296.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-where-found-tm-ah-paper-dim)\"></path><rect x=\"296.0\" y=\"40.0\" width=\"128.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">code</text><rect x=\"310.0\" y=\"131.0\" width=\"100.0\" height=\"74.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">rewrite the module</text><text x=\"360.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">built on it</text><path d=\"M424.0 58.0 L434.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-where-found-tm-ah-paper-dim)\"></path><rect x=\"434.0\" y=\"40.0\" width=\"128.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"498.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">testing</text><rect x=\"448.0\" y=\"109.0\" width=\"100.0\" height=\"96.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"498.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the rewrite, and</text><text x=\"498.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the tests around it</text><path d=\"M562.0 58.0 L572.0 58.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-where-found-tm-ah-paper-dim)\"></path><rect x=\"572.0\" y=\"40.0\" width=\"128.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"636.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">production</text><rect x=\"586.0\" y=\"87.0\" width=\"100.0\" height=\"118.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"636.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the rewrite, a data</text><text x=\"636.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">migration, an incident</text><text x=\"20.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">what fixing it involves</text></svg>", "caption": "No percentage, because the honest number depends on the flaw. What grows is the list of things that have to change."}
```

Found in design, the webhook flaw is a sentence in a requirement and an arrow redrawn on a
whiteboard. Found in production, it is the change to the handler, plus finding out which bookings
were marked paid by somebody other than the gateway, plus deciding what to tell those patients and
the clinic's accountant. The fix itself is the same few lines at every stage. Everything around it
grows.

### What threat modelling is not

Three things get called threat modelling and are something else:

- **A penetration test.** A pentest attacks the built system to find what is exploitable now. It is
  evidence about the implementation, after the fact. A threat model is reasoning about the design,
  and it tells a pentester where to look.
- **A checklist.** A list of controls asks "did we do X?". It cannot ask what this particular
  system needs that is on nobody's list, which is where flaws live.
- **A compliance document.** An auditor may ask to see a threat model (lesson 14). Writing one *for*
  the auditor produces the document and skips the thinking, and the manifesto's first value
  statement exists because that happens so often.
