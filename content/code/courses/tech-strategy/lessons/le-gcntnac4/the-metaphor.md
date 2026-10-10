---
title: What Cunningham meant by debt
version: 1
---

"Technical debt" is used in most engineering organisations to mean code somebody dislikes: old
code, ugly code, code written by a team that has since left. At Coreto the phrase was line 6 of the
first draft in lesson 1, "pay down technical debt", and nobody could say which debt or why. **Used
that way, the phrase names a feeling, and a feeling cannot be prioritised against a feature.** The
metaphor was coined for something narrower and more useful, and the narrow version is the one that
lets you argue for money.

## Where the phrase comes from

Ward Cunningham introduced it in an experience report at the OOPSLA conference in 1992, about a
portfolio-management product his team was building. His argument, in paraphrase: shipping code
before you fully understand the problem is like taking on a loan. A little of it speeds development,
as long as it is paid back promptly by reworking the code to match what the team has learnt. The
danger is the loan that is never repaid, because every minute spent working on not-quite-right code
is interest on it — and an organisation can be brought to a standstill by the interest alone.

Three things in that are easy to lose.

**The debt is taken on deliberately, to learn faster.** Cunningham's team shipped code that
reflected their understanding at the time, knowing it would be wrong in ways they could not yet see,
because shipping was how they would find out. The debt is the gap between the code and what they
understood later.

**Borrowing is a good decision.** A company that never borrows grows slower than one that borrows
well. A team that refuses to ship until the design is perfect is not avoiding debt; it is paying
the cost of delay instead, which lesson 13 prices.

**The danger is in not repaying.** The loan is fine. The loan left on the books for years, while
everybody works around it, is what stops an organisation.

## What the metaphor gives you

It brings two words that finance already uses, and lesson 5 turns both into hours and reais.

**Principal** is the work it would take to remove the debt: rework the code so that it matches what
the team now knows. It is paid once.

**Interest** is the extra cost the debt adds to every piece of work that touches it, for as long as
it stays: the longer change, the extra review, the incident, the workaround. It is paid again and
again, by whoever touches the code next.

The words matter because the people who decide budgets understand them. Otávio, Coreto's CFO, has
never read the reservation module and never will. He knows exactly what it means to carry a loan
whose interest is larger than the cost of paying it off.

## A mess is not a loan

The narrow meaning excludes something the everyday use includes. **Code written carelessly, by
people who could have done better and chose not to, is not a loan taken to learn faster.** Nobody
got anything for it. It still costs interest, which is why later writers widened the term to cover
it, and the next section uses that wider map. But it is worth keeping the difference in view, for a
practical reason: a deliberate loan comes with a plan to repay it, and a mess comes with none. The
first needs a repayment date. The second needs a change in how the team works, or it will be back.

## Where the metaphor misleads

Every metaphor stops somewhere, and this one stops in three places worth knowing.

**Debt nobody touches charges no interest.** A bank loan costs money every month whatever you do. A
badly designed module that nobody has changed for years costs almost nothing, because interest is
paid only when somebody works in it. Some technical debt never needs repaying, and paying it off
anyway is spending principal to save interest that was never going to be charged.

**Nobody sends a statement.** A bank tells you each month what the loan cost. Technical debt sends
no bill: its interest is spread across hundreds of changes, each a little slower than it should
have been, and nobody adds them up. That is why debt stays invisible until somebody measures it,
and measuring it is lesson 5.

**The borrower and the payer are different people.** Whoever took the loan has often moved on.
At Coreto, the seat-hold code that locks database rows was written in the company's first years.
The people paying its interest today are the Reservations team and every buyer whose seat
vanished during an on-sale, and none of them chose it.

## Coreto's register, named

When Davi asked the teams which debts actually slowed them down, as distinct from code they simply
disliked, four came back named, with a team able to say what each cost them:

- the seat-hold locking in the reservation module;
- the hand-rolled PDF ticket generator;
- the flaky end-to-end test suite;
- the old reporting replica.

Four is a short list for a nine-year-old monolith, and it is short on purpose. The next section
asks how each of the four came to exist, because the answer says what Coreto should change so that
it borrows better next time.
