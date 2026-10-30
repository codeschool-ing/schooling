---
title: The secure score, and what it counts
version: 1
---

**The secure score is a percentage, and it counts resources, not recommendations.** Recommendations are
grouped into **security controls**, such as *enable MFA*, *encrypt data in transit* or *restrict
unauthorized network access*, and each control has a maximum number of points. A control earns its
points in proportion to the share of its resources that are healthy:

```
control score = max points × healthy resources ÷ (healthy + unhealthy resources)
secure score  = sum of control scores ÷ sum of max points × 100
```

A worked example, written by the course: *restrict unauthorized network access* is worth 4 points and
applies to the shop's 10 resources with a network surface, of which 6 are healthy. It contributes
4 × 6 ÷ 10 = 2.4 points. Fixing one more resource adds 0.4.

Three consequences follow, and each one shapes behaviour.

- **Partial credit counts.** Fixing three resources out of ten moves the score; a control does not have
  to be finished to be worth working on.
- **A control with many resources moves slowly.** One more healthy resource out of fifty is worth a
  fiftieth of the control; one out of two is worth half. A team chasing the number fixes the small
  controls first, which is not the same as fixing the dangerous things first.
- **Exemptions remove a resource from the count.** A recommendation that does not apply, a test
  resource or a risk accepted on purpose, can be exempted with a reason and an expiry date, and the
  score stops counting it. An exemption with no expiry is a hole somebody will forget.

So the score is a good trend line and a bad to-do list. It says whether posture is improving month on
month; it does not say what to fix this afternoon. That is the next section.
