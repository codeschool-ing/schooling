---
title: Turning a characteristic into something you can check
version: 1
---

**A requirement nobody can check is a defect in the requirement, and it is the cheapest defect a tester
will ever find.** Joana's first draft of the ticket shop's goals had three lines that looked fine and
could not be tested at all:

> The shop must be fast. It must be easy to use. It must not lose sales.

Each names a characteristic from the previous section: performance efficiency, interaction capability,
reliability. None says what would count as failing. Ask a developer whether the shop is fast and the
honest answer is "compared with what?". Ask a tester to test that it is fast and the honest answer is
"I cannot tell you when I am finished".

## Four questions that make it checkable

A quality requirement becomes checkable when it answers four questions:

1. **Who**, or what, is doing something? A customer, the box office, the nightly report.
2. **Doing what?** One task, named: opening the seat map, buying two tickets, printing a receipt.
3. **Under what conditions?** On a phone, on a slow connection, with three hundred people buying at
   once, on the first night of a release.
4. **How much is enough?** A number, a proportion, or an observable event, with the boundary stated.

Apply them to Joana's three lines and they come out like this:

| vague | checkable |
|---|---|
| the shop must be fast | on a phone over a 4G connection, the seat map opens within 2 seconds for 95 of every 100 requests, with 300 customers buying at once |
| it must be easy to use | five regular customers who have never used the new shop each buy two tickets without help, in under three minutes |
| it must not lose sales | if the card payment fails, the seats stay held for ten minutes and the customer can pay again without choosing them again |

The numbers on the right are decisions, not facts. Two seconds might be three; five customers might be
eight. **What changed is that somebody now has to choose them**, and Joana is the one who should,
because she knows what the cinema can afford and what its customers put up with. The tester's job was to
make the choice visible, not to make it.

## Why this belongs to quality assurance

Asking the four questions is prevention in its purest form. Nothing has been built, nothing has been
run, and a whole class of argument has been avoided: the one at the end of a project where the
developer says the shop is fast enough, the product owner says it is not, and neither can prove
anything because nobody wrote down what enough meant.

It also exposes requirements that hide a disagreement. When Lia asked what *must not lose sales* meant,
Joana said "the payment never fails", Rafael said "the payment provider fails about once in two hundred
attempts and we cannot change that", and the checkable version on the right is the compromise the
question forced. Without the question, Rafael would have built one thing, Joana would have expected
another, and the first person to discover the difference would have been a customer with two seats they
could no longer pay for.

## The characteristic nobody asked about

Run the four questions down all nine characteristics and some come back with no answer at all, because
nobody had thought about them. At Cine Aurora that was **safety**: a screen has 180 seats, the box
office and the website sell for the same room, and nothing in any document said what stops the two of
them, together, selling a 181st ticket. The fire licence sets that number, so it is not a commercial
detail. That is a requirement too, and its absence is the kind of gap a
checklist exists to reveal.

You do not have to resolve such a gap yourself. Writing it down as a question to the product owner,
with the scenario that worries you, is the deliverable.
