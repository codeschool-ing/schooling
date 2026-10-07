---
title: An estimate, a target and a commitment
version: 1
---

"How long will it take?" sounds like one question. It is usually three, and most of the damage done by estimates comes from answering one while the person asking hears another. Steve McConnell's *Software Estimation* (2006) separates them, and the separation is worth learning before any technique.

- An **estimate** is a prediction of how long something will take or how much it will cost. It is a statement about the world, and it can be right or wrong.
- A **target** is a statement of what the business wants: *we need online booking before the clinics' annual contract renewal in May*. It is a wish, and it can be reasonable or unreasonable.
- A **commitment** is a promise to deliver a defined piece of work by a date, at a level of quality.

The sequence that works is that the business states a target, the team produces an estimate, and the two are compared. If the estimate fits the target, the team can commit. If it does not, somebody changes the scope, the date or the resources, and the team commits to what is left. The sequence that fails is the one where the target is quietly renamed an estimate: *"the estimate is May, because that is when we need it"*. Nothing about the work changed; only the word did.

## Why estimates go wrong in one direction

Estimates of software work are not wrong at random. They are wrong **mostly on the short side**, and the reasons are well documented. Daniel Kahneman and Amos Tversky named the **planning fallacy** in 1979: people estimate their own tasks by imagining how the work will go, and an imagined plan has no interruptions, no illness, no misunderstood requirement and no dependency that arrives late. Douglas Hofstadter put the experience in a joke that is also a law: *it always takes longer than you expect, even when you take into account Hofstadter's law*.

The remedy that works best is not trying harder to imagine. It is **using what happened last time**, which is what estimating by analogy and parametric estimating, the next two sections, both do.

## What a good estimate looks like

A good estimate has three parts: **a range or a probability**, not a single number; **the assumptions** it rests on; and **when it was made**, because lesson 1's cone of uncertainty says an estimate made before the requirements are known is wider than one made after. "Between 18 and 26 working days, 85% confident, assuming the payment provider's sandbox is available from the first week, as of 2 March" is a good estimate. "Three weeks" is a number that will be remembered as a promise.
