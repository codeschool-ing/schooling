---
title: Where the sequence breaks
version: 1
---

**The waterfall and the V model share one assumption, and most of their trouble comes from it: that the
requirements can be known completely at the start and will not change.** When that holds, the sequence is
efficient. When it does not, which for most software is most of the time, the sequence turns every change
into a trip back to the top of the drawing.

## Three ways it breaks

**Requirements change.** Joana writes the price rule in January. In March, the cinema decides to offer a
loyalty discount. In a sequential project, that change goes back to the requirements phase, through
design, into code that is already written, and then through every test level again. The cost of a change
depends on how far down the V the project has already gone, which is lesson 3's curve in another form.

**Feedback arrives late.** The first time anybody outside the team uses the shop is acceptance testing,
at the end. If Célia's reaction to the first screen is *"nobody at the counter would understand this"*, the
team learns it after the screen, and everything behind it, has been built. Royce's own warning was about
exactly this.

**Testing gets squeezed.** Testing is the last phase before a fixed date. Every delay in the phases above
it comes out of testing's time, and the phase most often cut short is the one whose job is to say whether
the rest worked. Testers in waterfall projects learn to plan for a testing phase half as long as the one
on the schedule.

## Partial answers inside the model

Teams that must work sequentially have found ways to soften these:

- **design tests on the way down**, as the previous section described, so that the right side of the V is
  ready the day code arrives and ambiguities are found while writing them;
- **the W model**, proposed by Andreas Spillner around 2000, which draws a second V of test activities
  running in parallel to development: reviewing each document as it is written is itself a test, at the
  same moment the document is produced;
- **reviews and inspections at every phase**, which are static testing from lesson 1, catching defects in
  requirements and designs without waiting for code.

All three are prevention bolted onto a process designed around detection. They help, and they keep the
sequence.

## The other answer

The more radical answer is to stop assuming the requirements can be known at the start: build a small part,
show it to somebody, learn, and build the next part with what was learnt. Royce himself suggested doing the
whole thing twice. The models of the next lessons, the spiral and then the agile family, take that idea and
make it the whole process. For a tester, the change is less about technique than about rhythm: instead of
one long testing phase at the end, a short one in every cycle, all the time.
