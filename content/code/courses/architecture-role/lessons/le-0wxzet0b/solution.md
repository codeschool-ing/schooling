---
title: Solution architecture: one outcome across several systems
version: 1
---

Most of what the business asks for does not fit inside one service. **Solution architecture is
the design of one business outcome that crosses several systems, several teams and often a party
outside the company.** Its subject is the arrows rather than the boxes: who tells whom what, in
which order, within what time, and what happens when one of them is down.

It is also where a company without an architect hurts first. Each team designs its own service
well, and nobody designs the journey between them, because nobody owns it. At Carreto, that gap
was the reason Tomás Viana created Renata's role.

## The request: pay the driver within 24 hours

Carreto pays drivers once a week, on Friday, for every delivery completed the week before. A
driver who delivers on a Monday waits up to eleven days for the money, and drivers who own one
truck and pay for fuel up front notice. Helena Prado, the product director, brought numbers to
the planning meeting: in the last quarter, a third of the drivers who stopped using Carreto said
in the exit survey that a competitor paid faster.

Her request was one sentence: **pay the driver within 24 hours of delivery.** Sílvio Matos, the
finance director, added two conditions in the same meeting. The shipper must have a chance to
contest a delivery before the money goes out, because paying for a load that never arrived is a
loss Carreto cannot recover from a driver; and no delivery may be paid twice.

No single team can deliver that sentence. Four systems and an outside party are involved:

| party | what it does for this outcome | who owns it |
|---|---|---|
| Driver app | captures the proof: photo, receiver's signature, GPS position | Diego Araújo's team |
| Tracking | decides that a delivery is proved, and keeps the proof | the Tracking team |
| Shipper app | shows the proof to the shipper, who may contest it | the Shipper team |
| Payments | waits out the contest window, pays the driver, invoices the shipper | Bruno Farias's team |
| Bank partner | executes the Pix transfer to the driver's account | outside Carreto |

Each team could build its own part in a sprint or two. **What nobody could build alone was the
promise**, because the 24 hours are spent across all of them.

## The budget, and why it is the architecture

Renata's first move was to turn the sentence into a time budget, measured from the moment the
truck is unloaded:

- **up to 4 hours** for the proof to reach Tracking, because drivers often unload in rural areas
  with no signal and the app uploads when it finds one;
- **12 hours** in which the shipper may contest, Sílvio's condition, starting when the proof is
  shown;
- **up to 1 hour** for Payments to run its checks and for the bank partner to complete the Pix.

That is 4 + 12 + 1 = 17 hours in the worst normal case, which leaves **7 hours of slack** for
everything that is not normal: a retry, a bank partner outage, a delivery that needs a person to
look at it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Four boxes in a row: Driver app, Tracking, Payments and Bank partner, joined by arrows labelled proof uploaded, delivery proved and Pix payout. Below Tracking and Payments, a Shipper app box: the shipper sees the proof and may contest it. At the bottom, a 24-hour bar measured from delivery: up to 4 hours for the proof, 12 hours in which the shipper may contest, 1 hour for the payout, and 7 hours of slack.\"><defs><marker id=\"pay24-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"20\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"76\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Driver app</text><text x=\"76\" y=\"63\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Driver team</text><rect x=\"202\" y=\"20\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Tracking</text><text x=\"262\" y=\"63\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Tracking team</text><rect x=\"388\" y=\"20\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"448\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Payments</text><text x=\"448\" y=\"63\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Payments team</text><rect x=\"574\" y=\"20\" width=\"130\" height=\"56\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"639\" y=\"44\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Bank partner</text><text x=\"639\" y=\"63\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">outside Carreto</text><path d=\"M138 48 L198 48\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pay24-ah)\"></path><path d=\"M324 48 L384 48\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#pay24-ah)\"></path><path d=\"M510 48 L570 48\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pay24-ah)\"></path><text x=\"169\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">proof</text><text x=\"169\" y=\"108\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uploaded</text><text x=\"355\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">delivery</text><text x=\"355\" y=\"108\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">proved</text><text x=\"541\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Pix</text><text x=\"541\" y=\"108\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">payout</text><path d=\"M262 78 L262 130\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pay24-ah)\"></path><path d=\"M448 130 L448 80\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#pay24-ah)\"></path><rect x=\"202\" y=\"134\" width=\"306\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355\" y=\"153\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Shipper app</text><text x=\"355\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">the shipper sees the proof and may contest it</text><text x=\"40\" y=\"214\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">the 24-hour budget, measured from delivery</text><rect x=\"40\" y=\"224\" width=\"107\" height=\"30\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><rect x=\"147\" y=\"224\" width=\"320\" height=\"30\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><rect x=\"467\" y=\"224\" width=\"27\" height=\"30\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"494\" y=\"224\" width=\"186\" height=\"30\" fill=\"none\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"93\" y=\"244\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">proof: 4 h</text><text x=\"307\" y=\"244\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">shipper may contest: 12 h</text><text x=\"587\" y=\"244\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">slack: 7 h</text><path d=\"M480 256 L480 270\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"480\" y=\"284\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">payout: 1 h</text><text x=\"40\" y=\"284\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">0 h</text><text x=\"680\" y=\"284\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">24 h</text></svg>", "caption": "One promise, four systems and a partner. The boxes already existed; the solution is the arrows, and the time budget that none of the teams owns on its own."}
```

**The budget is the architecture of this solution.** Every design question that followed was
answered against it. Can Payments learn about proved deliveries from a batch that runs every six
hours? Not if the slack is seven hours and a single missed run takes six of them. Can the contest
window start when the truck is unloaded rather than when the proof is shown? Sílvio said no: a
shipper cannot contest a proof they have not seen.

## The questions that live between the boxes

With the budget written down, Renata ran one working session with the four tech leads and a
person from finance. She did not bring a design. She brought the questions that no single team
would ask, because each sits on a boundary:

- **Who decides that a delivery is proved?** Tracking already had the photo, the signature and
  the GPS position, so Tracking owns the rule, and nobody else re-implements it. Payments trusts
  Tracking's word.
- **How does Payments find out?** Polling, a direct call, or an event on the message broker
  Carreto already runs. Lesson 5 shows this decision written up whole, with the options it
  rejected.
- **What happens when the bank partner is down?** The payout waits and is retried, the slack
  absorbs it, and finance is alerted if a payout is still pending at hour 20.
- **How is a double payment prevented?** Every payout carries the delivery's id as an
  idempotency key, so a retry or a repeated message cannot pay twice. The `architecture` course
  covered the technique in lesson 7; here the question is only who guarantees it, and the answer
  is Payments.
- **What does the shipper see if they contest?** The Shipper team owns the screen, and Payments
  owns the hold on the money. The contract between them is one field and one state change.

Each answer is small. **The value is in asking all five before anybody writes code**, because the
same question discovered in testing costs a sprint, and discovered in production costs a driver's
payment.

## Horizon, audience and artefacts

**The horizon is a programme**: months of building, then years of the solution running and being
changed. The 24-hour payout went from Helena's sentence to the first paid driver in eleven weeks,
and the contract between Tracking and Payments will outlive every line written in those weeks.

**The audience is wide and mixed**: several teams, the product director, finance, and in this case
an outside bank whose API terms set one of the numbers. So the artefacts have to work for people
who do not read code:

- a **context view and a container view** (the first two C4 levels) showing which systems take part
  and how they talk, which lesson 8 helps you choose and `architecture-modeling` lesson 3 draws;
- the **time budget**, written as a number per step, with the owner of each step named;
- the **contracts** between systems: the event's fields, the API's errors, who retries what;
- the **decision records** for every choice that spans teams, of which lesson 5 shows one in full;
- a short **solution design document** tying it together, written for Helena and Sílvio as much as
  for the engineers.

**And the solution needs one owner.** Renata did not build any of it. She owned the budget, the
contracts and the open questions until each had an answer, and she was the person Helena asked
"are we on track?" because nobody else could see all four teams at once.

## What this level looks like in Renata's week

In her first quarter, this is where most of Renata's time goes: the 24-hour payout, a new CT-e
layout that the tax authorities will require, and a request from a supermarket chain to post loads
from its own system. **Every one of those crosses teams, and every one would otherwise have been
solved four times, slightly differently, by four teams.**

It is also the level where an architect in a company of Carreto's size is most clearly worth the
salary. Application architecture already has owners in the teams. Enterprise architecture, the
next section's subject, matters, but a company of fifty engineers needs a small amount of it.
Solution architecture is the work that was being done by nobody.
