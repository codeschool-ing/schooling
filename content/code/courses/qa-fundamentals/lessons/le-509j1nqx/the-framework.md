---
title: Scrum in one page, and where the tester is in it
version: 1
---

**Scrum is the most widely used agile framework, and it is small: three accountabilities, five events,
three artefacts.** Its rules are in the *Scrum Guide*, written by Ken Schwaber and Jeff Sutherland and
revised several times since 2010; the 2020 edition is thirteen pages. Everything else people associate with
Scrum, story points, burndown charts, the word "ceremonies", is practice that grew around it.

## Three accountabilities

| accountability | responsible for | at Cine Aurora |
|---|---|---|
| **Product Owner** | the value of the product: what is built, in what order | Joana |
| **Scrum Master** | the team's effectiveness: removing obstacles, helping the team use Scrum well | Tomás, part of his time |
| **Developers** | creating a usable increment every sprint | Rafael, Tomás and Lia |

Look at the last row. **The Scrum Guide has no tester role.** Everyone who builds the increment is a
Developer, whatever their specialism, and the Guide says so deliberately: the team is accountable for the
increment together, so no sub-group can be accountable for "the testing" of it. Lia is a Developer in
Scrum's sense, whose specialism is testing. That is lesson 5's whole-team approach written into the rules.

## Five events

The **sprint** is a fixed-length cycle of one month or less, usually two weeks, and contains the other four:

1. **sprint planning**: the team decides what it can deliver this sprint and how, and writes a sprint goal;
2. **daily scrum**: fifteen minutes each day to inspect progress toward the goal and adapt the plan;
3. **sprint review**: at the end, the team shows what it built to the people who care and decides what to
   do next with them;
4. **sprint retrospective**: the team looks at how it worked and chooses improvements for the next sprint.

## Three artefacts, each with a commitment

- the **product backlog**, the ordered list of everything that might be built, whose commitment is the
  **product goal**;
- the **sprint backlog**, what the team chose for this sprint and its plan, whose commitment is the **sprint
  goal**;
- the **increment**, the usable result of the sprint, whose commitment is the **definition of done**.

That last commitment is the one testers care about most, and it gets a section of its own.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 205\" role=\"img\" data-fig=\"l12-sprint\" aria-label=\"The Scrum cycle. The product backlog feeds sprint planning, which produces the sprint backlog. Inside a two-week sprint, the daily scrum happens every day. The sprint ends with the sprint review, then the retrospective, and produces an increment that meets the definition of done. Under each event, the tester’s contribution: at planning, questions and how to test; at the daily scrum, what waits for testing; at the review, Célia tries it; at the retrospective, why was it possible.\"><defs><marker id=\"qa-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10.0\" y=\"50.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">product backlog</text><path d=\"M121.0 70.0 L139.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"140.0\" y=\"50.0\" width=\"110.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"195.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">sprint planning</text><rect x=\"270.0\" y=\"30.0\" width=\"270.0\" height=\"160.0\" rx=\"8\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"405.0\" y=\"46.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">the sprint: two weeks</text><path d=\"M251.0 70.0 L285.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"286.0\" y=\"56.0\" width=\"100.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"336.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">sprint backlog</text><rect x=\"400.0\" y=\"56.0\" width=\"126.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"463.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">daily scrum, every day</text><rect x=\"286.0\" y=\"120.0\" width=\"110.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"341.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">sprint review</text><rect x=\"410.0\" y=\"120.0\" width=\"116.0\" height=\"36.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"468.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">retrospective</text><path d=\"M397.0 138.0 L409.0 138.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><path d=\"M541.0 138.0 L555.0 138.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#qa-ah-paper-dim)\"></path><rect x=\"556.0\" y=\"108.0\" width=\"116.0\" height=\"60.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"614.0\" y=\"125.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">increment</text><text x=\"614.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">meets the definition</text><text x=\"614.0\" y=\"150.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">of done</text><text x=\"195.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">questions, how to test</text><text x=\"463.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">what waits for testing</text><text x=\"341.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">Célia tries it</text><text x=\"468.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">why was it possible?</text></svg>", "caption": "The events of a sprint, with what testing brings to each. The increment only counts if it meets the definition of done."}
```

## What Scrum does not say

Scrum says nothing about how to test, how to write code, how to estimate, or what a story looks like. It is a
frame for a team to inspect and adapt its own work. That is why two Scrum teams can test in completely
different ways, and why a Scrum team can fall into every trap lesson 11 described while following every rule
in the Guide. The frame helps exactly as much as the team's honesty in its definition of done and its
retrospectives.
