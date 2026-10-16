---
title: Conflict between two people on the team
version: 1
---

Conflict on a team is normal, and some of it is useful. **The useful kind is a disagreement about the
work; the harmful kind is a disagreement about each other**, and the manager's job is mostly to keep
the first from turning into the second, and to find the first inside the second when it already has.

## Two kinds of conflict

Karen Jehn, studying work groups in the 1990s, separated **task conflict**, disagreement about the work
itself, its design, its priorities, its approach, from **relationship conflict**, friction between the
people: irritation, distrust, dislike. Later research has qualified how often task conflict actually
helps, but the distinction has held up, and so has the finding that relationship conflict damages
teams reliably.

The two feed each other. A design disagreement argued badly becomes personal, and a personal grudge
makes every design disagreement harder. Most conflicts that reach a manager are a mixture, and the
mixture is presented as purely one or the other by each person involved.

## Diego and Paula

When Paula took over the calendar-sync service in lesson 13, she started changing its retry logic,
which Diego had designed. Diego's reviews of her changes became longer and sharper. Paula stopped asking
him for reviews, and in a planning meeting said, in front of the team, that "some people find it hard to
let go of their code". Diego left the meeting early.

Renata heard about it from both of them the same afternoon. Diego said Paula was undoing careful work
without understanding why it was built that way. Paula said Diego was treating her ownership as
temporary and reviewing her as if she were a junior. **Both accounts were partly true, and each person
was certain the other was the problem.**

## What Renata did

**She talked to each of them separately first**, and listened without agreeing. She asked each the same
two questions: what is the disagreement about the work, and what would a good outcome look like? Asked
that way, the task conflict surfaced. Diego believed the retry logic handled a failure mode with one
particular clinic's calendar provider that Paula's change would break. Paula did not know about that
failure mode, because it was documented nowhere.

**She did not decide who was right from either account.** Taking a side after hearing one person is the
fastest way to make a relationship conflict permanent, because the other person now has two adversaries.

**She brought them together with a shared problem, not a grievance.** The meeting was framed as "the
retry logic has a failure mode only Diego knows about, and Paula owns the service now. How do we get the
knowledge across?" Diego explained the failure mode. Paula wrote it into the service's documentation and
adjusted her change. They agreed, on lesson 2's page, that Paula decides the design of the service she
owns and Diego is consulted on changes to the retry logic until the documentation is complete.

**She dealt with the public remark separately**, in Paula's next one-to-one, with the feedback structure
from lesson 8. Pointing at a colleague in planning had an impact on the whole team regardless of who was
right about the code.

## Five ways of handling it

Kenneth Thomas and Ralph Kilmann described five ways people handle conflict, along two axes: how much
each person pushes for their own concern, and how much for the other's.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l22-modes\" aria-label=\"Two axes: how much a person pushes for their own concern, from low to high, going up; and how much for the other person’s, from low to high, going right. Competing is high on own concern and low on the other’s. Collaborating is high on both. Avoiding is low on both. Accommodating is low on own concern and high on the other’s. Compromising sits in the middle.\"><defs><marker id=\"l22-modes-pl-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"160.0\" y=\"30.0\" width=\"420.0\" height=\"250.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M160.0 294.0 L580.0 294.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-modes-pl-ah-paper-dim)\"></path><text x=\"370.0\" y=\"312.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pushing for the other’s concern</text><path d=\"M146.0 280.0 L146.0 30.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l22-modes-pl-ah-paper-dim)\"></path><text x=\"136.0\" y=\"140.7\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">pushing for</text><text x=\"136.0\" y=\"155.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">your own</text><text x=\"136.0\" y=\"169.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">concern</text><rect x=\"176.0\" y=\"51.5\" width=\"136.0\" height=\"32.0\" rx=\"16\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"244.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">competing</text><rect x=\"428.0\" y=\"51.5\" width=\"136.0\" height=\"32.0\" rx=\"16\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"496.0\" y=\"67.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">collaborating</text><rect x=\"302.0\" y=\"139.0\" width=\"136.0\" height=\"32.0\" rx=\"16\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"370.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">compromising</text><rect x=\"176.0\" y=\"226.5\" width=\"136.0\" height=\"32.0\" rx=\"16\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"244.0\" y=\"242.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">avoiding</text><rect x=\"428.0\" y=\"226.5\" width=\"136.0\" height=\"32.0\" rx=\"16\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></rect><text x=\"496.0\" y=\"242.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">accommodating</text></svg>", "caption": "After Thomas and Kilmann. Each mode fits some situations; the harm comes from using one for everything."}
```

None is always right. Competing fits an emergency where somebody has to decide now. Accommodating fits
something that matters much more to the other person. Avoiding fits a trivial disagreement that will
fade. **The harm comes from using one mode for everything**: Diego was competing by habit, and Paula
had been accommodating until she stopped, abruptly, in public. What Renata steered them towards was
collaborating, on the one question where both had something the other needed.
