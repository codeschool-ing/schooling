---
title: What a test plan is for
version: 1
---

A test plan is often pictured as a long document that somebody writes because a process asks for
one, and that nobody reads once it is approved. Plenty of plans are exactly that. **What a plan is
for is narrower and more useful: it writes down the decisions about testing before the testing
starts.** They are then made once, on purpose, by people who can see all of them at the same time,
instead of one at a time by whoever happens to be testing on the day.

Testing has more possible work than time, always. The nine requirements of the application in this
course already allow more cases than anybody would run, and a real product has hundreds of
requirements. Somebody decides what gets tested and what does not. The only question is whether
the decision is written where the team can disagree with it, or taken silently by whoever runs out
of time first.

## The questions a plan answers

The standard for test documentation, ISO/IEC/IEEE 29119-3, lists what a plan contains, and the
list is long. Read as questions, it comes down to seven:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" data-fig=\"l01-plan-questions\" aria-label=\"Seven boxes around the words a test plan. Each box holds a question and the part of the plan that answers it: what and what not, scope; where could it hurt, risks; how, approach; who and with what, people and environment; when, schedule; when are we done, exit criteria; what makes us stop, suspension criteria.\"><rect x=\"280.0\" y=\"105.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a test plan</text><rect x=\"20.0\" y=\"20.0\" width=\"200.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"36.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">What, and what not?</text><text x=\"120.0\" y=\"51.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">scope</text><rect x=\"20.0\" y=\"102.0\" width=\"200.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"118.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Where could it hurt?</text><text x=\"120.0\" y=\"133.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">risks</text><rect x=\"250.0\" y=\"20.0\" width=\"200.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"36.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">How?</text><text x=\"350.0\" y=\"51.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">approach</text><rect x=\"480.0\" y=\"20.0\" width=\"200.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"36.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Who, and with what?</text><text x=\"580.0\" y=\"51.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">people, environment</text><rect x=\"480.0\" y=\"102.0\" width=\"200.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"118.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">When?</text><text x=\"580.0\" y=\"133.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">schedule</text><rect x=\"20.0\" y=\"185.0\" width=\"200.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"201.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">When are we done?</text><text x=\"120.0\" y=\"216.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">exit criteria</text><rect x=\"250.0\" y=\"185.0\" width=\"200.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"201.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">What makes us stop?</text><text x=\"350.0\" y=\"216.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">suspension criteria</text></svg>", "caption": "The seven questions inside a test plan, and the name each answer goes by. The risks box is drawn in another colour because the others follow from it."}
```

**What are we testing, and what are we not?** The scope: which product, which version, which
features, and the features left out on purpose. A feature out of scope is a decision; a feature
nobody mentioned is a gap.

**Where could it hurt most?** The risks, ranked, because they decide where the effort goes. Most of
a plan's other answers follow from this one, which is why section 06 of this lesson is about it.

**How will we test it?** The approach: which levels and types of testing, which techniques, how
much is manual and how much automated.

**Who, and with what?** The people, their roles and the skills they need, and the environment:
machines, browsers, devices, data, accounts.

**When?** The schedule, tied to the project's own dates rather than to a calendar of its own.

**How do we know we are done?** The exit criteria, written before the first case runs, because
afterwards "done" means "out of time".

**What makes us stop?** The suspension criteria: the conditions under which testing pauses because
continuing would waste effort, such as a build that does not start.

## How big a plan is

A plan for a two-week change to a small web application fits on one page, and section 07 of this
lesson writes one for boxoffice. A plan for a bank's new core system runs to dozens of pages and is
split in two: a **master plan** for the whole project, and a **level plan** per level of testing,
system or acceptance, that inherits from it. An agile team often keeps no separate document at
all: the same decisions live in the team's definition of done, in the acceptance criteria of each
story, and in a page on the wiki.

The format is the cheap part. What makes a plan worth its time is that **every answer in it can be
disagreed with**. "We will test thoroughly" cannot be argued with and therefore decides nothing.
"We will not test on Safari for this release, because 3% of last month's visits used it and the
release changes no layout" can be argued with, and that is what makes it useful. The product
owner who knows that the theatre's biggest sponsor uses an iPhone now has something to object to,
before the release instead of after it.

## A plan is not a schedule of cases

A plan says how the testing will be decided. It does not list the cases themselves: those are
**test cases**, written to a shape of their own, and lesson 2 is about them. A plan that tries to
list every case is out of date by the second day, because the cases change every time a
requirement does, and the decisions above them change far less often.

The other confusion is with a **test strategy**. In a company that tests many products, the
strategy is the organisation's standing answer to the "how" question: the levels, the tools, the
kinds of report. Each project's plan refers to it rather than repeating it. A plan without a
strategy above it simply answers the "how" question itself, which is the case for boxoffice.
