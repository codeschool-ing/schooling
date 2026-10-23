---
title: Stakeholders, including the ones nobody invited
version: 1
---

**A stakeholder is anybody with a relationship to the change, the need or the solution**, and the
expensive mistakes in requirements usually come from the stakeholder nobody thought to ask. BABOK
treats identifying them as a task of its own, not as an attendance list.

## Finding them

Start with the obvious and then ask, for each one, *who else does this person depend on, or affect?*
For the reconciliation:

- **Joana**, who does the matching today: the person whose two days the change returns.
- **The finance director**, who signs the monthly close and approves the change.
- **The Payments team**, who own the gateway integration the job will read from.
- **The external auditors**, who sample the reconciliation every quarter.
- **The payment company**, whose settlement files are the input, and who may change their format.
- **Station agents**, who refund cash at the counter: found by asking Joana what causes the
  mismatches she cannot explain.
- **Platform**, who will run the job and be paged when it fails.

The last two were not in the first meeting. **Each of them could have stopped the solution from
working**: without the agents, the cash refunds stay invisible; without Platform, a nightly job
nobody can operate is a new incident waiting.

## Mapping them

A **stakeholder map** places each stakeholder on two axes, influence over the change and interest in
it, and suggests how to engage each quadrant:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l07-stakeholder-map\" aria-label=\"A stakeholder map for the reconciliation, with influence up the vertical axis and interest along the horizontal. High influence and high interest, manage closely: the finance director. High influence, low interest, keep satisfied: the Payments tech lead and Platform. Low influence, high interest, keep informed: Joana and the station agents. Low influence, low interest, monitor: the payment company. The external auditors sit between the two upper quadrants.\"><rect x=\"110.0\" y=\"20.0\" width=\"580.0\" height=\"280.0\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M400.0 20.0 L400.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M110.0 160.0 L690.0 160.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"120.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">keep satisfied</text><text x=\"410.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">manage closely</text><text x=\"120.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">monitor</text><text x=\"410.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">keep informed</text><text x=\"60.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">influence</text><text x=\"60.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">high</text><text x=\"60.0\" y=\"294.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">low</text><text x=\"400.0\" y=\"318.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">interest →</text><circle cx=\"532.0\" cy=\"70.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"540.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Finance director</text><circle cx=\"192.0\" cy=\"70.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"200.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Payments tech lead</text><circle cx=\"192.0\" cy=\"112.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"200.0\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Platform</text><circle cx=\"362.0\" cy=\"50.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"370.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">External auditors</text><circle cx=\"502.0\" cy=\"210.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"510.0\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Joana</text><circle cx=\"522.0\" cy=\"250.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"530.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Station agents</text><circle cx=\"172.0\" cy=\"230.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"180.0\" y=\"230.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Payment company</text></svg>", "caption": "The quadrant says how to engage, not how much somebody matters. The station agents have little influence over the project and are essential to its requirements."}
```

- **high influence, high interest**: manage closely; they decide and they care. The finance director.
- **high influence, low interest**: keep satisfied; they can block it if surprised. Payments' tech lead.
- **low influence, high interest**: keep informed; they live with the result. Joana and the agents.
- **low influence, low interest**: monitor. The payment company, for now.

The quadrant is not a judgement of the person. The station agents have low influence over the
project and are essential to its requirements; the map says how to engage them, which is to go and
talk to them, because they will not come to the workshop.

## Who decides

The last question is about decisions, not information: **who approves the requirements, who is
consulted, who is only informed?** A **RACI** table answers it, naming for each decision who is
*Responsible* for doing it, who is *Accountable* for the outcome, who is *Consulted* and who is
*Informed*. One rule makes it work: **exactly one A per row**. A requirement two people can approve
is a requirement nobody owns.
