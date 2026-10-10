---
title: Working with teams: Conway, team types and a forum
version: 1
---

The picture of an architect who designs and teams who implement is a hand-off, and it fails for a
reason that has nothing to do with anybody's skill: **the teams' structure shapes the system at least
as much as any diagram does.** An architect who works only on the system, and never on how the teams
around it are arranged and how they talk, is designing the half that loses when the two disagree.

## Conway's law, used rather than quoted

Lesson 1 named Conway's law. Melvin Conway's 1968 paper put it roughly like this: an organisation that
designs a system produces a design whose structure copies the organisation's communication
structure. The usual reading is a warning. The useful reading is a tool.

Carreto had the warning in its incident log. The monolith's invoicing module was edited by two teams.
Shipper changed it when the shipper's screens needed something new; Payments changed it when the
payouts needed something new. Neither team owned it, both deployed it, and each made assumptions about
it that the other did not know. Of the nine incidents in invoicing over the previous year, **six began
with one team's change breaking an assumption the other team had built on.** The code was shared
because the responsibility was, and the responsibility was shared because nobody had decided
otherwise.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Two panels. Before: the Shipper team and the Payments team both have arrows into one invoicing module; both teams change it, and six of nine incidents began between the two. After: Payments has an arrow into the invoicing module, and Shipper has an arrow into a small api box on top of it; Payments owns it, Shipper asks through its api, one team changes it and one team is on call.\"><defs><marker id=\"conway-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"conway-ok\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"180\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--amber)\">before</text><text x=\"540\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--phosphor)\">after</text><rect x=\"10\" y=\"30\" width=\"340\" height=\"280\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"370\" y=\"30\" width=\"340\" height=\"280\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"30\" y=\"60\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Shipper</text><rect x=\"200\" y=\"60\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"265\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Payments</text><rect x=\"95\" y=\"200\" width=\"170\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">invoicing</text><path d=\"M95 102 L140 198\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#conway-ah)\"></path><path d=\"M265 102 L220 198\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#conway-ah)\"></path><text x=\"180\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">both teams change it</text><text x=\"180\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">six of nine incidents began between the two</text><rect x=\"390\" y=\"60\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"455\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Shipper</text><rect x=\"560\" y=\"60\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"625\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">Payments</text><rect x=\"545\" y=\"200\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"640\" y=\"225\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">invoicing</text><rect x=\"550\" y=\"170\" width=\"60\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"183\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">api</text><path d=\"M660 102 L660 198\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#conway-ok)\"></path><path d=\"M455 102 L578 168\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#conway-ah)\"></path><text x=\"540\" y=\"272\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Payments owns it; Shipper asks through its api</text><text x=\"540\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">one team changes it, one team is on call</text></svg>", "caption": "The inverse Conway manoeuvre at Carreto. Shared ownership produced a shared module and incidents at the seam; giving invoicing to one team put the seam in an interface."}
```

The **inverse Conway manoeuvre** turns the law round: decide the structure you want, then arrange the
teams so that their ordinary communication produces it. Renata's proposal was that Payments own
invoicing entirely, behind an interface, and that Shipper ask for what it needs through that interface
the way it would ask any other team. The code would follow the ownership: one team changing it, one
team on call for it, and one place where a change to the interface is discussed.

That proposal was not Renata's to carry out. **Moving work between teams is a decision about people,
and it belongs to the people who manage them.** She brought the incident count and the proposal to
Tomás and the two engineering managers, who moved two Shipper developers' invoicing work to Payments
and gave Payments a quarter to take it over. The architect's part was the argument and the interface;
the managers' part was the organisation.

## Four kinds of team

Matthew Skelton and Manuel Pais gave the arrangement a vocabulary in *Team Topologies* (2019). It names
four types of team and three ways for teams to work together, and Carreto's seven teams fit it
without forcing:

| type | what it does | at Carreto |
|---|---|---|
| **stream-aligned** | owns a flow of work for a customer or user, end to end | Shipper, Driver, Matching, Payments, Tracking |
| **platform** | provides internal services other teams use without needing to ask | Platform |
| **complicated subsystem** | owns a part that needs specialist knowledge most teams do not have | Pricing: freight pricing and the ANTT floor |
| **enabling** | helps another team acquire a capability, then steps away | nobody, until Renata |

The three interaction modes are **collaboration** (two teams working closely for a while on something
new), **X-as-a-service** (one team consumes what another provides, through an interface, with little
talking) and **facilitating** (one team helps another learn). The invoicing change moved Shipper and
Payments from an accidental, permanent collaboration to X-as-a-service, which is the cheap mode once
an interface is clear.

The book's other idea is **cognitive load**: a team can only hold so much in its head, and a team that
owns too much stops owning any of it well. Shipper owned its screens, half of invoicing and the CT-e
step of the shipper flow. Taking invoicing away was also a way of giving Shipper back the attention
its own work needed.

## The architect as an enabling team of one

An architect with no team of her own fits the enabling type better than any other: she joins a team
for a while to help it with something it cannot yet do alone, and the work is finished when they no
longer need her.

In the spring the Driver team had to make the app work through the dead zones on the roads to the
port of Paranaguá, where a driver loses signal for forty minutes. Diego's team had never designed
offline synchronisation. Renata spent three weeks working with them: two design sessions, a spike
she paired on with one of Diego's developers, and a review of the ADR his team wrote. She did not
write the design for them. By the fourth week the team was making the decisions without her, which
was the point.

**The measure of enabling work is that it stops being needed.** An architect who stays with a team,
or whose approval the team waits for, has turned facilitation into a dependency. Lesson 11 is about
the advising itself, and lesson 17 about the gatekeeper it turns into when the dependency sets in.

## A forum, not a board

Seven teams make decisions every week that cross their boundaries. Renata needed one place where those
decisions were seen before they were made, without creating a committee everybody had to get past.

Carreto's **architecture forum** meets on Thursdays for 45 minutes and is open to anybody. Its rules
fit on a card:

1. A proposal is a draft ADR, posted by Tuesday. A proposal that arrives later waits a week.
2. No slides. People read the draft before the meeting and the time is for questions.
3. The forum gives advice. It does not approve. The person proposing decides, after hearing it, as in
   lesson 3's advice process.
4. The advice given, and what the proposer did with it, goes into the ADR.

The third rule is the one that keeps it a forum rather than a review board. A board that approves
becomes a queue, and teams learn to bring it decisions that are already made. A forum that advises gets
proposals early, because early is when advice is most useful. In its first six months the forum heard
**23 proposals**, and 4 of them changed substantially because of what was said in the room; the
offline synchronisation design was one.

Attendance is not the measure. About twelve people come on an ordinary Thursday. What Renata watches
is which teams bring proposals: by the third month every team had brought at least one, and the
Pricing team, which had brought none in the first two, brought two in a row once its tech lead
saw that the forum changed proposals without blocking them.

The skills a forum like this runs on, listening for the real objection under the stated one and
mediating when two teams disagree, are `architect-communication` lessons 6 and 9. What this lesson
needs from them is the structure they work inside: teams arranged so that the system they produce is
the one intended, an architect who enables rather than approves, and one place where decisions that
cross boundaries are heard before they are made.
