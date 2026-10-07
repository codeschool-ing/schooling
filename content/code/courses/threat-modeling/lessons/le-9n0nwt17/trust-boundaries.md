---
title: Trust boundaries
version: 1
---

Without the dashed line, a data flow diagram is documentation. With it, the diagram becomes a
threat model, because **a trust boundary marks where the level of trust changes, and a flow
crossing one is where most threats live.** On one side of the line, the data and the code are
controlled by one set of people and permissions; on the other side, by different ones. Anything
crossing has to be checked on arrival, because whatever was true on the far side is no longer
guaranteed.

The common wrong idea is that there is one boundary: the firewall, with the outside world beyond
it and everything trusted inside. That picture misses most of the boundaries a real system has.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l02-boundaries-redrawn\" aria-label=\"The same five parts drawn twice. On the left, one boundary around everything Vereda runs, the firewall view: patient outside, portal, worker and database inside together. On the right, boundaries wherever trust changes: the portal answers the internet, so it sits in its own zone; the database and the worker sit in a private network; the SMS provider is another company. The flow from the worker to the database now crosses nothing, and the flow from the portal to the database crosses a boundary that the left drawing hid.\"><defs><marker id=\"l02-boundaries-redrawn-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"175.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">one boundary: inside and outside</text><rect x=\"10.0\" y=\"73.0\" width=\"80.0\" height=\"34.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"50.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Patient</text><circle cx=\"165.0\" cy=\"90.0\" r=\"30\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"165.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Portal</text><rect x=\"120.0\" y=\"205.0\" width=\"90.0\" height=\"30.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M120.0 205.0 L210.0 205.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M120.0 235.0 L210.0 235.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"165.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Database</text><circle cx=\"290.0\" cy=\"220.0\" r=\"30\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"290.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Worker</text><rect x=\"255.0\" y=\"73.0\" width=\"70.0\" height=\"34.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">SMS</text><path d=\"M90.0 90.0 L135.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-boundaries-redrawn-tm-ah-paper-dim)\"></path><path d=\"M165.0 120.0 L165.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-boundaries-redrawn-tm-ah-paper-dim)\"></path><path d=\"M260.0 220.0 L210.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-boundaries-redrawn-tm-ah-paper-dim)\"></path><path d=\"M290.0 190.0 L290.0 107.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-boundaries-redrawn-tm-ah-paper-dim)\"></path><text x=\"545.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a boundary wherever trust changes</text><rect x=\"380.0\" y=\"73.0\" width=\"80.0\" height=\"34.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"420.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Patient</text><circle cx=\"535.0\" cy=\"90.0\" r=\"30\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"535.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Portal</text><rect x=\"490.0\" y=\"205.0\" width=\"90.0\" height=\"30.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M490.0 205.0 L580.0 205.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M490.0 235.0 L580.0 235.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"535.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Database</text><circle cx=\"660.0\" cy=\"220.0\" r=\"30\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"660.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Worker</text><rect x=\"625.0\" y=\"73.0\" width=\"70.0\" height=\"34.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"660.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">SMS</text><path d=\"M460.0 90.0 L505.0 90.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-boundaries-redrawn-tm-ah-paper-dim)\"></path><path d=\"M535.0 120.0 L535.0 205.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-boundaries-redrawn-tm-ah-paper-dim)\"></path><path d=\"M630.0 220.0 L580.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-boundaries-redrawn-tm-ah-paper-dim)\"></path><path d=\"M660.0 190.0 L660.0 107.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-boundaries-redrawn-tm-ah-paper-dim)\"></path><path d=\"M115.0 45.0 L335.0 45.0 L335.0 265.0 L115.0 265.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M483.0 45.0 L583.0 45.0 L583.0 130.0 L483.0 130.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M483.0 165.0 L705.0 165.0 L705.0 265.0 L483.0 265.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 4\"></path><path d=\"M625.0 45.0 L695.0 45.0 L695.0 130.0 L625.0 130.0 Z\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"175.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">1 boundary, 2 flows cross it</text><text x=\"545.0\" y=\"282.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3 boundaries, 3 flows cross one</text></svg>", "caption": "The left drawing is not wrong about the firewall. It is silent about everything behind it, which is where the portal’s worst threats live."}
```

### Where trust changes

A boundary belongs wherever one of these differs on the two sides:

| what differs | example at the portal |
|---|---|
| **who controls the machine** | the patient's phone against Vereda's cloud; Vereda's cloud against the payment gateway's |
| **who controls the code** | the portal, which Vereda wrote, against the SMS provider's API |
| **the privilege the code runs with** | the portal, which answers anybody, against the database, which holds every record |
| **the network reachability** | the cloud's public zone, reachable from the internet, against its private network |
| **the people** | patients against clinic staff, who can read other people's exams |

The portal's processes sit in Vereda's cloud, and the cloud is not one zone. The portal answers
strangers on the internet. The database answers only from inside the private network. If the
portal is taken over, what stops the attacker from reading every record is whatever checks sit on
the flow from the portal into that network. Drawing a single box round the cloud hides that flow
at exactly the place it needs examining.

### What a crossing makes you ask

For each flow that crosses a boundary, three questions come before any method has a name:

- **Who sent this, and how do we know?** The payment webhook crosses from the vendors' zone into
  the cloud, and lesson 1 already found that the portal does not check its sender.
- **Can it be read or changed on the way?** An exam PDF crossing the internet.
- **Can it be sent too much, or too large?** An upload from anybody, of any size.

Lesson 3 gives these questions a structure, STRIDE, and a reason each one is on the list. For now
the useful habit is drawing the line, because a threat that sits on an undrawn boundary does not
get asked about at all.

### A boundary is not a control

Drawing a boundary says that trust changes there. It does not say anything is enforcing it. The
staff console sits behind a line marked "clinic network", and lesson 1's first fact says it
actually answers from the internet: the drawing shows the intention, and the system does not
match it. **Draw boundaries where trust should change, and then check whether something enforces
each one.** A line with nothing enforcing it is a finding in itself, and a good one.
