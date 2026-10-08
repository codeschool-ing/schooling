---
title: A design review that looks at the change
version: 1
---

A design review is where a change that touches the model is modelled. The difference between one
that keeps the model alive and one that does not is what it looks at: **the change, not the
system**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" data-fig=\"l15-review\" aria-label=\"A design review in four steps. The change is shown as a difference to the DFD. STRIDE is applied to the elements and flows that changed, not to the whole system. The threats and requirements that result are written into the model. The model change and the code change go in the same pull request.\"><defs><marker id=\"l15-review-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">the change, as a DFD diff</text><path d=\"M170.0 70.0 L195.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-review-tm-ah-paper-dim)\"></path><rect x=\"195.0\" y=\"40.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"270.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">STRIDE on what changed</text><path d=\"M345.0 70.0 L370.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-review-tm-ah-paper-dim)\"></path><rect x=\"370.0\" y=\"40.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"445.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">threats and requirements</text><path d=\"M520.0 70.0 L545.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-review-tm-ah-paper-dim)\"></path><rect x=\"545.0\" y=\"40.0\" width=\"150.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"620.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">one pull request</text><text x=\"360.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">thirty minutes, the people who will build it, and the model open on the screen</text></svg>", "caption": "A review that only looks at what changed is short enough to happen every time, which is the only frequency that keeps a model alive."}
```

### Four steps

1. **The change, as a difference to the DFD.** The invoice story adds one external entity, the
   city's invoice service, and three flows: the portal asks for an invoice, the service returns
   it, the patient downloads it. Drawn on the level 1 diagram, the new parts are all anybody needs
   to look at. `model.py` gets the same additions, so the diff the reviewers read is the diff that
   will be committed.
2. **STRIDE on what changed.** Each new element and flow gets the six questions of lesson 3, and
   only those. The new flow to the city's service crosses the vendors' boundary: spoofing (is it
   really the city?), tampering (could the amount be altered on the way?), information disclosure
   (what does the service keep about Vereda's patients?).
3. **Threats and requirements.** What the questions find is written into `threats.csv` and
   `requirements.csv` with new ids, and estimated if it is big enough to compete for money with the
   rest. A threat the team decides to accept gets a decision record, as in lesson 12.
4. **One pull request.** The model's changes go in the same pull request as the code. The reviewer
   who approves the code sees the threats beside it, and **the model cannot fall behind the code it
   describes**, because they are merged together or not at all.

### Who, and for how long

The people who will build the change, ana with the model open, and carla when the change crosses a
trust boundary. Thirty minutes is usually enough, because the scope is a handful of elements. A
review that needs two hours is a sign that the change is bigger than one story, which is useful
to know in its own right.

### What it catches that refinement does not

Refinement asks whether a story touches the model. The review asks **what could go wrong in what it
touches**, element by element, and it is where a requirement is written precisely enough to be
tested. "Only the patient who paid gets the invoice" is a refinement sentence. "The portal returns
an invoice only to the account that paid for the session, and answers any other request as if the
invoice did not exist" is a requirement, with the same shape as R10, and a test can be written
against it.

### The minimum that is still a review

When a team is too busy for anything, one rule keeps the habit: **a pull request that changes an
entry point, a data store or a boundary has to change the model too, or say in its description why
not.** It is cheap to check in review and cheap to follow. A reviewer who sees a new upload route
and no change to `model.py` asks one question, and that question is most of what a design review
is for.
