---
title: Parametric estimating
version: 1
---

Parametric estimating takes analogy one step further. Instead of comparing whole pieces of work, it finds a **measurable quantity** that drives the effort — screens, interfaces, reports, data tables — works out from past work how much effort one unit has taken, and multiplies.

## A worked example

Over the last year, the Agenda team built 40 screens across several features, and the time spent on screen work was **128 working days**. That is **3.2 days a screen**, a rate that already contains the design, the review, the tests and the rework the team actually did.

The online-booking feature needs **7 screens**. At 3.2 days each, the screen work comes to **22.4 working days**.

The estimate is as good as two things: whether screens really drive the effort for this kind of work, and whether the new screens are like the old ones. A booking screen with complex calendar logic is not a settings page, and a single rate for both hides the difference. Teams that use parametric estimating seriously keep separate rates for kinds of unit that behave differently.

## The formal models

Parametric estimating has a long and formal history. Barry Boehm's **COCOMO**, published in 1981 in the same book as the cone of uncertainty, estimated effort from the expected size of the code in lines, adjusted by factors for the team, the product and the environment. **Function points**, introduced by Allan Albrecht at IBM in 1979, measure size from the user's side — inputs, outputs, inquiries, files and interfaces — so that it can be counted before any code is written. Both are still used in contracts, particularly in public procurement, where a price per function point is a common way to buy software.

## Its strength and its trap

The strength of a parametric estimate is that it is **reproducible**: two people with the same counts and the same rate get the same number, which is useful when an estimate has to be defended. The trap is that a precise-looking rate makes the answer look more certain than it is. 22.4 days has a decimal place; the uncertainty in whether this feature really needs seven screens is far larger than the decimal. Lesson 10 calls this the fallacy of precision.
