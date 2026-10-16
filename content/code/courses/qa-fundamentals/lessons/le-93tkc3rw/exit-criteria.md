---
title: Exit criteria, or when testing is enough
version: 1
---

**Exit criteria say what must be true for a test cycle to end, and they are written before the cycle starts.** Written
afterwards, they describe whatever happened. Written before, they are a commitment the team can hold itself to when
Friday arrives and everybody wants to release.

## What exit criteria are made of

Good exit criteria mix three kinds of statement:

- **coverage**: what was supposed to be tested, was. Usually stated against the priority table of lesson 20, not as a
  percentage of something;
- **results**: what is allowed to be still broken, by how bad it is. Defects are commonly graded by **severity**, the
  damage they do, from critical down to trivial;
- **knowledge**: what is not known is written down. The list of things not tested from lesson 20 is part of the exit,
  not an embarrassment kept outside it.

## Cine Aurora's exit criteria

| criterion | why |
|---|---|
| every area in the priority table got its planned hours, or the shortfall is written down | coverage that matches the risk, not an even spread |
| every agreed acceptance test passes | these are the stories' definition, agreed with Joana |
| no open defect of high or critical severity in prices, orders or refunds | the areas where a defect costs money in front of a customer |
| every open defect has an owner and a decision: fix now, fix later, or accept | nothing open is unowned |
| the summary lists what was tested lightly and what was not tested | the release decision is made with the gaps visible |

## Measures that make poor exit criteria

Some exit criteria are popular because they are easy to count, and they are poor for exactly that reason:

- **"95% of test cases passed"**: which 5% failed? One failing price test outweighs a hundred passing report tests, and a
  percentage hides which is which;
- **"zero open defects"**: it encourages not reporting, reclassifying, or closing defects as "won't fix" on Thursday
  night. It also cannot be met by any real release;
- **"100% code coverage"**: lesson 7 showed that a line run is not a line checked, and lesson 15 that a test only
  exists for the questions somebody asked;
- **"testing has ended because the time ran out"**: this is the absence of an exit criterion, and it is the most common
  one of all.

Lesson 22 is about measures in general, and about what happens to a number once a team is rewarded for it.

## What the criteria are for

Exit criteria do not decide whether to release. They decide whether **testing** has done what it set out to do, and
they make the state of the product readable for the person who does decide. Lia's job on Friday morning is to say,
for each criterion, met or not met, with the evidence. Joana's job is the decision.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 200\" role=\"img\" data-fig=\"l21-cycle\" aria-label=\"A test cycle as a timeline. Entry criteria at the start: one build, the smoke test passes, the right machine and data. Testing runs through Wednesday and Thursday, with a suspended stretch on Thursday from 9:40 to 11:50. On Friday morning the exit criteria are reported, met or not met, with evidence, and the decision is Joana’s.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"50.0\" width=\"140.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"80.0\" y=\"69.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">entry criteria</text><text x=\"80.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">one build, smoke passes,</text><text x=\"80.0\" y=\"94.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">right machine and data</text><path d=\"M151.0 82.0 L169.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"170.0\" y=\"62.0\" width=\"300.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"240.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">testing</text><rect x=\"340.0\" y=\"62.0\" width=\"50.0\" height=\"40.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"365.0\" y=\"122.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">suspended</text><text x=\"365.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">9:40 to 11:50</text><path d=\"M320.0 66.0 L320.0 98.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"2 3\"></path><text x=\"245.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Wednesday</text><text x=\"395.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Thursday</text><text x=\"535.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Friday morning</text><path d=\"M471.0 82.0 L489.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"490.0\" y=\"50.0\" width=\"110.0\" height=\"64.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"69.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--phosphor)\">exit criteria</text><text x=\"545.0\" y=\"82.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">met or not met,</text><text x=\"545.0\" y=\"94.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">with evidence</text><path d=\"M601.0 82.0 L615.0 82.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"616.0\" y=\"58.0\" width=\"58.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"645.0\" y=\"75.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--amber)\">decision</text><text x=\"645.0\" y=\"88.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Joana</text></svg>", "caption": "Entry and exit criteria are written before the cycle starts. The tester reports against them; the product owner decides."}
```
