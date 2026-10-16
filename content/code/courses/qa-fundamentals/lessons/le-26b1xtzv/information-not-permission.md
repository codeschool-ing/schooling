---
title: Information, not permission
version: 1
---

**Cem Kaner, one of the founders of the context-driven school of testing, defined software testing as
an empirical, technical investigation conducted to provide stakeholders with information about the
quality of the product or service under test.** Every word earns its place, and the last important one
is *information*. Not approval, not a verdict: information, for somebody else to decide with.

## What a release decision actually needs

On the Thursday before the first Sunday morning session, Lia had found the 9:30 defect from lesson 4,
and Rafael's fix was not ready. Under a gate, the question would have been whether Lia approved the
release. Under Kaner's definition, the question was what Joana needed to know to decide. Lia gave her
four things:

1. **What is known.** *A session time written as `9:30` is charged as evening. Every session that starts
   before 10:00 is affected. There is one: Sunday at 9:30, about sixty seats.*
2. **What it costs if it ships.** *Each adult pays R$ 8,00 too much, each child R$ 4,00. Customers will
   notice at the counter, because Célia sells the same session for less.*
3. **What is not known.** *I have tested prices. I have not tested the seat map for a session before
   10:00, because the first time one existed was yesterday.*
4. **What could reduce the risk.** *Writing the time as `09:30` in the session list works around it
   today. Or the box office alone could sell the morning session this week.*

None of those is "yes" or "no". Joana chose to release on Friday with the session written as `09:30`,
and the fix the following week. **That was her decision to make, and it was a better one because the
information was complete**, including the part about what had not been tested.

## The part people leave out

The third item is the one testers most often leave out, and it is the most valuable. A report of what
was found answers a question nobody asked: "is everything fine?". Nobody can answer that. A report of
what was **not** checked tells the decision-maker where the unknowns are, and they may know something
the tester does not: that the seat map shares no code with the price rule, or that it shares all of it.

Michael Bolton, writing about testing reports, says a good one tells three stories at once: **the
product** (what you found), **the testing** (how you looked, and how well), and **the quality of the
testing** (what made it harder, and what you could not reach). The third is the one that lets a reader
judge how much to trust the first.

## Advocacy without a veto

Giving information instead of permission does not mean being neutral. A tester who believes a defect
should stop a release says so, plainly, with the evidence. What changes is the form of the sentence:

| as a gate | as information |
|---|---|
| "I am not approving this release." | "I would not ship this, and here is why: every Sunday morning customer pays too much, and Célia will hear about it first." |
| "QA has failed this build." | "Two defects found; one affects money, one affects a label. Here is the money one in two commands." |
| "This is not ready." | "Here is what I tested and what I did not. The untested part is the seat map before 10:00." |

The right-hand column is more persuasive, not less. It gives the decision-maker something to weigh, and
a recommendation backed by evidence is harder to dismiss than a refusal, which only invites the question
of who outranks whom.

## When the answer is ship anyway

Sometimes the person who owns the product hears everything and decides to ship a defect the tester
would have held back. That is not a failure of the tester. It is the system working: the decision was
made by the person accountable for it, with the risks in view. What the tester owes the team then is to
**write down what was known and what was decided**, so that if the risk materialises, the conversation
afterwards is about the decision and not about who knew what. Lesson 18 is about having that
conversation without blame.
