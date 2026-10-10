---
title: Discovery with engineers in it
version: 1
---

In most companies engineering meets a product idea for the first time as a specification. Product
has talked to customers, a designer has drawn the screens, and the team is asked how long it will
take. **By then the most expensive questions have been answered without engineering**, and some of
them have been answered wrongly. This section is about moving engineers to the start of that work,
and about what they are there to find.

## The relay that fails

The wrong idea is a relay race. Product discovers what to build, then hands the baton to
engineering, which builds it. Each side does its own job, and the handover is a document.

**The relay fails in a predictable place.** The specification describes a solution, and the people who
know what the system can and cannot do see it only after the solution is chosen. When it collides
with the system, the collision is found during the build, with a date already promised. At that
point the choices are bad ones: cut scope in a hurry, take on debt nobody planned for, or miss the
date. Engineering gets the blame for the estimate. The real failure is that nobody asked them while
the idea was still cheap to change.

## Cagan's four risks

Marty Cagan, who has written about product teams for many years, describes discovery as the work of
testing an idea against four risks before anybody commits to building it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 322\" role=\"img\" aria-label=\"Four boxes in a two by two grid, one per risk. Value: will customers choose it, or pay for it? Led by product. Usability: can they work out how to use it? Led by design. Feasibility, highlighted: can we build it, with these people, this system and this time? Led by engineering. Viability: does it work for finance, legal, sales and support? Led by product, with the business. Underneath: discovery tests all four before anyone commits to building.\"><rect x=\"20\" y=\"20\" width=\"330\" height=\"116\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"185\" y=\"50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">Value</text><text x=\"185\" y=\"76\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Will customers choose it,</text><text x=\"185\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">or pay for it?</text><text x=\"185\" y=\"120\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">led by product</text><rect x=\"370\" y=\"20\" width=\"330\" height=\"116\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"535\" y=\"50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">Usability</text><text x=\"535\" y=\"76\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Can they work out</text><text x=\"535\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">how to use it?</text><text x=\"535\" y=\"120\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">led by design</text><rect x=\"20\" y=\"148\" width=\"330\" height=\"116\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"185\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--amber)\">Feasibility</text><text x=\"185\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Can we build it, with these people,</text><text x=\"185\" y=\"222\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">this system and this time?</text><text x=\"185\" y=\"248\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">led by engineering</text><rect x=\"370\" y=\"148\" width=\"330\" height=\"116\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"535\" y=\"178\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"15\" font-weight=\"600\" fill=\"var(--phosphor)\">Viability</text><text x=\"535\" y=\"204\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Does it work for finance, legal,</text><text x=\"535\" y=\"222\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">sales and support?</text><text x=\"535\" y=\"248\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">led by product, with the business</text><rect x=\"20\" y=\"278\" width=\"680\" height=\"30\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"298\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">discovery tests all four before anyone commits to building</text></svg>", "caption": "Cagan’s four risks. Feasibility is the one only engineering can answer, which is why an engineer belongs in discovery from the start rather than at the handover."}
```

| risk | the question | who leads on it |
|---|---|---|
| value | Will customers choose it, or pay for it? | product |
| usability | Can they work out how to use it? | design |
| feasibility | Can we build it, with these people, this system and this time? | engineering |
| viability | Does it work for the rest of the business: finance, legal, sales, support? | product, with the business |

**Feasibility is the one only engineering can answer**, and that alone is a reason to have an
engineer in discovery. It is not the only reason. Engineers also know what has recently become
possible, and an idea that nobody in product would propose because they do not know it is cheap now
is one an engineer in the room can offer. Cagan's own point is that engineers are often the best
source of new ideas, if they are allowed near the problem.

Feasibility also covers more than "can it be done". It asks what doing it would cost the system, and
that is where a technical strategy and a product idea meet.

## Festival seat maps, with Mateus in the room

Coreto sells general admission for festivals: a ticket gets you through the gate. Festival organisers
told Júlia Sato's team that they wanted to sell reserved areas as well, with a map where a buyer
picks a spot in a grandstand or a box. Júlia's team had heard it from several organisers, so the
value risk looked low. In earlier years this would have become a specification and reached
Checkout as a project with a quarter on it.

This time Mateus Araújo, the Checkout tech lead, joined discovery in its second week. He went to
two of the organiser calls and read the notes from the rest. Within days he had found the risk that
mattered.

A reserved festival area is a seat map, and every seat on a map goes through the seat-hold path. A
large festival's on-sale is exactly the kind of big on-sale where that path fails today. Building
festival maps on top of the current hold code would add a new, larger on-sale to the one module the
strategy says to protect first. **The feature was feasible only after ADR-0006**, the decision from
lesson 17 to hold seats without row locks, had landed.

That changed the plan without killing the idea. The team tested the other three risks while the
Reservations team worked:

- Value: Júlia's team showed organisers a clickable prototype and asked which events they would use
  it for.
- Usability: the designer put the same prototype in front of buyers on their phones, because a
  festival map is read on a small screen in a queue.
- Viability: Otávio Lins's team checked how Coreto's fee per ticket would apply to a reserved area
  priced differently from the rest of the festival.
- Feasibility: Mateus ran a short spike against the on-sale load test, using the new hold path
  behind its flag.

The build started when all four came back clean. It started later than Júlia first hoped, and the
reason was in writing, on the roadmap, months before anybody could have missed a date over it.

## What it costs to include engineers

Discovery with an engineer in it costs engineering time, and pretending otherwise sets up the next
argument. Three choices make it workable at Coreto.

**One engineer, not the team.** A tech lead, or a senior engineer the team nominates, joins the
calls and the prototype sessions. The rest of the team keeps building, and hears what was learned at
the next planning meeting.

**The engineer's job is the risks, not the estimate.** An early estimate given in a discovery meeting
becomes a promise by the end of the week. Mateus said what the festival maps depended on and what
would have to be true before the build could start; he gave no date, and nobody asked him for one.

The time counts as product work. Coreto files discovery under the product side of each team's
capacity, the subject of the next section. Engineering investment is a different thing, and putting
discovery in it would make the share for debt shrink every time product had a new idea.

Disagreements will still happen. When product and engineering disagree about a risk, the useful
question is what evidence would settle it, and who will collect it by when.
`people-leadership` lesson 22 covers the conflict itself when the evidence does not settle it.
