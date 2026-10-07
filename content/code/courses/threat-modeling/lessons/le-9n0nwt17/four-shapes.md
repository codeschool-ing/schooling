---
title: Five shapes
version: 1
---

The first question, *what are we working on*, needs an answer that two people can point at and
disagree about. A paragraph cannot do that, and an architecture diagram usually answers a
different question: it shows which boxes exist and which product each one is, and threat
modelling needs to know **where data goes and who touches it on the way**. That is a **data flow
diagram (DFD)**, a notation from structured analysis in the 1970s that Microsoft adopted for
threat modelling in the 2000s because it shows exactly that and nothing else.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l02-shapes\" aria-label=\"The notation. An external entity is a rectangle: somebody or something outside the system, such as a patient. A process is a circle: code that transforms data, such as the portal. A data store is two parallel lines: data at rest, such as the records database. A data flow is an arrow with a label: data moving, such as an uploaded exam. A trust boundary is a dashed line: where the level of trust changes, such as between the internet and the cloud.\"><defs><marker id=\"l02-shapes-tm-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"22.0\" y=\"60.0\" width=\"100.0\" height=\"40.0\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"72.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Patient</text><circle cx=\"216.0\" cy=\"80.0\" r=\"36\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"216.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal</text><rect x=\"305.0\" y=\"65.0\" width=\"110.0\" height=\"30.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"none\" stroke-width=\"1.2\"></rect><path d=\"M305.0 65.0 L415.0 65.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M305.0 95.0 L415.0 95.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"360.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Records</text><path d=\"M452.0 80.0 L556.0 80.0\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l02-shapes-tm-ah-paper)\"></path><text x=\"504.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">exam PDF</text><path d=\"M648.0 40.0 L648.0 120.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"6 4\"></path><text x=\"72.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">external entity</text><text x=\"72.0\" y=\"175.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">outside the system;</text><text x=\"72.0\" y=\"188.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">you do not control it</text><text x=\"216.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">process</text><text x=\"216.0\" y=\"175.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">code that does</text><text x=\"216.0\" y=\"188.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">something to data</text><text x=\"360.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">data store</text><text x=\"360.0\" y=\"175.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">data at rest:</text><text x=\"360.0\" y=\"188.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a table, a bucket</text><text x=\"504.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">data flow</text><text x=\"504.0\" y=\"175.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">data in motion,</text><text x=\"504.0\" y=\"188.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">always labelled</text><text x=\"648.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">trust boundary</text><text x=\"648.0\" y=\"175.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">where the level</text><text x=\"648.0\" y=\"188.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">of trust changes</text><text x=\"360.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">A flow has a process at one end at least. Data does not move by itself.</text></svg>", "caption": "Five shapes are the whole notation. The boundary is the one that makes a data flow diagram a threat model."}
```

| shape | what it is | at the portal |
|---|---|---|
| **external entity** (rectangle) | a person or system outside your control that sends or receives data | a patient, clinic staff, the payment gateway, the SMS provider |
| **process** (circle) | code you run that receives data, does something with it and passes it on | the portal, the staff console, the reminder worker |
| **data store** (two parallel lines) | data at rest: a database, a bucket, a file, a queue, a cache | the records database, the exam files |
| **data flow** (labelled arrow) | data moving from one element to another | an uploaded exam PDF, a payment webhook |
| **trust boundary** (dashed line) | a place where the level of trust changes | between the internet and Vereda's cloud |

Older books draw processes as rounded rectangles (Gane and Sarson) where this course draws
circles (Yourdon and DeMarco). Nothing depends on which one you choose, as long as a diagram
uses one.

### The rules that make it a DFD

The shapes come with three rules, and each catches a drawing that has stopped describing data:

1. **Every flow has a process at one end at least.** Data does not move from one database to
   another by itself; some code copies it, and that code is where things go wrong.
2. **Every flow has a label naming the data.** "HTTPS" is not a label, because it names the
   transport and says nothing about what is carried. "Exam PDF" is a label.
3. **A flow between two external entities is not drawn.** What a patient and the payment gateway
   say to each other happens outside your system. If it matters, it reaches you through a process,
   and that is the flow to draw.

### What is not in a DFD

**Control flow.** A DFD has no "if", no loop and no order of steps. "The worker runs at 20:00
and then sends the reminders" is a sequence, and the DFD only says that bookings flow from the
database to the worker and reminders flow from the worker to the SMS provider. When the order
matters for a threat, a sequence diagram beside the DFD says it.

**Infrastructure for its own sake.** A load balancer, a container or a server appears only if it
does something to the data that matters, such as ending TLS and passing plain HTTP on. The
question for each box is whether it changes what the data is or who can see it.
