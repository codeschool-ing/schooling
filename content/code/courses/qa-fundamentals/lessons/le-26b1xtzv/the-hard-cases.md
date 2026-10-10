---
title: The hard cases
version: 1
---

**The argument against the gate has limits, and a tester who has absorbed it too thoroughly can fail in
the opposite direction.** Information without a veto works when the decision-maker can weigh the risk.
Some risks are not theirs to weigh, and in a few situations a tester has to do more than report.

## Risks that belong to somebody outside the room

A product owner decides commercial trade-offs: ship now with a known defect, or wait a week. There are
risks no single team can accept on the company's behalf:

- **legal.** Charging people over sixty the full price is not only a defect at Cine Aurora; Brazilian
  law guarantees them the half price. A team can choose to ship a typo. It cannot choose to break a
  statute, and a tester who knows the law is involved should say so in exactly those words;
- **safety.** Selling more tickets than a room holds puts people at risk in an evacuation. Lesson 2
  found that nothing prevented it;
- **people's data.** A defect that shows one customer another customer's orders exposes personal data
  that the company has a legal duty to protect;
- **money that is not the company's.** A refund that is never sent, a card charged twice.

For these, the tester's information goes further than the product owner if needed: to whoever in the
company answers for the law, the safety licence or the data. **That is escalation, not obstruction**, and
a healthy team expects it and knows the route in advance. A team that does not have one should decide
it on a calm day, not the night before a release.

## Saying "I would not ship this"

Even when nothing is legal or dangerous, a tester is entitled to a view, and should give it. The craft is
in the form:

1. state the recommendation plainly, in the first sentence;
2. give the evidence that leads to it, briefly, with a reproduction;
3. name the cost of shipping and the cost of waiting, as honestly as you can, including the ones that
   weaken your case;
4. say what would change your mind: a workaround, a fix, a narrower release.

The fourth is what separates a view from a veto. *"I would not ship the Sunday session priced as it is;
writing it as 09:30 makes me comfortable"* hands Joana a way forward. *"This cannot ship"* hands her a
standoff.

## When you are overruled

You will be, and sometimes you will be wrong to have objected. When it happens:

- **record it**, neutrally: what was known, what was recommended, what was decided and by whom. A short
  note in the team's tracker is enough;
- **then help.** The decision is made; the most useful thing now is to reduce the risk that was
  accepted. Watch the first Sunday's sales. Ask Célia to tell you if a family complains;
- **do not keep score.** If the risk materialises, the record makes the conversation afterwards about the
  decision, which is where it belongs. Saying "I told you so" turns it into one about people, and lesson
  18 explains why that conversation finds nothing.

## The test of the role

There is a simple way to tell whether a team has a gatekeeper or a tester. Ask the developers what they
do when they are unsure whether something works. If the answer is "send it to QA and see", the tester is
a gate, whatever the job title says. If it is "ask Lia what she would try", the tester has become what
this lesson describes: somebody whose way of thinking the team borrows, long before anything is finished.
