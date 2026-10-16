---
title: Asking until it has a number
version: 1
---

**The words a business uses for qualities are adjectives, and an adjective cannot be tested.**
"Fast", "always available", "secure", "easy to change" are where a conversation starts. The
architect's work is to keep asking, about goals and consequences rather than about technology,
until each one becomes a number that a design can be held to.

Two habits get this wrong in opposite directions. One takes the request literally and starts
estimating the screen. The other asks the product director a technical question — "what latency do
you need?" — and accepts whatever comes back. Helena does not think in latency. She thinks in
dispatchers, loads on a dock and bookings lost to competitors, and that is where the questions
have to go.

## Asking for the goal

Before putting numbers on a request, find out what it is for. **A request is usually a solution
somebody has already chosen**, and the problem it was chosen for is the requirement. The tool for
getting from one to the other is old: ask why, and then ask why of the answer. Taiichi Ohno made
"five whys" part of the Toyota production system as a way of finding the root cause of a defect.
Pointed at a request instead of a defect, the same habit finds the goal.

Renata did not open with the screen. She asked what happens today:

> Renata: What happens now, between the quote and the truck?
>
> Helena: The price comes back straight away. That part is fine. Then the shipper clicks "request
> truck" and waits.
>
> Renata: Why does the wait matter?
>
> Helena: Because 30% of our quotes turn into bookings, and I need 40% this year. The ones we lose,
> we lose while they wait.
>
> Renata: Why do they leave while they wait?
>
> Helena: A dispatcher at a furniture factory has a load on the dock at seven. If she doesn't know
> by half past eight that a truck is coming, she phones the carrier she used last year.
>
> Renata: So what she needs is to know a truck is coming. Not one screen.
>
> Helena: Yes. One screen was my idea of how to make it feel quicker.

Three whys, and **the requirement moved from the screen to the wait.** Helena brought the numbers
behind it the next day: Carreto issues about 42,000 quotes a month and 12,600 become bookings,
which is the 30%. Forty per cent would be 16,800, so the goal is worth about 4,200 more bookings a
month. And the wait she meant has a median of 47 minutes from "request truck" to a driver
accepting, with one request in ten waiting more than 3 hours 10 minutes.

The last two whys were not for Helena. Renata took them to Kátia Lemos, the tech lead of Matching.
Why 47 minutes? Because Matching offers each load to one driver at a time, and each driver has ten
minutes to answer before the offer moves to the next. Why one at a time? Because in 2019 two drivers
accepted the same load and both turned up at the factory gate, and offering to one driver at a time
was the fix.

**The business knows the goal; the team knows the cause.** The whys go to whoever can answer them,
and here the answers changed what kind of work this is. The slow part is not the screen and not
Pricing. It is a rule inside Matching, written to protect a guarantee — one load, one driver — that
any replacement still has to keep. That is a structural change across Matching, the Driver app and
the Shipper app, which makes it the architect's.

"Five" is not a quota. Stop when the answer is a goal the business would defend on its own terms,
such as more bookings, or a cause the team can change.

## Turning adjectives into numbers

With the goal clear, "fast" can get a number. Asking for the number directly fails: Helena would
say "instant", or invent a figure to end the question. **Ask about consequences, and offer numbers
for the other person to react to.** People who cannot produce a threshold from nothing are very
good at saying which of three is wrong.

The questions that worked with Helena:

- **Fast for whom, doing what while they wait?** The dispatcher, with a load on the dock and a
  phone in her hand.
- **What happens at five minutes, at fifteen, at an hour?** At five, nothing different from fifteen.
  At fifteen, she waits. Past an hour, she is phoning somebody else.
- **For which loads, and when?** Full loads on the corridors that carry most of the volume, during
  the hours shippers work. A part load to a small town on a Saturday afternoon can take longer.
- **How many need to make it?** Not all of them; nine in ten would move the conversion, and the
  last one in a hundred has to be inside an hour.

Out of that came something testable: **a driver accepts within 15 minutes for 90% of requests, and
within 60 minutes for 99%,** on the main corridors, in business hours. Nobody asked Helena about
percentiles. She chose the numbers by reacting to consequences, and the percentiles are only how
the architect writes them down.

"Always available" took the same treatment and came apart into two different requirements. Asked
what an hour of the booking flow being down costs on a Tuesday at 10:00 and on a Sunday at 03:00,
Helena said the first was a disaster and the second was nothing: shippers book from Monday to
Saturday, between 06:00 and 20:00. That is 14 hours on 26 days, or 364 hours a month, and only those
hours count.

Drivers are different. They are on the road at all hours, deliver at night, and prove a delivery
with a photo and a signature in places with no signal. **For them, "always available" is not about
the servers at all**: it means the Driver app records the proof with no connection and sends it
when the phone finds one. That is a different requirement for a different team, and no amount of
server redundancy would have met it.

For the booking flow, the number is a percentage, and the percentage has a price. Each nine
removes most of the downtime that was allowed and adds cost: another database replica, automatic
failover, an on-call rota that answers in minutes. Over a 30-day month:

| availability | downtime allowed in a month |
|---|---|
| 99% | 7.2 hours |
| 99.5% | 3.6 hours |
| 99.9% | 43.2 minutes |
| 99.99% | 4.32 minutes |

Measured only over the 364 business hours, 99.5% allows about 109 minutes of downtime a month.
Helena chose that, after Sílvio Matos, the finance director, saw what 99.99% would add to the
infrastructure bill and the on-call rota for a flow nobody uses at night. **Do not let the business
pick a number because it sounds serious.** Show what each one costs and let them choose with the
price in view; lesson 13 comes back to that conversation.

## Putting the flow on a wall

Interviews find what one person knows. Some requirements live between people: in a hand-off that
nobody owns, or in a workaround that one team invented and the others never heard of. **A workshop
that puts the whole flow in front of everybody at once finds those.**

The one Renata used is **event storming**, devised by Alberto Brandolini. The people who know the
business stand in front of a long wall and write *domain events* — things that happened, in the
past tense — on sticky notes: "quote issued", "driver accepted", "CT-e authorised". They put them in
time order, argue about the order, and mark *hot spots* wherever somebody disagrees or something
hurts. No laptops, no boxes and arrows, no technology words.

Renata ran it for three hours with Helena, Kátia, Diego Araújo from the Driver app, Bruno Farias
from Payments, two people from customer support, and a dispatcher from the furniture factory who
agreed to come in for a morning. The part of the wall that mattered looked like this:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 302\" role=\"img\" aria-label=\"Eight domain events on sticky notes, in time order across two rows: quote issued, truck requested, load offered to one driver, offer expired after 10 minutes, then driver accepted, CT-e authorised, truck departed, delivery proved. An arrow loops from offer expired back to load offered, labelled next driver, 10 minutes each. A hot spot around the loop says: median 47 minutes until a driver accepts; support phones drivers by hand after an hour.\"><defs><marker id=\"l7storm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"362\" y=\"52\" width=\"336\" height=\"100\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><rect x=\"362\" y=\"6\" width=\"336\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"530\" y=\"19\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">hot spot: median 47 min until a driver accepts</text><text x=\"530\" y=\"34\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">support phones drivers by hand after an hour</text><rect x=\"30\" y=\"60\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Quote issued</text><path d=\"M180 83.0 L198 83.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><rect x=\"200\" y=\"60\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"83.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Truck requested</text><path d=\"M350 83.0 L368 83.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><rect x=\"370\" y=\"60\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"445.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Load offered</text><text x=\"445.0\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">to one driver</text><path d=\"M520 83.0 L538 83.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><rect x=\"540\" y=\"60\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Offer expired</text><text x=\"615.0\" y=\"91\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">after 10 min</text><rect x=\"30\" y=\"200\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Driver accepted</text><path d=\"M180 223.0 L198 223.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><rect x=\"200\" y=\"200\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">CT-e authorised</text><path d=\"M350 223.0 L368 223.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><rect x=\"370\" y=\"200\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"445.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Truck departed</text><path d=\"M520 223.0 L538 223.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><rect x=\"540\" y=\"200\" width=\"150\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">Delivery proved</text><path d=\"M600 106 L600 124 L460 124 L460 108\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><text x=\"530\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">next driver, 10 min each</text><path d=\"M690 83.0 L708 83.0 L708 172 L14 172 L14 223.0 L28 223.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><path d=\"M30 276 L690 276\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#l7storm-ah)\"></path><text x=\"30\" y=\"292\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">time</text></svg>", "caption": "Part of the wall after Renata's event storming. The loop between offering a load and the offer expiring is where the 47 minutes go, and the hot spot carries the manual workaround nobody in engineering had heard of."}
```

Three things came off the wall that no interview had produced. **Customer support phones drivers by
hand** when a load has waited more than an hour, a process nobody in engineering knew existed and
that the new design would either replace or have to keep working. **"CT-e authorised" comes after
"driver accepted"**, so confirming a truck to the shipper does not have to wait for SEFAZ; only the
departure does. And the dispatcher said she would accept a truck an hour later if she knew at once
that it was coming, which moved the 15 minutes from "the truck arrives" to "the driver is
committed".

Event storming is also the usual start of a domain model, and `design-patterns` lesson 11 takes it
from there into bounded contexts. Listening well in an interview is a craft of its own, which
`architect-communication` lesson 6 teaches, and `architecture-modeling` lesson 7 covers structured
business analysis in depth.
