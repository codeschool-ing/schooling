---
title: STRIDE per element
version: 1
---

Asking six questions of every element of a diagram with twenty elements is a hundred and twenty
questions, and many of them make no sense: you cannot "elevate privilege" in a data store,
because a store does not run code. **STRIDE per element** is the version Microsoft settled on:
each kind of element in a DFD is exposed to some letters and not others.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l03-per-element\" aria-label=\"STRIDE per element, as a grid. External entities: spoofing and repudiation. Processes: all six. Data stores: tampering, information disclosure and denial of service, plus repudiation when the store is a log. Data flows: tampering, information disclosure and denial of service.\"><text x=\"267.5\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">S</text><text x=\"267.5\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">spoofing</text><text x=\"342.5\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">T</text><text x=\"342.5\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">tampering</text><text x=\"417.5\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">R</text><text x=\"417.5\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repudiation</text><text x=\"492.5\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">I</text><text x=\"492.5\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">disclosure</text><text x=\"567.5\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">D</text><text x=\"567.5\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">denial</text><text x=\"642.5\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--phosphor)\">E</text><text x=\"642.5\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">elevation</text><rect x=\"20.0\" y=\"70.0\" width=\"660.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36.0\" y=\"87.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">external entity</text><circle cx=\"267.5\" cy=\"87.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"417.5\" cy=\"87.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><rect x=\"20.0\" y=\"108.0\" width=\"660.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36.0\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">process</text><circle cx=\"267.5\" cy=\"125.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"342.5\" cy=\"125.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"417.5\" cy=\"125.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"492.5\" cy=\"125.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"567.5\" cy=\"125.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"642.5\" cy=\"125.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><rect x=\"20.0\" y=\"146.0\" width=\"660.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36.0\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">data store</text><circle cx=\"342.5\" cy=\"163.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"417.5\" cy=\"163.0\" r=\"8\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><circle cx=\"492.5\" cy=\"163.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"567.5\" cy=\"163.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><rect x=\"20.0\" y=\"184.0\" width=\"660.0\" height=\"34.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"36.0\" y=\"201.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">data flow</text><circle cx=\"342.5\" cy=\"201.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"492.5\" cy=\"201.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"567.5\" cy=\"201.0\" r=\"8\" fill=\"var(--phosphor)\"></circle><circle cx=\"250.0\" cy=\"236.0\" r=\"6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></circle><text x=\"262.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">repudiation applies to a store that is a log: tampering with it erases the record</text></svg>", "caption": "A process is exposed to all six because it is where code runs. A flow cannot be spoofed by itself: its source can."}
```

The reasoning behind each row is what makes the chart worth remembering:

- **External entities: S and R.** They are outside your control, so the questions are whether
  they are who they claim to be, and whether they can deny what they did. You cannot tamper with a
  patient; you can pretend to be one.
- **Processes: all six.** A process runs code, takes input, holds privileges and serves people. It
  can be impersonated, altered, made to act without a trace, made to leak, stopped, and tricked
  into doing what its caller may not do.
- **Data stores: T, I and D**, and **R** when the store is a log. Data at rest can be changed, read
  or made unavailable. A log is the record that answers repudiation, so tampering with it is a
  repudiation threat.
- **Data flows: T, I and D.** Data in motion can be changed on the way, read on the way, or
  blocked. A flow cannot be spoofed by itself; spoofing a flow means spoofing its source, and that
  question belongs to the source.

### Walking the portal

Applied to the portal's level 1 diagram, the chart gives the number of questions to ask before any
are answered:

| elements | how many | letters each | questions |
|---|---|---|---|
| external entities | 4 | 2 | 8 |
| processes | 3 | 6 | 18 |
| data stores | 2 | 3 | 6 |
| data flows | 12 | 3 | 36 |
| | | | **68** |

Sixty-eight questions is an afternoon, and most answers are "no, because" or "yes, already
handled". The point is not that each one finds a threat. It is that **none is skipped because
nobody thought of it**, which is the failure mode of the unstructured list.

### Where it falls short

Per-element STRIDE looks at each element alone. Some threats only exist in the relationship
between two elements: the webhook (flow 7) is only dangerous because of *what the portal does on
receiving it*, which is a fact about the flow and the process together. The next section is the
variation that looks at exactly that.
