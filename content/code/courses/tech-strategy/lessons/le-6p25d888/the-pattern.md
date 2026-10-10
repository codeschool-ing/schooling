---
title: The strangler pattern
version: 1
---

A system that has to change is usually argued about as if there were two choices: keep patching the
old code, or rewrite it. Lesson 6 priced the rewrite and turned it down. Patching alone leaves the
seat-hold debt charging its interest every sprint. **There is a third choice: replace the old system
one piece at a time, while it keeps serving traffic.** At every moment production runs on some
mixture of old and new, and nobody has to pick a day to switch.

## The fig

Martin Fowler named it in 2004, in a short article called "StranglerFigApplication", after a plant he
had seen in the rainforests of Queensland. A strangler fig starts as a seed in the branches of a host
tree. It sends roots down to the ground, wraps the trunk, and grows until it stands on its own; the
host tree inside eventually dies and rots away, and the fig keeps its shape.

The software version keeps the parts that matter. The new system grows around the old one rather
than beside it. It takes over one function at a time. And the old system keeps working the whole
while, until there is nothing left for it to do and it can be removed.

## The shape

The pattern has five moves, and the order is the point:

1. Put something in front of the old system that every relevant request passes through. Fowler's
   word for it is a facade; it can be a proxy, a router or a single entry point inside the old code.
2. Build the new piece for one slice of behaviour.
3. Route that slice to the new piece, and keep the way back open.
4. Repeat with the next slice, until nothing is left on the old path.
5. Delete the old code.

**The first move costs the most thought and delivers nothing a customer sees.** Every later move depends
on it, because the facade is what makes a slice movable — and movable back.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Three stages left to right. The callers — buyers on the web and the apps, and the Box Office at the door — send every seat-hold request to a facade. The facade looks up the event in a routing table and sends it either to coreto-core, the old seat-hold code with its row locks, for events not yet moved, or to the new reservation service, which holds seats with an expiry, for events already moved.\"><defs><marker id=\"l07f-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"125\" width=\"150\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"151\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Callers</text><text x=\"95.0\" y=\"169\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper-dim)\">web and apps</text><text x=\"95.0\" y=\"187\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper-dim)\">Box Office</text><rect x=\"230\" y=\"105\" width=\"180\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"320.0\" y=\"142\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--amber)\">Facade</text><text x=\"320.0\" y=\"160\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper)\">looks up the event</text><text x=\"320.0\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper)\">in a routing table,</text><text x=\"320.0\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper)\">sends it one way</text><rect x=\"480\" y=\"30\" width=\"220\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"66\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">coreto-core</text><text x=\"590.0\" y=\"84\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper)\">old seat-hold code</text><text x=\"590.0\" y=\"102\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper-dim)\">row locks</text><rect x=\"480\" y=\"200\" width=\"220\" height=\"100\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"590.0\" y=\"236\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Reservation service</text><text x=\"590.0\" y=\"254\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper)\">new seat-hold code</text><text x=\"590.0\" y=\"272\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"400\" fill=\"var(--paper-dim)\">holds that expire</text><path d=\"M172 165 L226 165\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l07f-ah)\"></path><path d=\"M412 140 L476 90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l07f-ah)\"></path><path d=\"M412 190 L476 240\" stroke=\"var(--phosphor)\" stroke-width=\"2\" marker-end=\"url(#l07f-ah)\"></path><text x=\"436\" y=\"100\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">not yet moved</text><text x=\"436\" y=\"244\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">moved</text></svg>", "caption": "The shape of the strangler at Coreto. Every seat-hold request passes the facade, and moving an event is a change to one row of its routing table — which also makes moving it back a change to one row."}
```

## At Coreto

The Reservations team, the four engineers lesson 1 formed from Checkout and Payments on 1 March, took
on the seat-hold code. Their new reservation service holds a seat with a record that expires on its
own, in a store of its own, instead of locking a row in `coreto-core`'s database for as long as the
buyer takes to pay. The facade sits where every seat-hold request already enters the monolith, and it
decides, event by event, which code answers.

At the end of month 1 the new service carried 5% of reservation traffic. At the end of month 6 it
carried 71%. The whole migration took twelve months, and on no day in those twelve did Coreto stop
selling tickets, freeze the other teams or announce a switch-over to venues.

## What it changes from a rewrite

| | rewrite | strangler |
|---|---|---|
| when value arrives | at the cutover, after the whole build | with the first slice moved |
| if the new code is wrong | wrong for everything, on one morning | wrong for one slice, routed back |
| the old system meanwhile | a moving target the new one chases | shrinking, one slice at a time |
| where the knowledge in the old code goes | rediscovered after the switch | found slice by slice, while both run |
| how it ends | a switch, on a date | when the old code is deleted |

**The moving target from lesson 6 stops being a problem**, because the part being replaced no longer
moves: once an event's holds are on the new service, changes to how that event's holds work are made
there. The teams keep shipping, and what they ship lands on whichever side currently owns it.

## What it costs

The pattern is cheaper than a rewrite and it is not free. For the length of the migration Coreto runs
two seat-hold systems instead of one, plus the facade between them. Some data has to be kept in step
across both, which is its own source of bugs. And the pattern asks for a discipline a rewrite never
does: **the work is finished only when the old code is gone**, and by then the urgent part is long over.

Those costs are where the next two sections go. Seams and routing are about choosing the slices and
moving them safely; the last ten percent is about the end, which is where most migrations of this
kind quietly stop.
