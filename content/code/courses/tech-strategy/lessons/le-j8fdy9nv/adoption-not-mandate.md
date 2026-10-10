---
title: Adoption is measured, not mandated
version: 1
---

The quickest way to standardise anything is to require it. A memo says every new service starts from
the template, a review checks that it did, and within a quarter the adoption figure reads 100%.
**That figure measures obedience, and obedience says nothing about whether the standard is good.**
A team that would have left the path for a sound reason now stays on it and works around it, and
the reason never reaches the people who could have fixed the path.

Coreto's template was never compulsory. Rafaela published it, showed it at the engineering all-hands
and then counted what happened.

## The number

In the template's first year Coreto created 26 new services, and 18 of them started from the
template: **18 of 26, or 69%**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 192\" role=\"img\" aria-label=\"Twenty-six squares, one per new service created at Coreto in the template's first year. Eighteen are lit: those services started from the template. Eight are unlit: they started another way.\"><text x=\"360\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">New services created in the template's first year: 26</text><rect x=\"52\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"100\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"148\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"196\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"244\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"292\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"340\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"388\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"436\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"484\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"532\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"580\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"628\" y=\"48\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"52\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"100\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"148\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"196\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"244\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--phosphor)\"></rect><rect x=\"292\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"340\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"388\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"436\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"484\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"532\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"580\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"628\" y=\"96\" width=\"40\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"52\" y=\"162\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"74\" y=\"174\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">started from the template: 18 (69%)</text><rect x=\"392\" y=\"162\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"414\" y=\"174\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper)\">started another way: 8</text></svg>", "caption": "Adoption that nobody required. Each lit square is a team that judged the template to be less work than building the same layers itself; each dark one is a team with a reason worth asking about."}
```

The 69% is worth something precisely because nobody had to reach it. Each of the 18 was a team
deciding that the template was less work than doing it themselves, which is the only evidence that
a golden path is golden. A mandated 100% would have hidden the eight that went elsewhere, and the
eight are where the next improvement was.

## The eight that went elsewhere

Rafaela asked the team behind each of the eight why. The answers fell into three kinds, and each
kind calls for a different response:

| what the team said | what it means | what Platform did |
|---|---|---|
| "It does not fit what we build" | legitimate off-road work | nothing — Data's nightly jobs belong off the path |
| "It was missing something we needed" | a gap on the path | added a queue consumer to the template once a second team asked for one |
| "We did not know it existed" | a communication failure | linked the template from the page where teams request a new repository |

Only the middle row is a defect in the path, and only the first row is a reason to leave the number
below 100% for good. **A share of new services that stays off the path by choice is a healthy
sign**: it means the path is narrow enough to be kept working and teams still use their judgement
where it fits badly.

## Measures that keep it honest

One number invites the usual games, so Rafaela tracked it beside two questions that are harder to
flatter:

1. **Do services stay on the path?** A service started from the template and then edited until its
   pipeline no longer accepts the template's updates has left the path in all but name. Counting
   only starts would miss that drift.
2. **What did teams stop doing?** The point of the template was the days at the start of each new
   service spent on wiring. Asking the teams whether those days had gone tests the reason the
   template exists, rather than the template itself.

She did not set a target for the share. A target turns a measurement into a goal, and lesson 1
already showed what happens to a goal nobody has a plan for: it gets met by relabelling. The share
is read for its trend and for the reasons behind the services that are not in it.

## When a rule is the right tool

Some things should be required, and the line is clear once it is stated. **Mandate the outcome when
there is a right answer; offer a path when there is a better way.**

Card data is the case at Coreto. How Payments stores and transmits card details has a right answer,
set by the card industry's rules, and leaving it to each team's preference would be a risk with no
upside. So the rule is written as an outcome — card details never pass through a service outside
Payments — and the rule is checked. How a team builds its pipeline has no right answer of that kind.
There is a cheaper way and a more expensive way, and the team that picks the expensive one pays for
it.

Even a mandated outcome is easier to keep when the path makes it the default. If the template is
the easiest way to build a service and the template already sends logs without card numbers in
them, most teams meet the rule without thinking about it. The rule catches the rest.

| use a rule | use a golden path |
|---|---|
| there is a right answer | there is a better way |
| leaving it creates risk for others | leaving it costs only the team that leaves |
| checked, and an exception is escalated | measured, and an exception is a conversation |
| card data, access to production, personal data | pipelines, logging libraries, service layout |

Lesson 15 is the opposite of this section's story: a tool Coreto spent heavily on that the teams
did not choose, and what it took to find out why.
