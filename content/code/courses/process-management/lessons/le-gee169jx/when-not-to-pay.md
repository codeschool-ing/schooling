---
title: When not to pay it down
version: 1
---

Not every debt should be paid. Treating repayment as always good is the mirror of treating debt as always bad, and both lead to spending effort where it buys little. A debt is worth paying when its interest, over the time the code will live, is larger than its principal. Several common situations fail that test.

## Code that will be deleted

A module scheduled to be replaced in the next quarter does not need refactoring now. Every hour spent improving it is lost when it goes. The interest still has to be paid until then, but paying the principal would be paying twice.

## Code nobody changes

A tangled module that works, is not touched, and is not on the path of any planned change charges no interest. It may look alarming in a static-analysis report, and it may offend the people who read it; it costs the team nothing while it sits there. Leave it, and record it, so that the day a change is planned the debt is priced into that change.

## Prototypes and experiments

Code written to learn something — a spike, a prototype shown to three receptionists, an experiment with one clinic — is meant to be cheap and disposable. Holding it to production standards slows the learning that was its purpose. The risk is the prototype that quietly becomes production, and the defence is to **decide explicitly** when an experiment graduates, and to pay its debt at that moment.

## When the interest is tiny

A debt whose measured interest is an hour a month is not worth a week of work, however ugly the code. The fifth section of this lesson exists to find these: a debt that everybody complains about and nobody has measured sometimes turns out, measured, to cost almost nothing.

## Accepting debt deliberately

Finally, taking on debt can be the right decision. Shipping online booking a week early to meet the clinics' contract renewal, with a simpler payment integration that will need reworking, can be worth far more than the rework costs. That is the prudent, deliberate cell of Fowler's quadrant. It is good management when the decision is **written down with its interest and its repayment trigger**, in an architecture decision record, so that it is paid when it comes due — and poor management when it is not written down at all.
