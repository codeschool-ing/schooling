---
title: State machines: every state and every way out of it
version: 1
---

**A state machine diagram shows the states one thing can be in during its life, and the events that
move it from one state to another.** Where an activity diagram follows a process, a state machine
follows an object: a ticket, a bus, a payment. It is the most underused diagram in this course and
the one most likely to find a bug before it ships.

## The notation

- A **state** is a box with rounded corners, named with an adjective or a past participle: *Held*,
  *Paid*, *Boarded*. It is a condition the object stays in for a while, not something it does.
- A **transition** is an arrow from one state to another, labelled `event [guard] / action`: the
  event that triggers it, an optional condition that must be true, and an optional action that runs
  as it happens. `cancelled [3 h or more before departure] / refund` reads: *when the ticket is
  cancelled, if it is three hours or more before departure, refund it and move*.
- The **initial pseudostate**, a filled circle, points at the state the object is born in.
- A **final state**, a circle around a dot, means the object's life in this machine is over.
- A state can carry **entry and exit actions**, written inside it: `entry / start 10-minute timer`.
- States can **nest**: a composite state *Active* can contain *Paid* and *Boarded*, and a transition
  from *Active* applies to both.

## The life of a Carcará ticket

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" data-fig=\"l04-state\" aria-label=\"A state machine of a Carcará ticket. From the initial pseudostate, the ticket starts in Held, whose entry action starts a ten-minute timer. Payment declined is a transition from Held back to Held. Payment approved moves Held to Paid. Ten minutes passing moves Held to Expired and releases the seat. From Paid: scanned at the door moves to Boarded; cancelled, three hours or more before departure, refunds and moves to Refunded; departed without being scanned moves to No-show.\"><defs><marker id=\"l04-state-am-fill-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" markerUnits=\"userSpaceOnUse\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"95.0\" y=\"103.0\" width=\"150.0\" height=\"54.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Held</text><text x=\"170.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8\" fill=\"var(--paper-dim)\">entry / start 10-min timer</text><rect x=\"340.0\" y=\"110.0\" width=\"120.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"400.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Paid</text><rect x=\"550.0\" y=\"30.0\" width=\"120.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Boarded</text><rect x=\"550.0\" y=\"130.0\" width=\"120.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Refunded</text><rect x=\"550.0\" y=\"230.0\" width=\"120.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"610.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">No-show</text><rect x=\"110.0\" y=\"260.0\" width=\"120.0\" height=\"40.0\" rx=\"14\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"170.0\" y=\"280.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Expired</text><circle cx=\"30.0\" cy=\"130.0\" r=\"7\" fill=\"var(--paper)\"></circle><path d=\"M37.0 130.0 L93.0 130.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-state-am-fill-paper)\"></path><path d=\"M245.0 130.0 L338.0 130.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-state-am-fill-paper)\"></path><text x=\"292.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">payment approved</text><path d=\"M170.0 157.0 L170.0 258.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-state-am-fill-paper)\"></path><text x=\"178.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">10 min pass</text><text x=\"178.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">/ release seat</text><path d=\"M140 103 C140 60, 200 60, 200 103\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-state-am-fill-paper)\"></path><text x=\"170.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">payment declined</text><path d=\"M460.0 120.0 L548.0 58.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-state-am-fill-paper)\"></path><text x=\"492.0\" y=\"76.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">scanned at the door</text><path d=\"M460.0 136.0 L548.0 148.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-state-am-fill-paper)\"></path><text x=\"500.0\" y=\"158.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">cancelled [≥ 3 h]</text><text x=\"500.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">/ refund</text><path d=\"M440.0 150.0 L550.0 240.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-state-am-fill-paper)\"></path><text x=\"470.0\" y=\"222.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">departed</text><text x=\"470.0\" y=\"236.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">[not scanned]</text></svg>", "caption": "Seven transitions, each labelled event [guard] / action. The happy path is the top row; most of the value is in the other arrows."}
```

- A ticket is born **Held**, when the seat is held, and on entry a ten-minute timer starts.
- `payment approved` moves it to **Paid**. `10 minutes pass` moves it to **Expired**, and the seat is
  released.
- From Paid, `scanned at the door` moves it to **Boarded**. `cancelled [3 h or more before] / refund`
  moves it to **Refunded**. `departed [not scanned]` moves it to **No-show**.
- A `payment declined` in Held is a transition **to itself**: the passenger may try another card,
  and the timer keeps running.

Everything that sells, checks or reports on a ticket has to agree with this picture. The boarding
app's offline list, for example, contains only tickets in *Paid*: an *Expired* ticket in that list
would let somebody board without paying.

## States are conditions, not steps

The commonest mistake is drawing an activity diagram with rounded boxes: states named *Validating
payment*, *Sending e-mail*, *Saving*. Those are things the system does, and they last
milliseconds. A test that separates the two: **could you query the database and find a ticket in
this state tomorrow morning?** *Paid*, yes. *Sending e-mail*, no.

The second commonest is drawing only the happy path, *Held → Paid → Boarded*, and leaving out the
transitions that a real ticket takes every day: the expiry, the refund, the no-show. The happy path
is the part everybody already knows. **The value of a state machine is in the arrows nobody
thought of**, which is what the next section turns into a method.
