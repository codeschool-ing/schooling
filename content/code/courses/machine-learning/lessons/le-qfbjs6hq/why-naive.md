---
title: What is naive about it, and why it works anyway
version: 1
---

Naive Bayes multiplies the evidence of each word as though the words were **independent of each
other, given the class**: as though knowing a complaint says *bruised* told you nothing about
whether it also says *bananas*. That is false for nearly all text. Words travel in phrases; *arrived*
and *late* come together; a review that mentions *refund* is likely to mention something that went
wrong. The assumption is the naive part, and the model makes it knowingly, because it turns an
impossible calculation into multiplying a few counts.

The surprise is how little it hurts the **ranking**. To decide whether a review is a complaint, the
model only has to put complaints above non-complaints; it does not have to get the probability
exactly right. Correlated words make it count the same evidence twice, which pushes every score
further towards the end it was already heading for, and the order of the reviews mostly survives.

What it does hurt is the **probabilities themselves**. The last line of `bayes.py` says it: **56.8%
of the test reviews were scored below 1% or above 99%.** Each correlated word adds its evidence
again, and the model ends up certain where it has no right to be. A review it scores at 99.9% is not
a thousand times surer than one at 99%; both are mostly *very likely a complaint*.

That matters as soon as the number is used as a probability rather than a ranking. Lesson 11 sets a
threshold from costs, and a threshold computed from costs assumes that 0.3 means three in ten.
**Naive Bayes probabilities need calibrating before they are used that way**, which lesson 11 does
for any model whose scores are not to be trusted as they come.

## Where it fits

Naive Bayes is the right first model for text, for the same reason linear regression is the right
first model for numbers: it is fast, it needs no tuning, it is readable, and it is a strong baseline.
Spam filters ran on it for years. Its limits are the independence assumption and the overconfident
scores; on the churn data, where the columns are few, numeric and correlated, it has no advantage
at all, and this course does not use it there.
