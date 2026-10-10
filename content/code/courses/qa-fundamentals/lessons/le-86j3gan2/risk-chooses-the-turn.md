---
title: Risk chooses the turn
version: 1
---

**The spiral's central question is easy to state and hard to answer: of everything that could go wrong,
what is most likely to sink us, and what is the cheapest way to find out?** It is worth seeing what that
looks like on a real decision.

## Cine Aurora's first turns

Suppose Cine Aurora had built its online shop as a spiral. Before any code, Joana, Rafael, Tomás and Lia
listed what could make the project fail, with a rough judgement of how likely each was and how bad:

| risk | how likely | how bad | the cheapest way to find out |
|---|---|---|---|
| customers do not understand the seat map | medium | high: no sales | paper prototype, five regulars, one afternoon |
| two buyers get the same seat at the same moment | medium | high: angry customers, refunds | a small program that tries it a thousand times |
| the price rule is wrong | low | medium: refunds | review it with Célia |
| the payment provider is slow on opening nights | low | high | ask the provider for their numbers |

The first turn takes the top of that list: a paper prototype of the seat map, shown to five regulars. Two
of them could not tell a taken seat from a free one. That cost an afternoon and a redraw. Found after the
shop was built, it would have meant a redesign of the screen every other part depends on.

The second turn takes the next risk: double-sold seats. Rafael writes the smallest reservation program he
can and Lia writes another that tries to take the same seat from two places at once, a thousand times. It
is an experiment, and the result decides how the real reservation will be built.

The price rule, which this course has spent eight lessons on, sits third. **Not because it does not
matter, but because it is the cheapest to fix late**: one function, nothing built on it, as lesson 3's
four costs showed. A spiral would still have reviewed it with Célia, cheaply, early, and *over-60s* might
well have surfaced in that review.

## Likelihood and impact

The table judged each risk on two things: **how likely** it is and **how bad** it would be. That pair is
the basis of almost every way of prioritising tests, and lesson 20 turns it into a method with numbers.
What matters here is the habit the spiral builds: before deciding what to do, list what could go wrong,
judge each item on both axes, and start with the ones that are both likely and bad.

## What a tester brings to the list

Testers are good at this list, for the same reason they are good at finding defects: they spend their
days thinking about how things fail. In a risk conversation, the tester's contributions tend to be:

- **risks nobody listed**, because they come from looking at how real people use things: the box office
  and the website selling the same seat, a session typed with a single-digit hour;
- **cheaper experiments** for a risk already listed, because designing a test that could refute a belief
  is the job;
- **honesty about what an experiment did not show**: the thousand attempts that never double-sold a seat
  prove nothing about ten thousand.

The spiral is not used by many teams under that name today. The habit of choosing the next piece of work
by risk, and of treating the riskiest assumption as a hypothesis to test first, is everywhere, and you
will see it again in lessons 11 and 20.
