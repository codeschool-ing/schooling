---
title: Testing inside a two-week cycle
version: 1
---

**An agile team builds the system in short cycles, usually one to four weeks long, and at the end of each
one something works that did not work before.** For a tester, the difference from everything in lessons 9
and 10 is the size of the loop. The whole V, from requirement to acceptance, has to happen inside two weeks,
for a slice of the system small enough to fit.

## The mini-waterfall, and why it fails

The most common way agile goes wrong for testers has a name of its own: the **mini-waterfall**. The team
plans a two-week cycle, developers build for eight days, and everything arrives at the tester on the ninth.
It is lesson 9's waterfall, shrunk: the same squeeze at the end, the same work arriving all at once, now
every two weeks instead of once a year.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 230\" role=\"img\" data-fig=\"l11-two-sprints\" aria-label=\"Two timelines of ten working days. Mini-waterfall: building fills days 1 to 8 and testing is squeezed into days 9 and 10, with a note that everything arrives on day 9. Testing throughout: on day 1 the tester asks questions, and from day 2 small pieces are built and each is tested a day or two later, so build and test blocks alternate across the whole cycle.\"><text x=\"174.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">day 1</text><text x=\"223.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">day 2</text><text x=\"272.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">day 3</text><text x=\"321.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">day 4</text><text x=\"370.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">day 5</text><text x=\"419.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">day 6</text><text x=\"468.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">day 7</text><text x=\"517.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">day 8</text><text x=\"566.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">day 9</text><text x=\"615.5\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">day 10</text><text x=\"140.0\" y=\"60.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">mini-waterfall</text><rect x=\"150.0\" y=\"40.0\" width=\"390.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"345.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">build</text><rect x=\"542.0\" y=\"40.0\" width=\"96.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"590.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">test</text><text x=\"542.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">everything arrives on day 9</text><text x=\"140.0\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">testing throughout</text><rect x=\"150.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"173.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">ask</text><rect x=\"199.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"222.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">build</text><rect x=\"248.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"271.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">build</text><rect x=\"297.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"320.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">test</text><rect x=\"346.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"369.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">build</text><rect x=\"395.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"418.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">test</text><rect x=\"444.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"467.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">build</text><rect x=\"493.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"516.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">test</text><rect x=\"542.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"565.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">build</text><rect x=\"591.0\" y=\"130.0\" width=\"47.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"614.5\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--phosphor)\">test</text></svg>", "caption": "The same two weeks. Above, the waterfall shrunk to a sprint; below, testing keeps pace with building, and every defect is found while it is young."}
```

The figure shows the difference. In the mini-waterfall, testing is a block at the end and anything it finds
either rolls into the next cycle or is shipped. In the version that works, testing runs from the first day:
on day one Lia is asking questions about the stories, on day three she is testing the first small piece
Rafael finished, and by the last day there is little left that nobody has looked at.

## What makes testing continuous possible

Three habits, each of which a team has to choose, and each of which has a later lesson of its own:

- **small stories.** A piece of work small enough to be built and tested in a day or two arrives at testing
  early, alone, while its author still remembers it. "The whole price rule" is too big; "students pay half"
  is a story;
- **a shared definition of done.** A story is not done when the code is written; it is done when it is
  tested, by whatever the team agrees "tested" means. Lesson 12 is about writing that definition;
- **automated regression checks.** Every cycle changes code that worked last cycle, and lesson 10 showed how
  regression grows. A team that re-tests by hand stops being able to finish a cycle within a few months.
  Lessons 15 to 17 are about the forms of automated checks that agile teams lean on most.

## What the tester does all day

In a short cycle, the tester's week looks less like a test phase and more like lesson 5's table of Lia's
third week: questions at the start, pairing in the middle, exploring whatever is newly finished, and helping
the team decide whether the cycle's work is ready. The checking of finished pieces is still there, but it
happens in small portions, all the time, rather than in one block at the end.

The rhythm matters because of lesson 3. A defect found on day three of a two-week cycle is a few hours old;
its author remembers it, nothing is built on it, nobody outside the team has met it. **Short cycles make
every defect a young defect**, which is the cheapest kind there is, provided testing keeps pace with the
building rather than waiting for the end.
