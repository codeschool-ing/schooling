---
title: Four positions, and what to say to each
version: 1
---

The tables of this lesson reach the people who decide, and four positions come back. Each is held in good
faith, each is half right, and each has a reply.

**1. "Just remove age from the model, and the problem is gone."** The legal team's first instinct.

The second table of `by_age.py` is the reply. Removing age cut the young leavers' chance of a credit from
26.7% to 19.4%, and the model still separated the bands: the columns it kept pick out the over-65s with an
AUC of 0.872, `app_user` and boleto above all. **Unawareness changed who benefits without removing age from the
decision.** The useful version of the instinct is to keep age out of the model and in the audit.

**2. "It's a discount, not a loan. Nobody is harmed."** Marketing's view.

A benefit withheld is the harm. If one group is systematically less likely to be offered something of
value, that is unequal treatment even when nobody is charged anything. Brazil's general data protection
law, the LGPD, lists **non-discrimination** among the principles of processing personal data (art. 6,
IX): data may not be processed for unlawful or abusive discriminatory purposes. A small benefit lowers the
stakes; it does not remove the question.

**3. "Give every age group the same share of credits."** A board member who wants a simple rule.

`parity.py` priced it: R$ 1,088 over six months, fewer leavers reached, and credits moved away from the
youngest, the group that leaves most. The reply is the definitions table: **equal shares is the right goal
when the benefit should be spread evenly, and the wrong one when it is meant for those who need it.** Equal
recall fits this credit better.

**4. "The model is maths. It can't be biased."** An engineer who has not read this lesson.

The model learns from what happened, and it reproduces what it learns: the young leave more, so the model
credits them more; older subscribers use the app less, so `days_since_login` is missing for them more
often, and the model treats that gap as information. **A model is as fair as its data and its objective,
and both were chosen by people.** The tables are how anybody finds out which way it leans.

## What Ana writes in the frame

Lesson 1's frame gains three lines. **Age is kept out of the model and kept for audit.** Every month, the
recall of the credit is printed by age band, with lesson 2's bootstrap interval, and a band whose recall
falls clearly below the others is investigated. And a subscriber who asks why they were or were not
offered a credit gets an answer: the LGPD gives people the right to ask for a review of decisions made
solely by automated processing that affect their interests (art. 20), and lesson 19's SHAP values are
what make an answer possible.
