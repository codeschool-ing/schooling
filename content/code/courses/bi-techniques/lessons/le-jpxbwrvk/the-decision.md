---
title: The decision, and its reasons
version: 1
---

The plan of lesson 7 said: ship if conversion rises significantly at 5 per cent and no guardrail is
clearly worse. Over the three weeks, conversion rose with p = 0.032. Read mechanically, the decision
is made.

The other two readings complicate it, and a good report says so rather than hiding it.

- **The interval** says the lasting lift could be anywhere from almost nothing to 0.76 points.
- **The weekly pattern** of lesson 9 says most of the lift came in the first week, and the last two
  weeks on their own show +0.07 points, not significant, with an interval reaching from −0.36 to
  +0.51.

So the defensible decision is to **follow the plan and ship, while stating that the lasting effect
is probably smaller than the three-week figure**, and to keep measuring conversion after launch
against the forecast of what it would have been without the change. Lessons 1 to 6 are exactly the
tools for that forecast. Changing the rule after seeing the data, in either direction, would be the
mistake: declaring a loss because the late weeks look flat is as much a post-hoc decision as
declaring a bigger win because week 1 looks great.

What the report says, in four lines:

> The one-step checkout raised first-order conversion from 4.28% to 4.67% over three weeks (+0.40
> points, 95% interval +0.03 to +0.76, p = 0.032). The split and the guardrails were clean. Most of
> the lift came in the first week; in weeks 2 and 3 the difference was +0.07 points (−0.36 to
> +0.51). We are shipping as planned and will track conversion against forecast for eight weeks.

**Every number is there, every doubt is named, and the decision follows the rule written before the
test.** That is what reading a result means.

## The truth, this once

`panela.py` built the test: the new page adds 0.4 points for good, plus a novelty bonus that starts
at 1.2 points and fades by about two thirds every three days. So the lasting effect really is 0.4
points, inside both intervals. The three-week estimate of 0.40 happens to match it, carried up by
the novelty and down by noise; the two-week estimate of 0.07 was pulled down by noise. Neither
reader could have known which, which is why intervals are reported and why the plan was to measure
after launch.
