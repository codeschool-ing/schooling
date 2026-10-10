---
title: Who has a stake, and what each of them needs
version: 1
---

Two pictures of stakeholders are common and both are wrong. In one, the stakeholder is "the
business": the product director and the CTO, and everybody else is an implementer. In the other,
everybody affected is a stakeholder in the same way, and they all get the same weekly email. **A
stakeholder is anybody who can affect a decision or is affected by it, and they differ in how much
they can change it and how much they care.** Those two differences decide what each of them needs
from the architect, and how often.

## One initiative, eleven stakeholders

In 2026 Carreto decided to take the issuing of the CT-e, the electronic waybill every freight
service needs before the truck leaves, out of the monolith and into a service of its own. The code in
the monolith had grown around one state's rules and was hard to change; a new CT-e layout was
coming; and when the monolith was slow, trucks waited at the dock for a document.

Renata's first step was a list, made by asking one question in every conversation: **who gets the
phone call when this fails?** The answers went well past the people in the planning meeting:

- Tomás Viana, the CTO, who approved the initiative and answers for it to the board;
- Sílvio Matos, the finance director, because the CT-e is a tax document and a wrong one becomes a
  fine;
- Helena Prado, the product director, because shippers see the CT-e step in their flow;
- Bruno Farias and Payments, because every invoice to a shipper refers to its CT-e;
- Diego Araújo and the Driver team, because the app shows the driver the document before departure;
- Paula Reis and Platform, who will run the service and look after the digital certificate that
  signs each CT-e;
- the outside accounting firm that files Carreto's tax obligations;
- the support team, who answer when a shipper's truck is stuck at the dock;
- the drivers, who cannot leave without the document and are paid by the trip;
- the Matching and Tracking teams, whose services read the load the CT-e describes;
- SEFAZ, the state tax authority that authorises each CT-e.

The last item is a stakeholder of a different kind. SEFAZ cannot be persuaded and will not attend a
meeting. It is a **constraint with an interface**: its rules, its availability and its layout
changes shape the design, and the stakeholder work is to read its technical notes and plan for its
outages. Listing it beside the people is still useful, because somebody has to own following it.

## The power and interest grid

A list of eleven does not say where to spend time. The usual tool is a grid with two axes: **power**,
meaning how much a person can change or stop the decision, and **interest**, meaning how much the
decision affects them or how closely they follow it. The grid is often credited to Aubrey Mendelow's
work in the early 1990s, and its four quadrants each come with a standard instruction.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 390\" role=\"img\" aria-label=\"A grid with power on the vertical axis and interest on the horizontal axis. High power and high interest, manage closely: Sílvio Matos, finance; Helena Prado, product; Bruno Farias, Payments. High power and low interest, keep satisfied: Tomás Viana, CTO; the accounting firm. Low power and high interest, keep informed: support; Diego and the Driver team; Paula and Platform; the drivers. Low power and low interest, monitor: Matching; Tracking. A note below says SEFAZ is off the grid: a constraint with an interface, not a person to persuade.\"><defs><marker id=\"grid-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"90\" y=\"30\" width=\"270\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"225\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">keep satisfied</text><text x=\"225\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Tomás Viana, CTO</text><text x=\"225\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the accounting firm</text><rect x=\"360\" y=\"30\" width=\"270\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"495\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">manage closely</text><text x=\"495\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Sílvio Matos, finance</text><text x=\"495\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Helena Prado, product</text><text x=\"495\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Bruno Farias, Payments</text><rect x=\"90\" y=\"180\" width=\"270\" height=\"150\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"225\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">monitor</text><text x=\"225\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Matching</text><text x=\"225\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Tracking</text><rect x=\"360\" y=\"180\" width=\"270\" height=\"150\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"495\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">keep informed</text><text x=\"495\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">support</text><text x=\"495\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Diego and the Driver team</text><text x=\"495\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Paula and Platform</text><text x=\"495\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">the drivers</text><path d=\"M70 330 L70 34\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#grid-ah)\"></path><text x=\"40\" y=\"18\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">power</text><path d=\"M90 350 L626 350\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#grid-ah)\"></path><text x=\"636\" y=\"350\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">interest</text><text x=\"360\" y=\"376\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">SEFAZ is off the grid: a constraint with an interface, not a person to persuade</text></svg>", "caption": "The stakeholders of the CT-e service on Mendelow's grid, as Renata drew it at the start. The quadrant says how much attention each one gets; it is redrawn at each phase."}
```

- High power, high interest: **manage closely.** Sílvio, Helena and Bruno can each stop the work, and
  each will notice every change. Renata met them every two weeks for thirty minutes, with the
  decisions coming up and their consequences.
- High power, low interest: **keep satisfied.** Tomás sponsors the work and does not want the detail;
  the accounting firm could refuse to sign off on a filing and has no interest in how the service is
  built. Each got a monthly page: progress, risks in reais, and any decision that needed them.
- Low power, high interest: **keep informed.** Support, Diego's team and Platform live with the result
  every day and do not decide the scope. They got a post in the project channel at each milestone and
  an open invitation to the architecture forum (the third section of this lesson).
- Low power, low interest: **monitor.** Matching and Tracking are affected only at the edges. The ADRs
  were enough, and Renata checked with them before any change to the load's data.

**The quadrants are instructions about effort, not about respect.** The drivers sit in the
keep-informed corner because none of them sits in Carreto's planning meetings, and they are the people
the whole initiative exists for. Their interest arrives through Diego, who knows that a driver at a
dock in Paranaguá with no signal cannot wait for a document to load, and through support, who hear
when it goes wrong.

## The grid moves

A grid drawn once is wrong within a month. In July SEFAZ published the date for the new layout, and
Sílvio moved from attentive to anxious: a missed date meant trucks that could not legally leave.
Renata moved the fortnightly meeting with him to weekly until the new layout was in production. The
accounting firm moved too, from a monthly page to a review of the test documents.

The opposite movement matters as much. Once the service was live and stable, Helena's interest
dropped back to the step in the shipper flow, and a fortnightly meeting would have been a cost to her
with nothing in it. **Redraw the grid at each phase of the work**, and say so when you change how often
you meet somebody; otherwise the change reads as being dropped.

## What each of them needs from the architect

The grid says how much attention each stakeholder gets. What goes into that attention depends on what
they are trying to protect, and Renata wrote one line per stakeholder before the first meeting:

| stakeholder | what they protect | what they need from Renata |
|---|---|---|
| Sílvio | no fines, no rejected waybills | the risk of rejection in reais, and the date the new layout is ready |
| Helena | the shipper's flow | which screens change, and when |
| Bruno | invoices that match their CT-e | the interface between the new service and invoicing, before it is built |
| Tomás | the commitment to the board | one page a month and no surprises |
| support | not being the last to know | what changes for a shipper on the day it changes |

None of these people asked for an architecture diagram, and only Bruno would read one. **Saying the
same thing to five people in five forms is not inconsistency**: the decision is the same and the
consequences differ by reader. The craft of adapting a message to the board, to product, to a team and
to a client is `architect-communication` lesson 3; this lesson is about knowing whom you owe a message
to in the first place.

## The stakeholders nobody listed

The question about the phone call found three stakeholders that the first planning meeting had not
mentioned: support, the accounting firm and Platform's certificate. The certificate is not a person,
but it expires every year, and a CT-e signed with an expired certificate is rejected. Somebody has to
own that date, and before Renata's list nobody did.

The pattern is general. **The stakeholders most often missed are the ones who meet the system when it
fails**: support, on-call, operations, an outside party who files or audits. They have little power
over the design and the most direct knowledge of what goes wrong with it, and an hour with them early
costs less than one incident later.
