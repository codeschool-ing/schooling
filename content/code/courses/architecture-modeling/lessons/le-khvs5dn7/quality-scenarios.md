---
title: Quality attributes as scenarios
version: 1
---

**A quality attribute becomes a requirement when it is written as a scenario: a situation, what
happens, and a measure that says whether the system coped.** `architecture-role` lessons 6 and 7
introduced the six-part form; this section uses it to model Carcará's most important qualities, and
to show how a scenario is drawn.

## The six parts, drawn

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l06-scenario\" aria-label=\"The six parts of a quality attribute scenario, drawn for offline boarding. The source, a driver, sends the stimulus, scans a ticket, to the artefact, the boarding app, inside a dashed environment, on the road with no signal. The response, accept or refuse, leads to the response measure, within one second for every scan.\"><defs><marker id=\"l06-scenario-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"200.0\" y=\"40.0\" width=\"330.0\" height=\"160.0\" rx=\"6\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.3\" stroke-dasharray=\"6 4\"></rect><text x=\"212.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">environment: on the road, no signal</text><circle cx=\"80.0\" cy=\"91.0\" r=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></circle><rect x=\"34.0\" y=\"105.0\" width=\"92.0\" height=\"44.0\" rx=\"12\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Driver</text><path d=\"M128.0 125.0 L240.0 125.0\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l06-scenario-am-fill-paper)\"></path><text x=\"184.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">scans a ticket</text><rect x=\"240.0\" y=\"95.0\" width=\"160.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"320.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Boarding app</text><text x=\"320.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">artefact</text><path d=\"M400.0 125.0 L560.0 125.0\" stroke=\"var(--paper)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l06-scenario-am-fill-paper)\"></path><text x=\"470.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">accept or refuse</text><rect x=\"560.0\" y=\"95.0\" width=\"140.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">within 1 s,</text><text x=\"630.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">every scan</text><text x=\"80.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">source</text><text x=\"184.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">stimulus</text><text x=\"470.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">response</text><text x=\"630.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">response measure</text><text x=\"320.0\" y=\"230.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">artefact</text></svg>", "caption": "The environment is drawn around the artefact because it is the condition the response has to hold under. Change it, and it is a different scenario."}
```

| part | what it says | the boarding scenario |
| --- | --- | --- |
| **source** | who or what causes the stimulus | a driver |
| **stimulus** | the event that arrives | scans a passenger's ticket at the door |
| **environment** | the conditions at the time | on the road, with no mobile signal, after the last sync |
| **artefact** | what part of the system is stimulated | the boarding app on the driver's phone |
| **response** | what the system does | accepts a Paid ticket for this trip, refuses anything else |
| **response measure** | how anybody knows it was good enough | within one second, with no network, for 100% of scans |

As one sentence, which is how it goes into a document:

> **QS-02.** When a driver scans a ticket at the door with no mobile signal, the boarding app accepts
> or refuses it within one second from its local list, for every scan.

## Carcará's significant scenarios

Five scenarios came out of the checklist and the conversations with Celeste and Otávio:

| id | attribute | the scenario |
| --- | --- | --- |
| QS-01 | performance | In the week before São João, with 2,000 purchases starting per minute, 95% of purchases complete within 2 seconds, not counting the payment gateway's time. |
| QS-02 | availability | With no mobile signal, the boarding app accepts or refuses a scan within one second, for every scan. |
| QS-03 | availability | If the booking database's primary fails, ticket sales resume within 5 minutes, with no paid booking lost. |
| QS-04 | modifiability | A new payment method is in production within 10 working days, without changing the booking service. |
| QS-05 | security | Every refund over R$ 500 is traceable to the person who approved it, for five years. |

## What makes a scenario good

- **The environment is specific.** *At peak* is better than nothing; *in the week before São João,
  with 2,000 purchases starting per minute* is something a load test can reproduce.
- **The measure has a number and a scope.** *95% within 2 seconds* says what share is allowed to be
  slow, which an average would hide.
- **It says what, not how.** QS-02 does not say *a local SQLite database*. That is the design, and it
  belongs in a decision record, where it can be argued with.
- **It can fail.** If no plausible system could miss the measure, the scenario constrains nothing.
